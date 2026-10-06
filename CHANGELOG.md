# Changelog

## 0.1.1 - 2026-10-06

- Fix: the preview pane only appeared on terminals over 200 columns wide; it now hides below about 100
- Fix: with fzf older than 0.31 (Ubuntu 22.04, Debian 11) the picker failed to open; it now falls back to a
  fixed preview, and works back to fzf 0.24
- Packaging: AUR PKGBUILD in `packaging/aur`, Homebrew formula in lAvArt/homebrew-tap

## 0.1.0 - 2026-10-05

First release.

- Fuzzy project picker with git log/status preview, sorted by pins, usage and last commit
- Setup wizard: finds project folders (home, mounted drives), picks the run command and open mode,
  installs your own command names with tab completion for bash, zsh and fish
- Opens projects in a herdr tab, tmux window or the current terminal, detecting nested multiplexers
- Claude Code `/repo` skill for switching projects mid-session
- `--doctor`, `--edit`, `--uninstall`; Windows worktrees on dual-boot drives are labeled, not touched
