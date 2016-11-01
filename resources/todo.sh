#! /usr/bin/env sh

todo_add() {
  printf "* $*\n" >>$(todo_file)
}

todo_edit() {
  $EDITOR $(todo_file)
}

todo_exit_with_number_of_items() {
  file="$(todo_file)"
  if [ -s $file ]; then
    exit $(wc -l $file | awk '{ print $1 }')
  else
    exit 0
  fi
}

todo_file() {
  if [ "$HOME/.todo.markdown" -nt "$HOME/.todo.md" ]; then
    printf "$HOME/.todo.markdown\n"
  else
    printf "$HOME/.todo.md\n"
  fi
}

todo_help() {
  file=$(todo_file)
  printf "A simple to-do list, stored in ${file/$HOME/~}\n\n"

  printf "  $(basename $0) Something to do   Adds \"Something to do\" to the to-do list\n\n"

  printf "  $(basename $0) --edit            Opens the to-do list in your editor\n"
  printf "  $(basename $0) -e\n"
  printf "  $(basename $0)\n\n"

  printf "  $(basename $0) --list            Lists to-do items\n"
  printf "  $(basename $0) -l\n\n"

  printf "  $(basename $0) --open            Opens the to-do list in the application associated with \e[4m$(todo_file)\e[24m\n"
  printf "  $(basename $0) -o\n\n"

  printf "  $(basename $0) --help            Displays this help message\n"
  printf "  $(basename $0) -h\n"
}

todo_list() {
  if [ -s $(todo_file) ]; then
    printf "To-do list\n"
    echo    ----------
    cat "$(todo_file)"
  # else
  #   printf "Nothing in the to-do list\n"
  fi
}

todo_open() {
  open "$(todo_file)"
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
  --open | -o )
    todo_open
    ;;
  * )
    todo_add "$*"
    todo_list
    ;;
esac
todo_exit_with_number_of_items
