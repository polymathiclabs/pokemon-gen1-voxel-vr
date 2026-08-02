# Pokemon Red, Blue, and Yellow Voxel VR

A Windows desktop and PC-connected headset VR project combining the [Gen1Recomp engine](https://github.com/polymathiclabs/gen1recomp), the [Dramatic Shape Voxel Mod](https://github.com/polymathiclabs/DramaticShapeVoxelMod), and an optional OpenXR/SteamVR bridge.

## Video

[![Gameplay video](https://i.ytimg.com/vi/mPyatutVRQ0/hqdefault.jpg)](https://www.youtube.com/watch?v=mPyatutVRQ0)

Watch a short gameplay video of the voxel world and VR mode.

## Downloads

- [Download Desktop build](https://github.com/polymathiclabs/pokemon-gen1-voxel-vr/releases/latest/download/pokemon-gen1-voxel-desktop-latest.zip)
- [Download VR build](https://github.com/polymathiclabs/pokemon-gen1-voxel-vr/releases/latest/download/pokemon-gen1-voxel-vr-latest.zip)

The archives include the runnable project and launchers. They do not include a ROM, save data, or generated ROM-derived data. The VR archive includes the matching native bridge; SteamVR and the OpenXR runtime are installed separately.

## Desktop mode

Install LÖVE 11.5, download the Desktop archive, and provide your own legally obtained compatible ROM:

```powershell
./Play-Windows.bat -RomPath 'C:/Games/your-legally-obtained-rom.gb'
```

The first run may take a few minutes while the private game cache is built. Desktop mode provides above, third-person, and first-person voxel camera modes, controller input, and staged battles. It does not start Steam or load OpenXR.

## Headset VR mode

Install LÖVE 11.5, Steam, and SteamVR. Connect the headset to the PC, confirm that SteamVR can see it, and set SteamVR as the active OpenXR runtime.

Provide your own legally obtained compatible ROM, then run:

```powershell
./Play-VR.bat -RomPath 'C:/Games/your-legally-obtained-rom.gb'
```

The launcher starts or checks SteamVR, validates the native bridge, and launches the voxel build. VR requires a PC-connected headset; it does not run natively on a standalone Quest.

The VR build opens an 800x600 resizable PC mirror by default. The mirror shows the completed left-eye view fitted inside the window, without changing the headset eye resolution. Set `POKEPORT_VR_MIRROR_WIDTH` and `POKEPORT_VR_MIRROR_HEIGHT` before launching to choose another mirror size.

## Running from source

The downloadable archives already contain the required engine and voxel mod. A source checkout also needs these two repositories placed beside the integration project:

- [Polymatic Labs Gen1Recomp fork](https://github.com/polymathiclabs/gen1recomp) in `gen1recomp`
- [Polymatic Labs Dramatic Shape Voxel Mod fork](https://github.com/polymathiclabs/DramaticShapeVoxelMod) in `DramaticShapeVoxelMod`

The root launchers and `install.ps1` use those forks by default. You still need LÖVE 11.5 and your own legally obtained compatible ROM. SteamVR and the active OpenXR runtime are also required for source VR launches.

## Controls and camera modes

- Press `V` to cycle ABOVE -> 3RD -> POV.
- In POV mode, `W`/Up moves forward in the trainer's facing direction; `A`/`D` turn in place.
- Toggle `MINIMAP` in the Dramatic Shape mod settings to show the current 2D map in the lower-left corner.
- In VR, either thumbstick moves; right `A`/`B` are Game Boy A/B; left `X` is START; left `Y` is SELECT.
- Click either thumbstick to recenter the seated view on the character.
- Dialogue, menus, and battle controls appear as floating VR panels.

## Known limitations

- The maintained launchers and VR bridge target Windows x64.
- VR requires SteamVR, an active OpenXR runtime, a PC-connected headset, and the matching x64 native bridge.
- SteamVR provides the headset compositor; the ordinary Windows window is a mirror, not a required side-by-side eye view.
- The first import and the first visit to a large map can take longer while caches are built.

## Legal and attribution

This is an unofficial fan-made technical project. It is not affiliated with, endorsed by, sponsored by, or approved by Nintendo, The Pokemon Company, Game Freak, Creatures, or any of their subsidiaries or partners. Pokemon, Pokemon character names, artwork, music, and related trademarks belong to their respective owners.

- You must provide your own legally obtained compatible ROM. This project does not distribute or download ROMs, save data, or ROM-derived generated data.
- Do not upload a ROM, save file, generated game data, or personal build products to this repository or its releases. The VR archive may include the project's matching x64 `xrbridge.dll`; it does not include SteamVR or the OpenXR runtime.
- The root integration scripts are MIT-licensed; see [`LICENSE`](LICENSE) and [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).
- Preserve the licenses and attribution of the upstream engine, voxel mod, and all third-party dependencies.
- The release archives and source code remain subject to their respective authors' copyrights and licenses.
