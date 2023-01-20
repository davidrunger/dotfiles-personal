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
cheat() { echo "alias $1='$2'" >> ~/code/dotfiles/shell/aliases.sh && source ~/.zshrc }

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
  git show $1 | EXT=diff tos
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

# git update current commit with all uncommitted changes (after checking we're ahead of master)
gup() {
  if [[ $(git rev-list --right-only --count master...HEAD) -eq 0 ]]
  then
    echo "Not committing because you are not ahead of master."
    return 1
  fi

  git add -A . && git commit --amend --no-edit
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

# kill rubocop processes
# (I'm making this an alias so I don't have to deal with escaping the single quotes)
kr() {
  ps -e | egrep rubocop | egrep -v e?grep | awk '{print $1}' | xargs kill
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
# ex: `git diff | tos`
tos() {
  TMPDIR=${TMPDIR:-/tmp}  # default to /tmp if TMPDIR isn't set
  DATE="`date +%Y%m%d%H%M%S`"
  EXT=${EXT:-}
  F=$(mktemp $TMPDIR/tos-$DATE.$EXT)
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
