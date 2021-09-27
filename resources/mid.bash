#!/usr/bin/env bash

set -Eeuo pipefail

function die {
  message="${1-}"
  printf "%s" "$message" >&2
  status="${2-}"
  exit $status || 1
}

function main {
  parse_arguments $@

  if [ -z "${file-}" ]; then
    process_stream
  else
    process_file
  fi
}

function parse_arguments {
  for argument in $@; do
    case "$argument" in
      -[0-9]*)
        num_opt="${argument/-/}"
        expecting_lines_opt=0
        expecting_bytes_opt=0
        num_type=line
        ;;
      -n)
        expecting_lines_opt=1
        expecting_bytes_opt=0
        ;;
      -c)
        expecting_bytes_opt=1
        expecting_lines_opt=0
        ;;
      [0-9]*)
        if (( $expecting_lines_opt )); then
          num_opt="$argument"
          num_type=line
        elif (( $expecting_bytes_opt )); then
          num_opt="$argument"
          num_type=byte
        elif [ ! -p /dev/stdin ] && [ -z "$file" ] && [ -f "$argument" ]; then
          file="$argument"
        else
          print_usage_and_die
        fi
        expecting_lines_opt=0
        expecting_bytes_opt=0
        ;;
      *)
        if [ ! -p /dev/stdin ] && [ -z "${file-}" ] && [ -f "$argument" ]; then
          file="$argument"
        else
          print_usage_and_die
        fi
        expecting_lines_opt=0
        expecting_bytes_opt=0
        ;;
    esac
  done

  if [ ! -p /dev/stdin ] && [ -z "${file-}" ]; then
    print_usage_and_die
  elif [ -z "${num_opt-}" ]; then
    print_usage_and_die
  fi

  num1="${num_opt/,*/}"
  num2="${num_opt/*,/}"
  if [ -z "$num2" ]; then
    num2="$num1"
  fi
  if ! [ -z "$num1" ] && ! [ -z "$num2" ] && [ $num2 -lt $num1 ]; then
    print_usage_and_die
  fi

  if ! [ -z "$num1" ] && [ -z "$num_type" ]; then
    print_usage_and_die
  fi

  case "$num_type" in
    line)
      head_and_tail_opts="-n"
      printf_suffix="\n"
      read_opts=""
      wc_opts="-l"
      ;;
    byte)
      head_and_tail_opts="-c"
      printf_suffix=""
      read_opts="-n 1 -d \"\0\""
      wc_opts="-c"
      ;;
    *)
      die "Expected \$num_type to be 'line' or 'byte'\n" 2
  esac
}

function print_usage_and_die {
  script="$(basename "$0")"
  printf "Usage:\n"
  printf "       \e[1m$script\e[22m -\e[4mline\e[24m          \e[4mfile\e[24m\n"            >&2
  printf "       \e[1m$script\e[22m -\e[4mline1\e[24m,\e[4mline2\e[24m   \e[4mfile\e[24m\n" >&2
  printf "       \e[1m$script\e[22m -n \e[4mline\e[24m        \e[4mfile\e[24m\n"            >&2
  printf "       \e[1m$script\e[22m -n \e[4mline1\e[24m,\e[4mline2\e[24m \e[4mfile\e[24m\n" >&2
  printf "       \e[1m$script\e[22m -c \e[4mbyte\e[24m        \e[4mfile\e[24m\n"            >&2
  printf "       \e[1m$script\e[22m -c \e[4mbyte1\e[24m,\e[4mbyte2\e[24m \e[4mfile\e[24m\n" >&2
  die
}

function process_file {
  if [ $num1 -eq 1 ]; then
    head $head_and_tail_opts $num2 "$file"
  else
    file_size=$(($(wc $wc_opts <"$file")))
    if [ $num1 -le $file_size ]; then
      if [ $num2 -lt $file_size ]; then
        if [ $((num2 * 2)) -lt $((file_size + num2 - num1 + 1)) ]; then
          head_size=$num2
          tail_size=$((num2 - num1 + 1))
          head $head_and_tail_opts $head_size "$file" | tail $head_and_tail_opts $tail_size
        else
          tail_size=$((file_size - num1 + 1))
          head_size=$((num2 - num1 + 1))
          tail $head_and_tail_opts $tail_size "$file" | head $head_and_tail_opts $head_size
        fi
      else
        tail_size=$((file_size - num1 + 1))
        tail $head_and_tail_opts $tail_size "$file"
      fi
    fi
  fi
}

function process_stream {
  if [ $num1 -eq 1 ]; then
    head $head_and_tail_opts $num2
  else
    total_read=1
    while read $read_opts -r && [ $total_read -le $num2 ]; do
      read_value="$REPLY"
      if [ $num1 -le $total_read ]; then
        printf "%s$printf_suffix" "$read_value"
      fi
      total_read=$((total_read + 1))
    done
  fi
}

main $@
