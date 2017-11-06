#!/usr/bin/env bash

function main {
  parse_arguments $@

  if [ -z "$file" ]; then
    process_stream
  else
    process_file
  fi
}

function parse_arguments {
  if [ -t 0 ]; then
    if [ "$#" -eq 2 ] && [ -f "$2" ]; then
      # Input comes from a specified filename.
      file="$2"
      lines_opt="$1"
    else
      print_usage_and_exit
    fi
  else
    # Input comes from a stream.
    if [ "$#" -eq 1 ]; then
      file=""
      lines_opt="$1"
    else
      print_usage_and_exit
    fi
  fi

  line1="${lines_opt/-/}"
  line1="${line1/,*/}"

  line2="${lines_opt/-/}"
  line2="${line2/*,/}"
  if [ -z "$line2" ]; then
    line2=$line1
  fi

  if [ $line2 -lt $line1 ]; then
    print_usage_and_exit
  fi
}

function print_usage_and_exit {
  script="$(basename "$0")"
  printf "Usage:\n"
  printf "       \e[1m$script\e[22m -\e[4mline\e[24m        \e[4mfile\e[24m\n"            >&2
  printf "       \e[1m$script\e[22m -\e[4mline1\e[24m,\e[4mline2\e[24m \e[4mfile\e[24m\n" >&2
  exit 1
}

function process_file {
  if [ $line1 -eq 1 ]; then
    head -$line2 "$file"
  else
    lines_in_file=$(($(wc -l <"$file")))
    if [ $line1 -le $lines_in_file ]; then
      if [ $line2 -lt $lines_in_file ]; then
        if [ $((line2 * 2)) -lt $((lines_in_file + line2 - line1 + 1)) ]; then
          head_lines=$line2
          tail_lines=$((line2 - line1 + 1))
          head -$head_lines "$file" | tail -$tail_lines
        else
          tail_lines=$((lines_in_file - line1 + 1))
          head_lines=$((line2 - line1 + 1))
          tail -$tail_lines "$file" | head -$head_lines
        fi
      else
        tail_lines=$((lines_in_file - line1 + 1))
        tail -$tail_lines "$file"
      fi
    fi
  fi
}

function process_stream {
  if [ $line1 -eq 1 ]; then
    head -$line2
  else
    lines_read=1
    while read -r && [ $lines_read -le $line2 ]; do
      line="$REPLY"
      if [ $line1 -le $lines_read ]; then
        printf "%s\n" "$line"
      fi
      lines_read=$((lines_read + 1))
    done
  fi
}

main $@
