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

HOOK_SRC="$SCRIPT_DIR/fcitx-patch-for-wps.hook"
HOOK_DEST="/etc/pacman.d/hooks"

if [ -f "$HOOK_SRC" ]; then
    echo "将 hook 文件复制到 $HOOK_DEST，需要 sudo"
    sudo mkdir -p "$HOOK_DEST"
    sudo cp "$HOOK_SRC" "$HOOK_DEST/fcitx-patch-for-wps.hook"
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

# -------------------------------
# 4. 在 binds.kdl 追加快捷键（如果不存在）
BINDS_FILE="$HOME/.config/niri/dms/binds.kdl"
BINDS_LINE1='    Super+B cooldown-ms=200 { spawn "firefox"; }'
BINDS_LINE2='    Super+E cooldown-ms=100 { spawn "sh" "-c" "dolphin > /dev/null 2>&1 &"; }'

if [ -f "$BINDS_FILE" ]; then
    # 检查两行是否已经存在
    if grep -Fq "$BINDS_LINE1" "$BINDS_FILE" && grep -Fq "$BINDS_LINE2" "$BINDS_FILE"; then
        echo "快捷键已经存在，跳过追加"
    else
        # 在最后一个大括号前插入
        tmp_file="$(mktemp)"
        awk -v line1="$BINDS_LINE1" -v line2="$BINDS_LINE2" '
        {
            if ($0 ~ /^}$/ && !inserted) {
                print line1
                print line2
                inserted=1
            }
            print
        }' "$BINDS_FILE" > "$tmp_file" && mv "$tmp_file" "$BINDS_FILE"
        echo "已在 binds.kdl 追加快捷键"
    fi
else
    echo "警告：binds.kdl 文件不存在 $BINDS_FILE"
fi

# -------------------------------
# 5. 解压 a.zip 到 ~/Downloads
ZIP_SRC="$SCRIPT_DIR/Archive.zip"
ZIP_DEST="$HOME/.local/share/fonts/windows/"

if [ -f "$ZIP_SRC" ]; then
    mkdir -p "$ZIP_DEST"

    if command -v unzip >/dev/null 2>&1; then
        unzip -o "$ZIP_SRC" -d "$ZIP_DEST"
        echo "已将 $ZIP_SRC 解压到 $ZIP_DEST"
    else
        echo "错误：未安装 unzip，请先执行：sudo pacman -S unzip"
    fi
else
    echo "警告：压缩包不存在 $ZIP_SRC"
fi

# -------------------------------
# 6. 写入输入法环境变量到 ~/.config/environment.d/99-local.conf
ENV_DIR="$HOME/.config/environment.d"
ENV_FILE="$ENV_DIR/99-local.conf"

mkdir -p "$ENV_DIR"

cat > "$ENV_FILE" <<'EOF'
QT_IM_MODULE=fcitx
SDL_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
GLFW_IM_MODULE=ibus
QT_IM_MODULES=wayland;fcitx
EOF

echo "已写入输入法环境变量到 $ENV_FILE"
# -----------------------------
# GTK 输入法配置：GTK2 / GTK3 / GTK4
# -----------------------------

GTK2_RC="$HOME/.gtkrc-2.0"
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"

log() {
    printf '[fcitx-config] %s\n' "$*"
}

# GTK2: ~/.gtkrc-2.0
log "配置 GTK2: $GTK2_RC"

touch "$GTK2_RC"

if grep -qE '^[[:space:]]*gtk-im-module[[:space:]]*=' "$GTK2_RC"; then
    sed -i 's|^[[:space:]]*gtk-im-module[[:space:]]*=.*|gtk-im-module="fcitx"|' "$GTK2_RC"
    log "GTK2 已更新 gtk-im-module=fcitx"
else
    echo 'gtk-im-module="fcitx"' >> "$GTK2_RC"
    log "GTK2 已追加 gtk-im-module=fcitx"
fi


# 通用函数：写 GTK3 / GTK4 settings.ini
set_gtk_im_module() {
    local file="$1"
    local name="$2"

    log "配置 $name: $file"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    # 如果文件为空，直接写完整内容
    if [ ! -s "$file" ]; then
        cat > "$file" <<EOF
[Settings]
gtk-im-module=fcitx
EOF
        log "$name 文件为空，已写入 [Settings] 和 gtk-im-module=fcitx"
        return
    fi

    # 如果没有 [Settings]，追加一个
    if ! grep -qE '^[[:space:]]*\[Settings\][[:space:]]*$' "$file"; then
        cat >> "$file" <<EOF

[Settings]
gtk-im-module=fcitx
EOF
        log "$name 未找到 [Settings]，已追加配置段"
        return
    fi

    # 如果已有 gtk-im-module，则替换
    if grep -qE '^[[:space:]]*gtk-im-module[[:space:]]*=' "$file"; then
        sed -i 's|^[[:space:]]*gtk-im-module[[:space:]]*=.*|gtk-im-module=fcitx|' "$file"
        log "$name 已更新 gtk-im-module=fcitx"
    else
        # 在 [Settings] 下一行插入
        sed -i '/^[[:space:]]*\[Settings\][[:space:]]*$/a gtk-im-module=fcitx' "$file"
        log "$name 已在 [Settings] 下插入 gtk-im-module=fcitx"
    fi
}

set_gtk_im_module "$GTK3_SETTINGS" "GTK3"
set_gtk_im_module "$GTK4_SETTINGS" "GTK4"

log "GTK 输入法配置完成"
# -------------------------------
# 8. 拷贝脚本目录下 wallpapers 里的所有图片到 ~/Pictures/Wallpapers
WALLPAPER_SRC_DIR="$SCRIPT_DIR/Wallpapers"
WALLPAPER_DEST_DIR="$HOME/Pictures/Wallpapers"

if [ -d "$WALLPAPER_SRC_DIR" ]; then
    mkdir -p "$WALLPAPER_DEST_DIR"

    find "$WALLPAPER_SRC_DIR" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) \
        -exec cp -n {} "$WALLPAPER_DEST_DIR/" \;

    echo "已将 $WALLPAPER_SRC_DIR 下的图片拷贝到 $WALLPAPER_DEST_DIR"
else
    echo "警告：壁纸目录不存在 $WALLPAPER_SRC_DIR"
fi
