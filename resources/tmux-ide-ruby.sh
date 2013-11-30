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

echo Setting up tmux IDE for Ruby

bundler=''
bundle check >/dev/null 2>&1
case $? in
  # Exit code 0: bundle is defined and installed
  # Exit code 1: bundle is defined but not installed
  0|1 )
    echo "* Detected Bundler configuration"
    bundler=true
    ;;
esac

bundle_exec=""
if [ $bundler ]; then
  bundle_exec="bundle exec"
fi

session_name=`basename $(pwd)`
tmux_cmd="tmux -S /var/tmux/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code/test'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -p 40 -t $session_name:1.1

guard=''
if [ -e Guardfile ]; then
  which guard >/dev/null
  if [ $? = 0 ]; then
    guard=true
  fi
fi
if [ $guard ]; then
  echo "* Detected Guard configuration"
  $tmux_cmd send-keys -t $session_name:1.2 "$bundle_exec guard" C-m
  $tmux_cmd split-window -v -p 40 -t $session_name:1.2
fi

if [ -d app ] && [ -d config ] && [ -d db ]; then
  echo "* Detected Rails project"
  $tmux_cmd new-window -t $session_name -n 'web server'
  $tmux_cmd send-keys -t $session_name:2 "$bundle_exec `if [ -f script/server ]; then echo 'script/'; else echo 'rails '; fi`server" C-m

  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:3 "$bundle_exec `if [ -f script/console ]; then echo 'script/'; else echo 'rails '; fi`console" C-m
else
  $tmux_cmd new-window -t $session_name -n REPL
  if [ $bundler ]; then
    $tmux_cmd send-keys -t $session_name:2 "bundle console" C-m
  else
    $tmux_cmd send-keys -t $session_name:2 "irb" C-m
  fi
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
