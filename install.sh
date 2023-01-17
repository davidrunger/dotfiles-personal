#!/usr/bin/env bash

ln -sf ~/code/dotfiles/gitignore_global ~/.gitignore_global
ln -sf ~/code/dotfiles/initializers/z.rb ~/code/david_runger/config/initializers/z.rb
ln -sf ~/code/dotfiles/irbrc.rb ~/.irbrc.rb
ln -sf ~/code/dotfiles/pryrc.rb ~/.pryrc
ln -sf ~/code/dotfiles/rspec ~/.rspec
ln -sf ~/code/dotfiles/rubocop.yml ~/.rubocop.yml
ln -sf ~/code/dotfiles/zsh/themes/bolso.zsh-theme ~/.oh-my-zsh/custom/themes/bolso.zsh-theme
ln -sf ~/code/dotfiles/zshrc.sh ~/.zshrc
ln -sf ~/code/dotfiles/zprofile.sh ~/.zprofile

gem install amazing_print foreman guard guard-shell slop specific_install
# gem specific_install davidrunger/fcom
# gem specific_install davidrunger/runger_style
