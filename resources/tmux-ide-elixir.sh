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

echo Setting up tmux IDE for Elixir

session_name=`basename $(pwd)`
tmux_cmd="tmux -S /var/tmux/$session_name"
$tmux_cmd new-session -s $session_name -d

$tmux_cmd rename-window -t $session_name:1 'code/test'
$tmux_cmd send-keys -t $session_name:1.1 C-m 'vim .' C-m

$tmux_cmd split-window -h -p 40 -t $session_name:1.1

if [ -d spec ]; then
  espec_files_count="`find spec -name '*.ex' -o -name '*.exs' | wc -l`"
else
  espec_files_count=0
fi
if [ -d test ]; then
  exunit_files_count="`find test -name '*.ex' -o -name '*.exs' | wc -l`"
else
  exunit_files_count=0
fi
if [ "$espec_files_count" -lt "$exunit_files_count" ]; then
  echo "* Detected no ESpec examples so running ExUnit tests instead"
  mix_test_cmd="mix test"
else
  echo "* Detected ESpec examples"
  mix_test_cmd="mix espec"
fi

fswatch=''
which fswatch >/dev/null
if [ $? = 0 ]; then
  fswatch=true
fi

if [ $fswatch ]; then
  echo "* Detected fswatch"
  fswatch_cmd="fswatch -1 \`find . -type d -depth 1 -not -name '.*' -not -name '_*' -exec printf ' "{}"' \;\`"
  mix_test_cmd="while :; do; $mix_test_cmd; $fswatch_cmd; done"
else
  echo "* Running tests/examples once -- install fswatch to run them continuously"
fi

$tmux_cmd send-keys -t $session_name:1.2 "$bundle_exec $mix_test_cmd" C-m
$tmux_cmd split-window -v -p 40 -t $session_name:1.2

if [ -d lib ] && [ -d priv ] && [ -d web ]; then
  echo "* Detected Phoenix project"

  $tmux_cmd new-window -t $session_name -n 'web server'
  $tmux_cmd send-keys -t $session_name:2 "iex -S mix phoenix.server" C-m

  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:3 iex C-m
else
  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:2 iex C-m
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
