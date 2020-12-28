#! /usr/bin/env sh

set -Eeuo pipefail

tmux_sessions_path=/var/tmux
if [ -w "$tmux_sessions_path" ] && [ -x "$tmux_sessions_path" ]; then
  printf "\e[4m$tmux_sessions_path\e[24m exists and is writable/executable\n" >&2
  :
else
  printf "Can’t write to \e[4m$tmux_sessions_path\e[24m —— " >&2
  tmux_sessions_path="$HOME/.tmux-sessions"
  printf "trying \e[4m$tmux_sessions_path\e[24m instead ... " >&2
  mkdir "$tmux_sessions_path" &>/dev/null || true
  if [ -w "$tmux_sessions_path" ] && [ -x "$tmux_sessions_path" ]; then
    printf "\e[1mOK\e[22m\n"
  else
    printf "\e[1mFAIL\e[22m\n"
    printf "Can’t write to \e[4m$tmux_sessions_path\e[24m\n" >&2
    exit 1
  fi
fi

clojure_files_count=`   find . -name '*.clj'                              | wc -l`
elixir_files_count=`    find . -name '*.ex' -o -name '*.exs'              | wc -l`
javascript_files_count=`find . -name '*.js' -not -path "./node_modules/*" | wc -l`
ruby_files_count=`      find . -name '*.rb'                               | wc -l`
sh_files_count=`        find . -name '*.sh'                               | wc -l`
if [ $elixir_files_count     -lt $clojure_files_count ] &&
   [ $javascript_files_count -lt $clojure_files_count ] &&
   [ $ruby_files_count       -lt $clojure_files_count ] &&
   [ $sh_files_count         -lt $clojure_files_count ]; then
  TMUX_SESSIONS_PATH="$tmux_sessions_path" tmux-ide-clojure "$@"
elif [ $clojure_files_count    -lt $elixir_files_count ] &&
     [ $javascript_files_count -lt $elixir_files_count ] &&
     [ $ruby_files_count       -lt $elixir_files_count ] &&
     [ $sh_files_count         -lt $elixir_files_count ]; then
  TMUX_SESSIONS_PATH="$tmux_sessions_path" tmux-ide-elixir "$@"
elif [ $clojure_files_count -lt $javascript_files_count ] &&
     [ $elixir_files_count  -lt $javascript_files_count ] &&
     [ $ruby_files_count    -lt $javascript_files_count ] &&
     [ $sh_files_count      -lt $javascript_files_count ]; then
  TMUX_SESSIONS_PATH="$tmux_sessions_path" tmux-ide-javascript "$@"
elif [ $clojure_files_count    -lt $ruby_files_count ] &&
     [ $elixir_files_count     -lt $ruby_files_count ] &&
     [ $javascript_files_count -lt $ruby_files_count ] &&
     [ $sh_files_count         -lt $ruby_files_count ]; then
  TMUX_SESSIONS_PATH="$tmux_sessions_path" tmux-ide-ruby "$@"
elif [ $clojure_files_count    -lt $sh_files_count ] &&
     [ $elixir_files_count     -lt $sh_files_count ] &&
     [ $javascript_files_count -lt $sh_files_count ] &&
     [ $ruby_files_count       -lt $sh_files_count ]; then
  TMUX_SESSIONS_PATH="$tmux_sessions_path" tmux-ide-sh "$@"
else
  echo "Could not detect a Clojure, Elixir, JavaScript, Ruby, or shell project" >&2
  exit 1
fi
