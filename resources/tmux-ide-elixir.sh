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
RUN_TESTS_SCRIPT=/tmp/$me-run-tests-for-$session_name
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
  espec=1
  mix_test_cmd="mix espec"
fi

fswatch=''
which fswatch >/dev/null
if [ $? = 0 ]; then
  fswatch=true
fi

cat /dev/null >$RUN_TESTS_SCRIPT
if [ $fswatch ]; then
  echo "* Detected fswatch"
  root_dirs=$(find . -type d -depth 1 -not -name '.*' -not -name '_*' -exec printf ' "{}"' \;)
  spec_dirs=$(find . -type d -name spec -exec printf ' "{}"' \;)
  test_dirs=$(find . -type d -name test -exec printf ' "{}"' \;)
  fswatch_cmd="fswatch -1$root_dirs"
  grep_include_opts="--include='*.ex' --include='*.exs'"
  echo "while :; do"                                                                                                              >>$RUN_TESTS_SCRIPT
  echo "  grep --extended-regexp $grep_include_opts --recursive '^[^#]*([[:space:]]:debugger|IEx\\.pry)'$root_dirs >/dev/null"    >>$RUN_TESTS_SCRIPT
  echo "  iex=\$?"                                                                                                                >>$RUN_TESTS_SCRIPT
  echo "  if [ -z '$espec' ]; then"                                                                                               >>$RUN_TESTS_SCRIPT
  echo "    grep --extended-regexp $grep_include_opts --recursive '^[^#]*[[:space:]]@tag +[^#]*:focus'$test_dirs >/dev/null"      >>$RUN_TESTS_SCRIPT
  echo "    focus=\$?"                                                                                                            >>$RUN_TESTS_SCRIPT
  echo "    focus_option='--only focus'"                                                                                          >>$RUN_TESTS_SCRIPT
  echo "  else"                                                                                                                   >>$RUN_TESTS_SCRIPT
  echo "    grep --extended-regexp $grep_include_opts --recursive '^[^#]*[[:space:]]f(it|describe|specify)'$spec_dirs >/dev/null" >>$RUN_TESTS_SCRIPT
  echo "    focus=\$?"                                                                                                            >>$RUN_TESTS_SCRIPT
  echo "    focus_option='--focus'"                                                                                               >>$RUN_TESTS_SCRIPT
  echo "  fi"                                                                                                                     >>$RUN_TESTS_SCRIPT
  echo "  if [ \$iex -eq 0 -a \$focus -ne 0 ]; then"                                                                              >>$RUN_TESTS_SCRIPT
  echo "    printf \"\\e[1mBuilding/testing with IEx ...\\e[0m\\\n\""                                                             >>$RUN_TESTS_SCRIPT
  echo "    iex -S $mix_test_cmd"                                                                                                 >>$RUN_TESTS_SCRIPT
  echo "  elif [ \$iex -ne 0 -a \$focus -eq 0 ]; then"                                                                            >>$RUN_TESTS_SCRIPT
  echo "    printf \"\\e[1mBuilding/testing focused ...\\e[0m\\\n\""                                                              >>$RUN_TESTS_SCRIPT
  echo "    $mix_test_cmd \$focus_option"                                                                                         >>$RUN_TESTS_SCRIPT
  echo "  elif [ \$iex -eq 0 -a \$focus -eq 0 ]; then"                                                                            >>$RUN_TESTS_SCRIPT
  echo "    printf \"\\e[1mBuilding/testing focused with IEx ...\\e[0m\\\n\""                                                     >>$RUN_TESTS_SCRIPT
  echo "    iex -S $mix_test_cmd \$focus_option"                                                                                  >>$RUN_TESTS_SCRIPT
  echo "  else"                                                                                                                   >>$RUN_TESTS_SCRIPT
  echo "    printf \"\\e[1mBuilding/testing ...\\e[0m\\\n\""                                                                      >>$RUN_TESTS_SCRIPT
  echo "    $mix_test_cmd"                                                                                                        >>$RUN_TESTS_SCRIPT
  echo "  fi"                                                                                                                     >>$RUN_TESTS_SCRIPT
  echo "  printf \"\\\n\""                                                                                                        >>$RUN_TESTS_SCRIPT
  echo "  $fswatch_cmd"                                                                                                           >>$RUN_TESTS_SCRIPT
  echo "  printf \"\\\n\""                                                                                                        >>$RUN_TESTS_SCRIPT
  echo "done"                                                                                                                     >>$RUN_TESTS_SCRIPT
else
  echo "* Running tests/examples once -- install fswatch to run them continuously"
  echo "$mix_test_cmd" >>$RUN_TESTS_SCRIPT
fi
chmod u+x $RUN_TESTS_SCRIPT

$tmux_cmd send-keys -t $session_name:1.2 "clear; $RUN_TESTS_SCRIPT" C-m

$tmux_cmd split-window -v -p 40 -t $session_name:1.2

if [ -d lib ] && [ -d priv ] && [ -d web ]; then
  echo "* Detected Phoenix project"

  $tmux_cmd new-window -t $session_name -n 'web server'
  $tmux_cmd send-keys -t $session_name:2 "iex -S mix phoenix.server" C-m

  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:3 "iex -S mix" C-m
else
  $tmux_cmd new-window -t $session_name -n REPL
  $tmux_cmd send-keys -t $session_name:2 "iex -S mix" C-m
fi

$tmux_cmd select-window -t $session_name:1
$tmux_cmd select-pane -t $session_name:1.1

$tmux_cmd attach-session -t $session_name
