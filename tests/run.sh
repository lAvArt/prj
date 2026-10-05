#!/usr/bin/env bash
# Test suite for prj. Runs in a throwaway HOME, so it never touches your real config.
# Usage: tests/run.sh [path/to/bash]   (pass /bin/bash on macOS to test bash 3.2)
# shellcheck disable=SC2034  # out/rc/first are read inside check's eval strings

BASH_BIN="${1:-bash}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRJ="$ROOT/prj"
T="$(mktemp -d "${TMPDIR:-/tmp}/prj-test.XXXXXX")"
T="$(cd "$T" && pwd)"   # macOS TMPDIR ends in a slash, which would leave // in every path
trap 'rm -rf "$T"' EXIT

export HOME="$T/home" SHELL=/bin/bash XDG_CONFIG_HOME="" XDG_STATE_HOME=""
unset PRJ_CONFIG PRJ_STATE_DIR HERDR_ENV TMUX TMUX_PANE
export PRJ_SCAN_MOUNTS=""   # only look inside the fake HOME
mkdir -p "$HOME/.claude" "$T/bin"
touch "$HOME/.bashrc"
ln -s "$PRJ" "$T/bin/prj"
export PATH="$T/bin:$PATH"

pass=0 fail=0
ok() { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL %s\n' "$1"; [ -n "$2" ] && printf '%s\n' "$2" | sed 's/^/       | /'; }
check() { if eval "$2"; then ok "$1"; else bad "$1" "$3"; fi; }
prj() { "$BASH_BIN" "$PRJ" "$@"; }

mkrepo() {   # mkrepo <dir> [commit date]
  git init -q "$1" 2>/dev/null
  [ -z "$2" ] && return
  GIT_COMMITTER_DATE="$2T12:00:00" GIT_AUTHOR_DATE="$2T12:00:00" \
    git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

C="$HOME/code"
mkrepo "$C/alpha" 2026-01-03
mkrepo "$C/beta" 2026-01-02
mkrepo "$C/gamma ray" 2026-01-01
mkrepo "$C/old-thing" 2025-06-01
mkrepo "$C/alpha/packages/inner" 2026-01-01   # nested: hidden
mkrepo "$C/group/delta" 2026-01-01            # only found with depth 2
mkrepo "$C/empty"                             # no commits
mkdir -p "$C/winwt" && printf 'gitdir: D:/Development/x/.git/worktrees/winwt\n' >"$C/winwt/.git"

printf 'prj tests (%s)\n\n' "$("$BASH_BIN" -c 'echo bash $BASH_VERSION')"

echo "before setup"
out="$(prj -l 2>&1)"; rc=$?
check "asks for setup when unconfigured" '[ $rc = 1 ] && [[ $out == *"prj --setup"* ]]' "$out"
check "completion stays silent when unconfigured" '[ -z "$(prj --names 2>&1)" ]'

echo "setup"
out="$(prj --setup -y --name dev --cd-name dcd --run 'echo opened' 2>&1)"; rc=$?
cfg="$HOME/.config/prj/config"
check "setup succeeds" '[ $rc = 0 ]' "$out"
check "detects ~/code" 'grep -q "^roots = .*~/code" "$cfg"' "$(cat "$cfg" 2>&1)"
check "saves names and run command" 'grep -q "^name = dev" "$cfg" && grep -q "^cd_name = dcd" "$cfg" && grep -q "^run = echo opened" "$cfg"'
check "writes shell functions" 'grep -q "^dev()" "$HOME/.config/prj/shell.sh" && grep -q "^dcd()" "$HOME/.config/prj/shell.sh"'
check "hooks ~/.bashrc" 'grep -q "shell.sh" "$HOME/.bashrc"'
prj --setup -y >/dev/null 2>&1
check "re-running setup keeps settings" 'grep -q "^name = dev" "$cfg" && grep -q "^run = echo opened" "$cfg"'
check "re-running setup adds no second hook" '[ "$(grep -c "shell.sh" "$HOME/.bashrc")" = 1 ]' "$(cat "$HOME/.bashrc")"
check "installs the Claude skill" 'grep -q "prj -l --tsv" "$HOME/.claude/skills/repo/SKILL.md"'
check "skill names the user's command" 'grep -q "shortcut, \`dev\`" "$HOME/.claude/skills/repo/SKILL.md"'

echo "listing"
out="$(prj -l 2>&1)"
check "lists repos" '[[ $out == *alpha* && $out == *"gamma ray"* && $out == *empty* ]]' "$out"
check "hides nested repos" '[[ $out != *inner* ]]' "$out"
check "respects depth 1" '[[ $out != *delta* ]]' "$out"
check "labels Windows worktrees" '[[ $out == *"(windows worktree)"* ]]' "$out"
first="$(prj -l --tsv | head -1 | cut -f1)"
check "newest commit first when unused" '[ "$first" = alpha ]' "$(prj -l --tsv)"
check "names for completion" '[ "$(prj --names | grep -c .)" = 6 ]' "$(prj --names)"

sed -i.bak 's/^pinned = .*/pinned = beta/; s/^exclude = .*/exclude = old-*/; s/^depth = .*/depth = 2/' "$cfg"
out="$(prj -l --tsv)"
check "pinned project first" '[ "$(printf "%s\n" "$out" | head -1 | cut -f1,5)" = "beta	pinned" ]' "$out"
check "exclude patterns" '[[ $out != *old-thing* ]]' "$out"
check "depth 2 finds deeper repos" '[[ $out == *delta* ]]' "$out"

echo "matching"
check "exact name" '[ "$(prj -p beta)" = "$C/beta" ]'
check "case-insensitive" '[ "$(prj -p ALPHA)" = "$C/alpha" ]'
check "fuzzy unique match" '[ "$(prj -p gam)" = "$C/gamma ray" ]'
out="$(prj -p a 2>&1)"; rc=$?
check "ambiguous query fails and lists candidates" '[ $rc = 1 ] && [[ $out == *"matches several"* ]]' "$out"
out="$(prj -p zzz 2>&1)"; rc=$?
check "unknown query fails" '[ $rc = 1 ] && [[ $out == *"no project matches"* ]]' "$out"
out="$(prj 2>&1)"; rc=$?
check "picker without a terminal explains itself" '[ $rc != 0 ] && [[ $out == *"needs a terminal"* ]]' "$out"

echo "ranking"
for i in 1 2 3; do prj -p gamma >/dev/null; done
prj -p alpha >/dev/null
check "most used after pinned" '[ "$(prj -l --tsv | sed -n 2p | cut -f1)" = "gamma ray" ]' "$(prj -l --tsv)"
old=$(($(date +%s) - 86400 * 365))
for i in 1 2 3 4 5 6 7 8; do printf '%s\t%s\n' "$old" "$C/empty" >>"$HOME/.local/state/prj/history"; done
check "old use counts less than recent use" '[ "$(prj -l --tsv | sed -n 2p | cut -f1)" = "gamma ray" ]' "$(prj -l --tsv)"

echo "opening"
out="$(cd / && prj beta -o here 2>&1)"
check "runs the configured command" '[ "$out" = opened ]' "$out"
# GNU /bin/pwd prints the physical path, BSD's the logical one; macOS TMPDIR sits behind a symlink
real_beta="$(cd "$C/beta" && pwd -P)"
out="$(cd / && prj beta -o here -r pwd 2>&1)"
check "runs in the project folder" '[ "$out" = "$real_beta" ] || [ "$out" = "$C/beta" ]' "$out"
out="$(prj beta -o here -r "printf [%s]" -- --continue "a b" 2>&1)"
check "passes extra args with quoting" '[ "$out" = "[--continue][a b]" ]' "$out"
out="$(prj beta -o herdr-tab -r pwd 2>&1)"
check "falls back to here outside herdr" '[[ $out == *"not inside herdr"* ]] && [[ $out == *"$real_beta"* || $out == *"$C/beta"* ]]' "$out"
out="$(prj beta -o nonsense 2>&1)"; rc=$?
check "rejects unknown open modes" '[ $rc = 1 ] && [[ $out == *"unknown open mode"* ]]' "$out"

echo "shell integration"
out="$("$BASH_BIN" -c '. "$HOME/.config/prj/shell.sh"; dcd beta >/dev/null && pwd')"
check "cd function" '[ "$out" = "$C/beta" ]' "$out"
out="$("$BASH_BIN" -c '. "$HOME/.config/prj/shell.sh"; COMP_WORDS=(dev gam); COMP_CWORD=1; _prj_complete; printf "%s\n" "${COMPREPLY[@]}"')"
check "tab completion" '[ "$out" = "gamma ray" ]' "$out"

echo "doctor and missing folders"
out="$(prj --doctor 2>&1)"
check "doctor reports the setup" '[[ $out == *"(6 repos)"* && $out == *"defines: dev, dcd"* ]]' "$out"
sed -i.bak 's#^roots = .*#roots = /nonexistent/drive#' "$cfg"
out="$(prj -l 2>&1)"; rc=$?
check "missing folder is explained" '[ $rc = 1 ] && [[ $out == *"not found"* ]]' "$out"

echo "uninstall"
printf '# my own prj notes\n' >>"$HOME/.bashrc"
out="$(prj --uninstall 2>&1)"
check "removes the hook" '! grep -q "shell.sh" "$HOME/.bashrc"' "$(cat "$HOME/.bashrc")"
check "keeps the user's own lines" 'grep -q "my own prj notes" "$HOME/.bashrc"'
check "removes shell file and skill" '[ ! -f "$HOME/.config/prj/shell.sh" ] && [ ! -f "$HOME/.claude/skills/repo/SKILL.md" ]'
check "keeps the config" '[ -f "$cfg" ]'
mkdir -p "$HOME/.claude/skills/repo" && printf 'my own skill\n' >"$HOME/.claude/skills/repo/SKILL.md"
prj --uninstall >/dev/null 2>&1
check "leaves a skill it didn't write" '[ -f "$HOME/.claude/skills/repo/SKILL.md" ]'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
