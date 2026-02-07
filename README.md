# git-rituals

Branch shortcuts and git utilities for your terminal. Stop typing `git checkout -b feat/your-name/branch-name` — just type `feat branch name`.

## Install

```sh
curl -fsSL rituals.haxzie.com/install.sh | sh
```

Supports **zsh**, **bash**, and **fish**. The installer auto-detects your shell and sets everything up.

### Requirements

- `git` (with `user.name` configured)
- `curl` or `wget`

## Branch Commands

Create and switch to a new branch with a consistent naming convention. Branch names are automatically slugified and timestamped.

```
<type>/<your-name>/<branch-name>-<YYYY-MM-DD>
```

| Command | Example | Branch Created |
|---|---|---|
| `feat` | `feat add login page` | `feat/your-name/add-login-page-2025-02-07` |
| `fix` | `fix broken auth` | `fix/your-name/broken-auth-2025-02-07` |
| `chore` | `chore update deps` | `chore/your-name/update-deps-2025-02-07` |
| `refactor` | `refactor auth module` | `refactor/your-name/auth-module-2025-02-07` |
| `docs` | `docs api reference` | `docs/your-name/api-reference-2025-02-07` |
| `style` | `style fix spacing` | `style/your-name/fix-spacing-2025-02-07` |
| `perf` | `perf optimize queries` | `perf/your-name/optimize-queries-2025-02-07` |

If the branch already exists, it switches to it instead of creating a new one.

The username is pulled from `git config user.name` and slugified. Set it with:

```sh
git config --global user.name "Your Name"
```

## Shortcut Commands

| Command | What it does |
|---|---|
| `push` | Push current branch to remote (auto-sets upstream on first push) |
| `pull` | Pull current branch from remote |
| `status` | Show `git status` |
| `logs` | Pretty-printed git log — last 50 commits in a color-coded table |
| `nuke` | Hard reset all staged and unstaged changes |
| `yeet` | Switch to parent branch and delete the current branch (with confirmation) |

### push

Pushes the current branch. On first push, automatically sets the upstream with `-u origin`.

```sh
push                    # git push (or git push -u origin <branch>)
push --force-with-lease # flags are passed through
```

### pull

Pulls the current branch from remote.

```sh
pull            # git pull
pull --rebase   # flags are passed through
```

### logs

Displays the last 50 commits in a color-coded columnar format showing hash, date, author, and subject.

```
a1b2c3d    2025-02-07 14:30:00  haxzie          Add login page
f4e5d6c    2025-02-07 12:15:00  haxzie          Fix auth bug
```

### nuke

Resets all staged and unstaged changes. Runs `git reset --hard HEAD` followed by `git clean -fd`.

```sh
nuke  # everything is gone
```

### yeet

Deletes the current branch and switches back to `main`/`master`. Prompts for confirmation since this discards all changes.

```sh
yeet
# Warning: this will permanently delete branch "feat/haxzie/add-login-page-2025-02-07"
# All staged and unstaged changes will be lost.
# Switching to: main
#
# Continue? [Y/n]
```

Refuses to yeet `main` or `master`.

## Meta Commands

```sh
git-rituals list       # Show all available commands and their status
git-rituals uninstall  # Remove git-rituals completely
git-rituals version    # Show version
```

## Uninstall

```sh
git-rituals uninstall
```

This removes all files from `~/.git-rituals/`, cleans up shell config files, and unloads all commands from the current session.

## How It Works

- **Install location**: `~/.git-rituals/`
- **Shell integration**: A source line is added to your `.zshrc`, `.bashrc`, or fish `conf.d`
- **Config**: `~/.git-rituals/config` stores which rituals are enabled
- Branch names are slugified — spaces become hyphens, special characters are stripped, everything is lowercased
- Works across **macOS** and **Linux**

## License

MIT
