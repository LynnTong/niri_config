#!/usr/bin/env bash
set -e

echo "安装yazi"
paru yazi

echo "添加插件"
ya pkg add yazi-rs/plugins:smart-enter

echo "配置复原"
cp yazi/yazi.toml ~/.config/yazi
cp yazi/keymap.toml ~/.config/yazi
