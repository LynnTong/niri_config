#!/usr/bin/env bash
set -e

AUR_PACKAGES=(
    #中文输入法
    #请在kde设置里将virtual keyboard设置为fcitx5
    fcitx5
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-qt
    fcitx5-rime
    #微信
    wechat-bin
    #钉钉
    dingtalk-bin
    #网易云音乐
    netease-cloud-music-web-player
    #vscode
    visual-studio-code-bin
    #wps
    wps-office-cn
    wps-office-fonts
    wps-office-mime-cn
    wps-office-mui-zh-cn
    ttf-ms-fonts
    ttf-wps-fonts
    #svn
    kdesvn
    #挂载smb网盘
    smb4k
    #pdf阅读器
    okular
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
echo "可能需要对wps指定QT_FONT_DPI=96/144/192来获得1/1.5/2倍缩放"

echo "设置串口权限"
sudo usermod -aG uucp,lock $USER
echo "串口权限设置完成"
