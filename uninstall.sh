#!/usr/bin/env sh
# git-rituals uninstaller
set -e

INSTALL_DIR="${HOME}/.git-rituals"

# --- Colors ---
RESET=""
GREEN=""
RED=""
CYAN=""

if [ -t 1 ] || [ -t 2 ]; then
  RESET="\033[0m"
  GREEN="\033[32m"
  RED="\033[31m"
  CYAN="\033[36m"
fi

ok()   { printf "${GREEN}%s${RESET}\n" "$*"; }
info() { printf "${CYAN}%s${RESET}\n" "$*"; }
err()  { printf "${RED}%s${RESET}\n" "$*" >&2; }

# Cross-platform sed -i wrapper (macOS BSD sed vs GNU sed)
sed_inplace() {
  if sed --version > /dev/null 2>&1; then
    # GNU sed
    sed -i "$@"
  else
    # BSD sed (macOS)
    sed -i '' "$@"
  fi
}

# Remove source lines from a shell rc file
remove_from_rc() {
  local rcfile="$1"
  if [ -f "$rcfile" ] && grep -q "git-rituals" "$rcfile" 2>/dev/null; then
    sed_inplace '/# git-rituals/d' "$rcfile"
    sed_inplace '/\.git-rituals\/rituals\.sh/d' "$rcfile"
    ok "Cleaned $(basename "$rcfile")"
  fi
}

# --- Main ---
printf "\n"
info "Uninstalling git-rituals..."
printf "\n"

# Remove source lines from shell configs
remove_from_rc "${HOME}/.zshrc"
remove_from_rc "${HOME}/.bashrc"
remove_from_rc "${HOME}/.bash_profile"

# Remove fish config
FISH_CONF="${HOME}/.config/fish/conf.d/git-rituals.fish"
if [ -f "$FISH_CONF" ]; then
  rm -f "$FISH_CONF"
  ok "Removed fish config"
fi

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  ok "Removed ${INSTALL_DIR}"
fi

printf "\n"
ok "git-rituals has been uninstalled."
info "Restart your shell to complete removal."
printf "\n"
