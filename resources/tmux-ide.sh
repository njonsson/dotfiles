#! /usr/bin/env sh

clojure_files_count=`find . -name "*.clj" | wc -l`
javascript_files_count=`find . -name "*.js" | wc -l`
ruby_files_count=`find . -name "*.rb" | wc -l`
if [ $javascript_files_count -lt $clojure_files_count ] && [ $ruby_files_count -lt $clojure_files_count ]; then
  tmux-ide-clojure "$*"
elif [ $clojure_files_count -lt $javascript_files_count ] && [ $ruby_files_count -lt $javascript_files_count ]; then
  tmux-ide-javascript "$*"
elif [ $clojure_files_count -lt $ruby_files_count ] && [ $javascript_files_count -lt $ruby_files_count ]; then
  tmux-ide-ruby "$*"
else
  echo "Could not automatically detect a Clojure, JavaScript, or Ruby project" 1>&2
  exit 1
fi
