#!/usr/bin/env sh

set -Eeuo pipefail

function format_date() {
  local input="$1"
  local input_format="$2"
  local output_format="$3"
  date -ju -f $input_format $input +$output_format
}

function process_argument() {
  case "$1" in
    [0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1 %s %Y-%m-%dT%H:%M:%SZ
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date ${1:0:10} %s %Y-%m-%dT%H:%M:%S.${1:10:3}Z
      ;;
    *)
      return 1
      ;;
  esac
}

function process_stdin() {
  while read -r; do
    if [ -z "$REPLY" ]; then
      echo
    else
      process_argument "$REPLY" || return 1
    fi
  done
}

function usage() {
  local now_in_seconds=$(
    date -ju +%s
  )
  local now_in_milliseconds="$now_in_seconds"000
  printf "Usage: \e[1m$(basename $0) \e[22;4m$now_in_seconds\e[24m\n"      >&2
  printf "       \e[1m$(basename $0) \e[22;4m$now_in_milliseconds\e[24m\n" >&2
}

if [ -p /dev/stdin ]; then
  [ $# -eq 0 ] && process_stdin && exit 0
else
  [ $# -eq 1 ] && process_argument "$1" && exit 0
fi

usage
exit 1
