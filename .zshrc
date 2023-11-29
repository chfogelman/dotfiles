alias cfg="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -x "$(which nvim)" ] && alias vim="$(which nvim)"
