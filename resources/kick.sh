#! /usr/bin/env sh

set -Euo pipefail

arguments=("$@")
arguments_count=$#

function die {
  message="${1-}"
  status="${2-}"
  if [ "$message" != "" ]; then
    printf "$message\n" >&2
  fi
  exit $status || 1
}

function discover_user_ttys_and_tty_pids {
  if [ -z "$user" ]; then
    return
  fi

  ttys="$(who -u | grep "$user" | awk '{ print $2 }')"
  tty_pids="$(who -u | grep "$user" | cut -f 2)"
  if [ -z "$ttys" ] || [ -z "$tty_pids" ]; then
    die "User \e[1m$user\e[22m is not logged in." 2
  fi
}

function kill_user_tty_pids {
  if [ -z "$user" ] || [ -z "$tty_pids" ] || [ -z "$ttys" ]; then
    return
  fi

  sudo kill -9 $tty_pids
  if [ $? -eq 0 ]; then
    printf "Kicked user \e[1m$user\e[22m off the following TTYs after sending the message \e[4m$message_opt\e[24m:\n"
    for tty in $ttys; do
      printf "• \e[1m$tty\e[22m\n"
    done
  else
    die
  fi
}

function main {
  parse_arguments
  if [ "$user" == "$(whoami)" ]; then
    die "Stop kicking yourself!" 3
  fi

  discover_user_ttys_and_tty_pids
  notify_user_on_ttys
  kill_user_tty_pids
}

function notify_user_on_ttys {
  if [ -z "$message_opt" ] || [ -z "$user" ] || [ -z "$ttys" ]; then
    return
  fi

  for tty in $ttys; do
    echo "$message_opt" | sudo write $user $tty
  done
}

function parse_arguments {
  for ((i=0;i<$arguments_count;i++)); do
    argument="${arguments[i]}"
    case "$argument" in
      --message|-m)
        message_opt=""
        expecting_message_opt=true
        ;;
      -*)
        print_usage_and_die
        ;;
      *)
        if [ "${expecting_message_opt-}" == true ]; then
          expecting_message_opt=""
          if [ -z "$message_opt" ]; then
            message_opt="$argument"
            expecting_message_opt=""
          else
            print_usage_and_die
          fi
        else
          user="$argument"
        fi
        ;;
    esac
  done
  if [ -z "${user-}" ] || [ "${expecting_message_opt-}" ]; then
    print_usage_and_die
  fi
}

function print_usage_and_die {
  script="$(basename "$0")"
  printf "Usage:\n"
  printf "       \e[1m$script\e[22m --message \e[4mmessage\e[24m \e[4muser\e[24m\n" >&2
  printf "       \e[1m$script\e[22m  -m       \e[4mmessage\e[24m \e[4muser\e[24m\n" >&2
  printf "       \e[1m$script\e[22m                   \e[4muser\e[24m\n"            >&2
  die
}

main
