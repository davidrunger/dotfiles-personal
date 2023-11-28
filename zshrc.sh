. ~/code/dotfiles-personal/shell/aliases.sh

# path setup
export PATH="$HOME/code/dotfiles-personal/bin:$PATH"

export NOTES_DIRECTORY="$HOME/Sync/notes"

export NVM_DIR="/Users/david/.nvm" # must be an absolute path for some reason; can't start with `~/`
# Load nvm lazily! Modified slightly from:
# add our default nvm node (`nvm alias default v10.16.0`) to path without loading nvm
# alias `nvm` to this one liner lazy load of the normal nvm script
alias nvm="unalias nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm $@"
