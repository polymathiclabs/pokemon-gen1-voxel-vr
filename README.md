# Pokémon Red, Blue, and Yellow Voxel VR

An unofficial Windows fan project combining the [Gen1Recomp engine](https://github.com/bryanthaboi/gen1recomp), the [Dramatic Shape Voxel Mod](https://github.com/DramaticShape/DramaticShapeVoxelMod), and an optional OpenXR/SteamVR bridge.

It supports the canonical US Pokemon Red, Blue, and Yellow ROMs with desktop above/third-person/first-person modes, controller input, staged battles, and optional head-tracked stereo VR.

## Downloads

Once the first GitHub release is published, the end-user downloads will be:

- [Download Desktop build](https://github.com/polymathiclabs/pokemon-gen1-voxel-vr/releases/latest/download/pokemon-gen1-voxel-desktop-latest.zip)
- [Download VR build](https://github.com/polymathiclabs/pokemon-gen1-voxel-vr/releases/latest/download/pokemon-gen1-voxel-vr-latest.zip)

The archives contain the runnable project and launchers, but no ROM, save files, generated ROM-derived data, or personal build cache. The VR archive contains the matching native bridge; SteamVR and the OpenXR runtime remain system dependencies.

> **Unofficial fan project - not affiliated with Nintendo, The Pokemon Company, Game Freak, Creatures, or any of their subsidiaries or partners.** Pokemon, Pokemon character names, artwork, music, and related trademarks belong to their respective owners. This project is not endorsed, sponsored, or approved by any of them.

## Important legal and distribution rules

- This repository does not include a ROM, ROM dump, save data, or ROM-derived generated game data.
- You must provide your own legally obtained compatible ROM. Do not upload it to GitHub, attach it to a release, or distribute it with this project.
- Do not commit any `.gb`/`.gbc` ROM, `data/generated`, `assets/generated`, `xrbridge.dll`, `.vr-build`, or personal save files.
- Keep upstream copyright notices, licenses, history, and attribution when maintaining the engine or voxel-mod repositories.
- Before making any repository public, review the upstream licenses and the terms for every third-party asset and dependency.
- The root integration scripts are MIT-licensed; see [`LICENSE`](LICENSE) and [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).
- The engine keeps its own MIT license and copyright notice. The voxel-mod snapshot has no blanket upstream license; its original material must not be redistributed publicly until the author grants permission or adds an explicit license. The MIT notice for Polymatic Labs' changes is in [`DramaticShapeVoxelMod/LICENSE-POLYMATIC-LABS.md`](https://github.com/polymathiclabs/DramaticShapeVoxelMod/blob/main/LICENSE-POLYMATIC-LABS.md).

The release archives are not "copyright-free": source code and third-party dependencies remain copyrighted by their respective authors and must be distributed under their licenses.

## Supported games and modes

The launchers recognize these canonical US ROMs by SHA-1:

| Game | SHA-1 | Typical extension |
| --- | --- | --- |
| Pokemon Red | `ea9bcae617fdf159b045185467ae58b2e4a48b9a` | `.gb` |
| Pokemon Blue | `d7037c83e1ae5b39bde3c30787637ba1d4c48ce2` | `.gb` |
| Pokemon Yellow | `cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1` | `.gb` or `.gbc` |

| Mode | Requires | Launch |
| --- | --- | --- |
| Desktop voxel | Windows x64, LÖVE 11.5, and one compatible ROM | `Play-Windows.bat` |
| Headset VR | Desktop requirements, Steam, SteamVR, a working headset connection, and matching x64 `xrbridge.dll` | `Play-VR.bat` |

The selected game is identified automatically. Red, Blue, and Yellow use separate generated caches and save namespaces, so changing games does not mix their maps, graphics, text, or saves.

If `-RomPath` is omitted, the launcher uses `Pokemon Red.gb` when it is present. If Red is not present and exactly one supported ROM is beside the launcher, that ROM is selected automatically. When multiple non-Red ROMs are present, pass `-RomPath` to choose one.

## Desktop mode

Install LÖVE 11.5 first. On Windows systems with `winget`:

```powershell
winget install --exact --id Love2d.Love2d
```

Then download and extract the Desktop archive. Place a legally obtained ROM next to the launcher, or pass its path explicitly:

```powershell
./Play-Windows.bat -RomPath 'C:/Games/Pokemon Red.gb'
./Play-Windows.bat -RomPath 'C:/Games/Pokemon - Blue Version.gb'
./Play-Windows.bat -RomPath 'C:/Games/Pokemon - Yellow Version.gb'
```

The first run may take a few minutes while the private versioned cache is built. Later launches reuse it.

Desktop mode does not start Steam, load OpenXR, or require a Steam App ID.

## Headset VR mode

Install LÖVE 11.5, Steam, and SteamVR. Start SteamVR once, confirm that the headset is visible, and set SteamVR as the active OpenXR runtime in SteamVR settings.

The VR archive does not bundle or silently install SteamVR, Steam, or the OpenXR runtime. The launcher detects the existing installation, starts Steam/SteamVR when needed, and checks that the runtime is ready.

For an end-user release, place the matching x64 `xrbridge.dll` beside the root launcher. End users do not need CMake, Visual Studio, OpenXR SDK headers, or LuaJIT headers when the release archive already contains this bridge. Those are maintainer-only bridge-build dependencies; see [`gen1recomp/vrbridge/README.md`](https://github.com/bryanthaboi/gen1recomp/tree/main/vrbridge).

Run the same command for any supported game:

```powershell
./Play-VR.bat -RomPath 'C:/Games/Pokemon Red.gb'
./Play-VR.bat -RomPath 'C:/Games/Pokemon - Blue Version.gb'
./Play-VR.bat -RomPath 'C:/Games/Pokemon - Yellow Version.gb'
```

The VR launcher identifies the ROM, prepares or reuses the matching cache, checks the native bridge and SteamVR OpenXR runtime, and then starts the voxel build. It may request one normal Windows UAC approval when selecting SteamVR as the active runtime.

## Controls and camera modes

- Press `V` to cycle ABOVE -> 3RD -> POV.
- In POV mode, `W`/Up moves forward in the trainer's facing direction; `A`/`D` turn in place.
- In VR, either thumbstick moves; right `A`/`B` are Game Boy A/B; left `X` is START; left `Y` is SELECT.
- Click either thumbstick to recenter the seated view on the character.
- Dialogue, menus, and battle controls remain available as floating VR panels.

## Diagnostics

Run these from the project root:

```powershell
./Play-Windows.bat -CheckOnly -SkipSetup -RomPath 'C:/Games/Pokemon Red.gb'
./Play-VR.bat -CheckOnly -SkipSetup -RomPath 'C:/Games/Pokemon - Blue Version.gb'
./Play-VR.bat -DesktopPreview -SkipSetup -RomPath 'C:/Games/Pokemon - Yellow Version.gb'
```

`-DesktopPreview` exercises the VR composition without requiring a headset or native bridge. The ordinary game window is a single desktop mirror; a side-by-side SteamVR eye preview is an optional SteamVR debug view, not a requirement.

## Known limitations

- The maintained launchers and VR bridge target Windows x64. The upstream engine contains other platform work, but this integration does not package or test those targets.
- VR requires a PC-connected headset, SteamVR, an active OpenXR runtime, and a matching x64 `xrbridge.dll`; it does not run natively on a standalone Quest.
- The ordinary desktop window is a mirror/preview, not a required side-by-side eye view. SteamVR is responsible for the headset compositor.
- The first import and the first visit to a large map can take longer while private ROM-derived caches are built.

## Source checkout

The downloadable archives are self-contained and are the recommended way for
players to install the project. A fresh source checkout intentionally does not
contain the two nested repositories. Maintainers and contributors can populate
it with the optional installer below; Git is required for this source-only
workflow, but players do not need Git when using a release archive.

```powershell
./install.ps1 -Mode Desktop -RomPath 'C:/Games/Pokemon Red.gb' `
  -EngineUrl 'https://github.com/polymathiclabs/gen1recomp.git' `
  -VoxelUrl 'https://github.com/polymathiclabs/DramaticShapeVoxelMod.git' `
  -EngineRef '3d684534ec03dfedbfe707c5a5c108ae162600cb' `
  -VoxelRef 'b5559dc810c5297dcef10c439a889e28d5b5be56'
```

Use `-Mode VR` for the headset setup. Record the exact clean nested checkout
commits used for each release, as shown in the release checklist.

## Maintainer release packaging

After the three repositories are checked out together, create the two release archives with:

```powershell
./package-release.ps1 -Mode Desktop -Version v0.1.0
./package-release.ps1 -Mode VR -Version v0.1.0 -BridgePath './xrbridge.dll'
```

The packaging script copies Git-tracked engine/mod files only and explicitly leaves out ROMs, generated ROM-derived data, saves, and local build products. It includes the root MIT license, engine license, and third-party notices. The VR package requires a matching x64 `xrbridge.dll`; it does not package SteamVR or the OpenXR runtime. Do not publish the complete VR archive until the voxel-mod redistribution permission described above is resolved.

## Development layout

```text
pokemon-gen1-voxel-vr/       integration repository
├── gen1recomp/              engine repository, kept as its own Git history
├── DramaticShapeVoxelMod/   voxel-mod repository, kept as its own Git history
├── rom-info.ps1             shared Red/Blue/Yellow ROM identification
├── package-release.ps1      maintainer release-archive builder
├── Play-Windows.bat         desktop production launcher
└── Play-VR.bat              SteamVR/OpenXR production launcher
```

The integration checkout intentionally keeps the engine and voxel-mod projects as separate repositories. This preserves their histories and makes it possible to maintain private engine and mod copies independently. The root repository must not be pushed with the nested repositories accidentally embedded as ordinary files.

## Private copies versus GitHub forks

The original engine and voxel-mod repositories are public. GitHub does not allow a public fork to be changed to private; repositories in a fork network share visibility. For private development, create private standalone copies instead, configure your copy as `origin`, and keep the original project as `upstream`. Later, make your own repositories public only after checking licensing, attribution, and redistribution rules. See [GitHub's fork visibility documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-permissions-and-visibility-of-forks).

This is a fan-made technical project. It is not a replacement for an official Pokémon product, does not distribute a Game Boy ROM, and does not use Steamworks or require distribution through Steam. See [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) before publishing.
