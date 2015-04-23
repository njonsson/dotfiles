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

build=''
if [ -e build ]; then
  build=true
fi
if [ $build ]; then
  echo '* Detected build script'
  $tmux_cmd send-keys -t $session_name:1.2 'watch --color --no-title ./build' C-m
else
  $tmux_cmd send-keys -t $session_name:1.2 'watch --color --no-title ./build'
fi
$tmux_cmd split-window -v -p 94 -t $session_name:1.2

run_tests=''
if [ -e run-tests ]; then
  run_tests=true
fi
if [ $run_tests ]; then
  echo '* Detected run-tests script'
  $tmux_cmd send-keys -t $session_name:1.3 'watch --color --no-title "echo \"...\" && ./run-tests | tail -16"' C-m
else
  $tmux_cmd send-keys -t $session_name:1.3 'watch --color --no-title "echo \"...\" && ./run-tests | tail -16"'
fi
$tmux_cmd split-window -v -p 70 -t $session_name:1.3

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
