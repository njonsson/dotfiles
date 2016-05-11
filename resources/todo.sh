#! /usr/bin/env sh

function todo_add() {
  echo "* $*" >>$(todo_file)
}

function todo_edit() {
  $EDITOR $(todo_file)
}

function todo_file() {
  if [ "$HOME/.todo.markdown" -nt "$HOME/.todo.md" ]; then
    echo "$HOME/.todo.markdown"
  else
    echo "$HOME/.todo.md"
  fi
}

function todo_help() {
  file=$(todo_file)
  echo "A simple to-do list, stored in ${file/$HOME/~}"
  echo
  echo "  $(basename $0) Something to do   Adds \"Something to do\" to the to-do list"
  echo
  echo "  $(basename $0) --edit            Opens the to-do list in your editor"
  echo "  $(basename $0) -e"
  echo "  $(basename $0)"
  echo
  echo "  $(basename $0) --list            Lists to-do items"
  echo "  $(basename $0) -l"
  echo
  echo "  $(basename $0) --help            Displays this help message"
  echo "  $(basename $0) -h"
}

function todo_list() {
  if [ -f $(todo_file) ]; then
    echo To-do list
    echo ----------
    cat "$(todo_file)"
  else
    echo Nothing in the to-do list
  fi
}

case "$*" in
  --edit | -e | '' )
    todo_edit
    ;;
  --help | -h )
    todo_help
    ;;
  --list | -l )
    todo_list
    ;;
  * )
    todo_add "$*"
    todo_list
    ;;
esac
