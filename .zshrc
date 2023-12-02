alias cfg="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -x "$(which nvim)" ] && alias vim="$(which nvim)"

function git_branch_name() {
    echo "$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /')"
}

setopt prompt_subst
export PS1='%n@%m:%~ $(git_branch_name)%# '
