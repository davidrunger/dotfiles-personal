#!/usr/bin/env bash

# NOTE: Using a hard link rather than a symbolic link to avoid Docker issues
# with symlinks to files outside of the Docker context.
# https://github.com/moby/moby/issues/ 1676
ln -f ~/code/dotfiles-personal/initializers/z.rb ~/code/david_runger/config/initializers/z.rb
