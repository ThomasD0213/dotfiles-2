export ZSH="$HOME/.config/oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Aliases
alias vim="nvim"

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Start tmux on shell launch
if [ -z "$TMUX" ]; then
    tmux
else
    fortune -s | cowsay -r
fi
