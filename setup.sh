#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

SANDBOX=${SANDBOX:-0}
SYNC_ONLY=false
SKIP_CONFIRM=false

log() {
  _log "SETUP" "$1"
}

success() {
  _success "SETUP" "$1"
}

warn() {
  _warn "SETUP" "$1"
}

error() {
  _error "SETUP" "$1"
}

CURRENT_STEP=0

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo -e "${BLUE}[$CURRENT_STEP/$TOTAL_STEPS]${NC} $1"
}

setup_help() {
  echo "🚀 setup.sh - dotfiles環境セットアップツール

[使用方法]
./setup.sh [オプション]

[説明]
WSL2/Linux環境にdotfilesをセットアップします。
二度目以降の実行では、既にインストール済みのツールはスキップされます。

[オプション]
--sync        設定ファイルのみ同期（ツールインストールをスキップ）
-y, --yes     すべての確認プロンプトをスキップ
-h, --help    このヘルプを表示

[例]
./setup.sh            フルセットアップ（初回）
./setup.sh --sync     設定ファイルのみ同期
./setup.sh --sync -y  確認なしで設定を同期"
}

CRITICAL_FILES=(
  "$HOME/.gitconfig"
  "$HOME/.config/fish/config.fish"
  "$HOME/.ssh/config"
  "$HOME/.ssh/github/config"
)

is_critical() {
  local file="$1"
  for critical in "${CRITICAL_FILES[@]}"; do
    if [ "$file" == "$critical" ]; then
      return 0
    fi
  done
  return 1
}

is_installed_command() {
  command -v "$1" &>/dev/null
}

is_brew_installed() {
  if is_installed_command brew; then
    brew list "$1" &>/dev/null
    return $?
  fi
  return 1
}

overwrite() {
  local file="$1"

  if [ "$SKIP_CONFIRM" == "true" ]; then
    return 0
  fi

  if [ ! -f "$file" ]; then
    return 0
  fi

  if ! is_critical "$file"; then
    return 0
  fi

  warn "File exists: $file"
  read -r -p "Overwrite? (y/N/a=all/s=skip) > " response
  case "$response" in
  [Yy]) return 0 ;;
  [Aa])
    SKIP_CONFIRM=true
    return 0
    ;;
  [Ss] | [Nn] | "") return 1 ;;
  *) return 1 ;;
  esac
}

setup_wsl2() {
  log "Starting WSL2 setup."

  if ! grep -q Microsoft /proc/version 2>/dev/null && [ ! -f /.dockerenv ]; then
    warn "This script is optimized for WSL2 environment."
    log "Running in alternative environment (Docker container or native Linux)."
  else
    log "Running in WSL2 or Docker container environment."
  fi

  success "WSL2 setup completed."
}

setup_user() {
  step "Starting user information setup."

  load_environment

  if [[ -z "$GIT_USER_NAME" ]]; then
    echo -n "Please enter Git username: "
    read -r GIT_USER_NAME
  fi

  if [[ -z "$GIT_USER_EMAIL" ]]; then
    echo -n "Please enter Git email address: "
    read -r GIT_USER_EMAIL
  fi

  GITHUB_SSH_KEY=${GITHUB_SSH_KEY:-""}

  if [ -z "${GITHUB_USERNAME:-}" ] && [ -d ".git" ]; then
    GITHUB_USERNAME=$(git remote get-url origin 2>/dev/null | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p')
    [ -n "$GITHUB_USERNAME" ] && log "Auto-detected GitHub username from remote URL: $GITHUB_USERNAME"
  fi

  if [[ -z "$GITHUB_USERNAME" ]]; then
    echo -n "Please enter GitHub username: "
    read -r GITHUB_USERNAME
  fi

  if [[ -z "$GITHUB_USERNAME" ]]; then
    error "GitHub username is required."
  fi

  SSH_KEY_NAME=${SSH_KEY_NAME:-"$GIT_USER_NAME"}

  if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
    error "Git username and email address are required."
  fi

  log "Configuration:"
  log "  Git username: $GIT_USER_NAME"
  log "  Git email: $GIT_USER_EMAIL"
  log "  Windows username: $WINDOWS_USERNAME"
  log "  GitHub username: $GITHUB_USERNAME"
  log "  SSH key name: $SSH_KEY_NAME"
  log "  GitHub SSH key: ${GITHUB_SSH_KEY:-Not specified}"

  success "User information setup completed."
}

install_apt_tools() {
  step "Starting basic development tools and libraries installation."

  log "Updating system package list..."
  sudo apt-get update

  local packages_to_install=""
  for pkg in build-essential git curl unzip tree fish; do
    if ! dpkg -l "$pkg" &>/dev/null; then
      packages_to_install="$packages_to_install $pkg"
    else
      log "Package '$pkg' is already installed. Skipping."
    fi
  done

  if [ -n "$packages_to_install" ]; then
    log "Installing packages:$packages_to_install"
    sudo apt-get install -y $packages_to_install
  else
    log "All basic packages are already installed."
  fi

  if ! dpkg -l wslu &>/dev/null; then
    log "Adding WSL utility packages..."
    if sudo add-apt-repository -y ppa:wslutilities/wslu 2>/dev/null && sudo apt-get install -y wslu 2>/dev/null; then
      success "WSL utilities installation completed."
    else
      warn "WSL utilities installation failed. This is normal in non-WSL environments."
    fi
  else
    log "WSL utilities already installed. Skipping."
  fi

  if ! is_installed_command brew; then
    log "Installing Homebrew package manager..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    success "Homebrew installation completed."
  else
    log "Homebrew is already installed. Skipping."
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  success "Basic development tools and libraries installation completed."
}

install_editors() {
  step "Starting editor installation."

  if is_installed_command nvim; then
    local current_version
    current_version=$(nvim --version | head -n1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
    log "Neovim is already installed ($current_version). Skipping."
    success "Editor installation completed."
    return
  fi

  log "Downloading Neovim binary (tar.gz) from GitHub..."
  log "Installation path: /opt/nvim-linux-x86_64"

  sudo rm -rf /opt/nvim*

  cd /tmp
  if ! curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
    error "Failed to download Neovim binary"
    exit 1
  fi

  if [ ! -f nvim-linux-x86_64.tar.gz ] || [ ! -s nvim-linux-x86_64.tar.gz ]; then
    error "Downloaded file is empty or corrupted"
    exit 1
  fi

  log "Extracting Neovim binary..."
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

  rm nvim-linux-x86_64.tar.gz

  success "Editor installation completed."
}

install_fonts() {
  step "Starting font installation."

  if fc-list | grep -qi "JetBrains.*Mono.*Nerd"; then
    log "JetBrains Mono Nerd Font is already installed. Skipping."
    success "Font installation completed."
    return
  fi

  log "Font installation path: ~/.local/share/fonts/"
  mkdir -p ~/.local/share/fonts

  log "Downloading JetBrains Mono Nerd Font v3.4.0 from GitHub..."

  cd ~

  if [ ! -f "JetBrainsMono.zip" ]; then
    curl -fLo "JetBrainsMono.zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    log "Font archive download completed."
  else
    log "Font archive already exists. Reusing it."
  fi

  log "Extracting and installing font files..."
  unzip -o JetBrainsMono.zip -d JetBrainsMono
  cp JetBrainsMono/*.ttf ~/.local/share/fonts/
  fc-cache -fv
  rm -rf JetBrainsMono JetBrainsMono.zip

  log "Checking font installation status..."
  if fc-list | grep -qi jetbrains; then
    success "Font installation completed."
    log "Next, install the same font on Windows and configure it in Windows Terminal."
  else
    warn "Font registration cannot be confirmed. Please reinstall manually."
  fi
}

install_ghq() {
  step "Starting ghq installation."

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  if is_brew_installed ghq; then
    log "ghq is already installed. Skipping."
  else
    log "Installing ghq via Homebrew..."
    brew install ghq
  fi

  log "Setting up ghq root directory..."
  git config --global ghq.root "~/workspaces"
  mkdir -p ~/workspaces

  success "ghq installation completed."
  log "Usage: 'ghq get https://github.com/user/repo' to clone repository"
  log "Usage: 'ghq list' to display list of managed repositories"
}

clone_dotfiles() {
  step "Starting dotfiles clone."

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  local dotfiles_path="$(ghq root)/github.com/$GITHUB_USERNAME/playgrounds.dotfiles"

  if [[ "${SANDBOX:-0}" == "1" ]]; then
    success "Running in sandbox environment."
    log "Path: $dotfiles_path"
    return
  fi

  if [ -d "$dotfiles_path" ]; then
    log "playgrounds.dotfiles already exists: $dotfiles_path"
    log "Reusing existing directory."
    success "Dotfiles clone completed."
    return
  fi

  log "Cloning dotfiles repository..."

  if ghq get git@github.com:$GITHUB_USERNAME/playgrounds.dotfiles.git 2>/dev/null; then
    success "SSH clone completed."
    log "SSH key is properly configured."
  else
    warn "SSH connection failed. Cloning via HTTPS."
    log "SSH key may not be configured or access permission may not be available."

    ghq get https://github.com/$GITHUB_USERNAME/playgrounds.dotfiles.git
    success "HTTPS clone completed."
  fi

  if [ -d "$dotfiles_path" ]; then
    success "Dotfiles clone completed."
    log "Clone destination: $dotfiles_path"
    log "Dotfiles configuration files are now available."
  else
    error "Dotfiles clone failed. Please check network connection and access permissions."
  fi
}

deploy_configs() {
  step "Starting dotfiles configuration."

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  local dotfiles_path="$(ghq root)/github.com/$GITHUB_USERNAME/playgrounds.dotfiles"

  if [ ! -d "$dotfiles_path" ] && [ -f "./fish/config.fish" ]; then
    dotfiles_path="$(pwd)"
    log "Using current directory as dotfiles path: $dotfiles_path"
  elif [ ! -d "$dotfiles_path" ]; then
    error "Dotfiles repository not found: $dotfiles_path"
  fi

  log "Moving to dotfiles directory: $dotfiles_path"
  cd "$dotfiles_path"

  log "Setting up Fish shell configuration..."
  log "  - Main config: config.fish (environment variables, aliases, path settings)"
  log "  - Initialization config: conf.d/ (auto-run at startup)"
  log "  - Custom functions: functions/ (utility commands)"
  mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions

  if [ -f "fish/config.fish" ]; then
    if overwrite ~/.config/fish/config.fish; then
      expand_placeholder "fish/config.fish" ~/.config/fish/config.fish || { error "Failed to process Fish configuration file"; }
      log "Updated: ~/.config/fish/config.fish"
    else
      log "Skipped: ~/.config/fish/config.fish"
    fi
  else
    warn "fish/config.fish not found"
  fi

  if [ -d "fish/conf.d" ] && [ "$(ls -A fish/conf.d 2>/dev/null)" ]; then
    log "Syncing Fish conf.d files..."
    cp fish/conf.d/* ~/.config/fish/conf.d/ || log "Skipped copying some Fish conf.d files"
  fi

  if [ -d "fish/functions" ] && [ "$(ls -A fish/functions 2>/dev/null)" ]; then
    log "Syncing Fish functions..."
    cp fish/functions/* ~/.config/fish/functions/ || log "Skipped copying some Fish functions files"
  fi

  log "Setting up Git global configuration..."
  log "  - Main config: .gitconfig (aliases, default branch, etc.)"
  log "  - gitmoji config: gitmojis.json (emojis for commit messages)"

  if [ -f "git/.gitconfig" ]; then
    if overwrite ~/.gitconfig; then
      expand_placeholder "git/.gitconfig" ~/.gitconfig || { error "Failed to process Git configuration file"; }
      log "Updated: ~/.gitconfig"
    else
      log "Skipped: ~/.gitconfig"
    fi
  else
    warn "git/.gitconfig not found"
  fi

  if [ -f "git/gitmojis.json" ]; then
    cp git/gitmojis.json ~/.gitmojis.json || log "Skipped copying gitmojis.json"
  fi

  log "Setting up Neovim editor configuration..."
  log "  - Main config: init.lua (basic editor behavior settings)"
  log "  - Plugins: plugins.lua (LSP, file explorer, etc.)"
  mkdir -p ~/.config/nvim/lua

  if [ -f "nvim/init.lua" ]; then
    cp nvim/init.lua ~/.config/nvim/ || { error "Failed to copy Neovim configuration file"; }
  else
    warn "nvim/init.lua not found"
  fi

  if [ -f "nvim/lua/plugins.lua" ]; then
    cp nvim/lua/plugins.lua ~/.config/nvim/lua/ || log "Skipped copying Neovim plugin configuration"
  fi

  log "Setting up SSH connection configuration..."
  log "  - Main config: config (host-specific connection settings)"
  log "  - GitHub config: github/config (for GitHub server)"
  mkdir -p ~/.ssh/github

  if [ -f "ssh/config" ]; then
    if overwrite ~/.ssh/config; then
      cp ssh/config ~/.ssh/ || { error "Failed to copy SSH configuration file"; }
      log "Updated: ~/.ssh/config"
    else
      log "Skipped: ~/.ssh/config"
    fi
  else
    warn "ssh/config not found"
  fi

  if [ -f "ssh/github/config" ]; then
    if overwrite ~/.ssh/github/config; then
      expand_placeholder "ssh/github/config" ~/.ssh/github/config || log "Failed to process SSH GitHub configuration"
      log "Updated: ~/.ssh/github/config"
    else
      log "Skipped: ~/.ssh/github/config"
    fi
  else
    warn "ssh/github/config not found"
  fi

  log "Adjusting environment-specific settings..."

  local username=$(whoami)
  if [ -f ~/.config/fish/functions/github.fish ]; then
    log "  - Adjusting workspaces path for username '$username'"
    sed -i "s|/home/[^/]*/workspaces|/home/$username/workspaces|g" ~/.config/fish/functions/github.fish
  fi

  log "Adjusting SSH configuration file permissions for security..."
  chmod 600 ~/.ssh/config ~/.ssh/*/config 2>/dev/null || true

  success "Dotfiles configuration completed."
  log "Tip: Start Fish shell to apply new settings."
}

install_additional_tools() {
  step "Starting additional tools installation."

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  if [ ! -f ~/.config/fish/functions/fisher.fish ]; then
    log "Installing Fisher plugin manager..."
    log "Installation content: Fisher core + ghq-fzf integration plugin"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher decors/fish-ghq"
    rm -f ~/.config/fish/conf.d/ghq_key_bindings.fish ~/.config/fish/functions/__ghq_repository_search.fish 2>/dev/null || true
  else
    log "Fisher is already installed. Skipping."
  fi

  log "Installing development tool libraries..."
  local brew_tools="gh fzf gitmoji xh bat eza fd ripgrep delta"
  local tools_to_install=""

  for tool in $brew_tools; do
    if ! is_brew_installed "$tool"; then
      tools_to_install="$tools_to_install $tool"
    else
      log "Tool '$tool' is already installed. Skipping."
    fi
  done

  if [ -n "$tools_to_install" ]; then
    log "Installing:$tools_to_install"
    brew install $tools_to_install
  else
    log "All brew tools are already installed."
  fi

  log "Resolving Node.js conflicts between Homebrew and nvm.fish..."
  brew uninstall node --ignore-dependencies 2>/dev/null || true

  log "Fixing gitmoji shebang for nvm.fish compatibility..."
  if command -v gitmoji &>/dev/null; then
    sed -i '1s|.*|#!/usr/bin/env node|' $(which gitmoji) 2>/dev/null || true
    log "gitmoji shebang updated to use nvm.fish Node.js"
  fi

  if ! fish -c "functions -q nvm" 2>/dev/null; then
    log "Installing Node.js version management tool (nvm.fish)..."
    fish -c "fisher install jorgebucaran/nvm.fish" 2>/dev/null || true
  else
    log "nvm.fish is already installed. Skipping."
  fi

  log "Setting up Node.js LTS version as default..."
  fish -c "nvm install lts" 2>/dev/null || true
  fish -c "set --universal nvm_default_version lts" 2>/dev/null || true
  log "Node.js LTS version installed and set as default"

  success "Additional tools installation completed."
  log "Tip: Commands like 'fzf', 'bat', 'eza' are now available in Fish shell."
}

configure_git() {
  step "Starting Git global configuration."

  log "Applying Git user information to global configuration..."

  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"

  git config --global core.editor "nvim"

  log "Applied Git configuration:"
  log "  - Username: $GIT_USER_NAME"
  log "  - Email: $GIT_USER_EMAIL"
  log "  - Default editor: Neovim"

  success "Git global configuration completed."
  log "Tip: You can check configuration with 'git config --list'."
}

verify() {
  step "Starting configuration verification."

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  log "Nerd Font icon test..."
  printf "\ue5fe \uf07b \uf1c0 \uf0c7 \uf013\n"

  log "Checking installed tools..."
  echo "Fish: $(fish --version 2>/dev/null || echo 'Not found')"
  echo "Neovim: $(nvim --version | head -n1 2>/dev/null || echo 'Not found')"
  echo "ghq: $(ghq --version 2>/dev/null || echo 'Not found')"
  echo "GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'Not found')"

  log "Checking configuration files..."
  echo "Fish config: $([ -f ~/.config/fish/config.fish ] && echo 'OK' || echo 'Missing')"
  echo "Git config: $([ -f ~/.gitconfig ] && echo 'OK' || echo 'Missing')"
  echo "Neovim config: $([ -f ~/.config/nvim/init.lua ] && echo 'OK' || echo 'Missing')"
  echo "SSH config: $([ -f ~/.ssh/config ] && echo 'OK' || echo 'Missing')"

  success "Configuration verification completed."
}

manual_tasks() {
  step "Please start the manual task."

  warn "Manual tasks:"

  success "1. Install font on Windows"
  echo "   https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  echo "   After extracting zip, right-click .ttf files to install"

  success "2. Configure Windows Terminal font"
  echo "   Ctrl + , → Profile → Ubuntu → Appearance"
  echo "   Change font face to 'JetBrains Mono' and restart"

  success "3. SSH key setup (optional)"
  if [ -n "${GITHUB_SSH_KEY:-}" ]; then
    echo "   Place private key at ~/.ssh/github/$GITHUB_SSH_KEY"
    echo "   chmod 600 ~/.ssh/github/$GITHUB_SSH_KEY"
    echo "   Test with ssh -T git@github.com"
  else
    echo "   Skip"
  fi

  success "4. Set Fish shell as default shell"
  echo "   chsh -s \$(which fish)"

  success "5. PowerShell configuration (optional)"
  echo "   Copy power-shell/Microsoft.PowerShell_profile.ps1 to Windows \$PROFILE"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --sync)
      SYNC_ONLY=true
      shift
      ;;
    -y | --yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h | --help)
      setup_help
      exit 0
      ;;
    *)
      warn "Unknown option: $1"
      setup_help
      exit 1
      ;;
    esac
  done

  if [ "$SYNC_ONLY" == "true" ]; then
    TOTAL_STEPS=4
    success "🔄 setup.sh --sync"
    setup_wsl2
    setup_user
    deploy_configs
    configure_git
    verify
    success "✨ Sync completed"
  else
    TOTAL_STEPS=$(grep -c "step \"" "$0")
    success "🚀 setup.sh"

    setup_wsl2
    setup_user

    install_apt_tools
    install_editors
    install_fonts
    install_ghq

    clone_dotfiles
    deploy_configs
    configure_git
    install_additional_tools

    verify
    manual_tasks

    success "✨ Automatic setup completed"
  fi
}

main "$@"
