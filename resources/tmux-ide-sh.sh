#! /usr/bin/env sh

me=`basename $0`
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

session_name=`basename $(pwd)`
tmux_cmd="tmux -S /var/tmux/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code/test'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -p 40 -t $session_name:1.1

if [ -s Makefile ] || [ -s makefile ]; then
  echo '* Detected Make configuration'
  $tmux_cmd send-keys -t $session_name:1.2 "rm -f .test-run; watch --color --differences --interval=1 --no-title 'make --question .test-run && cat .test-run || make test --silent'" C-m
  $tmux_cmd split-window -v -p 94 -t $session_name:1.2
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
