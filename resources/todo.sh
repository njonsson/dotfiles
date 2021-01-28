#! /usr/bin/env sh

set -Eeuo pipefail

LIST_TITLE="To-do list"
PROGRAM=$(
  basename $0
)
PROGRAM_TAG_LINE="A simple to-do list"
PROGRAM_URL=https://github.com/njonsson/dotfiles

indentation_width() {
  local TEXT="$1"

  local indentation_text=$(
    printf -- "$TEXT" | grep --only-matching --regexp "^\s*"
  )
  local result=$((
    $(
      printf -- "$indentation_text" | wc -c
    )
  ))
  echo "$result"
}

is_list_item() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\s*\([*+-]\|\d\+[.)]\)\s\+\S\+" \
    >/dev/null
}

is_list_item_in_completed_state() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\s*\([*+-]\|\d\+[.)]\)\(\s\+\[\S\]\)\s\+\S\+" \
    >/dev/null
}

is_list_item_in_incomplete_state() {
  local TEXT="$1"

  printf -- "$TEXT" \
    | grep --regexp "^\s*\([*+-]\|\d\+[.)]\)\(\s\+\[\s\]\)\s\+\S\+" \
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
  printf "\n"              >>"$(todo_filename)"

  printf "> This file was created by the *$PROGRAM* " >>"$(todo_filename)"
  printf "program. Run \`$PROGRAM --help\` at the "   >>"$(todo_filename)"
  printf "command line to learn about it.\n"          >>"$(todo_filename)"
  printf "\n"                                         >>"$(todo_filename)"
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

  printf "$PROGRAM_TAG_LINE"

  # Right-align a credit.
  local tag_line_length=${#PROGRAM_TAG_LINE}
  local url_length=${#PROGRAM_URL}
  local space_length=$(($(tput cols) - $tag_line_length - $url_length))
  for i in $(seq 1 $space_length); do
    printf " "
  done
  unset i
  printf "\e[2;4m$PROGRAM_URL\e[24;22m\n"

  printf "\n"

  printf "  \e[1m$PROGRAM 'Something to do'\e[22m   Adds \e[4mSomething to do\e[24m as a new, incomplete item in the to-do list\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --edit\e[22m              Opens the to-do list file in your \$EDITOR, \e[4m$EDITOR\e[24m\n"
  printf "  \e[1m$PROGRAM -e\e[22m\n"
  printf "  \e[1m$PROGRAM\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --filename\e[22m          Displays the to-do list filename\n"
  printf "  \e[1m$PROGRAM -f\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --list\e[22m              Lists all to-do items\n"
  printf "  \e[1m$PROGRAM -l\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --list-completed\e[22m    Lists completed to-do items\n"
  printf "  \e[1m$PROGRAM -c\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --list-incomplete\e[22m   Lists incomplete to-do items\n"
  printf "  \e[1m$PROGRAM -i\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --open\e[22m              Opens the to-do list file in the application associated with it\n"
  printf "  \e[1m$PROGRAM -o\e[22m\n"
  printf "\n"

  printf "  \e[1m$PROGRAM --help\e[22m              Displays this help message\n"
  printf "  \e[1m$PROGRAM -h\e[22m\n"
  printf "\n"

  printf "  Exit status is the number of to-do list items displayed.\n"
}

todo_items() {
  local FILTER="${1-}"

  if [ -s "$(todo_filename)" ]; then
    local unmatching_ancestors=()

    local ifs_original="$IFS"
    IFS='' # Read whitespace verbatim.
    while read line; do
      # Ignore lines that are not list items.
      is_list_item "$line" || continue

      local item="$line"
      local item_indent_width=$(indentation_width "$item")

      # Discard unmatching siblings and younger relations in reverse order.
      while [ 0 -lt ${#unmatching_ancestors[*]} ]; do
        local last_unmatching_ancestor="${unmatching_ancestors[@]: -1}"
        if [ $item_indent_width -le $(indentation_width "$last_unmatching_ancestor") ]; then
          # Pop right.
          local unmatching_ancestors_count="${#unmatching_ancestors[*]}"
          local unmatching_ancestors=("${unmatching_ancestors[@]::$unmatching_ancestors_count-1}")
        else
          break
        fi
      done

      if [ "$FILTER" == COMPLETED ] && ! is_list_item_in_completed_state "$item"; then
        local item_matches_filter=false
      elif [ "$FILTER" == INCOMPLETE ] && is_list_item_in_completed_state "$item"; then
        local item_matches_filter=false
      else
        local item_matches_filter=true
      fi

      if [ $item_matches_filter == true ]; then
        # Print and discard unmatching ancestors in order.
        while [ 0 -lt ${#unmatching_ancestors[*]} ]; do
          printf -- "${unmatching_ancestors[0]}\n"

          # Pop left.
          local unmatching_ancestors=("${unmatching_ancestors[@]:1}")
        done

        printf -- "$item\n"
      else
        # Push right.
        local unmatching_ancestors_count="${#unmatching_ancestors[*]}"
        local unmatching_ancestors[$unmatching_ancestors_count]="$item"
      fi
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
      # Print the title in bold, with a line underneath across the whole window.
      local title_length=${#LIST_TITLE}
      printf "\e[4m\e[1m$LIST_TITLE\e[22m" >&2
      for i in $(seq 1 $(($(tput cols) - $title_length))); do
        printf " " >&2
      done
      unset i
      printf "\e[24m\n" >&2

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
    printf "Unrecognized option: \e[4m$*\e[24m\n" >&2
    exit -1
    ;;
  * )
    todo_add "$*"
    todo_list
    ;;
esac
