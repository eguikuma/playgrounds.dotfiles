#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

log() {
  _log "CI" "$1"
}

success() {
  _success "CI" "$1"
}

error() {
  _error "CI" "$1"
}

warn() {
  _warn "CI" "$1"
}

CONTAINER_NAME="dotfiles-ci-container"
CONTAINER_ID=""
DRY_RUN=false

ci_help() {
  echo "⚙️ ci.sh - コードフォーマットツール

[使用方法]
./ci.sh [オプション]

[説明]
dotfilesリポジトリ内のコードをフォーマットします。
既存のコンテナがあれば再利用し、なければ新規作成します。

[対象ファイル]
- Shell (.sh)      : shfmt
- Fish (.fish)     : fish_indent
- Lua (.lua)       : stylua
- JSON (.json)     : prettier
- PowerShell (.ps1): pwsh

[オプション]
--clean     既存のコンテナを削除して新規作成
--remove    既存のコンテナを削除して終了
--status    コンテナの状態を表示
-h, --help  このヘルプを表示

[例]
./ci.sh              フォーマット実行
./ci.sh --clean      コンテナを再作成してフォーマット
./ci.sh --remove     コンテナを削除
./ci.sh --status     コンテナの状態を確認"
}

is_running() {
  local container_id="$1"
  [ -n "$(docker ps -q --filter "id=$container_id" 2>/dev/null)" ]
}

id() {
  docker ps -aq --filter "name=$CONTAINER_NAME" 2>/dev/null | head -n1
}

status() {
  local existing_id
  existing_id=$(id)

  if [ -n "$existing_id" ]; then
    echo "┌──────────────────────────────────────────────────────────────"
    echo "│ Container Name: $CONTAINER_NAME"
    echo "│ Container ID: ${existing_id:0:12}"

    if is_running "$existing_id"; then
      echo "│ Status: Running ✅"
    else
      echo "│ Status: Stopped ⏸️"
    fi

    echo "└──────────────────────────────────────────────────────────────"
  else
    log "No CI container exists"
    log "Run './ci.sh' to create one"
  fi
}

remove() {
  local existing_id
  existing_id=$(id)

  if [ -n "$existing_id" ]; then
    log "Removing existing container (ID: ${existing_id:0:12})..."
    docker stop "$existing_id" >/dev/null 2>&1 || true
    docker rm "$existing_id" >/dev/null 2>&1 || true
    success "Existing container removed"
  else
    log "No existing container found"
  fi
}

ensure() {
  local container_id="$1"

  if ! is_running "$container_id"; then
    log "Starting stopped container..."
    docker start "$container_id" >/dev/null 2>&1
    sleep 1
  fi
}

create() {
  log "Building Docker image for CI..."
  if ! docker build \
    --build-arg LOCAL_UID="$(id -u)" \
    --build-arg LOCAL_GID="$(id -g)" \
    -f Dockerfile.ci \
    -t dotfiles-ci .; then
    error "Failed to build Docker image"
    exit 1
  fi
  success "Docker image build completed"

  log "Starting new CI container..."
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    --label dotfiles-ci \
    -e LOCAL_UID="$(id -u)" \
    -e LOCAL_GID="$(id -g)" \
    -v "$(pwd):/workspaces" \
    --workdir /workspaces \
    dotfiles-ci \
    sleep 604800) # 7 days

  if [ -z "$CONTAINER_ID" ]; then
    error "Failed to start container"
    exit 1
  fi

  success "CI container created (ID: ${CONTAINER_ID:0:12})"
}

format() {
  log "Formatting Shell files (.sh)..."
  docker exec "$CONTAINER_ID" find /workspaces -name "*.sh" -type f -exec shfmt -w {} \; || warn "Issues occurred while formatting Shell files"

  log "Formatting Fish files (.fish)..."
  docker exec "$CONTAINER_ID" bash -c '
        for file in $(find /workspaces -name "*.fish" -type f); do
            fish_indent < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file" || echo "Warning：Failed to format $file"
        done
    ' || warn "Issues occurred while formatting Fish files"

  log "Formatting Lua files (.lua)..."
  docker exec "$CONTAINER_ID" bash -c '
        if [ -f /workspaces/stylua.toml ]; then
            find /workspaces -name "*.lua" -type f -exec stylua --config-path /workspaces/stylua.toml {} \;
        else
            find /workspaces -name "*.lua" -type f -exec stylua {} \;
        fi
    ' || warn "Issues occurred while formatting Lua files"

  log "Formatting JSON files (.json)..."
  docker exec "$CONTAINER_ID" bash -c '
        find /workspaces -name "*.json" -type f -exec prettier --write {} \;
    ' || warn "Issues occurred while formatting JSON files"

  log "Formatting PowerShell files (.ps1)..."
  docker exec "$CONTAINER_ID" bash -c '
        for file in $(find /workspaces -name "*.ps1" -type f); do
            pwsh -Command "
                try {
                    \$lines = Get-Content \"$file\"
                    \$result = @()

                    foreach (\$line in \$lines) {
                        \$cleaned = \$line -replace \"\\t\", \"    \"
                        \$cleaned = \$cleaned.TrimEnd()

                        if (\$cleaned -ne \"\") {
                            \$result += \$cleaned
                        } elseif (\$result.Count -gt 0 -and \$result[-1] -ne \"\") {
                            \$result += \"\"
                        }
                    }

                    while (\$result.Count -gt 1 -and \$result[-1] -eq \"\") {
                        \$result = \$result[0..(\$result.Count - 2)]
                    }

                    \$result | Set-Content \"$file\"
                    Write-Host \"Formatted：$file\"
                } catch {
                    Write-Host \"Warning：Failed to format $file - \$_\"
                }
            "
        done
    ' || warn "Issues occurred while formatting PowerShell files"
}

main() {
  local do_clean=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    --clean)
      do_clean=true
      shift
      ;;
    --remove)
      remove
      exit 0
      ;;
    --status)
      status
      exit 0
      ;;
    -h | --help)
      ci_help
      exit 0
      ;;
    *)
      error "Unknown option：$1"
      ci_help
      exit 1
      ;;
    esac
  done

  success "⚙️ ci.sh"

  if ! command -v docker >/dev/null 2>&1; then
    error "Docker not found. Please install Docker."
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker."
    exit 1
  fi

  if [ "$do_clean" = true ]; then
    remove
  fi

  local existing_id
  existing_id=$(id)

  if [ -n "$existing_id" ]; then
    success "Found existing container (ID: ${existing_id:0:12})"
    CONTAINER_ID="$existing_id"
    ensure "$existing_id"
  else
    create
  fi

  format

  success "✅ All file CI processing completed"
}

main "$@"
