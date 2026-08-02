# Third-party notices

This file describes the components combined by the integration repository. It
does not grant permission to distribute material that its copyright holder has
not licensed.

## Integration scripts and launcher changes

The root integration scripts and documentation authored by Polymatic Labs
are available under the MIT License in [`LICENSE`](LICENSE).

## Gen1Recomp engine

The engine is maintained as a separate repository in `gen1recomp`. Its source
license is the MIT License, with the copyright notice for BOIS CLUB GAMES, LLC,
in [`gen1recomp/LICENSE.MD`](gen1recomp/LICENSE.MD). Keep that notice with any
copy of the engine and with release archives that contain engine code.

The optional `xrbridge.dll` is built from the engine's `vrbridge` source. The
bridge dynamically loads the user's installed OpenXR loader and does not bundle
SteamVR or the OpenXR runtime.

## Dramatic Shape Voxel Mod

The voxel mod is maintained as a separate repository in
`DramaticShapeVoxelMod`. Its upstream snapshot did not contain an explicit
license file. Original code and assets remain attributed to DramaticShape and
are not automatically relicensed by this integration repository. The MIT
license in `DramaticShapeVoxelMod/LICENSE-POLYMATIC-LABS.md` applies only to changes
authored by Polymatic Labs.

Obtain written permission or an explicit upstream license before publishing a
redistributable copy of the complete voxel-mod repository or including its
original material in public release archives.

## Runtime dependencies

Players install LÖVE 11.5, Steam, SteamVR, and an active OpenXR runtime
separately. Those products remain under their own licenses and are not included
in this repository or its release archives.

## Pokémon trademarks and game content

Pokémon, Pokémon character names, artwork, music, and related trademarks belong
to their respective owners. This project does not include a ROM, save data, or
pre-extracted ROM-derived game data. Users must provide their own legally
obtained compatible ROM.
