#! /usr/bin/env sh

set -Eeuo pipefail

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

echo Setting up tmux IDE for JavaScript

session_name=$(
  basename $(pwd)
)
tmux_cmd="tmux -S $TMUX_SESSIONS_PATH/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -l 40% -t $session_name:1.1

meteor=''
if [ -d .meteor ]; then
  which meteor >/dev/null
  if [ $? = 0 ]; then
    meteor=true
  fi
fi
if [ $meteor ]; then
  echo "* Detected Meteor project"
  $tmux_cmd send-keys -t $session_name:1.2 "meteor test-packages --port 3010" C-m
  $tmux_cmd split-window -v -l 80% -t $session_name:1.2
  sleep 3 && open --background http://localhost:3010

  $tmux_cmd new-window -t $session_name -n 'web server'
  $tmux_cmd send-keys -t $session_name:2 "meteor" C-m

  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:3 "meteor shell" C-m
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
