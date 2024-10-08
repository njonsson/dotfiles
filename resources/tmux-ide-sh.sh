#! /usr/bin/env sh

set -Euo pipefail

me=$(
  basename $0
)
case $@ in
  "--help"|"-h" )
    echo Usage:
    echo "  $me"
    exit
    ;;
  "" )
    ;;
  * )
    echo Arguments '"'$@'"' not recognized
    echo Try:
    echo "  $me --help"
    exit
    ;;
esac

echo Setting up tmux IDE for shell programming

session_name=$(
  basename $(pwd)
)
tmux_cmd="tmux -S $TMUX_SESSIONS_PATH/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code/test'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -l 40% -t $session_name:1.1

if [ -s Makefile ] || [ -s makefile ]; then
  echo '* Detected Make configuration'
  make_cmd="make test --always-make --silent"

  fswatch=''
  which fswatch >/dev/null
  if [ $? = 0 ]; then
    fswatch=true
  fi

  if [ $fswatch ]; then
    echo "* Detected fswatch"
    fswatch_cmd="fswatch -1\`find . -type d -depth 1 -not -name '.*' -not -name '_*' -exec printf ' "{}"' \;\`"
    make_cmd="while :; do; printf \"\\e[1mBuilding/testing ...\\e[0m\\n\"; $make_cmd; printf \"\\n\"; $fswatch_cmd; printf \"\\n\"; done"
  else
    echo "* Running tests once -- install fswatch to run them continuously"
  fi

  $tmux_cmd send-keys -t $session_name:1.2 "clear; $make_cmd" C-m
  $tmux_cmd split-window -v -l 80% -t $session_name:1.2
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
