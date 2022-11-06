#!/usr/bin/env bash

ln -sf ~/code/dotfiles/gitignore_global ~/.gitignore_global
ln -sf ~/code/dotfiles/initializers/z.rb ~/code/david_runger/config/initializers/z.rb
ln -sf ~/code/dotfiles/irbrc.rb ~/.irbrc.rb
ln -sf ~/code/dotfiles/pryrc.rb ~/.pryrc
ln -sf ~/code/dotfiles/rspec ~/.rspec
ln -sf ~/code/dotfiles/rubocop.yml ~/.rubocop.yml
rm -rf ~/.oh-my-zsh/custom/themes/
ln -sf ~/code/dotfiles/zsh/themes ~/.oh-my-zsh/custom
ln -sf ~/code/dotfiles/zshrc.sh ~/.zshrc
