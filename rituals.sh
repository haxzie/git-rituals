#!/usr/bin/env bash
# git-rituals — branch shortcut functions for zsh/bash
# Source this file in your .zshrc or .bashrc

_GIT_RITUALS_DIR="${HOME}/.git-rituals"
_GIT_RITUALS_CONFIG="${_GIT_RITUALS_DIR}/config"
_GIT_RITUALS_VERSION="1.0.0"

# Load enabled rituals from config
_git_rituals_enabled=()
if [ -f "$_GIT_RITUALS_CONFIG" ]; then
  while IFS= read -r line; do
    case "$line" in
      RITUALS=*) IFS=',' read -ra _git_rituals_enabled <<< "${line#RITUALS=}" ;;
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
  date_stamp="$(date +%d%m%Y)"

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

  # Check if enabled (if config exists; if no config, enable all)
  if [ ${#_git_rituals_enabled[@]} -gt 0 ]; then
    local found=0
    for r in "${_git_rituals_enabled[@]}"; do
      if [ "$r" = "$name" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      return
    fi
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

# Meta-command
git-rituals() {
  case "${1:-}" in
    list)
      printf 'git-rituals v%s\n\n' "$_GIT_RITUALS_VERSION"
      printf 'Available rituals:\n'
      local all_rituals=(feat fix chore refactor docs style perf push pull nuke)
      for r in "${all_rituals[@]}"; do
        local ritual_state="disabled"
        if [ ${#_git_rituals_enabled[@]} -eq 0 ]; then
          ritual_state="enabled"
        else
          for e in "${_git_rituals_enabled[@]}"; do
            if [ "$e" = "$r" ]; then
              ritual_state="enabled"
              break
            fi
          done
        fi
        if [ "$ritual_state" = "enabled" ]; then
          printf '  %-12s [enabled]\n' "$r"
        else
          printf '  %-12s [disabled]\n' "$r"
        fi
      done
      printf '\nBranch rituals:\n'
      printf '  <ritual> <branch-name>    Create and switch to branch\n'
      printf '  Example: feat add login page\n'
      printf '    Creates: feat/<your-name>/add-login-page-07022026\n'
      printf '\nShortcuts:\n'
      printf '  push                      Push current branch to remote\n'
      printf '  pull                      Pull current branch from remote\n'
      printf '  nuke                      Reset all staged/unstaged changes\n'
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
