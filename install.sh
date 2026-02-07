#!/bin/zsh

# Mac 开发环境一键安装脚本
# 支持 macOS (Intel & Apple Silicon)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测架构
ARCH=$([[ $(uname -m) == 'arm64' ]] && echo "arm64" || echo "x86_64")
echo_info "检测到架构: $ARCH"

# ========== 1. 安装 Homebrew ==========
echo_info "========== 1/7 安装 Homebrew =========="
if ! command -v brew &> /dev/null; then
    echo_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$ARCH" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo_info "Homebrew 已安装"
fi
eval "$(brew shellenv)"

# ========== 2. 安装 Homebrew 包 ==========
echo_info "========== 2/7 安装 Homebrew 包 =========="

BREW_PACKAGES=(
    "zsh"
    "zsh-syntax-highlighting"
    "ranger"
    "autojump"
    "neovim"
    "zplug"
    "fzf"
    "eza"
    "bat"
    "fd"
    "ripgrep"
    "tmux"
    "the_silver_searcher"
    "duti"
    "iterm2"
    "warp"
)

for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &> /dev/null 2>/dev/null; then
        echo_info "$pkg 已安装"
    else
        echo_info "正在安装 $pkg..."
        brew install "$pkg" 2>/dev/null || brew install --cask "$pkg" 2>/dev/null || true
    fi
done

# ========== 3. 安装 nvm 和 Node ==========
echo_info "========== 3/7 安装 nvm =========="
if [[ ! -d "$HOME/.nvm" ]]; then
    echo_info "正在安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
    echo_info "nvm 已安装"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! nvm ls &> /dev/null; then
    echo_info "正在安装 Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
fi

# ========== 4. 配置 Zprezto ==========
echo_info "========== 4/7 配置 Zprezto =========="
ZPREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
if [[ ! -d "$ZPREZTO_DIR" ]]; then
    echo_info "正在克隆 Zprezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTO_DIR"
fi

setopt EXTENDED_GLOB
for rcfile in "$ZPREZTO_DIR"/runcoms/^README.md(.N); do
    target="$HOME/.${rcfile:t}"
    [[ -f "$target" ]] && cp "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null
    [[ -L "$target" ]] && rm "$target"
    ln -sf "$rcfile" "$target"
done

# ========== 5. 配置 iTerm2 ==========
echo_info "========== 5/7 配置 iTerm2 =========="
if [[ -d "/Applications/iTerm.app" ]]; then
    # 设置为默认终端
    duti -s com.googlecode.iterm2 public.shell-script all 2>/dev/null || true

    # 安装 Shell Integration
    ITERM2_SHELL="$HOME/.iterm2_shell_integration.zsh"
    if [[ ! -f "$ITERM2_SHELL" ]]; then
        echo_info "安装 iTerm2 Shell Integration..."
        curl -L https://iterm2.com/shell_integration/install_shell_integration.zsh 2>/dev/null | zsh
    fi

    # 安装 Utilities
    ITERM2_DIR="$HOME/.iterm2"
    mkdir -p "$ITERM2_DIR"
    for util in imgcat imgls it2copy it2setcolor it2getvar; do
        [[ ! -f "$ITERM2_DIR/$util" ]] && curl -L "https://iterm2.com/utilities/$util" -o "$ITERM2_DIR/$util" 2>/dev/null && chmod +x "$ITERM2_DIR/$util"
    done

    # 偏好设置
    defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool false 2>/dev/null || true
    defaults write com.googlecode.iterm2 SUSendProfileInfo -bool false 2>/dev/null || true
    killall cfprefsd 2>/dev/null || true
else
    echo_warn "iTerm2 未安装，跳过配置"
fi

# ========== 6. 配置 Warp ==========
echo_info "========== 6/7 配置 Warp =========="
if [[ -d "/Applications/Warp.app" ]]; then
    WARP_THEMES="$HOME/.warp/themes"
    mkdir -p "$WARP_THEMES"
    cp "$SCRIPT_DIR/warp_theme.yaml" "$WARP_THEMES/one-dark.yaml" 2>/dev/null || true
    echo_info "Warp 主题已安装: one-dark"
    echo_info "请在 Warp Settings > Appearance > Theme 中选择"
else
    echo_warn "Warp 未安装，跳过配置"
fi

# ========== 7. 配置 .zshrc ==========
echo_info "========== 7/7 配置 .zshrc =========="
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
[[ -f "$SCRIPT_DIR/.zshrc" ]] && cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# ========== 安装 zsh-autosuggestions ==========
ZSH_AUTOSUGGESTIONS="$HOME/.zsh/zsh-autosuggestions"
if [[ ! -d "$ZSH_AUTOSUGGESTIONS" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_AUTOSUGGESTIONS"
fi

# ========== 完成 ==========
echo_info "========== 安装完成! =========="
echo_info "请执行: source ~/.zshrc"
echo_info "然后重启终端或打开 iTerm2/Warp"
