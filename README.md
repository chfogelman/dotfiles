# Migration:

```bash
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME' \
echo ".dotfiles" >> .gitignore \
git clone --bare git@github.com:chfogelman/dotfiles.git $HOME/.dotfiles \
config config --local status.showUntrackedFiles no
```

## Back up files:

```bash
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

## Check out configuration:

```bash
config checkout
```
