#! /usr/bin/env sh

todo_add() {
  printf "* $*\n" >>$(todo_filename)
}

todo_edit() {
  $EDITOR $(todo_filename)
}

todo_exit_with_number_of_items() {
  if [ -s "$(todo_filename)" ]; then
    local wc_output=$(wc -l $(todo_filename))
    local wc_output_tokens=($wc_output)
    local line_count=${wc_output_tokens[0]}
    exit $line_count
  else
    exit 0
  fi
}

todo_filename() {
  if [ "$HOME/.todo.markdown" -nt "$HOME/.todo.md" ]; then
    printf "$HOME/.todo.markdown\n"
  else
    printf "$HOME/.todo.md\n"
  fi
}

todo_help() {
  local filename=$(todo_filename)
  local filename="${filename/$HOME/~}"
  local program=$(basename $0)

  printf "A simple to-do list, stored in \e[4m$file\e[24m\n\n"

  printf "  \e[1m$program Something to do\e[22m   Adds \"Something to do\" as new item in the to-do list\n\n"

  printf "  \e[1m$program --edit\e[22m            Opens the to-do list in your editor\n"
  printf "  \e[1m$program -e\e[22m\n"
  printf "  \e[1m$program\e[22m\n\n"

  printf "  \e[1m$program --list\e[22m            Lists to-do items\n"
  printf "  \e[1m$program -l\e[22m\n\n"

  printf "  \e[1m$program --open\e[22m            Opens the to-do list in the application associated with \e[4m$filename\e[24m\n"
  printf "  \e[1m$program -o\e[22m\n\n"

  printf "  \e[1m$program --help\e[22m            Displays this help message\n"
  printf "  \e[1m$program -h\e[22m\n"
}

todo_list() {
  if [ -s "$(todo_filename)" ]; then
    local title="To-do list"
    local title_length=${#title}
    printf "\e[4m\e[1m$title\e[22m"
    for i in $(seq 1 $(($(tput cols) - $title_length))); do
      printf " "
    done
    printf "\e[24m\n"
    cat "$(todo_filename)"
  # else
  #   printf "Nothing in the to-do list\n"
  fi
}

todo_open() {
  open "$(todo_filename)"
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
