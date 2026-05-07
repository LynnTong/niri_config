#!/usr/bin/env bash
set -e

AUR_PACKAGES=(
    netease-cloud-music-web-player
    ttf-ms-fonts
    ttf-wps-fonts
    visual-studio-code-bin
    wps-office-cn
    wps-office-fonts
    wps-office-mime-cn
    wps-office-mui-zh-cn
    # 下面这个包是为了在dolphin创建右键打开快捷方式准备的
    archlinux-xdg-menu
)

if ! command -v paru >/dev/null 2>&1; then
    echo "错误：未找到 paru，请先安装 paru"
    exit 1
fi

echo "准备安装以下 AUR / 第三方包："
printf '  %s\n' "${AUR_PACKAGES[@]}"

paru -S --needed "${AUR_PACKAGES[@]}"

echo "安装完成"
