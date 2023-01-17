alias all='redis-cli -n 1 FLUSHDB && FORCE_COLOR=1 foreman start -f Procfile.all.dev'
alias bat='bat --paging=never'
alias br='bin/rubocop'
alias bs='bin/rspec'
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
alias es='exercism submit'
alias favi='cp /Users/david/code/david_runger/public/favicon.ico ./'
alias ffs='RAILS_ENV=test bin/rails spec:fixture_builder:rebuild'
alias fix='git diff --name-only | uniq | xargs $EDITOR'
alias fsk='redis-cli -n 1 FLUSHDB && sk' # `-n 1` because of `config.redis = {db: 1}` in `config/initializers/sidekiq.rb`
alias fx='open -a Firefox\ Developer\ Edition'
alias ga='git add'
alias gaa='git add -p'
alias gac='ga . && gcom'
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
alias gcu='git add . && git commit -m "Update"'
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
alias gpwm='gpf && wm'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grep='grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias gs='git show'
alias gsf='git show $(git for-each-ref --format="%(refname:short)" refs/heads | rg -v "^(master|safe|$(git rev-parse --abbrev-ref HEAD))$" | fzf)'
alias gsl='git show -s --format=%s'
alias gstash='git stash --include-untracked --keep-index'
alias gunstage='git reset HEAD'
alias gunstash='git stash apply'
alias hwm='hpr && echo && wm'
alias iphone='FORCE_COLOR=1 foreman start -f Procfile.iphone.dev'
alias md='mkdir -p'
alias most='redis-cli -n 1 FLUSHDB && FORCE_COLOR=1 foreman start -f Procfile.most.dev'
alias np="rg --files-with-matches 'binding\\.pry' | xargs sed -i '' -e '/binding\\.pry/d'"
alias pspq='psql david_runger_development < personal/sql.sql'
alias rc="DISABLE_SPRING=1 IS_RAILS_CONSOLE=1 bin/rails console"
alias rgs='rg -F --max-columns 1000'
alias rmrf='rm -rf'
alias rmsi='rm -rf lib/ && shards install'
alias rr='bin/rails routes'
alias rs="bin/rails server"
alias s.='subl && sleep 0.1 && subl .'
alias s='subl && sleep 0.1 && subl'
alias safe='git checkout safe && gform'
alias say='say -v Rishi'
alias sb='subl ~/code/dotfiles/personal/bin/sublime-build.sh'
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
alias yic='yarn install --check-files --ignore-optional'
alias zrc='subl ~/.zshrc'
alias zs='source ~/.zshrc'
