#! /usr/bin/env sh

set -Eeuo pipefail

LIST_TITLE="To-do list"

is_list_item() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\([*+-]\|\d\+[.)]\)\s\+\S\+" \
    >/dev/null
}

is_list_item_in_completed_state() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\([*+-]\|\d\+[.)]\)\(\s\+\[\S\]\)\s\+\S\+" \
    >/dev/null
}

is_list_item_in_incomplete_state() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\([*+-]\|\d\+[.)]\)\(\s\+\[\s\]\)\s\+\S\+" \
    >/dev/null
}

todo_add() {
  todo_ensure_file_exists
  printf "* [ ] $*\n" >>"$(todo_filename)"
}

todo_edit() {
  $EDITOR "$(todo_filename)"
}

todo_ensure_file_exists() {
  if [ -a "$(todo_filename)" ]; then
    return
  fi

  printf "# $LIST_TITLE\n" >>"$(todo_filename)"
  printf "\n"             >>"$(todo_filename)"

  local program=$(basename $0)
  printf "> This file was created by the *$program* "  >>"$(todo_filename)"
  printf "program. Run \`$program --help\` at the "    >>"$(todo_filename)"
  printf "command line to learn about it.\n"           >>"$(todo_filename)"
  printf "\n"                                          >>"$(todo_filename)"
}

todo_filename() {
  if [ "$HOME/.todo.markdown" -nt "$HOME/.todo.md" ]; then
    printf "$HOME/.todo.markdown\n"
  else
    printf "$HOME/.todo.md\n"
  fi
}

todo_help() {
  local filename="$(todo_filename)"
  local filename="${filename/$HOME/~}"
  local program=$(basename $0)

  local tag_line="A simple to-do list"
  printf "$tag_line"

  # Right-align a credit.
  local tag_line_length=${#tag_line}
  local url=https://github.com/njonsson/dotfiles
  local url_length=${#url}
  local space_length=$(($(tput cols) - $tag_line_length - $url_length))
  for i in $(seq 1 $space_length); do
    printf " "
  done
  printf "\e[2;4m$url\e[24;22m\n"

  printf "\n"

  printf "  \e[1m$program 'Something to do'\e[22m   Adds \e[4mSomething to do\e[24m as a new, incomplete item in the to-do list\n"
  printf "\n"

  printf "  \e[1m$program --edit\e[22m              Opens the to-do list in your \$EDITOR, \e[4m$EDITOR\e[24m\n"
  printf "  \e[1m$program -e\e[22m\n"
  printf "  \e[1m$program\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --filename\e[22m          Displays the to-do list filename\n"
  printf "  \e[1m$program -f\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --list\e[22m              Lists all to-do items\n"
  printf "  \e[1m$program -l\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --list-completed\e[22m    Lists completed to-do items\n"
  printf "  \e[1m$program -c\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --list-incomplete\e[22m   Lists incomplete to-do items\n"
  printf "  \e[1m$program -i\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --open\e[22m              Opens the to-do list in the application associated with \e[4m$filename\e[24m\n"
  printf "  \e[1m$program -o\e[22m\n"
  printf "\n"

  printf "  \e[1m$program --help\e[22m              Displays this help message\n"
  printf "  \e[1m$program -h\e[22m\n"
  printf "\n"

  printf "  Exit status is the number of to-do list items displayed.\n"
}

todo_items() {
  local FILTER="${1-}"

  if [ -s "$(todo_filename)" ]; then
    local ifs_original="$IFS"
    IFS='' # Read whitespace verbatim.
    while read line; do
      # Ignore lines that are not list items.
      is_list_item "$line" \
        || continue

      # Ignore completed items if we want incomplete.
      [ "$FILTER" == INCOMPLETE ] \
        && is_list_item_in_completed_state "$line" \
        && continue

      # Ignore non-completed items if we want completed.
      [ "$FILTER" == COMPLETED ] \
        && ! is_list_item_in_completed_state "$line" \
        && continue

      printf -- "$line\n"
    done <"$(todo_filename)"
    IFS="$ifs_original"
  fi
}

todo_list() {
  local FILTER="${1-}"

  local items="$(todo_items $FILTER)"
  if [ -z "$items" ]; then
    local item_count=0
  else
    local item_count=$(($(printf -- "$items\n" | wc -l)))
    if [ 0 -lt $item_count ]; then
      # Underline the title.
      local title_length=${#LIST_TITLE}
      printf "\e[4m\e[1m$LIST_TITLE\e[22m"
      for i in $(seq 1 $(($(tput cols) - $title_length))); do
        printf " "
      done
      printf "\e[24m\n"

      printf -- "$items\n"
    fi
  fi
  return $item_count
}

todo_open() {
  todo_ensure_file_exists
  open "$(todo_filename)"
}

case "$*" in
  --edit | -e | '' )
    todo_edit
    ;;
  --filename | -f )
    todo_filename
    ;;
  --help | -h )
    todo_help
    ;;
  --list | -l )
    todo_list
    ;;
  --list-completed | -c )
    todo_list COMPLETED
    ;;
  --list-incomplete | -i )
    todo_list INCOMPLETE
    ;;
  --open | -o )
    todo_open
    ;;
  -* )
    printf "Unrecognized option: \e[4m$*\e[24m\n"
    exit 1
    ;;
  * )
    todo_add "$*"
    todo_list
    ;;
esac
