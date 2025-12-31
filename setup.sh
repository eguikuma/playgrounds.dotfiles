#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

SANDBOX=${SANDBOX:-0}
SYNC_ONLY=false
PULL_ONLY=false
ASSUME_YES=false
CURRENT_STEP=0
# 上書き確認が必要な重要ファイルのリスト
CRITICAL_FILES=(
  "$HOME/.gitconfig"
  "$HOME/.config/fish/config.fish"
  "$HOME/.ssh/config"
  "$HOME/.ssh/github/config"
  "$HOME/.config/nvim/lazy-lock.json"
  "nvim/lazy-lock.json"
)

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

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo -e "${BLUE}[$CURRENT_STEP/$TOTAL_STEPS]${NC} $1"
}

help() {
  echo "setup.sh - dotfiles環境セットアップツール

[使用方法]
./setup.sh [オプション]

[説明]
WSL2/Linux環境にdotfilesをセットアップします。
二度目以降の実行では、既にインストール済みのツールはスキップされます。

[オプション]
--sync        設定ファイルのみ同期
--pull        ローカル PC から設定を取得
-y, --yes     すべての確認プロンプトをスキップ
-h, --help    このヘルプを表示

[例]
./setup.sh            フルセットアップ
./setup.sh --sync     設定ファイルのみ同期
./setup.sh --sync -y  確認なしで設定を同期
./setup.sh --pull     ローカル PC から設定を取得"
}

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

normalized_dotfiles_path() {
  if [ -f "./fish/config.fish" ]; then
    echo "$(pwd)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    echo "$(ghq root)/github.com/$GITHUB_USERNAME/my.dotfiles"
  fi
}

ask_overwrite() {
  local file="$1"

  if [ "$ASSUME_YES" == "true" ]; then
    return 0
  fi

  if [ ! -f "$file" ]; then
    return 0
  fi

  if ! is_critical "$file"; then
    return 0
  fi

  warn "ファイルが既に存在します：$file"
  read -r -p "上書きしますか？（y/N/a=すべて上書き/s=スキップ）> " response
  case "$response" in
  [Yy]) return 0 ;;
  [Aa])
    ASSUME_YES=true
    return 0
    ;;
  [Ss] | [Nn] | "") return 1 ;;
  *) return 1 ;;
  esac
}

unmanaged_apt_packages() {
  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)
  local bootstrap_file="$dotfiles_path/apt/bootstrap_packages"
  local whitelist_file="$dotfiles_path/apt/whitelist_packages"

  if [ -f "$bootstrap_file" ] && [ -f "$whitelist_file" ]; then
    local installed whitelist unmanaged
    installed=$(apt-mark showmanual 2>/dev/null | sort)
    whitelist=$(cat "$whitelist_file" "$bootstrap_file" 2>/dev/null | grep -v '^#' | grep -v '^$' | sort -u)
    unmanaged=$(comm -23 <(echo "$installed") <(echo "$whitelist"))

    if [ -n "$unmanaged" ]; then
      local brew_packages
      brew_packages=$(brew list --formula 2>/dev/null | sort)

      warn "以下の apt パッケージは setup.sh で管理されていません："
      for pkg in $unmanaged; do
        if echo "$brew_packages" | grep -qx "$pkg"; then
          echo "  $pkg（削除可能）"
        else
          echo "  $pkg"
        fi
      done
      log "削除する場合：sudo apt remove <パッケージ名>"
    fi
  fi
}

prepare_wsl2() {
  step "WSL2 環境の準備を開始します。"

  if ! grep -qi Microsoft /proc/version 2>/dev/null && [ ! -f /.dockerenv ]; then
    warn "このスクリプトは WSL2 環境向けに最適化されています。"
    log "代替環境（Docker コンテナまたはネイティブ Linux）で実行中です。"
  else
    log "WSL2 または Docker コンテナ環境で実行中です。"
  fi

  success "WSL2 環境の準備が完了しました。"
}

prepare_user() {
  step "ユーザー情報の準備を開始します。"

  load_environment

  if [[ -z "$GIT_USER_NAME" ]]; then
    echo -n "Git ユーザー名を入力してください："
    read -r GIT_USER_NAME
  fi

  if [[ -z "$GIT_USER_EMAIL" ]]; then
    echo -n "Git メールアドレスを入力してください："
    read -r GIT_USER_EMAIL
  fi

  GITHUB_SSH_KEY=${GITHUB_SSH_KEY:-""}

  if [ -z "${GITHUB_USERNAME:-}" ] && [ -d ".git" ]; then
    GITHUB_USERNAME=$(git remote get-url origin 2>/dev/null | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p')
    [ -n "$GITHUB_USERNAME" ] && log "リモート URL から GitHub ユーザー名を自動検出しました：$GITHUB_USERNAME"
  fi

  if [[ -z "$GITHUB_USERNAME" ]]; then
    echo -n "GitHub ユーザー名を入力してください："
    read -r GITHUB_USERNAME
  fi

  if [[ -z "$GITHUB_USERNAME" ]]; then
    error "GitHub ユーザー名は必須です。"
  fi

  SSH_KEY_NAME=${SSH_KEY_NAME:-"$GIT_USER_NAME"}

  if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
    error "Git ユーザー名とメールアドレスは必須です。"
  fi

  log "設定内容："
  log "  Git ユーザー名：$GIT_USER_NAME"
  log "  Git メールアドレス：$GIT_USER_EMAIL"
  log "  Windows ユーザー名：$WINDOWS_USERNAME"
  log "  GitHub ユーザー名：$GITHUB_USERNAME"
  log "  SSH キー名：$SSH_KEY_NAME"
  log "  GitHub SSH キー：${GITHUB_SSH_KEY:-未指定}"

  success "ユーザー情報の準備が完了しました。"
}

cleanup_legacy_node() {
  step "旧 Node.js 環境のクリーンアップを開始します。"

  if brew list node &>/dev/null; then
    log "Homebrew の Node.js を削除しています..."
    brew uninstall node --ignore-dependencies 2>/dev/null || true
  else
    log "Homebrew の Node.js は存在しません。スキップします。"
  fi

  if fish -c "functions -q nvm" 2>/dev/null; then
    log "nvm.fish を削除しています..."
    fish -c "fisher remove jorgebucaran/nvm.fish" 2>/dev/null || true
    fish -c "set -e nvm_default_version" 2>/dev/null || true
  else
    log "nvm.fish は存在しません。スキップします。"
  fi

  success "旧 Node.js 環境のクリーンアップが完了しました。"
}

install_apt_packages() {
  step "apt パッケージのインストールを開始します。"

  log "システムパッケージリストを更新しています..."
  sudo apt-get update

  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)
  local bootstrap_file="$dotfiles_path/apt/bootstrap_packages"

  local packages_to_install=""

  if [ -f "$bootstrap_file" ]; then
    while IFS= read -r pkg || [ -n "$pkg" ]; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

      if ! dpkg -s "$pkg" &>/dev/null; then
        packages_to_install="$packages_to_install $pkg"
      else
        log "$pkg は既にインストール済みです。スキップします。"
      fi
    done <"$bootstrap_file"
  else
    warn "bootstrap_packages ファイルが見つかりません：$bootstrap_file"
    log "デフォルトで build-essential をインストールします..."
    packages_to_install="build-essential"
  fi

  if [ -n "$packages_to_install" ]; then
    log "パッケージをインストールしています：$packages_to_install"
    sudo apt-get install -y $packages_to_install
  else
    log "すべての apt パッケージはインストール済みです。"
  fi

  success "apt パッケージのインストールが完了しました。"
}

install_homebrew() {
  step "Homebrew のインストールを開始します。"

  if is_installed_command brew; then
    log "Homebrew は既にインストール済みです。スキップします。"
  else
    log "Homebrew をインストールしています..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  if [ -f ~/.bashrc ]; then
    if ! grep -q 'linuxbrew' ~/.bashrc 2>/dev/null; then
      log "bash でも Homebrew を使えるよう設定しています..."
      cat >>~/.bashrc <<'EOF'
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export HOMEBREW_CURL_PATH="/home/linuxbrew/.linuxbrew/bin/curl"
EOF
    fi
  fi

  success "Homebrew のインストールが完了しました。"
}

install_brew_packages() {
  step "Homebrew パッケージのインストールを開始します。"

  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)
  local brewfile_path="$dotfiles_path/brew/Brewfile"

  if [ -f "$brewfile_path" ]; then
    log "Brewfile からパッケージをインストールしています..."

    if ! brew list curl &>/dev/null; then
      brew install curl
    fi

    export HOMEBREW_CURL_PATH="/home/linuxbrew/.linuxbrew/bin/curl"
    brew bundle --file="$brewfile_path"

    if brew list man-db &>/dev/null; then
      local gman_path="$(brew --prefix man-db)/bin/gman"
      local man_path="$(brew --prefix)/bin/man"
      if [ -x "$gman_path" ] && [ ! -e "$man_path" ]; then
        log "man コマンドのシンボリックリンクを作成しています..."
        ln -sf "$gman_path" "$man_path"
      fi
    fi

    local installed expected unmanaged
    installed=$(brew leaves 2>/dev/null | sort)
    expected=$(grep '^brew "' "$brewfile_path" 2>/dev/null | sed 's/brew "\([^"]*\)".*/\1/' | sort)
    unmanaged=$(comm -23 <(echo "$installed") <(echo "$expected"))

    if [ -n "$unmanaged" ]; then
      warn "以下の Homebrew パッケージは Brewfile に含まれていません："
      echo "$unmanaged"
      read -r -p "これらのパッケージを削除しますか？（y/N）> " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$unmanaged" | xargs brew uninstall --force
        brew autoremove
        log "管理対象外パッケージを削除しました。"
      else
        log "管理対象外パッケージの削除をスキップしました。"
      fi
    else
      log "管理対象外の Homebrew パッケージはありません。"
    fi
  else
    warn "Brewfile が見つかりません：$brewfile_path"
  fi

  success "Homebrew パッケージのインストールが完了しました。"
}

install_fonts() {
  step "フォントのインストールを開始します。"

  if ls ~/.local/share/fonts/JetBrains*.ttf >/dev/null 2>&1; then
    log "JetBrains Mono Nerd Font は既にインストール済みです。スキップします。"
    success "フォントのインストールが完了しました。"
    return
  fi

  log "フォントのインストール先：~/.local/share/fonts/"
  mkdir -p ~/.local/share/fonts

  log "GitHub から JetBrains Mono Nerd Font v3.4.0 をダウンロードしています..."

  local original_dir="$(pwd)"
  cd ~

  if [ ! -f "JetBrainsMono.zip" ]; then
    curl -fLo "JetBrainsMono.zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    log "フォントアーカイブのダウンロードが完了しました。"
  else
    log "フォントアーカイブが既に存在します。再利用します。"
  fi

  log "フォントファイルを展開してインストールしています..."
  unzip -o JetBrainsMono.zip -d JetBrainsMono
  cp JetBrainsMono/*.ttf ~/.local/share/fonts/
  fc-cache -fv
  rm -rf JetBrainsMono JetBrainsMono.zip

  log "フォントのインストール状況を確認しています..."
  if ls ~/.local/share/fonts/JetBrains*.ttf >/dev/null 2>&1; then
    success "フォントのインストールが完了しました。"
    log "次に、Windows にも同じフォントをインストールし、Windows Terminal で設定してください。"
  else
    warn "フォントの登録が確認できません。手動で再インストールしてください。"
  fi

  cd "$original_dir"
}

install_fisher_plugins() {
  step "Fisher プラグインのインストールを開始します。"

  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)
  local plugins_file="$dotfiles_path/fish/fish_plugins"

  if [ ! -f ~/.config/fish/functions/fisher.fish ]; then
    log "Fisher をインストールしています..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  else
    log "Fisher は既にインストール済みです。スキップします。"
  fi

  if [ -f "$plugins_file" ]; then
    log "fish_plugins からプラグインをインストールしています..."
    while IFS= read -r plugin || [ -n "$plugin" ]; do
      [ -z "$plugin" ] && continue
      [[ "$plugin" =~ ^# ]] && continue
      if ! fish -c "fisher list | grep -q '$plugin'" 2>/dev/null; then
        log "$plugin をインストールしています..."
        fish -c "fisher install $plugin" 2>/dev/null || true
      fi
    done <"$plugins_file"

    local installed expected unmanaged
    installed=$(fish -c "fisher list" 2>/dev/null | sort)
    expected=$(grep -v '^#' "$plugins_file" 2>/dev/null | grep -v '^$' | sort)
    unmanaged=$(comm -23 <(echo "$installed") <(echo "$expected"))

    if [ -n "$unmanaged" ]; then
      warn "以下の Fisher プラグインは fish_plugins に含まれていません："
      echo "$unmanaged"
      read -r -p "これらのプラグインを削除しますか？（y/N）> " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$unmanaged" | while read -r plugin; do
          [ -n "$plugin" ] && fish -c "fisher remove $plugin" 2>/dev/null || true
        done
        log "管理対象外プラグインを削除しました。"
      else
        log "管理対象外プラグインの削除をスキップしました。"
      fi
    else
      log "管理対象外の Fisher プラグインはありません。"
    fi
  else
    warn "fish_plugins が見つかりません：$plugins_file"
  fi

  success "Fisher プラグインのインストールが完了しました。"
}

install_dotfiles() {
  step "dotfiles のインストールを開始します。"

  local dotfiles_path="$(ghq root)/github.com/$GITHUB_USERNAME/my.dotfiles"

  if [[ "${SANDBOX:-0}" == "1" ]]; then
    log "サンドボックス環境で実行中です。スキップします。"
    log "パス：$dotfiles_path"
    success "dotfiles のインストールが完了しました。"
    return
  fi

  if [ -d "$dotfiles_path" ]; then
    log "my.dotfiles は既に存在します。スキップします。"
    log "パス：$dotfiles_path"
    success "dotfiles のインストールが完了しました。"
    return
  fi

  log "dotfiles リポジトリをクローンしています..."

  if ghq get git@github.com:$GITHUB_USERNAME/my.dotfiles.git 2>/dev/null; then
    log "SSH でのクローンが完了しました。"
  else
    warn "SSH 接続に失敗しました。HTTPS でクローンします。"
    ghq get https://github.com/$GITHUB_USERNAME/my.dotfiles.git
    log "HTTPS でのクローンが完了しました。"
  fi

  if [ -d "$dotfiles_path" ]; then
    log "クローン先：$dotfiles_path"
  else
    error "dotfiles のクローンに失敗しました。ネットワーク接続とアクセス権限を確認してください。"
  fi

  success "dotfiles のインストールが完了しました。"
}

install_node() {
  step "Node.js のインストールを開始します。"

  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)
  local mise_config="$dotfiles_path/mise/config.toml"

  if [ -f "$mise_config" ]; then
    log "mise 設定ファイルを信頼しています..."
    mise trust "$mise_config"
  fi

  if mise which node &>/dev/null; then
    log "Node.js は既にインストール済みです。スキップします。"
  else
    log "mise で Node.js LTS をインストールしています..."
    mise install node@lts
    mise use --global node@lts
  fi

  success "Node.js のインストールが完了しました。"
}

install_pnpm() {
  step "pnpm のインストールを開始します。"

  if command -v pnpm &>/dev/null; then
    log "pnpm は既にインストール済みです。スキップします。"
  else
    log "pnpm をスタンドアロンでインストールしています..."
    curl -fsSL https://get.pnpm.io/install.sh | SHELL=/home/linuxbrew/.linuxbrew/bin/fish sh -
  fi

  success "pnpm のインストールが完了しました。"
}

install_bun() {
  step "Bun のインストールを開始します。"

  if [ -d "$HOME/.bun" ]; then
    log "Bun は既にインストール済みです。スキップします。"
  else
    log "Bun をインストールしています..."
    curl -fsSL https://bun.sh/install | bash
  fi

  success "Bun のインストールが完了しました。"
}

configure_default_shell() {
  step "デフォルトシェルの設定を開始します。"

  local brew_fish="/home/linuxbrew/.linuxbrew/bin/fish"

  if [ ! -x "$brew_fish" ]; then
    warn "Homebrew 版 fish が見つかりません。スキップします。"
    return
  fi

  if ! grep -q "$brew_fish" /etc/shells 2>/dev/null; then
    log "Homebrew 版 fish を /etc/shells に追加しています..."
    echo "$brew_fish" | sudo tee -a /etc/shells >/dev/null
  fi

  local current_shell
  current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)

  if [ "$current_shell" = "$brew_fish" ]; then
    log "デフォルトシェルは既に Homebrew 版 fish です。スキップします。"
  else
    log "デフォルトシェルを Homebrew 版 fish に変更しています..."
    sudo chsh -s "$brew_fish" "$(whoami)"
  fi

  success "デフォルトシェルの設定が完了しました。"
}

configure_ghq() {
  step "ghq の設定を開始します。"

  log "ghq のルートディレクトリを設定しています..."
  git config --global ghq.root "~/workspaces"
  mkdir -p ~/workspaces

  rm -f ~/.config/fish/conf.d/ghq_key_bindings.fish ~/.config/fish/functions/__ghq_repository_search.fish 2>/dev/null || true

  success "ghq の設定が完了しました。"
  log "使い方：'ghq get https://github.com/user/repo' でリポジトリをクローン"
  log "使い方：'ghq list' で管理中のリポジトリ一覧を表示"
}

configure_dotfiles() {
  step "dotfiles の設定を開始します。"

  local dotfiles_path
  dotfiles_path=$(normalized_dotfiles_path)

  if [ ! -d "$dotfiles_path" ]; then
    error "dotfiles リポジトリが見つかりません：$dotfiles_path"
  fi

  log "dotfiles ディレクトリに移動しています..."
  cd "$dotfiles_path"

  log "Fish shell の設定をセットアップしています..."
  mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions

  if [ -f "fish/config.fish" ]; then
    if ask_overwrite ~/.config/fish/config.fish; then
      expand_placeholder "fish/config.fish" ~/.config/fish/config.fish || { error "Fish 設定ファイルの同期に失敗しました"; }
      log "同期しました：~/.config/fish/config.fish"
    else
      log "スキップしました：~/.config/fish/config.fish"
    fi
  else
    warn "fish/config.fish が見つかりません"
  fi

  if [ -d "fish/conf.d" ] && [ "$(ls -A fish/conf.d 2>/dev/null)" ]; then
    log "Fish conf.d ファイルを同期しています..."
    cp fish/conf.d/* ~/.config/fish/conf.d/ || log "一部の Fish conf.d ファイルの同期をスキップしました"
  fi

  if [ -d "fish/functions" ] && [ "$(ls -A fish/functions 2>/dev/null)" ]; then
    log "Fish 関数を同期しています..."
    cp fish/functions/* ~/.config/fish/functions/ || log "一部の Fish 関数ファイルの同期をスキップしました"
  fi

  log "Git グローバル設定をセットアップしています..."

  if [ -f "git/.gitconfig" ]; then
    if ask_overwrite ~/.gitconfig; then
      expand_placeholder "git/.gitconfig" ~/.gitconfig || { error "Git 設定ファイルの同期に失敗しました"; }
      log "同期しました：~/.gitconfig"
    else
      log "スキップしました：~/.gitconfig"
    fi
  else
    warn "git/.gitconfig が見つかりません"
  fi

  log "Neovim エディタの設定をセットアップしています..."
  mkdir -p ~/.config/nvim/lua

  if [ -d "nvim" ]; then
    cp nvim/init.lua ~/.config/nvim/

    for dir in core plugins; do
      if [ -d "nvim/$dir" ]; then
        rsync -a --delete "nvim/$dir/" ~/.config/nvim/lua/"$dir"/
      fi
    done

    if [ -f "nvim/lazy-lock.json" ]; then
      if ask_overwrite ~/.config/nvim/lazy-lock.json; then
        cp nvim/lazy-lock.json ~/.config/nvim/ || { error "lazy-lock.json の同期に失敗しました"; }
        log "同期しました：~/.config/nvim/lazy-lock.json"
      else
        log "スキップしました：~/.config/nvim/lazy-lock.json"
      fi
    else
      warn "nvim/lazy-lock.json が見つかりません"
    fi
  else
    warn "nvim ディレクトリが見つかりません"
  fi

  log "SSH 接続設定をセットアップしています..."
  mkdir -p ~/.ssh/github

  if [ -f "ssh/config" ]; then
    if ask_overwrite ~/.ssh/config; then
      cp ssh/config ~/.ssh/ || { error "SSH 設定ファイルの同期に失敗しました"; }
      log "同期しました：~/.ssh/config"
    else
      log "スキップしました：~/.ssh/config"
    fi
  else
    warn "ssh/config が見つかりません"
  fi

  if [ -f "ssh/github/config" ]; then
    if ask_overwrite ~/.ssh/github/config; then
      expand_placeholder "ssh/github/config" ~/.ssh/github/config || log "SSH GitHub 設定の同期に失敗しました"
      log "同期しました：~/.ssh/github/config"
    else
      log "スキップしました：~/.ssh/github/config"
    fi
  else
    warn "ssh/github/config が見つかりません"
  fi

  log "mise 設定をセットアップしています..."
  mkdir -p ~/.config/mise
  if [ -f "mise/config.toml" ]; then
    cp mise/config.toml ~/.config/mise/config.toml
    log "同期しました：~/.config/mise/config.toml"
  else
    warn "mise/config.toml が見つかりません"
  fi

  log "環境固有の設定を調整しています..."

  local username=$(whoami)
  if [ -f ~/.config/fish/functions/github.fish ]; then
    sed -i "s|/home/[^/]*/workspaces|/home/$username/workspaces|g" ~/.config/fish/functions/github.fish
  fi

  log "セキュリティのため SSH 設定ファイルの権限を調整しています..."
  chmod 600 ~/.ssh/config ~/.ssh/*/config 2>/dev/null || true

  success "dotfiles の設定が完了しました。"
}

configure_clipboard() {
  step "クリップボード連携の設定を開始します。"

  if ! grep -qi microsoft /proc/version 2>/dev/null; then
    log "WSL2 環境ではありません。スキップします。"
    success "クリップボード連携の設定が完了しました。"
    return
  fi

  if command -v win32yank.exe &>/dev/null; then
    log "win32yank.exe は既に利用可能です。スキップします。"
    success "クリップボード連携の設定が完了しました。"
    return
  fi

  local win32yank_path="/mnt/c/Users/$WINDOWS_USERNAME/AppData/Local/Microsoft/WinGet/Links/win32yank.exe"

  if [ ! -f "$win32yank_path" ]; then
    warn "win32yank.exe が見つかりません。"
    log "Windows 側で以下のコマンドを実行してください："
    log "  winget install equalsraf.win32yank"
    success "クリップボード連携の設定が完了しました。"
    return
  fi

  mkdir -p ~/.local/bin
  ln -sf "$win32yank_path" ~/.local/bin/win32yank.exe
  log "シンボリックリンクを作成しました：~/.local/bin/win32yank.exe"

  success "クリップボード連携の設定が完了しました。"
}

configure_git() {
  step "Git の設定を開始します。"

  log "Git グローバル設定にユーザー情報を適用しています..."

  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global core.editor "nvim"

  log "Git 設定を適用しました："
  log "  - ユーザー名：$GIT_USER_NAME"
  log "  - メールアドレス：$GIT_USER_EMAIL"
  log "  - デフォルトエディタ：Neovim"

  success "Git の設定が完了しました。"
}

verify() {
  step "設定の検証を開始します。"

  log "Nerd Font アイコンテスト..."
  printf "\ue5fe \uf07b \uf1c0 \uf0c7 \uf013\n"

  log "インストール済みツールを確認しています..."
  echo "Fish：$(fish --version 2>/dev/null || echo '❌')"
  echo "Neovim：$(nvim --version | head -n1 2>/dev/null || echo '❌')"
  echo "ghq：$(ghq --version 2>/dev/null || echo '❌')"
  echo "GitHub CLI：$(gh --version 2>/dev/null | head -n1 || echo '❌')"

  log "設定ファイルを確認しています..."
  echo "Fish 設定：$([ -f ~/.config/fish/config.fish ] && echo '✅' || echo '❌')"
  echo "Git 設定：$([ -f ~/.gitconfig ] && echo '✅' || echo '❌')"
  echo "Neovim 設定：$([ -f ~/.config/nvim/init.lua ] && echo '✅' || echo '❌')"
  echo "SSH 設定：$([ -f ~/.ssh/config ] && echo '✅' || echo '❌')"

  unmanaged_apt_packages

  log "手動タスク："
  echo "1. Windows にフォントをインストール"
  echo "   https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  echo "   zip を展開後、.ttf ファイルを右クリックしてインストール"
  echo ""
  echo "2. Windows Terminal のフォント設定"
  echo "   Ctrl + , → プロファイル → Ubuntu → 外観"
  echo "   フォントフェイスを 'JetBrains Mono' に変更して再起動"
  echo ""
  echo "3. SSH キーのセットアップ（任意）"
  if [ -n "${GITHUB_SSH_KEY:-}" ]; then
    echo "   秘密鍵を ~/.ssh/github/$GITHUB_SSH_KEY に配置"
    echo "   chmod 600 ~/.ssh/github/$GITHUB_SSH_KEY"
    echo "   ssh -T git@github.com でテスト"
  else
    echo "   スキップ"
  fi
  echo ""
  echo "4. Windows Terminal 設定（任意）"
  echo "   windows/settings.json の actions と keybindings を"
  echo "   Windows Terminal の settings.json にマージ"
  echo ""
  echo "5. PowerShell 設定（任意）"
  echo "   windows/profile.ps1 を Windows の \$PROFILE にコピー"
  echo ""
  echo "6. Neovim クリップボード連携（任意）"
  echo "   Windows 側で実行：winget install equalsraf.win32yank"
  echo "   その後 ./setup.sh --sync を再実行"

  success "設定の検証が完了しました。"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --sync)
      SYNC_ONLY=true
      shift
      ;;
    --pull)
      PULL_ONLY=true
      shift
      ;;
    -y | --yes)
      ASSUME_YES=true
      shift
      ;;
    -h | --help)
      help
      exit 0
      ;;
    *)
      warn "不明なオプション：$1"
      help
      exit 1
      ;;
    esac
  done

  if [ "$PULL_ONLY" == "true" ]; then
    success "setup.sh --pull"

    if [ -f ~/.config/nvim/lazy-lock.json ]; then
      if ask_overwrite nvim/lazy-lock.json; then
        cp ~/.config/nvim/lazy-lock.json nvim/ || { error "lazy-lock.json の取得に失敗しました"; }
        log "取得しました：nvim/lazy-lock.json"
      else
        log "スキップしました：nvim/lazy-lock.json"
      fi
    else
      warn "lazy-lock.json が見つかりません"
    fi

    success "取得が完了しました"
  elif [ "$SYNC_ONLY" == "true" ]; then
    SYNC_STEPS=(
      prepare_wsl2
      prepare_user
      configure_default_shell
      configure_ghq
      configure_dotfiles
      configure_clipboard
      configure_git
      verify
    )
    TOTAL_STEPS=${#SYNC_STEPS[@]}
    success "setup.sh --sync"

    for func in "${SYNC_STEPS[@]}"; do
      $func
    done

    success "同期が完了しました"
  else
    TOTAL_STEPS=$(grep -c "step \"" "$0")
    success "setup.sh"

    # prepare
    prepare_wsl2
    prepare_user

    # cleanup
    cleanup_legacy_node

    # install
    install_apt_packages
    install_homebrew
    install_brew_packages
    install_fonts
    install_fisher_plugins
    install_dotfiles
    install_node
    install_pnpm
    install_bun

    # configure
    configure_default_shell
    configure_ghq
    configure_dotfiles
    configure_clipboard
    configure_git

    # verify
    verify

    success "自動セットアップが完了しました"
  fi
}

main "$@"
