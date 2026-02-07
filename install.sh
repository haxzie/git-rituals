#!/usr/bin/env sh
# git-rituals installer
# Usage: curl -fsSL <url>/install.sh | sh
set -e

# --- Configuration ---
INSTALL_DIR="${HOME}/.git-rituals"
REPO_RAW_URL="https://raw.githubusercontent.com/AhmedMustah662/git-rituals/main"
VERSION="1.0.0"

# --- Colors & formatting ---
BOLD=""
DIM=""
RESET=""
GREEN=""
RED=""
YELLOW=""
CYAN=""

if [ -t 1 ] || [ -t 2 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  RESET="\033[0m"
  GREEN="\033[32m"
  RED="\033[31m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
fi

# --- Helpers ---
info()  { printf "${CYAN}%s${RESET}\n" "$*"; }
ok()    { printf "${GREEN}%s${RESET}\n" "$*"; }
warn()  { printf "${YELLOW}%s${RESET}\n" "$*"; }
err()   { printf "${RED}%s${RESET}\n" "$*" >&2; }

has_cmd() { command -v "$1" > /dev/null 2>&1; }

# Prompt helper — reads from /dev/tty for curl|sh compatibility
prompt() {
  printf "%s " "$1" > /dev/tty
  read -r REPLY < /dev/tty
  printf '%s' "$REPLY"
}

prompt_yn() {
  local answer
  answer="$(prompt "$1 [Y/n]")"
  case "$answer" in
    [nN]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Download helper
download() {
  local url="$1" dest="$2"
  if has_cmd curl; then
    curl -fsSL "$url" -o "$dest"
  elif has_cmd wget; then
    wget -qO "$dest" "$url"
  else
    err "error: curl or wget is required"
    exit 1
  fi
}

# --- Banner ---
print_banner() {
  if has_cmd gum; then
    gum style --border rounded --padding "0 2" --border-foreground 212 \
      "git-rituals v${VERSION}" \
      "Branch shortcuts for your team"
  else
    printf "\n"
    printf "${BOLD}  git-rituals${RESET} v${VERSION}\n"
    printf "${DIM}  Branch shortcuts for your team${RESET}\n"
    printf "\n"
  fi
}

# --- Pre-flight checks ---
preflight() {
  if ! has_cmd git; then
    err "error: git is not installed"
    err "Install git first: https://git-scm.com/downloads"
    exit 1
  fi

  if ! has_cmd curl && ! has_cmd wget; then
    err "error: curl or wget is required to download files"
    exit 1
  fi
}

# --- Check for existing installation ---
check_existing() {
  if [ -d "$INSTALL_DIR" ]; then
    warn "git-rituals is already installed at ${INSTALL_DIR}"
    if ! prompt_yn "Reinstall?"; then
      info "Aborted."
      exit 0
    fi
    rm -rf "$INSTALL_DIR"
  fi
}

# --- Detect shells ---
detect_shells() {
  DETECTED_SHELLS=""
  [ -f "${HOME}/.zshrc" ] && DETECTED_SHELLS="${DETECTED_SHELLS} zsh"
  [ -f "${HOME}/.bashrc" ] && DETECTED_SHELLS="${DETECTED_SHELLS} bash"
  [ -f "${HOME}/.bash_profile" ] && [ ! -f "${HOME}/.bashrc" ] && DETECTED_SHELLS="${DETECTED_SHELLS} bash"
  [ -d "${HOME}/.config/fish" ] && DETECTED_SHELLS="${DETECTED_SHELLS} fish"

  if [ -z "$DETECTED_SHELLS" ]; then
    warn "No shell config files detected (.zshrc, .bashrc, fish config)"
    warn "You'll need to manually source rituals.sh in your shell config"
  else
    info "Detected shells:${DETECTED_SHELLS}"
  fi
}

# --- All rituals enabled by default ---
ALL_RITUALS="feat,fix,chore,refactor,docs,style,perf,push,pull"

# --- Install files ---
install_files() {
  mkdir -p "$INSTALL_DIR"

  info "Downloading files..."
  download "${REPO_RAW_URL}/rituals.sh" "${INSTALL_DIR}/rituals.sh"
  download "${REPO_RAW_URL}/rituals.fish" "${INSTALL_DIR}/rituals.fish"
  download "${REPO_RAW_URL}/uninstall.sh" "${INSTALL_DIR}/uninstall.sh"
  chmod +x "${INSTALL_DIR}/uninstall.sh"

  ok "Files installed to ${INSTALL_DIR}"
}

# --- Write config ---
write_config() {
  cat > "${INSTALL_DIR}/config" << EOF
# git-rituals config
RITUALS=${ALL_RITUALS}
EOF
  ok "Config written"
}

# --- Inject source lines ---
SOURCE_LINE='[ -f "$HOME/.git-rituals/rituals.sh" ] && source "$HOME/.git-rituals/rituals.sh"'
SOURCE_MARKER="git-rituals"

inject_source() {
  local rcfile="$1"
  if [ -f "$rcfile" ]; then
    if grep -q "$SOURCE_MARKER" "$rcfile" 2>/dev/null; then
      info "Already sourced in $(basename "$rcfile"), skipping"
    else
      printf '\n# git-rituals\n%s\n' "$SOURCE_LINE" >> "$rcfile"
      ok "Added source line to $(basename "$rcfile")"
    fi
  fi
}

setup_shells() {
  for shell in $DETECTED_SHELLS; do
    case "$shell" in
      zsh)
        inject_source "${HOME}/.zshrc"
        ;;
      bash)
        if [ -f "${HOME}/.bashrc" ]; then
          inject_source "${HOME}/.bashrc"
        elif [ -f "${HOME}/.bash_profile" ]; then
          inject_source "${HOME}/.bash_profile"
        fi
        ;;
      fish)
        local fish_conf_dir="${HOME}/.config/fish/conf.d"
        mkdir -p "$fish_conf_dir"
        if [ -f "${fish_conf_dir}/git-rituals.fish" ]; then
          info "Fish config already exists, replacing"
        fi
        cp "${INSTALL_DIR}/rituals.fish" "${fish_conf_dir}/git-rituals.fish"
        ok "Installed fish config to conf.d/git-rituals.fish"
        ;;
    esac
  done
}

# --- Success message ---
print_success() {
  printf "\n"
  if has_cmd gum; then
    gum style --border rounded --padding "0 2" --border-foreground 76 \
      "git-rituals installed!" \
      "" \
      "Restart your shell or run:" \
      "  source ~/.git-rituals/rituals.sh" \
      "" \
      "Then try:" \
      "  feat add login page" \
      "  fix broken auth" \
      "  chore update deps"
  else
    ok "git-rituals installed!"
    printf "\n"
    printf "  Restart your shell or run:\n"
    printf "    ${CYAN}source ~/.git-rituals/rituals.sh${RESET}\n"
    printf "\n"
    printf "  Then try:\n"
    printf "    ${CYAN}feat${RESET} add login page\n"
    printf "    ${CYAN}fix${RESET} broken auth\n"
    printf "    ${CYAN}chore${RESET} update deps\n"
    printf "\n"
    printf "  Run ${CYAN}git-rituals list${RESET} to see all enabled rituals\n"
    printf "  Run ${CYAN}git-rituals uninstall${RESET} to remove\n"
  fi
  printf "\n"
}

# --- Main ---
main() {
  print_banner
  preflight
  check_existing
  detect_shells
  install_files
  write_config
  setup_shells
  print_success
}

main
