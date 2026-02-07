# Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export EDITOR=vim
export VISUAL="$EDITOR"
export HISTSIZE=1000
export HISTFILESIZE=10000

# Homebrew 路径兼容 (Intel / Apple Silicon)
if [[ $(uname -m) == 'arm64' ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# Source Homebrew 安装的 zsh 插件
if [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ -f "$BREW_PREFIX/share/autojump/autojump.zsh" ]]; then
  source "$BREW_PREFIX/share/autojump/autojump.zsh"
fi

# Zplug Configuration
export ZPLUG_HOME="$BREW_PREFIX/opt/zplug"
if [[ -s "$ZPLUG_HOME/init.zsh" ]]; then
  source "$ZPLUG_HOME/init.zsh"
fi

# Nvm Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Zplug Plugins
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-history-substring-search"
zplug "junegunn/fzf", from:gh, as:command, use:"bin/fzf"
zplug "Aloxaf/fzf-tab"

# 只有 fasd 可用时才添加
if zplug check clvv/fasd 2>/dev/null; then
  zplug "clvv/fasd"
fi

# 加载插件
if ! zplug check; then
  zplug install
fi
zplug load

# Homebrew
export HOMEBREW_NO_AUTO_UPDATE=true

# Tab Completion (放在插件加载之后)
autoload -U compinit
compinit

# Aliases
alias e="vim"
alias gcm="git checkout master"
alias gcd="git checkout develop"
alias gst="git status"
alias f='ranger'
alias -g ...='../..'
alias -g ....='../../..'
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

# Navigation
setopt autocd autopushd
d='dirs -v | head -10'
1='cd -'
2='cd -2'
3='cd -3'
4='cd -4'
5='cd -5'
6='cd -6'
7='cd -7'
8='cd -8'
9='cd -9'

# UI Settings
DISABLE_LS_COLORS="true"

precmd() {
  echo -ne "\e]1;${PWD##*/}\a"
}
