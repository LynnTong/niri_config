#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.config/niri/config.kdl"

LINE='// Include user files
include "user/user.kdl"'

if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在，创建新文件：$CONFIG_FILE"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
fi

if grep -Eq '^[[:space:]]*include[[:space:]]+"user/user\.kdl"[[:space:]]*$' "$CONFIG_FILE"; then
    echo "include 已经存在，跳过追加"
else
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d_%H%M%S)"
    printf '\n%s\n' "$LINE" >> "$CONFIG_FILE"
    echo "已追加 include 到 $CONFIG_FILE"
fi

HOOK_SRC="$SCRIPT_DIR/updateKDEcache.hook"
HOOK_DEST="/etc/pacman.d/hooks"

if [ -f "$HOOK_SRC" ]; then
    echo "将 hook 文件复制到 $HOOK_DEST，需要 sudo"
    sudo mkdir -p "$HOOK_DEST"
    sudo cp "$HOOK_SRC" "$HOOK_DEST/updateKDEcache.hook"
    echo "hook 复制完成"
else
    echo "错误：源文件不存在 $HOOK_SRC"
fi

USER_SRC="$SCRIPT_DIR/niri/user/user.kdl"
USER_DEST_DIR="$HOME/.config/niri/user"

if [ -f "$USER_SRC" ]; then
    mkdir -p "$USER_DEST_DIR"
    cp "$USER_SRC" "$USER_DEST_DIR/"
    echo "已将 $USER_SRC 拷贝到 $USER_DEST_DIR/"
else
    echo "警告：源 user.kdl 文件不存在 $USER_SRC"
fi
