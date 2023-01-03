. ~/code/dotfiles/shell/aliases.sh
. ~/code/dotfiles/shell/functions.sh

setopt +o nomatch # https://unix.stackexchange.com/a/310553/276727
export EDITOR='subl'
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="bolso"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=black" # this "black" actually comes out gray
plugins=(zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
# git-extras completions
source /usr/local/opt/git-extras/share/git-extras/git-extras-completion.zsh

# path setup
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/git/bin"
export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
export PATH=$HOME/bin:$HOME/code/dotfiles/bin:$HOME/Sync/bin:$PATH

# ruby setup
export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"

# python setup
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
export PYTHONPATH='/Users/david/lib/python'

# go setup
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# rust setup
source "$HOME/.cargo/env"

# node setup
export NODE_ENV='development'
export NVM_SYMLINK_CURRENT=true # https://stackoverflow.com/a/60063217/4009384
export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export NVM_DIR="/Users/david/.nvm" # must be an absolute path for some reason; can't start with `~/`
# Load nvm lazily! Modified slightly from:
# https://gist.github.com/gfguthrie/9f9e3908745694c81330c01111a9d642
# add our default nvm node (`nvm alias default v10.16.0`) to path without loading nvm
export PATH="$NVM_DIR/versions/node/$(<$NVM_DIR/alias/default)/bin:$PATH"
# alias `nvm` to this one liner lazy load of the normal nvm script
alias nvm="unalias nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm $@"
export PATH=node_modules/.bin:$PATH

# load fzf (fuzzy searching)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# less options
export LESS='-Rj6 -X --quit-if-one-screen'
export LESSHISTFILE=- # don't store less search history https://web.archive.org/web/20141129223918/http://linuxcommand.org/man_pages/less1.html

# for SimpleCov::Formatter::Terminal
export SIMPLECOV_WRITE_TARGET_TO_FILE=1
