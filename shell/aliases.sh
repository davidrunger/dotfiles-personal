alias david="cd ~/code/david_runger"

if [ ! -v LINUX ]; then
  unalias ls > /dev/null 2>&1 || true
  alias ls="/bin/ls"
fi
