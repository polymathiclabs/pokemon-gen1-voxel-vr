# Public release checklist

Use this checklist before publishing a repository or attaching a release
archive.

## Repository state

- [ ] Confirm the root repository, engine repository, and voxel-mod repository
      each have the intended `main` branch and a clean working tree.
- [ ] Configure `origin` to the repository you own and keep the original
      project as `upstream` where appropriate.
- [ ] Push only the intended branch and tags. Do not use `git push --mirror`.
- [ ] Confirm no ROM, save, generated cache, native build output, or personal
      path is tracked with `git ls-files`.
- [ ] Confirm every repository has the appropriate license and attribution.
- [ ] Do not publish the voxel-mod repository until its original material has
      an explicit redistribution license or permission from its author.

## Release build

1. Put a legally obtained compatible ROM outside the release staging folders.
2. Build a matching x64 `xrbridge.dll` for the VR archive when releasing VR.
3. Run the desktop and VR `-CheckOnly` commands from the README for Red, Blue,
   and Yellow.
4. Run the desktop build once for each supported game and verify the window
   title, ROM cache, first-/third-person camera, controller input, and saves.
5. Run `package-release.ps1` with a version such as `v0.1.0`.
6. Inspect both ZIP files before upload. They must contain no `.gb`, `.gbc`,
   `.sav`, `data/generated`, `assets/generated`, `.vr-build`, or personal data.
7. Publish the ZIP files as GitHub release assets, then update the README links
   if the repository or asset names differ from the documented values.

## Public post

- [ ] Link only to the repository and release assets; never link to a ROM.
- [ ] State clearly that the project is unofficial and unaffiliated with
      Nintendo, The Pokémon Company, Game Freak, or Creatures.
- [ ] State that VR requires a PC headset connection, SteamVR, and OpenXR.
- [ ] Include the tested Windows/LÖVE/SteamVR versions and known limitations.
