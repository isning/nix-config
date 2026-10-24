"""Manage one Sunshine virtual output without losing the local display state."""

import argparse
import fcntl
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

OUTPUT = "sunshine"
RECOVERY_ERRORS = (OSError, ValueError, RuntimeError, subprocess.SubprocessError)


def active(output):
    return output.get("current_mode") is not None and output.get("logical") is not None


def physical(output):
    return output["name"] != OUTPUT and output.get("make") != "niri"


class Niri:
    def __init__(self, socket):
        self.socket = socket

    def command(self, *args):
        result = subprocess.run(
            ["niri", "msg", "--json", *args],
            env={**os.environ, "NIRI_SOCKET": self.socket},
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip())
        return json.loads(result.stdout) if result.stdout.strip() else None

    def outputs(self):
        return self.command("outputs")


class Session:
    def __init__(self, backend, state_file):
        self.backend = backend
        self.state_file = state_file

    def save(self, state):
        temporary = self.state_file.with_suffix(".tmp")
        temporary.write_text(json.dumps(state))
        temporary.replace(self.state_file)

    def load(self):
        if not self.state_file.exists():
            return None
        state = json.loads(self.state_file.read_text())
        if state["socket"] != self.backend.socket:
            raise RuntimeError(
                "Saved state belongs to a different Niri session; refusing to change displays"
            )
        return state

    def wait(self, predicate):
        deadline = time.monotonic() + 5
        while True:
            outputs = self.backend.outputs()
            if predicate(outputs):
                return outputs
            if time.monotonic() >= deadline:
                raise RuntimeError("Timed out waiting for the Niri output change")
            time.sleep(0.1)

    def start(self, width, height, fps):
        outputs = self.backend.outputs()
        state = self.load()
        if state is None:
            if OUTPUT in outputs:
                raise RuntimeError(
                    "An unmanaged 'sunshine' output already exists; refusing to take it over"
                )
            state = {"socket": self.backend.socket, "outputs": {}}

        # Checkpoint before any mutation, including new monitors attached during a retry.
        for name, output in outputs.items():
            if physical(output) and active(output):
                state["outputs"].setdefault(name, output["logical"])
        self.save(state)

        try:
            if OUTPUT not in outputs:
                self.backend.command(
                    "create-virtual-output",
                    "--name",
                    OUTPUT,
                    "--width",
                    str(width),
                    "--height",
                    str(height),
                    "--refresh-rate",
                    str(fps),
                )
            else:
                self.backend.command("output", OUTPUT, "on")
                self.backend.command(
                    "output", OUTPUT, "custom-mode", f"{width}x{height}@{fps}"
                )
            self.backend.command("output", OUTPUT, "scale", "1")
            self.backend.command("output", OUTPUT, "position", "set", "0", "0")

            def ready(current):
                output = current.get(OUTPUT)
                if not output or not active(output):
                    return False
                mode = output["modes"][output["current_mode"]]
                return (mode["width"], mode["height"], mode["refresh_rate"]) == (
                    width,
                    height,
                    fps * 1000,
                )

            self.wait(ready)
            # Only turn local displays off after the virtual output has the requested mode.
            for name, output in outputs.items():
                if physical(output) and active(output):
                    self.backend.command("output", name, "off")
            self.wait(
                lambda current: (
                    not any(physical(o) and active(o) for o in current.values())
                )
            )
        except BaseException:
            # Sunshine does not undo the preparation command that itself failed.
            try:
                self.stop()
            except RECOVERY_ERRORS as error:
                print(
                    f"Recovery needs attention: {error}; run sunshine-niri stop",
                    file=sys.stderr,
                )
            raise

    def stop(self):
        state = self.load()
        if state is None:
            return
        outputs = self.backend.outputs()
        errors = []
        for name, logical in state["outputs"].items():
            if name not in outputs:
                continue  # An unplugged monitor must not prevent the others from recovering.
            try:
                self.backend.command("output", name, "on")
                self.backend.command(
                    "output",
                    name,
                    "position",
                    "set",
                    "--",
                    str(logical["x"]),
                    str(logical["y"]),
                )
            except RECOVERY_ERRORS as error:
                errors.append(f"{name}: {error}")

        def restored(current):
            return all(
                name not in current or active(current[name])
                for name in state["outputs"]
            )

        outputs = self.wait(restored)
        if errors:
            raise RuntimeError("; ".join(errors))
        if OUTPUT in outputs:
            if not any(
                name != OUTPUT and active(output) for name, output in outputs.items()
            ):
                raise RuntimeError(
                    "No local display is available; keeping the virtual output and recovery state"
                )
            self.backend.command("remove-virtual-output", OUTPUT)
            self.wait(lambda current: OUTPUT not in current)
        self.state_file.unlink()


def client_value(name, maximum):
    raw = os.environ.get(f"SUNSHINE_CLIENT_{name}", "")
    if not raw.isdecimal() or not 1 <= int(raw) <= maximum:
        raise ValueError(
            f"SUNSHINE_CLIENT_{name} must be an integer from 1 to {maximum}"
        )
    return int(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["start", "stop", "status"])
    args = parser.parse_args()
    dimensions = None
    if args.action == "start":
        dimensions = (
            client_value("WIDTH", 16384),
            client_value("HEIGHT", 16384),
            client_value("FPS", 1000),
        )

    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    directory = runtime / "sunshine-niri"
    directory.mkdir(mode=0o700, exist_ok=True)
    state_file = directory / "state.json"
    with (directory / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.action == "stop" and not state_file.exists():
            return
        socket = os.environ.get("NIRI_SOCKET")
        if args.action == "stop":
            saved_socket = json.loads(state_file.read_text())["socket"]
            if not Path(saved_socket).exists():
                # Niri has exited; its transient output changes no longer exist.
                state_file.unlink()
                return
            socket = socket or saved_socket
        if not socket:
            sockets = [path for path in runtime.glob("niri.*.sock") if path.is_socket()]
            if len(sockets) != 1:
                raise RuntimeError(
                    "Run inside the Niri session or set NIRI_SOCKET explicitly"
                )
            socket = str(sockets[0])
        session = Session(Niri(socket), state_file)
        if args.action == "start":
            session.start(*dimensions)
        elif args.action == "stop":
            session.stop()
        else:
            print(
                json.dumps(
                    {"session": session.load(), "outputs": session.backend.outputs()},
                    indent=2,
                )
            )


def interrupted(signum, frame):
    raise InterruptedError(f"Interrupted by signal {signum}")


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        main()
    except (*RECOVERY_ERRORS, KeyboardInterrupt) as error:
        print(f"sunshine-niri: {error}", file=sys.stderr)
        sys.exit(1)
