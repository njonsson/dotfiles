#! /usr/bin/env sh

me=`basename $0`
bundler=''
case $@ in
  "--help"|"-h" )
    echo Usage:
    echo "  $me [--no-bundler]"
    exit
    ;;
  "--no-bundler" )
    echo * Ignoring Bundler
    ;;
  "" )
    bundle check >/dev/null 2>&1
    case $? in
      # Exit code 0: bundle is defined and installed
      # Exit code 1: bundle is defined but not installed
      0|1 )
        bundler=true
        ;;
    esac
    ;;
  * )
    echo Arguments '"'$@'"' not recognized
    echo Try:
    echo "  $me --help"
    exit
    ;;
esac
echo Setting up tmux IDE for Ruby
command_prefix=""
if [ $bundler ]; then
  echo "* Detected Bundler"
  command_prefix="bundle exec"
fi

session_name=`basename $(pwd)`
tmux new-session -s $session_name -d

# These settings seem to have no effect.
tmux set-option -gt $session_name set-titles off > /dev/null
tmux set-window-option -gt $session_name automatic-rename off > /dev/null

tmux send-keys -t $session_name 'vim .' C-m
tmux split-window -h -p 40 -t $session_name
guard show >/dev/null 2>&1
if [ $? = 0 ]; then
  echo "* Detected Guard"
  tmux send-keys -t $session_name:1.2 "$command_prefix guard --clear" C-m
  tmux split-window -v -p 40 -t $session_name
fi

if [ -d app ] && [ -d config ] && [ -d db ]; then
  echo "* Detected Rails project"
  tmux new-window -t $session_name
  tmux send-keys -t $session_name:2 "$command_prefix `if [ -f script/server ]; then echo 'script/'; else echo 'rails '; fi`server" C-m

  tmux new-window -t $session_name
  tmux send-keys -t $session_name:3 "$command_prefix `if [ -f script/console ]; then echo 'script/'; else echo 'rails '; fi`console" C-m

  sleep 16 # This is a workaround for `automatic-rename off`.
  tmux rename-window -t $session_name:2 'web server'
  tmux rename-window -t $session_name:3 REPL
else
  tmux new-window -t $session_name
  if [ $bundler ]; then
    tmux send-keys -t $session_name:2 "bundle console" C-m
  else
    tmux send-keys -t $session_name:2 "irb" C-m
  fi
  if [ -f *.gemspec ]; then
    echo "* Detected RubyGems project"
    sleep 3
    tmux send-keys -t $session_name:2 "require '`basename $(ls *.gemspec | head -1) .gemspec`'" C-m
  fi

  sleep 8 # This is a workaround for `automatic-rename off`.
  tmux rename-window -t $session_name:2 REPL
fi

tmux rename-window -t $session_name:1 'code/test'

tmux select-window -t $session_name:1
tmux select-pane -t $session_name:1.1

tmux attach-session -t $session_name