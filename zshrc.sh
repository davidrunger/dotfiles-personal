#############################
####     Functions
#############################

# print absolute path of a file
abs() { echo $(pwd)/$(ls $@ | sed "s|^\./||") }

# bundle
b() { bundle install }

# build ctags
build_ctags() {
  if [[ $BUILD_CTAGS == 'true' ]]
  then
    echo
    echo 'Building CTags. Thanks for your patience! :)'
    ctags -f .gemtags -R --languages=ruby $(bundle list --paths)
    if [ $? -eq 0 ]
    then
      echo "Great job! You built CTags successfully!"
    else
      echo "There might have been a problem building CTags."
    fi
  fi
}

# create an alias
cheat() { echo "alias $1='$2'" >> ~/.zshrc && source ~/.zshrc }

# copy text to clipboard
cpy() {
  TEXT=$(</dev/stdin)
  echo -n $TEXT | pbcopy
  echo "Text copied to clipboard:\n$TEXT"
}

# git checkout
gco() { git checkout $@ }

# git checkout branch based on current branch
gcob() {
  git checkout -b $@
  gsup
}

# git fetch and checkout specified branch
gfco() {
  git fetch
  git checkout $@
  gsup
}

# git fetch and check out new branch with specified name
gfcob() {
  BRANCH=origin/${2:-master}
  git fetch && git co -b $1 $BRANCH
}

# git fetch from origin and rebase updates from master
gform() {
  git fetch --no-tags --quiet origin && git fetch --no-tags --quiet origin master:master && git rebase origin/master
  gst
}

# find file
ff() { find . -type f -name $1 }

# "git diff date"
# shows the diff in code between the specified date and now
# example usage:
#   gddate 2022-10-01
gddate() { git diff `git rev-list -1 --before=\"$1\" master`..origin/master }

# show git diff in sublime
# ex:
#   gsd ae2b5a9c7c61597e34820694fed4612639274dba
gsd() {
  git show $1 | EXT=diff tosubl
}

# git set upstream
gsup() {
  UPSTREAM_NAME=${${1:-master}//origin\/}
  UPSTREAM=origin/$UPSTREAM_NAME
  git branch --set-upstream-to=$UPSTREAM
  git status -sb
}

# git commit (and write message in editor)
gcom() {
  verify-on-ok-branch
  if [ $? -ne 0 ]
  then
    return 1
  fi

  git commit --verbose
}

# git commit with message written in terminal
gcomm() {
  verify-on-ok-branch
  if [ $? -ne 0 ]
  then
    return 1
  fi

  git commit -m $1
}

# old name for `gpf`
gpfoh() {
  echo "Renamed to gpf"
}

# git push force without running `check-git-push-safety` first
gpfdangerous() {
  git push -fu origin HEAD
}

# git update current commit with all uncommitted changes
gup() {
  if [[ $(git rev-list --right-only --count master...HEAD) -eq 0 ]]
  then
    echo "Not committing because you are not ahead of master."
    return 1
  fi

  git add -A . && \
    git commit --fixup HEAD && \
    GIT_SEQUENCE_EDITOR=: git rebase --interactive --autosquash HEAD~2
}


# git rebase interactive
# Enter the number of commits back that you want to go.
# Ex: `gri 3` to rebase with the most recent 3 commits.
gri() { git rebase -i HEAD~$1 && git status -sb }

# git status
gst() {
  # switch upstream to master to get status relative to that
  git branch -u origin/master > /dev/null 2>&1
  git status -sb
  # switch upstream back to current branch so `gh` can know which PR this branch is for
  git branch -u origin/$(git rev-parse --abbrev-ref HEAD) 1>/dev/null 2>&1
}

# copy my IP address to clipboard
myip() {
  curl -s ifconfig.co -4 | rg '\A\d+\.\d+\.\d+\.\d+\z' | cpy
}

# make directory and cd into it
mcd() { mkdir $1 && cd $1; }

# open rollbar occurrence page using Rollbar error UUID
# Ex: `rb aaaaaaaa-bbbb-cccc-dddd-eeeeffffeeee`
rb() { open "https://rollbar.com/occurrence/uuid/?uuid=$1" }

# "sublime code" (open a GitHub repo in Sublime)
# ex: `sc https://github.com/plashchynski/crono`
sc() {
  cd ~/Downloads
  git clone $1
  repo_name=$(echo $1 | sed -E 's/https\:\/\/github.com\/[^/]*\///')
  subl $repo_name
  cd -
}

# receive input from stdout and open it in sublime
# ex: `git diff | tosubl`
tosubl() {
  TMPDIR=${TMPDIR:-/tmp}  # default to /tmp if TMPDIR isn't set
  DATE="`date +%Y%m%d%H%M%S`"
  EXT=${EXT:-}
  F=$(mktemp $TMPDIR/tosubl-$DATE.$EXT)
  cat >| $F  # use >| instead of > if you set noclobber in bash
  subl $F
  sleep .3  # give subl a little time to open the file
  # rm -f $F  # file will be deleted as soon as subl closes it. actually just leave it so it's easier to close sublime (no confirm dialog asking if we want to save or not.)
}

# open in sublime a file that is in the PATH
wh() { $EDITOR $(which $1) }

# Git stats on who wrote something, from log and blame. Works on a files or directories.
# I believe that this was written by Allan Grant (@allangrant).
whose() {
  echo "# Finding out who wrote $1\n"
  # echo "# git shortlog -n -s -e $1"
  echo "# Commits by author:"
  git shortlog -n -s $1 | cat

  # This only works on a single file:
  # git blame --line-porcelain $1 | sed -n 's/^author //p' | sort | uniq -c | sort -nr

  # This works on a directory as well:
  # echo "\n# git ls-tree -r -z --name-only HEAD -- $1 | xargs -0 -n1 git blame --line-porcelain HEAD | sed -n 's/^author //p' | sort | uniq -c | sort -nr"
  echo "\n# Lines in current version by author:"
  git ls-tree -r -z --name-only HEAD -- $1 | xargs -0 -n1 git blame --line-porcelain HEAD | sed -n 's/^author //p' | sort | uniq -c | sort -nr
}

#############################
####     Config/Path/Etc
#############################
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

# node setup
export NODE_ENV='development'
export NVM_SYMLINK_CURRENT=true # https://stackoverflow.com/a/60063217/4009384
export PATH=$PATH:node_modules/.bin
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export NVM_DIR="/Users/david/.nvm" # must be an absolute path for some reason; can't start with `~/`
# OLD SLOW WAY to load nvm:
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# -----------
# NEW FAST WAY to load nvm lazily! Modified slightly from:
# https://gist.github.com/gfguthrie/9f9e3908745694c81330c01111a9d642
# add our default nvm node (`nvm alias default v10.16.0`) to path without loading nvm
export PATH="$NVM_DIR/versions/node/$(<$NVM_DIR/alias/default)/bin:$PATH"
# alias `nvm` to this one liner lazy load of the normal nvm script
alias nvm="unalias nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm $@"

# load fzf (fuzzy searching)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# less options
export LESS='-Rj6 -X --quit-if-one-screen'
export LESSHISTFILE=- # don't store less search history https://web.archive.org/web/20141129223918/http://linuxcommand.org/man_pages/less1.html

# for SimpleCov::Formatter::Terminal
export SIMPLECOV_WRITE_TARGET_TO_FILE=1

#############################
####     Aliases
#############################
alias all='redis-cli -n 1 FLUSHDB && FORCE_COLOR=1 foreman start -f Procfile.all.dev'
alias bat='bat --paging=never'
alias br='bin/rubocop'
alias build='subl ~/code/dotfiles/personal/bin/sublime-build.sh'
alias chr='open -a Google\ Chrome'
alias cop='bin/rubocop $(git ls-tree -r HEAD --name-only) --force-exclusion --format progress'
alias d='clear'
alias david='cd ~/code/david_runger'
alias dbm='bin/rails db:migrate db:test:prepare'
alias dbr='bin/rails db:rollback db:test:prepare'
alias dl='curl -O'
alias dots='cd ~/code/dotfiles'
alias down='cd ~/Downloads'
alias dspec='DISABLE_SPRING=1 bin/rspec'
alias ffs='RAILS_ENV=test bin/rails spec:fixture_builder:rebuild'
alias fix='git diff --name-only | uniq | xargs $EDITOR'
alias fsk='redis-cli -n 1 FLUSHDB && sk' # `-n 1` because of `config.redis = {db: 1}` in `config/initializers/sidekiq.rb`
alias fx='open -a Firefox\ Developer\ Edition'
alias ga='git add'
alias gaa='git add -p'
alias gb='git branch -vv'
alias gbd='git branch -D'
alias gbdf='git branch -D $(git for-each-ref --format="%(refname:short)" refs/heads | rg -v "^(master|safe|$(git rev-parse --abbrev-ref HEAD))$" | fzf)'
alias gbm='git branch -m'
alias gc='git checkout $(git for-each-ref --format="%(refname:short)" refs/heads | rg -v "^(master|safe|$(git rev-parse --abbrev-ref HEAD))$" | fzf) && gst'
alias gclean='git checkout . && git clean -f'
alias gcoma='git commit --amend -v'
alias gcoom='git checkout origin/master'
alias gcp='git cherry-pick'
alias gcpf='git cherry-pick $(git for-each-ref --format="%(refname:short)" refs/heads | rg -v "^(master|safe|$(git rev-parse --abbrev-ref HEAD))$" | fzf)'
alias gd='git diff --no-prefix'
alias gdc='git diff --no-prefix --cached'
alias gdom='git diff --no-prefix origin/master..HEAD'
alias gemd='cd  ~/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/'
alias gemdg='cd  ~/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/bundler/gems'
alias gfiles='git show --pretty="format:" --name-only | tr "\n" " "'
alias gfilesn='git show --pretty="format:" --name-only'
alias gg='git graph'
alias gig='s ~/.gitignore_global'
alias gl='git diff --stat HEAD^'
alias gmod='subl $(gfiles)'
alias gol='git log --oneline'
alias gpr='git pull --rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grep='grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias gs='git show'
alias gsf='git show $(git for-each-ref --format="%(refname:short)" refs/heads | rg -v "^(master|safe|$(git rev-parse --abbrev-ref HEAD))$" | fzf)'
alias gsl='git show -s --format=%s'
alias gstash='git stash --include-untracked --keep-index'
alias gunstage='git reset HEAD'
alias gunstash='git stash apply'
alias hwm='hpr && wm'
alias iphone='FORCE_COLOR=1 foreman start -f Procfile.iphone.dev'
alias md='mkdir -p'
alias most='redis-cli -n 1 FLUSHDB && FORCE_COLOR=1 foreman start -f Procfile.most.dev'
alias np="rg --files-with-matches 'binding\\.pry' | xargs sed -i '' -e '/binding\\.pry/d'"
alias pspq='psql david_runger_development < personal/sql.sql'
alias rc="DISABLE_SPRING=1 IS_RAILS_CONSOLE=1 bin/rails console"
alias rgs='rg -F --max-columns 1000'
alias rmrf='rm -rf'
alias rr='bin/rails routes'
alias rrp="spring stop && (echo 'trying to kill ...') && (ps -e | egrep 'sidekiq|ruby|spring|puma' | egrep -v 'egrep|Slack|Postman|GitHub|rubocop|wait-for-gh-checks') && (ps -e | egrep 'spring' | egrep -v egrep | awk '{print \$1}' | xargs kill -TERM) && (ps -e | egrep 'ruby' | egrep -v egrep | awk '{print \$1}' | xargs kill -QUIT) && (ps -e | egrep 'puma|sidekiq' | egrep -v 'egrep|Slack|Postman|GitHub|rubocop|wait-for-gh-checks' | awk '{print \$1}' | xargs kill -INT) && (sleep 1) && (echo '\nremaining processes:\n') && (ps -e | egrep 'sidekiq|ruby|spring|puma' | egrep -v 'egrep|Slack|Postman|GitHub|rubocop|wait-for-gh-checks')"
alias rs="bin/rails server"
alias s.='subl && sleep 0.1 && subl .'
alias s='subl && sleep 0.1 && subl'
alias safe='git checkout safe && gform'
alias say='say -v Rishi'
alias sd='subl ~/code/david_runger'
alias sdm='safe; gdm'
alias sha='git log master --format=format:%H | head -n 1 | cut -c1-7 | cpy'
alias sk="bin/sidekiq"
alias sn='subl ~/Sync/notes'
alias ss='bin/spring stop'
alias vds='bin/vite dev'
alias vdsd='bin/vite dev --debug --trace-deprecation'
alias web='FORCE_COLOR=1 foreman start -f Procfile.web.dev'
alias wm='wait-merge'
alias work='cd ~/code'
alias yic='yarn install --check-files'
alias zrc='subl ~/.zshrc'
alias zs='source ~/.zshrc'
