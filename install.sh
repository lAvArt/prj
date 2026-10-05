#!/bin/sh
# Install prj:  curl -fsSL https://raw.githubusercontent.com/lAvArt/prj/main/install.sh | sh
#
# Puts the prj script in ~/.local/bin (or $PREFIX/bin), then starts the setup wizard.
# Environment: PREFIX (default ~/.local), PRJ_REF (git branch or tag, default main), PRJ_NO_SETUP=1

set -eu

PREFIX="${PREFIX:-$HOME/.local}"
REF="${PRJ_REF:-main}"
URL="https://raw.githubusercontent.com/lAvArt/prj/$REF/prj"
BIN="$PREFIX/bin"

say() { printf '%s\n' "$*"; }
die() { printf 'prj install: %s\n' "$*" >&2; exit 1; }

mkdir -p "$BIN"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if command -v curl >/dev/null 2>&1; then curl -fsSL "$URL" -o "$tmp" || die "download failed: $URL"
elif command -v wget >/dev/null 2>&1; then wget -qO "$tmp" "$URL" || die "download failed: $URL"
else die "needs curl or wget"; fi
head -1 "$tmp" | grep -q bash || die "unexpected download from $URL"
mv "$tmp" "$BIN/prj" && chmod 755 "$BIN/prj"
trap - EXIT
say "Installed $BIN/prj ($("$BIN/prj" --version))"

missing=""
for dep in git fzf; do command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"; done
[ -n "$missing" ] && say "Missing required:$missing. Install with your package manager (e.g. pacman -S fzf, apt install fzf, brew install fzf)."
command -v gum >/dev/null 2>&1 || say "Optional: install gum for a nicer setup wizard."

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) say "Note: $BIN isn't on your PATH yet. Add it in your shell rc: export PATH=\"$BIN:\$PATH\"" ;;
esac

if [ -z "${PRJ_NO_SETUP:-}" ] && [ -z "$missing" ] && (: </dev/tty) 2>/dev/null; then
  say ""
  PATH="$BIN:$PATH" exec "$BIN/prj" --setup </dev/tty
fi
say "Next: prj --setup"
