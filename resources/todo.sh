#! /usr/bin/env sh

todo_add() {
  printf "* $*\n" >>$(todo_file)
}

todo_edit() {
  $EDITOR $(todo_file)
}

todo_exit_with_number_of_items() {
  file="$(todo_file)"
  if [ -s "$file" ]; then
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
  local file=$(todo_file)
  local file="${file/$HOME/~}"
  local program=$(basename $0)

  printf "A simple to-do list, stored in \e[4m$file\e[24m\n\n"

  printf "  \e[1m$program Something to do\e[22m   Adds \"Something to do\" as new item in the to-do list\n\n"

  printf "  \e[1m$program --edit\e[22m            Opens the to-do list in your editor\n"
  printf "  \e[1m$program -e\e[22m\n"
  printf "  \e[1m$program\e[22m\n\n"

  printf "  \e[1m$program --list\e[22m            Lists to-do items\n"
  printf "  \e[1m$program -l\e[22m\n\n"

  printf "  \e[1m$program --open\e[22m            Opens the to-do list in the application associated with \e[4m$file\e[24m\n"
  printf "  \e[1m$program -o\e[22m\n\n"

  printf "  \e[1m$program --help\e[22m            Displays this help message\n"
  printf "  \e[1m$program -h\e[22m\n"
}

todo_list() {
  if [ -s "$(todo_file)" ]; then
    title="To-do list"
    title_length=${#title}
    printf "\e[4m\e[1m$title\e[22m"
    for i in $(seq 1 $(($(tput cols) - $title_length))); do
      printf " "
    done
    printf "\e[24m\n"
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
