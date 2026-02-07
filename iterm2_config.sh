#!/bin/zsh

# iTerm2 完整配置脚本
# 根据用户视觉与性能配置规范

set -e

echo_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
echo_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
THEME_FILE="$SCRIPT_DIR/iterm2_base16_256_dark.itermcolors"

echo_info "========== 配置 iTerm2 =========="

# 1. 检查并安装 iTerm2
if [[ ! -d "/Applications/iTerm.app" ]]; then
    echo_info "安装 iTerm2..."
    brew install --cask iterm2
else
    echo_info "iTerm2 已安装"
fi

# 2. 设置为默认终端
echo_info "设置 iTerm2 为默认终端..."
if command -v duti &> /dev/null; then
    duti -s com.googlecode.iterm2 public.shell-script all 2>/dev/null || true
fi

# 3. 安装 Shell Integration
ITERM2_SHELL="$HOME/.iterm2_shell_integration.zsh"
if [[ ! -f "$ITERM2_SHELL" ]]; then
    echo_info "安装 iTerm2 Shell Integration..."
    curl -L https://iterm2.com/shell_integration/install_shell_integration.zsh 2>/dev/null | zsh
fi

# 4. 安装 Utilities
echo_info "安装 iTerm2 Utilities..."
ITERM2_DIR="$HOME/.iterm2"
mkdir -p "$ITERM2_DIR"
for util in imgcat imgls it2copy it2setcolor it2getvar it2setkeylabel; do
    if [[ ! -f "$ITERM2_DIR/$util" ]]; then
        curl -L "https://iterm2.com/utilities/$util" -o "$ITERM2_DIR/$util" 2>/dev/null
        chmod +x "$ITERM2_DIR/$util"
    fi
done

# 5. 导入配色方案
if [[ -f "$THEME_FILE" ]]; then
    echo_info "导入配色方案..."
    open "$THEME_FILE" 2>/dev/null || true
    echo_warn "请在 iTerm2 > Preferences > Profiles > Colors > Color Presets 中选择 'base16-eighties-256-dark'"
fi

# 6. 配置 Appearance (使用 defaults)
echo_info "配置 Appearance..."

# Theme: Dark (4 = Dark)
defaults write com.googlecode.iterm2 "AppleWindowTabbingMode" -string "manual"

# Tab bar location: Bottom
defaults write com.googlecode.iterm2 "TabViewType" -integer 2

# Status bar location: Bottom
defaults write com.googlecode.iterm2 "StatusBarLocation" -integer 1

# Auto-hide menu bar in non-native fullscreen
defaults write com.googlecode.iterm2 "NSUserInterfaceStyleScaling" -bool true

# 窗口设置 - 取消勾选所有
defaults write com.googlecode.iterm2 "Window NumberingEnabled" -bool false
defaults write com.googlecode.iterm2 "WindowShouldCascade" -bool false
defaults write com.googlecode.iterm2 "HideScrollbar" -bool true
defaults write com.googlecode.iterm2 "HideBorder" -bool true

# Tab 设置
defaults write com.googlecode.iterm2 "ShowTabNumbers" -bool true
defaults write com.googlecode.iterm2 "ShowActivityIndicator" -bool true
defaults write com.googlecode.iterm2 "ShowNewOutputIndicator" -bool true
defaults write com.googlecode.iterm2 "FlashTabBarOnActivity" -bool true
defaults write com.googlecode.iterm2 "ShowTabBarInFullscreen" -bool true

# 取消勾选
defaults write com.googlecode.iterm2 "OnlyShowTabBarWhenThereAreMultipleTabs" -bool false
defaults write com.googlecode.iterm2 "TabShouldClose" -bool false
defaults write com.googlecode.iterm2 "StretchTabsToFillBar" -bool false

# Pane 设置 - 取消所有
defaults write com.googlecode.iterm2 "PaneTitlesEnabled" -bool false
defaults write com.googlecode.iterm2 "PaneStatusBarEnabled" -bool false

# Dimming 设置
defaults write com.googlecode.iterm2 "DimInactiveSplitPanes" -bool true
defaults write com.googlecode.iterm2 "DimBackgroundWindows" -bool true
defaults write com.googlecode.iterm2 "DimmingAffectsOnlyText" -bool true
defaults write com.googlecode.iterm2 "DimmingAmount" -float 0.5

# 7. 配置 Profile (Default)
echo_info "配置 Profile..."

# 创建或更新 plist 配置
PLIST_PATH="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

# 使用 plistbuddy 或直接写入
/usr/bin/defaults write com.googlecode.iterm2 "New Bookmarks" -array-add '
<dict>
    <key>Guid</key>
    <string>Default</string>
    <key>Name</key>
    <string>Default</string>
    <key>Background Color</key>
    <dict>
        <key>Blue Component</key>
        <real>0.16470588235294117</real>
        <key>Green Component</key>
        <real>0.16470588235294117</real>
        <key>Red Component</key>
        <real>0.16470588235294117</real>
    </dict>
    <key>Foreground Color</key>
    <dict>
        <key>Blue Component</key>
        <real>0.84705882352941175</real>
        <key>Green Component</key>
        <real>0.78823529411764703</real>
        <key>Red Component</key>
        <real>0.74901960784313726</real>
    </dict>
    <key>Cursor Color</key>
    <dict>
        <key>Blue Component</key>
        <real>0.84705882352941175</real>
        <key>Green Component</key>
        <real>0.78823529411764703</real>
        <key>Red Component</key>
        <real>0.74901960784313726</real>
    </dict>
    <key>Cursor Type</key>
    <integer>0</integer>
    <key>Blinking Cursor</key>
    <false/>
    <key>Normal Font</key>
    <string>Menlo-Regular 14</string>
    <key>Non-ASCII Font</key>
    <string>Menlo-Regular 14</string>
    <key>Vertical Spacing</key>
    <real>1.0</real>
    <key>Horizontal Spacing</key>
    <real>1.2</real>
    <key>Draw Bold in Bold Font</key>
    <true/>
    <key>Allow Italic</key>
    <true/>
    <key>Anti-Aliasing</key>
    <true/>
    <key>Use Thin Strokes</key>
    <integer>2</integer>
    <key>Brighten Bold Text</key>
    <true/>
    <key>Terminal Type</key>
    <string>xterm-256color</string>
    <key>Scrollback Lines</key>
    <integer>0</integer>
</dict>
'

# 刷新偏好设置
killall cfprefsd 2>/dev/null || true

echo_info "========== iTerm2 配置完成 =========="
echo ""
echo "请手动完成以下步骤:"
echo "1. 打开 iTerm2"
echo "2. ⌘ + , 打开 Preferences"
echo "3. Profiles > Colors > Color Presets > Import 选择 'base16-eighties-256-dark'"
echo "4. 选择 'base16-eighties-256-dark' 作为默认配色"
echo "5. Appearance > Theme 选择 'Dark'"
echo "6. 重启 iTerm2"
