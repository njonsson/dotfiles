#!/usr/bin/env sh

set -Eeuo pipefail
shopt -s extglob

function format_date() {
  local input="$1"
  local input_format="$2"
  local output_format="$3"
  date -ju -f $input_format $input +$output_format
}

function process_argument() {
  case "$1" in
    [0-9][0-9][0-9][0-9])
      format_date $1-01-01T00:00:00Z %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9])
      format_date $1-01T00:00:00Z %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      format_date $1T00:00:00Z %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]Z)
      format_date ${1:0:13}:00:00Z %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]Z)
      format_date ${1:0:16}:00Z %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z)
      format_date $1 %Y-%m-%dT%H:%M:%SZ %s
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].+([0-9])Z)
      local frac_with_z=${1#*.}
      format_date ${1%.*}Z %Y-%m-%dT%H:%M:%SZ %s.${frac_with_z%Z}
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      format_date $1T000000Z %Y%m%dT%H%M%SZ %s
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9]Z)
      format_date ${1:0:11}0000Z %Y%m%dT%H%M%SZ %s
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9]Z)
      format_date ${1:0:13}00Z %Y%m%dT%H%M%SZ %s
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z)
      format_date $1 %Y%m%dT%H%M%SZ %s
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].+([0-9])Z)
      local frac_with_z=${1#*.}
      format_date ${1%.*}Z %Y%m%dT%H%M%SZ %s.${frac_with_z%Z}
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
  printf "Usage: \e[1m$(basename $0) \e[22;4mYYYY\e[24m\n"                                                                                                                                >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24m\n"                                                                                                             >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24m\n"                                                                                          >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1mZ\e[22m\n"                                                              >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1mZ\e[22m\n"                                           >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1mZ\e[22m\n"                        >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1m.\e[22;4ms\e[24;1mZ\e[22m\n"      >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1m.\e[22;4mss\e[24;1mZ\e[22m ...\n" >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24m\n"                                                                                                                            >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhh\e[24;1mZ\e[22m\n"                                                                                                >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmm\e[24;1mZ\e[22m\n"                                                                                              >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1mZ\e[22m\n"                                                                                            >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1m.\e[22;4ms\e[24;1mZ\e[22m\n"                                                                          >&2
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1m.\e[22;4mss\e[24;1mZ\e[22m ...\n"                                                                     >&2
}

if [ -p /dev/stdin ]; then
  [ $# -eq 0 ] && process_stdin && exit 0
else
  [ $# -eq 1 ] && process_argument "$1" && exit 0
fi

usage
exit 1
