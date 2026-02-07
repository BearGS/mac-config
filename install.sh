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

# 检测架构
ARCH=$([[ $(uname -m) == 'arm64' ]] && echo "arm64" || echo "x86_64")
BREW_PREFIX=$([[ $(uname -m) == 'arm64' ]] && echo "/opt/homebrew" || echo "/usr/local")

# 检查是否在 Rosetta 下运行
if [[ "$ARCH" == "x86_64" ]] && [[ -d "/opt/homebrew" ]]; then
    echo_warn "检测到 Rosetta 2 模式，将使用 arch -arm64 安装"
    USE_ROSETTA=true
else
    USE_ROSETTA=false
fi

echo_info "检测到架构: $ARCH"

# ========== 1. 安装 Homebrew ==========
echo_info "========== 1/8 安装 Homebrew =========="
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
echo_info "========== 2/8 安装 Homebrew 包 =========="

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
)

# Cask 包
CASKS=("iterm2" "warp" "docker-desktop")

# Docker Compose 作为 formula 安装
echo_info "安装 docker-compose..."
if ! command -v docker-compose &> /dev/null; then
    brew install docker-compose
else
    echo_info "docker-compose 已安装"
fi

for pkg in "${BREW_PACKAGES[@]}"; do
    if ! brew list "$pkg" &> /dev/null 2>&1; then
        echo_info "安装 $pkg..."
        if [[ "$USE_ROSETTA" == "true" ]]; then
            arch -arm64 brew install "$pkg"
        else
            brew install "$pkg"
        fi
    else
        echo_info "$pkg 已安装"
    fi
done

for cask in "${CASKS[@]}"; do
    # 检查应用是否存在
    CASKS_INSTALLED=false
    for name in "$cask" "iTerm2" "iTerm" "ITerm2"; do
        if [[ -d "/Applications/${name}.app" ]]; then
            CASKS_INSTALLED=true
            break
        fi
    done

    if [[ "$CASKS_INSTALLED" == "true" ]]; then
        echo_info "$cask 已安装"
    else
        echo_info "安装 $cask..."
        if [[ "$USE_ROSETTA" == "true" ]]; then
            arch -arm64 brew install --cask "$cask" 2>&1 || echo_warn "$cask 安装失败，请手动安装"
        else
            brew install --cask "$cask" 2>&1 || echo_warn "$cask 安装失败，请手动安装"
        fi
    fi
done

# ========== 3. 安装 nvm 和 Node ==========
echo_info "========== 3/8 安装 nvm =========="
export NVM_DIR="$HOME/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
    echo_info "正在安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | zsh
fi

# 加载 nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装 Node LTS
if command -v nvm &> /dev/null; then
    if ! nvm ls &> /dev/null; then
        echo_info "正在安装 Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
    else
        echo_info "Node.js 已安装"
    fi
else
    echo_warn "nvm 安装失败，请手动安装 Node.js"
fi

# ========== 4. 配置 Zprezto ==========
echo_info "========== 4/8 配置 Zprezto =========="
ZPREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
if [[ ! -d "$ZPREZTO_DIR" ]]; then
    echo_info "正在克隆 Zprezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTO_DIR"
else
    echo_info "Zprezto 已存在"
fi

setopt EXTENDED_GLOB
for rcfile in "$ZPREZTO_DIR"/runcoms/^README.md(.N); do
    target="$HOME/.${rcfile:t}"
    [[ -f "$target" ]] && cp "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null
    [[ -L "$target" ]] && rm "$target" 2>/dev/null
    ln -sf "$rcfile" "$target" 2>/dev/null || echo_warn "无法创建链接: $target"
done

# ========== 5. 配置 iTerm2 ==========
echo_info "========== 5/8 配置 iTerm2 =========="
# 检查 iTerm2 是否安装
ITERM2_INSTALLED=false
for name in "iTerm2" "iTerm" "iterm2"; do
    if [[ -d "/Applications/${name}.app" ]]; then
        ITERM2_INSTALLED=true
        break
    fi
done

if [[ "$ITERM2_INSTALLED" == "true" ]]; then
    # 设置为默认终端
    duti -s com.googlecode.iterm2 public.shell-script all 2>/dev/null || true

    # 安装 Shell Integration
    ITERM2_SHELL="$HOME/.iterm2_shell_integration.zsh"
    if [[ ! -f "$ITERM2_SHELL" ]]; then
        echo_info "安装 iTerm2 Shell Integration..."
        curl -L --max-time 10 "https://iterm2.com/shell_integration/install_shell_integration.zsh" -o /tmp/iterm2_shell.zsh 2>/dev/null
        if [[ -s /tmp/iterm2_shell.zsh ]] && head -1 /tmp/iterm2_shell.zsh | grep -q "^#!/"; then
            zsh /tmp/iterm2_shell.zsh
        else
            echo_warn "iTerm2 Shell Integration 下载失败，跳过"
        fi
        rm -f /tmp/iterm2_shell.zsh
    fi

    # 安装 Utilities
    ITERM2_DIR="$HOME/.iterm2"
    mkdir -p "$ITERM2_DIR"
    for util in imgcat imgls it2copy it2setcolor it2getvar it2setkeylabel; do
        if [[ ! -f "$ITERM2_DIR/$util" ]]; then
            curl -L --max-time 10 "https://iterm2.com/utilities/$util" -o "$ITERM2_DIR/$util" 2>/dev/null
            if [[ -s "$ITERM2_DIR/$util" ]] && head -1 "$ITERM2_DIR/$util" | grep -q "^#!"; then
                chmod +x "$ITERM2_DIR/$util"
            else
                rm -f "$ITERM2_DIR/$util"
            fi
        fi
    done

    # 导入配置 plist
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
    PLIST_FILE="$SCRIPT_DIR/iterm2_com.apple.googlecode.iterm2.plist"
    if [[ -f "$PLIST_FILE" ]]; then
        echo_info "导入 iTerm2 配置..."
        [[ -f "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]] && cp "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist.bak"
        /usr/bin/defaults import com.googlecode.iterm2 "$PLIST_FILE" 2>/dev/null || echo_warn "iTerm2 配置导入失败"
        killall cfprefsd 2>/dev/null || true
        echo_info "iTerm2 配置已导入"
    else
        echo_warn "iTerm2 配置文件不存在"
    fi
else
    echo_warn "iTerm2 未安装，跳过配置"
fi

# ========== 6. 配置 Warp ==========
echo_info "========== 6/8 配置 Warp =========="
if [[ -d "/Applications/Warp.app" ]]; then
    WARP_THEMES="$HOME/.warp/themes"
    mkdir -p "$WARP_THEMES"
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
    [[ -f "$SCRIPT_DIR/warp_theme.yaml" ]] && cp "$SCRIPT_DIR/warp_theme.yaml" "$WARP_THEMES/one-dark.yaml" 2>/dev/null || true
    echo_warn "请在 Warp Settings > Appearance > Theme 中选择 one-dark"
fi

# ========== 7. 配置 .zshrc ==========
echo_info "========== 7/8 配置 .zshrc =========="
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
[[ -f "$SCRIPT_DIR/.zshrc" ]] && cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# ========== 8. 安装 zsh-autosuggestions ==========
echo_info "========== 8/8 安装 zsh 插件 =========="
ZSH_AUTOSUGGESTIONS="$HOME/.zsh/zsh-autosuggestions"
if [[ ! -d "$ZSH_AUTOSUGGESTIONS" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_AUTOSUGGESTIONS"
fi

# ========== 完成 ==========
echo_info "========== 安装完成! =========="
echo_info "请执行: source ~/.zshrc"
echo ""
echo_warn "Docker 启动方法:"
echo "  open /Applications/Docker.app"
echo "  或在 Applications 文件夹双击 Docker"
echo ""
echo_warn "注意:"
echo "  - 重启 iTerm2 使配置生效"
