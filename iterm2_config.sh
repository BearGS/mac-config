#!/bin/zsh

# iTerm2 配置脚本
# 支持 macOS (Intel & Apple Silicon)

set -e

echo_info "========== 配置 iTerm2 =========="

# 1. 安装 Homebrew (如果没有)
if ! command -v brew &> /dev/null; then
    echo_info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. 安装 iTerm2 (如果没有)
if [[ ! -d "/Applications/iTerm.app" ]]; then
    echo_info "安装 iTerm2..."
    brew install --cask iterm2
else
    echo_info "iTerm2 已安装"
fi

# 3. 设置 iTerm2 为默认终端
echo_info "设置 iTerm2 为默认终端..."
if command -v duti &> /dev/null; then
    duti -s com.googlecode.iterm2 public.shell-script all 2>/dev/null || true
fi

# 4. 安装 Shell Integration
ITERM2_SHELL="$HOME/.iterm2_shell_integration.zsh"
if [[ ! -f "$ITERM2_SHELL" ]]; then
    echo_info "安装 iTerm2 Shell Integration..."
    curl -L https://iterm2.com/shell_integration/install_shell_integration.zsh 2>/dev/null | zsh
else
    echo_info "Shell Integration 已存在"
fi

# 5. 安装 iTerm2 Utilities
ITERM2_DIR="$HOME/.iterm2"
mkdir -p "$ITERM2_DIR"

echo_info "安装 iTerm2 Utilities..."
for util in imgcat imgls it2check it2copy it2setcolor it2setkeylabel it2getvar; do
    if [[ ! -f "$ITERM2_DIR/$util" ]]; then
        curl -L "https://iterm2.com/utilities/$util" -o "$ITERM2_DIR/$util" 2>/dev/null
        chmod +x "$ITERM2_DIR/$util"
    fi
done

# 6. 配置默认设置
echo_info "配置 iTerm2 偏好设置..."

# 禁用自动更新检查
defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool false

# 禁用发送 profile 信息
defaults write com.googlecode.iterm2 SUSendProfileInfo -bool false

# 禁用滚动动画
defaults write com.googlecode.iterm2 NSScrollAnimationEnabled -bool false

# 抗锯齿阈值
defaults write com.googlecode.iterm2 AppleAntiAliasingThreshold -int 4

# 移除更新提示
defaults write com.googlecode.iterm2 "NoSyncNextAnnoyanceTime" -int $(date +%s)

# 刷新偏好设置
killall cfprefsd 2>/dev/null || true

echo_info "========== iTerm2 配置完成 =========="
echo_info "请重启 iTerm2 使配置生效"
