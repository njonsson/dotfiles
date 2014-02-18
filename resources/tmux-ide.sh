#! /usr/bin/env sh

ruby_files_count=`find . -name "*.rb" | wc -l`
clojure_files_count=`find . -name "*.clj" | wc -l`
if [[ $ruby_files_count < $clojure_files_count ]]; then
  tmux-ide-clojure
elif [[ $clojure_files_count < $ruby_files_count ]]; then
  tmux-ide-ruby
else
  echo "Could not automatically detect a Clojure or Ruby project" 1>&2
  exit 1
fi
