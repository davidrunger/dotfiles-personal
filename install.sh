#!/usr/bin/env bash

ln -sf ~/code/dotfiles-personal/initializers/z.rb ~/code/david_runger/config/initializers/z.rb
ln -sf ~/code/dotfiles-personal/zprofile.zsh ~/.zprofile

git config core.hookspath ~/code/dotfiles/githooks/dotfiles

# gem install \
#   dokku-cli
