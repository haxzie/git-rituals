#!/usr/bin/env bash
# git-rituals — branch shortcut functions for zsh/bash
# Source this file in your .zshrc or .bashrc

_GIT_RITUALS_DIR="${HOME}/.git-rituals"
_GIT_RITUALS_CONFIG="${_GIT_RITUALS_DIR}/config"
_GIT_RITUALS_VERSION="1.0.0"

# Load enabled rituals from config (comma-separated string)
_git_rituals_enabled=""
if [ -f "$_GIT_RITUALS_CONFIG" ]; then
  while IFS= read -r line; do
    case "$line" in
      RITUALS=*) _git_rituals_enabled="${line#RITUALS=}" ;;
    esac
  done < "$_GIT_RITUALS_CONFIG"
fi

# Slugify a string: lowercase, spaces/special chars to hyphens, collapse doubles, trim edges
_git_ritual_slugify() {
  printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/^-//;s/-$//'
}

# Core branch creation function
_git_ritual() {
  local type="$1"
  shift

  if [ $# -eq 0 ]; then
    printf 'Usage: %s <branch-name>\n' "$type" >&2
    printf 'Example: %s my cool feature\n' "$type" >&2
    return 1
  fi

  # Must be inside a git repo
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  # Get git user name
  local username
  username="$(git config user.name)"
  if [ -z "$username" ]; then
    printf 'error: git user.name is not set\n' >&2
    printf 'Fix it with: git config --global user.name "Your Name"\n' >&2
    return 1
  fi

  local user_slug
  user_slug="$(_git_ritual_slugify "$username")"

  local name_slug
  name_slug="$(_git_ritual_slugify "$*")"

  if [ -z "$name_slug" ]; then
    printf 'error: branch name resolves to empty after slugification\n' >&2
    return 1
  fi

  local date_stamp
  date_stamp="$(date +%Y-%m-%d)"

  local branch="${type}/${user_slug}/${name_slug}-${date_stamp}"

  # If branch already exists, switch to it
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    printf 'Branch already exists, switching to it\n'
    git checkout "$branch"
  else
    git checkout -b "$branch"
  fi
}

# Define a ritual command if it's in the enabled list
_define_ritual() {
  local name="$1"

  # Check if enabled (if config exists; if no config/empty, enable all)
  if [ -n "$_git_rituals_enabled" ]; then
    case ",$_git_rituals_enabled," in
      *,"$name",*) ;;
      *) return ;;
    esac
  fi

  eval "${name}() { _git_ritual ${name} \"\$@\"; }"
}

# Register all 7 ritual commands
_define_ritual feat
_define_ritual fix
_define_ritual chore
_define_ritual refactor
_define_ritual docs
_define_ritual style
_define_ritual perf

# Push current branch to remote
push() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"

  if git config "branch.${branch}.remote" > /dev/null 2>&1; then
    git push "$@"
  else
    git push -u origin "$branch" "$@"
  fi
}

# Pull current branch from remote
pull() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  git pull "$@"
}

# Nuke all staged and unstaged changes
nuke() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  git reset --hard HEAD
  git clean -fd
}

# Show git status
status() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  git status "$@"
}

# Pretty git log
logs() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  git log -50 --pretty=format:'%C(yellow)%h%C(reset)|%C(green)%ad%C(reset)|%C(blue)%an%C(reset)|%C(red)%s%C(reset)' --date=format:'%Y-%m-%d %H:%M:%S' | awk -F'|' '{printf "\033[33m%-10s\033[0m \033[32m%-20s\033[0m \033[34m%-15s\033[0m \033[31m%-50s\033[0m\n", $1, $2, $3, substr($4,0,50)}'
}

# Yeet current branch — switch to parent and delete the branch
yeet() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
    return 1
  fi

  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"

  if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
    printf 'error: refusing to yeet %s\n' "$current_branch" >&2
    return 1
  fi

  # Find parent branch (where current branch forked from)
  local parent_branch
  parent_branch="$(git log --pretty=format:'%D' --all | tr ',' '\n' | sed 's/^ *//' | grep -v "HEAD" | grep -v "$current_branch" | head -1 | sed 's|origin/||')"
  # Fallback to main/master if we can't detect
  if [ -z "$parent_branch" ]; then
    if git show-ref --verify --quiet refs/heads/main; then
      parent_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
      parent_branch="master"
    else
      printf 'error: could not determine parent branch\n' >&2
      return 1
    fi
  fi

  printf '\033[31mWarning: this will permanently delete branch "%s"\033[0m\n' "$current_branch"
  printf 'All staged and unstaged changes will be lost.\n'
  printf 'Switching to: %s\n\n' "$parent_branch"
  printf 'Continue? [Y/n] '
  read -r confirm
  case "$confirm" in
    [nN]*) printf 'Aborted.\n'; return 1 ;;
  esac

  git reset --hard HEAD
  git clean -fd
  git checkout "$parent_branch"
  git branch -D "$current_branch"
}

# Meta-command
git-rituals() {
  case "${1:-}" in
    list)
      printf 'git-rituals v%s\n\n' "$_GIT_RITUALS_VERSION"
      printf 'Available rituals:\n'
      for r in feat fix chore refactor docs style perf push pull nuke status logs yeet; do
        if [ -z "$_git_rituals_enabled" ]; then
          printf '  %-12s [enabled]\n' "$r"
        else
          case ",$_git_rituals_enabled," in
            *,"$r",*) printf '  %-12s [enabled]\n' "$r" ;;
            *) printf '  %-12s [disabled]\n' "$r" ;;
          esac
        fi
      done
      printf '\nBranch rituals:\n'
      printf '  <ritual> <branch-name>    Create and switch to branch\n'
      printf '  Example: feat add login page\n'
      printf '    Creates: feat/<your-name>/add-login-page-2026-02-07\n'
      printf '\nShortcuts:\n'
      printf '  push                      Push current branch to remote\n'
      printf '  pull                      Pull current branch from remote\n'
      printf '  nuke                      Reset all staged/unstaged changes\n'
      printf '  status                    Show git status\n'
      printf '  logs                      Pretty git log (last 50 commits)\n'
      printf '  yeet                      Delete current branch and switch to parent\n'
      ;;
    uninstall)
      if [ -f "${_GIT_RITUALS_DIR}/uninstall.sh" ]; then
        bash "${_GIT_RITUALS_DIR}/uninstall.sh"
      else
        printf 'error: uninstall script not found at %s/uninstall.sh\n' "$_GIT_RITUALS_DIR" >&2
        return 1
      fi
      ;;
    version)
      printf 'git-rituals v%s\n' "$_GIT_RITUALS_VERSION"
      ;;
    *)
      printf 'git-rituals v%s\n\n' "$_GIT_RITUALS_VERSION"
      printf 'Commands:\n'
      printf '  git-rituals list        Show available rituals\n'
      printf '  git-rituals uninstall   Remove git-rituals\n'
      printf '  git-rituals version     Show version\n'
      ;;
  esac
}
