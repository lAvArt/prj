# AUR package

Source for the [`prj` AUR package](https://aur.archlinux.org/packages/prj).

To release a new version:

1. Tag the release in this repo (`vX.Y.Z`) and push the tag.
2. Here, set `pkgver` (reset `pkgrel=1`) and update the checksum: `updpkgsums`
3. Build and test locally: `makepkg -f` (runs the test suite in `check()`)
4. Regenerate metadata: `makepkg --printsrcinfo > .SRCINFO`
5. Copy `PKGBUILD` and `.SRCINFO` into the AUR clone (`ssh://aur@aur.archlinux.org/prj.git`), commit, push.
