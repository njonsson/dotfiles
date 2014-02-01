#! /usr/bin/env sh

if [ $1 ]; then
  echo "* $@" >> ~/.todo.markdown
  echo To-Do List
  echo ----------
  cat ~/.todo.markdown
else
  $EDITOR ~/.todo.markdown
fi
