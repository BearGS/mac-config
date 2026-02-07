#!/bin/zsh

# Mac Studio 开发环境一键安装脚本
# 支持 macOS (Intel & Apple Silicon)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测架构
detect_arch() {
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "arm64"
    else
        echo "x86_64"
    fi
}

ARCH=$(detect_arch)
echo_info "检测到架构: $ARCH"

# 检测 Homebrew 是否已安装
check_brew() {
    if command -v brew &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 检测 Zsh 是否已安装
check_zsh() {
    if command -v zsh &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 备份现有配置文件
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        echo_info "已备份: $file -> $backup"
    fi
}

# ========== 1. 安装 Homebrew ==========
echo_info "========== 1/6 安装 Homebrew =========="
if check_brew; then
    echo_info "Homebrew 已安装"
else
    echo_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon 需要添加到 PATH
    if [[ "$ARCH" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# 临时启用 brew
eval "$(brew shellenv)"

# ========== 2. 安装 Zsh ==========
echo_info "========== 2/6 安装 Zsh =========="
if check_zsh; then
    echo_info "Zsh 已安装: $(zsh --version)"
else
    brew install zsh
fi

# 设为默认 shell
if [[ "$SHELL" != "/bin/zsh" ]] && [[ "$SHELL" != "/usr/local/bin/zsh" ]]; then
    echo_info "正在设置 Zsh 为默认 shell..."
    if sudo chsh -s /bin/zsh "$USER" 2>/dev/null; then
        echo_info "已设置 Zsh 为默认 shell (需要重启终端生效)"
    else
        echo_warn "无法自动设置默认 shell，请手动执行: sudo chsh -s /bin/zsh"
    fi
fi

# ========== 3. 安装 nvm 和 Node ==========
echo_info "========== 3/6 安装 nvm =========="
if [[ ! -d "$HOME/.nvm" ]]; then
    echo_info "正在安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
    echo_info "nvm 已安装"
fi

# 加载 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装 Node LTS
if ! nvm ls &> /dev/null; then
    echo_info "正在安装 Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
fi

# ========== 4. 安装 Homebrew 包 ==========
echo_info "========== 4/6 安装 Homebrew 包 =========="

BREW_PACKAGES=(
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
)

for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &> /dev/null; then
        echo_info "$pkg 已安装"
    else
        echo_info "正在安装 $pkg..."
        brew install "$pkg"
    fi
done

# ========== 5. 配置 Zprezto ==========
echo_info "========== 5/6 配置 Zprezto =========="

ZPREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
if [[ ! -d "$ZPREZTO_DIR" ]]; then
    echo_info "正在克隆 Zprezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTO_DIR"
else
    echo_info "Zprezto 已存在"
fi

# 备份并创建配置链接
echo_info "正在配置 Zprezto..."
setopt EXTENDED_GLOB
for rcfile in "$ZPREZTO_DIR"/runcoms/^README.md(.N); do
    target="$HOME/.${rcfile:t}"
    backup_file "$target"
    if [[ -L "$target" ]]; then
        rm "$target"
    fi
    ln -sf "$rcfile" "$target"
    echo_info "已创建链接: $target -> $rcfile"
done

# ========== 6. 配置 .zshrc ==========
echo_info "========== 6/6 配置 .zshrc =========="

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ZSHRC_SOURCE="$SCRIPT_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

if [[ -f "$ZSHRC_SOURCE" ]]; then
    backup_file "$ZSHRC_TARGET"
    cp "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
    echo_info "已复制 .zshrc"
else
    echo_warn "未找到 .zshrc 模板文件: $ZSHRC_SOURCE"
fi

# ========== 安装 zsh-autosuggestions ==========
echo_info "========== 安装 zsh-autosuggestions =========="

ZSH_AUTOSUGGESTIONS="$HOME/.zsh/zsh-autosuggestions"
if [[ ! -d "$ZSH_AUTOSUGGESTIONS" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_AUTOSUGGESTIONS"
    echo_info "已安装 zsh-autosuggestions"
else
    echo_info "zsh-autosuggestions 已存在"
fi

# ========== 完成 ==========
echo_info "========== 安装完成! =========="
echo_info "请执行: source ~/.zshrc"
echo_info "或者重启终端"
