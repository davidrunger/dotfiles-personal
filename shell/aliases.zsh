alias david="cd ~/code/david_runger"
alias hwm='hpr && echo && wm'
alias wm='wait-merge'

if [ ! -v LINUX ]; then
  unalias ls > /dev/null 2>&1 || true
  alias ls="/bin/ls"
fi
