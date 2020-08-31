#! /usr/bin/env sh

set -Eeuo pipefail

clojure_files_count=`   find . -name '*.clj'                              | wc -l`
elixir_files_count=`    find . -name '*.ex' -o -name '*.exs'              | wc -l`
javascript_files_count=`find . -name '*.js' -not -path "./node_modules/*" | wc -l`
ruby_files_count=`      find . -name '*.rb'                               | wc -l`
sh_files_count=`        find . -name '*.sh'                               | wc -l`
if [ $elixir_files_count     -lt $clojure_files_count ] &&
   [ $javascript_files_count -lt $clojure_files_count ] &&
   [ $ruby_files_count       -lt $clojure_files_count ] &&
   [ $sh_files_count         -lt $clojure_files_count ]; then
  tmux-ide-clojure "$@"
elif [ $clojure_files_count    -lt $elixir_files_count ] &&
     [ $javascript_files_count -lt $elixir_files_count ] &&
     [ $ruby_files_count       -lt $elixir_files_count ] &&
     [ $sh_files_count         -lt $elixir_files_count ]; then
  tmux-ide-elixir "$@"
elif [ $clojure_files_count -lt $javascript_files_count ] &&
     [ $elixir_files_count  -lt $javascript_files_count ] &&
     [ $ruby_files_count    -lt $javascript_files_count ] &&
     [ $sh_files_count      -lt $javascript_files_count ]; then
  tmux-ide-javascript "$@"
elif [ $clojure_files_count    -lt $ruby_files_count ] &&
     [ $elixir_files_count     -lt $ruby_files_count ] &&
     [ $javascript_files_count -lt $ruby_files_count ] &&
     [ $sh_files_count         -lt $ruby_files_count ]; then
  tmux-ide-ruby "$@"
elif [ $clojure_files_count    -lt $sh_files_count ] &&
     [ $elixir_files_count     -lt $sh_files_count ] &&
     [ $javascript_files_count -lt $sh_files_count ] &&
     [ $ruby_files_count       -lt $sh_files_count ]; then
  tmux-ide-sh "$@"
else
  echo "Could not automatically detect a Clojure, Elixir, JavaScript, Ruby, or shell-programming project" 1>&2
  exit 1
fi
