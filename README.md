# Pokémon Red Voxel VR

An unofficial Windows fan project that combines the [Gen1Recomp engine](https://github.com/bryanthaboi/gen1recomp), the [Dramatic Shape Voxel Mod](https://github.com/DramaticShape/DramaticShapeVoxelMod), and an optional OpenXR/SteamVR bridge.

The project adds a voxel overworld, above/third-person/first-person camera modes, controller support, staged battles, and optional head-tracked stereo VR. Desktop play does not require SteamVR or a headset.

## Downloads

Once the first GitHub release is published, these are the two end-user downloads:

- [Download Desktop build](https://github.com/polymathiclabs/pokemon-red-voxel-vr/releases/latest/download/pokemon-red-voxel-desktop-latest.zip)
- [Download VR build](https://github.com/polymathiclabs/pokemon-red-voxel-vr/releases/latest/download/pokemon-red-voxel-vr-latest.zip)

The archives are intended to contain the runnable source build and launchers, but no Pokémon ROM, save files, generated ROM-derived data, or personal build cache. The VR archive additionally contains the matching native bridge; SteamVR and OpenXR remain system dependencies.

> **Unofficial fan project — not affiliated with Nintendo, The Pokémon Company, Game Freak, Creatures, or any of their subsidiaries or partners.** Pokémon, Pokémon character names, artwork, music, and related trademarks are the property of their respective owners. This project is not endorsed, sponsored, or approved by any of them.

## Important legal and distribution rules

- This repository does **not** include a ROM, ROM dump, save data, or ROM-derived generated game data.
- You must provide your own legally obtained compatible ROM. Do not upload it to GitHub, attach it to a release, or distribute it with this project.
- Do not commit `Pokemon Red.gb`, `data/generated`, `assets/generated`, `xrbridge.dll`, `.vr-build`, or personal save files.
- Keep the upstream copyright notices, licenses, history, and attribution when maintaining the engine or voxel-mod repositories.
- Before making any repository public, review the upstream licenses and the terms for every third-party asset and dependency.

The release archives are not “copyright-free”: source code and third-party dependencies remain copyrighted by their respective authors and must be distributed under their licenses. The important restriction is that the archives do not bundle the Pokémon ROM or unauthorized ROM-derived game content.

## Two supported modes

| Mode | Requires | Launch |
| --- | --- | --- |
| Desktop voxel | Windows x64, Python 3.10+, LÖVE 11.5, and a compatible ROM | `Play-Windows.bat` |
| Headset VR | Everything in Desktop, plus Steam, SteamVR as the active Windows OpenXR runtime, a compatible headset connection, and matching x64 `xrbridge.dll` | `Play-VR.bat` |

Desktop mode includes the normal upstream ROM/save/mod launcher. It does not start Steam, load OpenXR, or require a Steam App ID.

VR mode uses SteamVR as a system OpenXR runtime. It is a standalone executable workflow, not a Steam Store release and not a Steamworks application. Quest headsets can connect through Virtual Desktop, Link, or Air Link, provided SteamVR sees the headset and SteamVR is the active OpenXR runtime.

### Desktop mode

Install Python 3.10+ and LÖVE 11.5 first. On Windows systems with `winget`:

```powershell
winget install --exact --id Python.Python.3.12
winget install --exact --id Love2d.Love2d
```

Then download and extract the Desktop archive. Place your legally obtained ROM next to the launcher, or keep it elsewhere and pass its path:

```powershell
./Play-Windows.bat -RomPath 'C:/Games/Pokemon Red.gb'
```

The first run may take a few minutes while the private ROM-derived cache is built. Later launches can use `Play-Windows.bat` directly.

### Headset VR mode

Install the desktop requirements first, then install Steam and SteamVR. Start SteamVR once, confirm that the headset is visible, and set SteamVR as the active OpenXR runtime in SteamVR settings.

For an end-user release, place the matching x64 `xrbridge.dll` beside the root launcher before running the VR command. The bridge must match the installed LÖVE/LuaJIT architecture. If you are building the bridge from source, also install:

- Visual Studio 2022 Build Tools with the Desktop C++ workload;
- CMake 3.20 or newer;
- the OpenXR SDK headers;
- LuaJIT headers and the matching `lua51.dll` from LÖVE 11.5.

The project helper can build the bridge after those prerequisites are installed. See [`gen1recomp/vrbridge/README.md`](gen1recomp/vrbridge/README.md).

Then download and extract the VR archive. Confirm that `xrbridge.dll` is beside the launcher, place your legally obtained ROM next to the launcher or pass its path, and run:

```powershell
./Play-VR.bat -RomPath 'C:/Games/Pokemon Red.gb'
```

If you are developing the bridge instead of using the release binary, use the native build prerequisites and instructions in [`gen1recomp/vrbridge/README.md`](gen1recomp/vrbridge/README.md).

The VR launcher checks the ROM, generated data, LÖVE 11.5, the native bridge, the SteamVR OpenXR loader, and the active runtime before launching. It may request one normal Windows UAC approval when selecting SteamVR as the active runtime.

## Maintainer release packaging

After the three repositories are checked out together, the maintainer can create the two release archives with:

```powershell
./package-release.ps1 -Mode Desktop -Version latest
./package-release.ps1 -Mode VR -Version latest -BridgePath './xrbridge.dll'
```

The packaging script archives tracked engine/mod files only and explicitly leaves out the ROM, generated ROM-derived data, saves, and local build products. The VR package requires a matching x64 `xrbridge.dll`; it does not package SteamVR or the OpenXR runtime.

## Controls and camera modes

- Press `V` to cycle **ABOVE → 3RD → POV**.
- In POV mode, `W`/Up moves forward in the trainer's facing direction; `A`/`D` turn in place.
- In VR, either thumbstick moves; right `A`/`B` are Game Boy A/B; left `X` is START; left `Y` is SELECT.
- Click either thumbstick to recenter the seated view on the character.
- Dialogue, menus, and battle controls remain available as floating VR panels.

## Diagnostics

Run these from the project root:

```powershell
./Play-Windows.bat -CheckOnly -SkipSetup
./Play-VR.bat -CheckOnly -SkipSetup
./Play-VR.bat -DesktopPreview -SkipSetup
```

`-DesktopPreview` exercises the VR composition without requiring a headset or native bridge. The ordinary game window is a single desktop mirror; a side-by-side SteamVR eye preview is an optional SteamVR debug view, not a requirement.

## Development layout

```text
pokemon-red-voxel-vr/        integration repository
├── gen1recomp/              engine repository, kept as its own Git history
├── DramaticShapeVoxelMod/   voxel-mod repository, kept as its own Git history
├── package-release.ps1      maintainer release-archive builder
├── Play-Windows.bat         desktop production launcher
└── Play-VR.bat              SteamVR/OpenXR production launcher
```

The integration checkout intentionally keeps the two upstream-derived projects as separate repositories. This preserves their histories and makes it possible to maintain your private engine and mod copies independently.

## Private copies versus GitHub forks

The original engine and voxel-mod repositories are public. GitHub does not allow a public fork to be changed to private; repositories in a fork network share visibility. For the private development phase, create private standalone copies/mirrors instead, and keep the original repositories configured as `upstream` remotes. Later, you can make your own repositories public after checking licensing, attribution, and redistribution rules. See [GitHub's fork visibility documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-permissions-and-visibility-of-forks).

This is a fan-made technical project. It is not a replacement for an official Pokémon product, does not emulate or distribute a Game Boy ROM, and does not use Steamworks or require distribution through Steam.
