#!/usr/bin/env sh

set -Eeuo pipefail

function format_date() {
  local input="$1"
  local input_format="$2"
  local output_format="$3"
  date -ju -f $input_format $input +$output_format
}

function usage() {
  printf "Usage: \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1m.\e[22;4ms\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1m.\e[22;4mss\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYY\e[24;1m-\e[22;4mMM\e[24;1m-\e[22;4mDD\e[24;1mT\e[22;4mhh\e[24;1m:\e[22;4mmm\e[24;1m:\e[22;4mss\e[24;1m.\e[22;4msss\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1m.\e[22;4ms\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1m.\e[22;4mss\e[24;1mZ\e[22m\n"
  printf "       \e[1m$(basename $0) \e[22;4mYYYYMMDD\e[24;1mT\e[22;4mhhmmss\e[24;1m.\e[22;4msss\e[24;1mZ\e[22m\n"
}

if [ $# -ne 1 ]; then
  usage
  exit 1
fi

case "$1" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z)
    format_date $1 %Y-%m-%dT%H:%M:%SZ %s
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].Z)
    format_date ${1:0:19}Z %Y-%m-%dT%H:%M:%SZ %s000
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]Z)
    format_date ${1:0:19}Z %Y-%m-%dT%H:%M:%SZ %s${1:20:1}00
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9]Z)
    format_date ${1:0:19}Z %Y-%m-%dT%H:%M:%SZ %s${1:20:2}0
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]Z)
    format_date ${1:0:19}Z %Y-%m-%dT%H:%M:%SZ %s${1:20:3}
    ;;
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z)
    format_date $1 %Y%m%dT%H%M%SZ %s
    ;;
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].Z)
    format_date ${1:0:15}Z %Y%m%dT%H%M%SZ %s000
    ;;
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].[0-9]Z)
    format_date ${1:0:15}Z %Y%m%dT%H%M%SZ %s${1:16:1}00
    ;;
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].[0-9][0-9]Z)
    format_date ${1:0:15}Z %Y%m%dT%H%M%SZ %s${1:16:2}0
    ;;
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].[0-9][0-9][0-9]Z)
    format_date ${1:0:15}Z %Y%m%dT%H%M%SZ %s${1:16:3}
    ;;
  *)
    usage
    exit 1
    ;;
esac
