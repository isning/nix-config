# Sunshine virtual desktop

Saika exposes declarative **Desktop** and **Virtual Desktop** applications to Artemis/Moonlight.
**Desktop** streams the existing desktop without creating a virtual output or disabling physical
displays. It uses the first connected display when no managed virtual output exists. **Virtual
Desktop** creates a client-sized output and switches off the active physical displays for streaming.
Quit an active virtual desktop session before switching to the ordinary desktop so its displays are
restored.

The application list is managed in `sunshine.nix`; any existing user-managed `apps.json` is left
untouched but is not used by this configuration. Pairing credentials remain in the existing Sunshine
state directory.

The preparation command creates the Niri output `sunshine` at the client's requested width, height
and refresh rate, with scale 1. It then disables the physical outputs that were active. Exiting the
application restores those outputs and their positions before removing the virtual output. Outputs
that were already disabled stay disabled. Original modes, scale, transform and VRR configuration are
not modified.

Recovery state is checkpointed in `$XDG_RUNTIME_DIR/sunshine-niri/state.json`. Preparation failures
roll back immediately. A repeated start reuses this state, and Sunshine's `ExecStartPre` and
`ExecStopPost` recover interrupted sessions. If no other display can be restored, recovery keeps the
virtual output and its state instead of removing the last display.

## Apply and connect

1. Run `just niri`, then log out and back in to load the patched compositor.
2. Open `https://localhost:27990` on the host for initial Sunshine setup/pairing if needed. The web
   UI remains restricted to localhost; the existing stream firewall rules and mandatory encryption
   are retained.
3. In Artemis/Moonlight, choose the desired resolution and FPS, disable HDR, and launch **Virtual
   Desktop**. This is a Sunshine preparation-command setup; Apollo-specific virtual-display controls
   are not provided.
4. Enable the client's option to quit the host application when ending a stream, or explicitly quit
   **Virtual Desktop** from the client. Sunshine does not execute undo commands on a plain
   disconnect; reconnecting resumes the virtual desktop and leaves the physical displays off until
   app exit.

The current Niri virtual-output patch supports SDR. Sunshine uses `wlr` capture and NVENC encoding.
CUDA capture is disabled in the package to use the RAM transfer path between an Intel-rendered
desktop and the NVIDIA encoder; NVENC still performs hardware encoding.

## Recovery and verification

These commands run in the logged-in Niri session:

```bash
sunshine-niri status
sunshine-niri stop
systemctl --user status sunshine
journalctl --user -u sunshine --since '5 minutes ago'
```

`status` reads the live output state without changing displays. `stop` restores the saved local
outputs and removes only the virtual output owned by this helper. It is safe to repeat.

Build the helper and run its recovery tests without changing the live desktop:

```bash
nix build --no-link -L .#nixosConfigurations.saika-niri.config.system.build.sunshine-niri
nix build --no-link -L .#nixosConfigurations.saika-niri.config.system.build.sunshine-niri-tests
just test
```

The tests simulate compositor failures, partial handoff, repeated starts, unplugged monitors and
recovery from a fresh process. Streaming quality and hardware encoding still require a real client
session to verify.
