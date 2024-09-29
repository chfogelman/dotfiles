# Migration:

```bash
alias cfg='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME' && \
git clone --bare git@github.com:chfogelman/dotfiles.git $HOME/.dotfiles && \
cfg config --local status.showUntrackedFiles no
```

## Back up files:

```bash
mkdir -p .config-backup && \
cfg checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

## Check out configuration:

```bash
cfg checkout && \
echo "[ -f ~/.config/bashrc_extra ] && source ~/.config/bashrc_extra" >> .bashrc && \
echo "[ -f ~/.config/zshrc_extra ] && source ~/.config/zshrc_extra" >> .zshrc
```
