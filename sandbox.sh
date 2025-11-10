#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

log() {
  _log "SANDBOX" "$1"
}

success() {
  _success "SANDBOX" "$1"
}

error() {
  _error "SANDBOX" "$1"
}

warn() {
  _warn "SANDBOX" "$1"
}

CONTAINER_NAME="dotfiles-sandbox-container"
CONTAINER_ID=""

sandbox_help() {
  echo "🏖️ sandbox.sh - サンドボックス環境

[使用方法]
./sandbox.sh [オプション]

[説明]
dotfilesのテスト用サンドボックス環境をDockerで作成・管理します。
既存のコンテナがあれば再利用し、なければ新規作成します。

[オプション]
--clean     既存のコンテナを削除して新規作成
--remove    既存のコンテナを削除して終了
--status    コンテナの状態を表示
-h, --help  このヘルプを表示

[例]
./sandbox.sh              既存コンテナに接続（なければ新規作成）
./sandbox.sh --clean      既存コンテナを削除して新規作成
./sandbox.sh --remove     既存コンテナを削除
./sandbox.sh --status     コンテナの状態を確認"
}

is_running() {
  local id="$1"
  [ -n "$(docker ps -q --filter "id=$id" 2>/dev/null)" ]
}

id() {
  docker ps -aq --filter "name=$CONTAINER_NAME" 2>/dev/null | head -n1
}

status() {
  local id
  id=$(id)

  if [ -n "$id" ]; then
    echo "┌──────────────────────────────────────────────────────────────"
    echo "│ Container Name: $CONTAINER_NAME"
    echo "│ Container ID: ${id:0:12}"

    if is_running "$id"; then
      echo "│ Status: Running ✅"
    else
      echo "│ Status: Stopped ⏸️"
    fi

    echo "│ Access: docker exec -it ${id:0:12} bash"
    echo "└──────────────────────────────────────────────────────────────"
  else
    log "No sandbox container exists"
    log "Run './sandbox.sh' to create one"
  fi
}

remove() {
  local id
  id=$(id)

  if [ -n "$id" ]; then
    log "Removing existing container (ID: ${id:0:12})..."
    docker stop "$id" >/dev/null 2>&1 || true
    docker rm "$id" >/dev/null 2>&1 || true
    success "Existing container removed"
  else
    log "No existing container found"
  fi
}

create() {
  log "Building Docker image for sandbox..."
  if ! docker build -f Dockerfile.sandbox -t dotfiles-sandbox .; then
    error "Failed to build Docker image"
    exit 1
  fi
  success "Docker image build completed"

  log "Starting new sandbox container..."
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    --label dotfiles-sandbox \
    -v "$(pwd):/home/sandbox/workspaces/github.com/sandbox/playgrounds.dotfiles" \
    --workdir /home/sandbox \
    dotfiles-sandbox \
    sleep 604800) # 7 days

  if [ -z "$CONTAINER_ID" ]; then
    error "Failed to start container"
    exit 1
  fi

  success "Sandbox container created (ID: ${CONTAINER_ID:0:12})"

  sleep 3

  log "Running setup.sh..."

  if timeout 2400 docker exec "$CONTAINER_ID" bash -c "cd workspaces/github.com/sandbox/playgrounds.dotfiles && ./setup.sh" 2>&1; then
    success "✅ setup.sh completed"
  else
    local setup_exit_code=$?
    if [ $setup_exit_code -eq 124 ]; then
      error "Timeout (40 minutes)"
    else
      error "Execution error (exit code: $setup_exit_code)"
    fi
    log "Starting debug shell in container..."
  fi
}

attach() {
  local id="$1"

  if ! is_running "$id"; then
    log "Starting stopped container..."
    docker start "$id" >/dev/null 2>&1
    sleep 1
  fi

  success "Attaching to container (ID: ${id:0:12})"
  echo "┌──────────────────────────────────────────────────────────────"
  echo "│ Tip: Type 'fish' to start Fish shell"
  echo "│ Tip: Type 'exit' to leave (container will keep running)"
  echo "│ Tip: Run './sync.sh' to apply dotfiles changes"
  echo "└──────────────────────────────────────────────────────────────"

  docker exec -it "$id" bash
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --clean)
      remove
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
      sandbox_help
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      sandbox_help
      exit 1
      ;;
    esac
  done

  success "🏖️ sandbox.sh"

  if ! command -v docker >/dev/null 2>&1; then
    error "Docker not found. Please install Docker."
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker."
    exit 1
  fi

  local id
  id=$(id)

  if [ -n "$id" ]; then
    success "Found existing container (ID: ${id:0:12})"
    CONTAINER_ID="$id"
    attach "$id"
  else
    create
    attach "$CONTAINER_ID"
  fi

  echo
  warn "Container is still running in background"
  warn "  Access again: docker exec -it ${CONTAINER_ID:0:12} bash"
  warn "  Check status: ./sandbox.sh --status"
  warn "  Remove: ./sandbox.sh --remove"
}

main "$@"
