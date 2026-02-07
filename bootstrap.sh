#!/bin/zsh

# Mac 开发环境一键配置
# 用法: curl -fsSL https://raw.githubusercontent.com/你的用户名/仓库名/main/bootstrap.sh | zsh

set -e

REPO="BearGS/mac-config"
SCRIPT_DIR="$HOME/.dotfiles"

echo "正在拉取配置..."

# 克隆或更新仓库
if [[ -d "$SCRIPT_DIR/.git" ]]; then
    cd "$SCRIPT_DIR"
    git pull
else
    git clone --depth 1 "https://github.com/$REPO.git" "$SCRIPT_DIR"
fi

# 执行安装脚本
cd "$SCRIPT_DIR"
chmod +x install.sh
./install.sh

echo ""
echo "安装完成! 请执行: source ~/.zshrc"
