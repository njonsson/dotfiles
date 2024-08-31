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

echo Setting up tmux IDE for Clojure

session_name=$(
  basename $(pwd)
)
tmux_cmd="tmux -S $TMUX_SESSIONS_PATH/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code/test'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -p 40 -t $session_name:1.1

$tmux_cmd new-window -t $session_name -n REPL
$tmux_cmd send-keys -t $session_name:2 "lein repl" C-m

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
