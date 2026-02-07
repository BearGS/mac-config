#!/bin/zsh

# Warp 终端配置脚本
# 支持 macOS (Intel & Apple Silicon)

set -e

echo_info "========== 配置 Warp =========="

# 1. 检查 Homebrew
if ! command -v brew &> /dev/null; then
    echo_info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi. 安装 Warp

# 2 (如果没有)
if [[ ! -d "/Applications/Warp.app" ]]; then
    echo_info "安装 Warp..."
    brew install --cask warp
else
    echo_info "Warp 已安装"
fi

# 3. 配置主题
WARP_THEMES_DIR="$HOME/.warp/themes"
mkdir -p "$WARP_THEMES_DIR"

# 复制主题文件
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
THEME_SOURCE="$SCRIPT_DIR/warp_theme.yaml"
THEME_TARGET="$WARP_THEMES_DIR/one-dark.yaml"

if [[ -f "$THEME_SOURCE" ]]; then
    cp "$THEME_SOURCE" "$THEME_TARGET"
    echo_info "主题已安装: $THEME_TARGET"
    echo_info "请在 Warp Settings > Appearance > Theme 中选择 'one-dark'"
else
    echo_warn "主题文件不存在: $THEME_SOURCE"
fi

# 4. Warp 配置文件 (基础设置)
WARP_SETTINGS="$HOME/.warp/settings.json"
mkdir -p "$(dirname "$WARP_SETTINGS")"

# 创建基础配置
cat > "$WARP_SETTINGS" << 'EOF'
{
  "theme": "one-dark",
  "use_system_theme": false,
  "show_sidebar": true,
  "command_hover_hint": true,
  "completion": true,
  "suggestions": true
}
EOF

echo_info "========== Warp 配置完成 =========="
echo_info "请重启 Warp 使配置生效"
echo_info "主题设置: Warp Settings > Appearance > Theme > one-dark"
