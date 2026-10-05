# prj

[![ci](https://github.com/lAvArt/prj/actions/workflows/ci.yml/badge.svg)](https://github.com/lAvArt/prj/actions/workflows/ci.yml)

Pick one of your projects from a list and open it in your AI coding agent, editor or shell.

```
$ prj
prj> shop
  * shop-api      main                    2026-10-03  │ 6a01a74 Add order webhooks
    shop-web      feat/checkout-redesign  2026-09-17  │ 27ebff3 Cache product pages
    shop-mobile   feat/splash-screen      2026-08-14  │
                                                      │ ## main...origin/main
```

Press Enter and `prj` opens a new herdr tab or tmux window named after the project, in the project folder, with
your agent (Claude Code, Codex, opencode, an editor, anything) already running. Outside a multiplexer it starts
the agent in the current terminal.

- **Set up once, in about 30 seconds.** `prj --setup` finds the folders that hold your git repos (home folders,
  mounted drives, dual-boot partitions), then asks what to run, where to open it, and what command names you want to type.
- **Your command names.** Type `dev`, `p`, `work` or anything else. `prj` installs them as shell functions, along
  with a cd command and tab completion.
- **Sorted the way you work.** Pinned projects first, then the ones you open most (recent use counts more), then the
  latest commit.
- **Agent-aware.** Opens in herdr tabs or tmux windows and works out which one you're in, even when nested.
  For Claude Code, setup adds a `/repo` skill so Claude can switch projects for you mid-session.
- **Small.** One bash script. Needs only `git` and `fzf`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/lAvArt/prj/main/install.sh | sh
```

This puts `prj` in `~/.local/bin` and starts the setup wizard. Or install from a clone:

```sh
git clone https://github.com/lAvArt/prj && cd prj
make install            # PREFIX=~/.local by default; also installs the man page
prj --setup
```

**Requirements:** bash (3.2 or newer, so the macOS system bash works), `git`, `fzf`.
**Optional:** `gum` (nicer wizard), `jq`, `herdr`, `tmux`.

## Setup

```
$ prj --setup
Looking for folders with git repos...
Which folders hold your projects?
> ✓ ~/code                            (14 repos)
  ✓ /run/media/me/Data/Development    (13 repos)
What should open in a project?        > claude   codex   opencode   hdl claude   nvim .   (nothing, just a shell)
Where should it open?                 > auto: new herdr/tmux tab if inside one, else here
Command you type to open a project    > dev
Command that just cd's into a project > dcd
Set up 'dev' and 'dcd' plus tab completion in your shell? Yes
Install a /repo skill so Claude Code can switch projects for you? Yes
```

Run it again any time to change your answers. For scripts and dotfiles, every answer has a flag:

```sh
prj --setup --yes --roots "~/code, ~/work" --run claude --open auto --name dev --cd-name dcd
```

## Usage

| Command | What it does |
|---|---|
| `prj` | Fuzzy picker with a git log/status preview |
| `prj api` | Open the matching project directly (exact name, else one fuzzy match, else the picker) |
| `prj api -- --continue` | Pass extra arguments to the run command |
| `prj api -o here` | Override where it opens: `auto`, `herdr-tab`, `tmux-window`, `here` |
| `prj api -r "nvim ."` | Override what runs |
| `prj -p api` | Print the path (your cd command uses this) |
| `prj -l` / `prj -l --tsv` | List projects |
| `prj --doctor` | Check dependencies, folders and shell integration |
| `prj --edit` | Open the config file |
| `prj --uninstall` | Remove the shell hooks and skill setup added (keeps your config) |

The commands you named during setup wrap these: `dev api` is `prj api`, and `dcd api` cd's into it.

## Configuration

`~/.config/prj/config` (or `$XDG_CONFIG_HOME/prj/config`):

```ini
roots   = ~/code, /run/media/me/Data/Development   # folders that hold your projects
depth   = 1           # how deep to look for repos inside each folder (1-5)
run     = claude      # typed in the project when it opens; empty opens a shell
open    = auto        # auto | herdr-tab | tmux-window | here
pinned  = shop-api, dotfiles                       # always listed first
exclude = *-stable, archive/*                      # name or path patterns to hide
name    = dev         # your open command
cd_name = dcd         # your cd command (empty for none)
```

`run` is typed into an interactive shell, so shell aliases and functions work, such as Omarchy's `cx` or `hdl claude`.

| Environment variable | Purpose |
|---|---|
| `PRJ_CONFIG` | Use a different config file |
| `PRJ_STATE_DIR` | Where usage history is kept (default `~/.local/state/prj`) |
| `PRJ_SCAN_MOUNTS` | Where setup looks for mounted drives (default `/run/media/$USER /media/$USER /mnt /Volumes`) |

## Notes

- **Nested repos** (packages and submodules inside a project) are hidden, so you only see top-level projects.
- **Dual boot:** git worktrees created on Windows point to `D:/...` paths that Linux git can't follow. They're listed
  as `(windows worktree)`. `prj` doesn't touch them: running `git worktree repair` would break them for Windows.
- **Claude Code:** a mid-session switch through `/repo` changes where Claude works, but not the project's
  `.claude/settings.json`, hooks or MCP servers. Those load at startup, which is what `prj <project>` gives you.
- **Omarchy:** set `run = hdl claude` to open each project in Omarchy's herdr dev layout (editor, agent, terminal).

## Development

```sh
make test     # 40+ checks in a throwaway HOME; `tests/run.sh /bin/bash` tests macOS's bash 3.2
make lint     # shellcheck
```

## License

MIT
