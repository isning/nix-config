"""Exercise real Cargo builds, Kache reuse, and Overstay's Cargo-lock protection."""

import argparse
import fcntl
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path


def run(argv, cwd, env):
    result = subprocess.run(
        argv, cwd=cwd, env=env, text=True, capture_output=True, check=False
    )
    if result.returncode:
        raise AssertionError(f"{argv}: {result.stdout}\n{result.stderr}")
    return result.stdout


def age_tree(path, timestamp):
    if not path.exists():
        return
    for child in path.rglob("*"):
        if not child.is_symlink():
            os.utime(child, (timestamp, timestamp))
    os.utime(path, (timestamp, timestamp))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--overstay", required=True)
    parser.add_argument("--kache", required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="rust-cache-check-") as temporary:
        root = Path(temporary)
        cache = root / "cache"
        build_root = cache / "build"
        build_root.mkdir(parents=True)
        shim = root / "bin"
        shim.mkdir()
        (shim / "cargo").symlink_to(args.overstay)
        state = root / "overstay-state"
        policy = root / "overstay.toml"
        # Record builds while suppressing detached workers during fixture setup.
        policy.write_text("disabled_for_fixture_setup = true\n")
        kache_config = root / "kache.toml"
        kache_config.write_text(
            '[cache]\nlocal_max_size = "1GiB"\n'
            "auto_clean_orphaned_targets = false\n"
            "auto_clean_idle_targets_days = 0\n"
            "auto_clean_unused_units_days = 0\nauto_recover_targets = false\n"
        )
        env = os.environ.copy()
        env.pop("CARGO_TARGET_DIR", None)
        env.pop("CARGO_BUILD_TARGET_DIR", None)
        env.update(
            PATH=f"{shim}:{env['PATH']}",
            CARGO_HOME=str(root / "cargo-home"),
            CARGO_BUILD_BUILD_DIR=str(build_root / "{workspace-path-hash}"),
            CARGO_OVERSTAY_BUILD_ROOT=str(build_root),
            CARGO_OVERSTAY_STATE=str(state),
            CARGO_OVERSTAY_CONFIG=str(policy),
            KACHE_CACHE_DIR=str(cache / "kache"),
            KACHE_CONFIG=str(kache_config),
            KACHE_HOST_CONFIG="",
            RUSTC_WRAPPER=args.kache,
        )
        projects = [root / "worktree-a", root / "worktree-b"]
        build_dirs = []
        try:
            for project in projects:
                (project / "src").mkdir(parents=True)
                (project / "Cargo.toml").write_text(
                    '[package]\nname = "cache-fixture"\nversion = "0.1.0"\nedition = "2021"\n'
                )
                (project / "src/lib.rs").write_text("pub fn value() -> u32 { 7 }\n")
                (project / "src/main.rs").write_text(
                    'fn main() { println!("{}", cache_fixture::value()); }\n'
                )
                run(["cargo", "build", "--offline"], project, env)
                metadata = json.loads(
                    run(
                        [
                            "cargo",
                            "metadata",
                            "--offline",
                            "--no-deps",
                            "--format-version=1",
                        ],
                        project,
                        env,
                    )
                )
                build = Path(metadata["build_directory"])
                assert build.is_relative_to(build_root), metadata
                assert Path(metadata["target_directory"]) == project / "target", (
                    metadata
                )
                assert (
                    run(
                        [str(project / "target/debug/cache-fixture")], project, env
                    ).strip()
                    == "7"
                )
                assert str(build) in state.read_text(), (
                    "Central build directory was not enrolled"
                )
                build_dirs.append(build)
            assert build_dirs[0] != build_dirs[1], "Worktrees shared intermediate state"
            stats = json.loads(run([args.kache, "stats", "--json"], root, env))
            assert stats["local_hits"] > 0, (
                "The second worktree did not reuse the compiler cache"
            )
            print(f"Passed: compiler cache reuse ({stats['local_hits']} local hits)")

            # A normal edit should keep Kache's adaptive incremental path available.
            (projects[0] / "src/lib.rs").write_text("pub fn value() -> u32 { 8 }\n")
            run(["cargo", "build", "--offline"], projects[0], env)
            assert (build_dirs[0] / "debug/incremental.kache-auto").is_dir()

            old = int(time.time()) - 31 * 86400
            current_state = state.read_text().splitlines()
            aged_rows = []
            for row in current_state[1:]:
                timestamp, workspace, directory = row.split("\t")
                if Path(workspace) == projects[0]:
                    timestamp = str(old)
                    age_tree(Path(directory), old)
                aged_rows.append(f"{timestamp}\t{workspace}\t{directory}")
            policy.write_text('max_total_size = "1MiB"\nmax_target_size = "100GiB"\n')
            state.write_text("0\t0\n" + "\n".join(aged_rows) + "\n")
            lock_path = build_dirs[0] / "debug/.cargo-build-lock"
            with lock_path.open("rb") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                run([args.overstay, "__gc-detached", str(build_dirs[1])], root, env)
                assert build_dirs[0].exists(), (
                    "GC removed a build directory locked by Cargo"
                )
            # Reset only the isolated fixture's maintenance throttle, then retry.
            rows = state.read_text().splitlines()[1:]
            state.write_text("0\t0\n" + "\n".join(rows) + "\n")
            run([args.overstay, "__gc-detached", str(build_dirs[1])], root, env)
            assert not build_dirs[0].exists(), (
                "GC failed to evict an unlocked stale build directory"
            )
            assert build_dirs[1].exists(), "GC removed the current build directory"
            assert (projects[0] / "src/lib.rs").exists(), "GC touched project sources"
            print(
                "Passed: worktree isolation, adaptive incremental, stale GC, and Cargo locks"
            )
        finally:
            run([args.kache, "daemon", "stop"], root, env)


if __name__ == "__main__":
    main()
