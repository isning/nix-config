"""Exercise display handoff and recovery without accessing a real compositor."""

import copy
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from sunshine_niri import OUTPUT, Session, active, client_value


def output(name, enabled=True, make="Acme", x=0):
    return {
        "name": name,
        "make": make,
        "modes": [{"width": 1920, "height": 1080, "refresh_rate": 60000}],
        "current_mode": 0 if enabled else None,
        "logical": {"x": x, "y": 0, "scale": 1.5} if enabled else None,
    }


class FakeNiri:
    socket = "/test/niri.sock"

    def __init__(self):
        self.monitors = {
            "eDP-1": output("eDP-1"),
            "HDMI-A-1": output("HDMI-A-1", x=-1280),
            "DP-1": output("DP-1", enabled=False),
        }
        self.fail = None
        self.commands = []

    def outputs(self):
        return copy.deepcopy(self.monitors)

    def command(self, *args):
        self.commands.append(args)
        if args == self.fail:
            self.fail = None
            raise RuntimeError("Simulated IPC failure")
        if args[0] == "create-virtual-output":
            options = dict(zip(args[1::2], args[2::2]))
            monitor = output(options["--name"], make="niri")
            monitor["modes"] = [
                {
                    "width": int(options["--width"]),
                    "height": int(options["--height"]),
                    "refresh_rate": int(options["--refresh-rate"]) * 1000,
                }
            ]
            self.monitors[monitor["name"]] = monitor
        elif args[0] == "remove-virtual-output":
            del self.monitors[args[1]]
        else:
            _, name, action, *values = args
            monitor = self.monitors[name]
            if action == "off":
                monitor["current_mode"] = None
                monitor["logical"] = None
            elif action == "on":
                monitor["current_mode"] = 0
                monitor["logical"] = monitor["logical"] or {
                    "x": 0,
                    "y": 0,
                    "scale": 1.5,
                }
            elif action == "position":
                monitor["logical"]["x"], monitor["logical"]["y"] = map(int, values[-2:])
            elif action == "scale":
                monitor["logical"]["scale"] = float(values[0])
            elif action == "custom-mode":
                dimensions, fps = values[0].split("@")
                width, height = map(int, dimensions.split("x"))
                monitor["modes"] = [
                    {"width": width, "height": height, "refresh_rate": int(fps) * 1000}
                ]
            else:
                raise AssertionError(args)


class DisplayHandoffTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.backend = FakeNiri()
        self.state = Path(self.directory.name) / "state.json"
        self.session = Session(self.backend, self.state)

    def assert_local_restored(self):
        self.assertTrue(active(self.backend.monitors["eDP-1"]))
        self.assertTrue(active(self.backend.monitors["HDMI-A-1"]))
        self.assertFalse(active(self.backend.monitors["DP-1"]))
        self.assertEqual(self.backend.monitors["HDMI-A-1"]["logical"]["x"], -1280)
        self.assertNotIn(OUTPUT, self.backend.monitors)
        self.assertFalse(self.state.exists())

    def test_handoff_and_restore_preserve_original_disabled_output_and_layout(self):
        self.session.start(2560, 1600, 120)
        self.assertTrue(self.state.exists())
        self.assertTrue(active(self.backend.monitors[OUTPUT]))
        self.assertFalse(active(self.backend.monitors["eDP-1"]))
        self.assertFalse(active(self.backend.monitors["HDMI-A-1"]))
        # Recovery is also available from a fresh process, not just the preparation process.
        Session(self.backend, self.state).stop()
        self.assert_local_restored()
        self.session.stop()

    def test_retry_changes_resolution_without_overwriting_recovery_state(self):
        self.session.start(2560, 1600, 120)
        self.session.start(1920, 1080, 60)
        self.assertEqual(self.backend.monitors[OUTPUT]["modes"][0]["width"], 1920)
        self.session.stop()
        self.assert_local_restored()

    def test_partial_handoff_failure_rolls_back_without_sunshine_undo(self):
        self.backend.fail = ("output", "HDMI-A-1", "off")
        with self.assertRaisesRegex(RuntimeError, "Simulated"):
            self.session.start(2560, 1600, 120)
        self.assert_local_restored()

    def test_unsupported_create_request_never_turns_local_outputs_off(self):
        self.backend.fail = (
            "create-virtual-output",
            "--name",
            OUTPUT,
            "--width",
            "2560",
            "--height",
            "1600",
            "--refresh-rate",
            "120",
        )
        with self.assertRaisesRegex(RuntimeError, "Simulated"):
            self.session.start(2560, 1600, 120)
        self.assertFalse(any(command[-1] == "off" for command in self.backend.commands))
        self.assert_local_restored()

    def test_unplugged_monitor_does_not_block_restoration(self):
        self.session.start(2560, 1600, 120)
        del self.backend.monitors["HDMI-A-1"]
        self.session.stop()
        self.assertTrue(active(self.backend.monitors["eDP-1"]))
        self.assertNotIn(OUTPUT, self.backend.monitors)

    def test_failed_restoration_keeps_state_and_can_be_retried(self):
        self.session.start(2560, 1600, 120)
        self.backend.fail = (
            "output",
            "HDMI-A-1",
            "position",
            "set",
            "--",
            "-1280",
            "0",
        )
        with self.assertRaisesRegex(RuntimeError, "Simulated"):
            self.session.stop()
        self.assertTrue(self.state.exists())
        self.assertTrue(active(self.backend.monitors[OUTPUT]))
        self.session.stop()
        self.assert_local_restored()

    def test_saved_state_from_another_session_is_not_applied(self):
        self.session.start(2560, 1600, 120)
        self.backend.socket = "/test/another-niri.sock"
        with self.assertRaisesRegex(RuntimeError, "different Niri session"):
            self.session.stop()
        self.assertTrue(self.state.exists())
        self.assertTrue(active(self.backend.monitors[OUTPUT]))

    def test_missing_local_displays_keep_the_last_virtual_output_for_recovery(self):
        self.session.start(2560, 1600, 120)
        del self.backend.monitors["eDP-1"]
        del self.backend.monitors["HDMI-A-1"]
        with self.assertRaisesRegex(RuntimeError, "No local display"):
            self.session.stop()
        self.assertTrue(active(self.backend.monitors[OUTPUT]))
        self.assertTrue(self.state.exists())

    def test_existing_unmanaged_virtual_output_is_not_removed(self):
        self.backend.monitors[OUTPUT] = output(OUTPUT, make="niri")
        with self.assertRaisesRegex(RuntimeError, "unmanaged"):
            self.session.start(2560, 1600, 120)
        self.session.stop()
        self.assertTrue(active(self.backend.monitors[OUTPUT]))

    def test_invalid_client_dimensions_are_rejected(self):
        for value in ["0", "-1", "1920; echo bad", "999999"]:
            with (
                self.subTest(value=value),
                patch.dict(os.environ, SUNSHINE_CLIENT_WIDTH=value),
                self.assertRaises(ValueError),
            ):
                client_value("WIDTH", 16384)


if __name__ == "__main__":
    unittest.main()
