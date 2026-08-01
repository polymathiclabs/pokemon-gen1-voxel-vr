# Pokémon Red voxel VR prototype

This workspace combines:

- `gen1recomp/`: the LÖVE 11.5/Lua gameplay port;
- `DramaticShapeVoxelMod/`: the voxel/diorama renderer from the video;
- `Pokemon Red.gb`: a user-supplied canonical US Pokémon Red ROM.

The VR work is optional. Desktop play remains available without SteamVR,
OpenXR, or a headset. When the optional bridge is present, the app uses the
OpenXR runtime selected by Windows (SteamVR can be that runtime) and does not
need a Steam App ID or Steam distribution.

## Production launchers

The two supported Windows entrypoints are:

- `Play-Windows.bat` — desktop voxel mode. It keeps the existing in-game
  ROM/save/mod launcher and includes the ABOVE / 3RD / POV camera modes; press
  `V` in-game to cycle them. It does not require SteamVR or OpenXR.
- `Play-VR.bat` — headset mode. It checks the native `xrbridge.dll`, OpenXR
  loader, SteamVR, and the active SteamVR runtime before starting the same
  voxel build. It does not use Steam distribution or a Steam App ID.

Both entrypoints resolve their paths relative to the workspace and run setup
when the generated data or voxel-mod link is missing. The first desktop launch
opens the same launcher used by the upstream Pokemon game, where the Red ROM
and save slots remain managed.

## First run

From PowerShell in this folder:

```powershell
./setup-vr.ps1
./play-vr.ps1
```

For the one-click headset launch, double-click `Play-VR.bat` (or the older
`launch-vr.bat` alias). It checks the
ROM, generated data, LÖVE 11.5, SteamVR, and `xrbridge.dll`; runs setup when
needed; selects SteamVR as the active Windows OpenXR runtime; adds SteamVR's
loader directory; starts SteamVR; and launches the game. Selecting the runtime
may show one normal Windows UAC prompt. It can be run from any folder because
it resolves paths relative to itself.

If the bridge has not been built yet, the launcher stops and points to
`gen1recomp/vrbridge/README.md`. Use `launch-vr.bat -CheckOnly` to inspect the
installation without starting anything, or `launch-vr.bat -DesktopPreview` to
skip the headset and native bridge checks. `-NoRuntimeSwitch` prevents the
launcher from changing the active OpenXR runtime.

To build the missing native bridge on Windows after the C++ Build Tools,
CMake, and the setup dependencies are available, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-vrbridge.ps1
```

The setup script validates the ROM, builds the private generated data, and
links the voxel mod into the game. It does not copy the ROM into a release
package. If the fast setup has not yet built the full audio cache, the VR
launcher supplies the validated ROM to the upstream importer so it can finish
the cache and boot automatically.

For normal desktop play, use `Play-Windows.bat`; it leaves the upstream
interactive ROM, save-slot, and mod launcher in control. The lower-level
`gen1recomp/scripts/run.ps1` entrypoint remains available for development.

For diagnostics, use `Play-Windows.bat -CheckOnly` or
`Play-VR.bat -CheckOnly`. `Play-VR.bat -DesktopPreview` exercises the VR
composition without requiring a headset or native bridge.

## VR runtime

The bridge targets OpenXR over the existing LÖVE desktop OpenGL context. Set
SteamVR as the active OpenXR runtime before using the bridge; the game does
not launch through Steam. The voxel overworld uses true head-tracked stereo.
Intro, menus, battles, and other non-voxel screens use a monoscopic full-frame
fallback copied to both eyes, with the existing keyboard and gamepad controls
retained as a fallback.
OpenXR controller actions are also mapped into the normal Game Boy input:
thumbstick movement, right A/B, left X for START, and left Y for SELECT.
Click either thumbstick to recenter the seated view on the character; the
headset's physical translation is kept inside a small collision-safe envelope
while rotation remains unrestricted.
Oculus Touch works through Virtual Desktop without hand tracking.
The ordinary game window remains a single monoscopic desktop mirror; a
side-by-side eye preview is a SteamVR "Display VR View" debug feature, not a
requirement for headset rendering. The headset launcher enables a small
desktop-only VR diagnostic showing session state, submitted-frame count, and
native errors; it never draws over the headset image.

Native bridge build instructions are in `gen1recomp/vrbridge/README.md`. To
launch with a DLL built elsewhere, use
`./play-vr.ps1 -XrBridge 'C:\path\to\xrbridge.dll'`.

The setup step requires Windows PowerShell, Python 3.10+, internet access for
the Pillow dependency, and LÖVE 11.5. If script execution is restricted, use
the full form:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-vr.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\play-vr.ps1
```

Without a compiled bridge, `play-vr.ps1` is a supported desktop stereo
preview. Headset-backed VR additionally requires the native DLL, OpenXR
loader, and SteamVR as the active OpenXR runtime. Setup creates ROM-derived
files in the developer checkout; exclude both the ROM and generated
`data/generated` and `assets/generated` trees from anything you redistribute.

## Legal and compatibility notes

The ROM and ROM-derived game data are not redistributable. Use a legally
obtained ROM and keep it out of source releases. This workspace contains the
upstream projects as separate Git working trees so their licenses and history
remain visible.
