#! /usr/bin/env sh

# set -Eeuo pipefail
set -Euo pipefail

FINAL_RELEASE_PATTERN="\b\d\+$"

function handle_result() {
  local result=$1
  if [ $result -eq 0 ]; then
    return
  fi

  case "${IGNORE_FAILURES:-}" in
    t|true|T|TRUE|y|yes|Y|YES)
      printf "\$IGNORE_FAILURES is \e[4m$IGNORE_FAILURES\e[24m " >&2
      printf "so proceeding\n" >&2
      return
      ;;
  esac

  printf "Set \$IGNORE_FAILURES in order to proceed\n" >&2
  exit $result
}

function latest_v_of() {
  local tool=$1
  local current_v=$2
  local current_v_flav=$(
    printf "$current_v\n" \
      | grep --ignore-case --only-matching '[a-z]\+[-._a-z]*[a-z]\+'
  )
  asdf      latest $tool                 | grep $FINAL_RELEASE_PATTERN \
    || asdf latest $tool $current_v_flav | grep $FINAL_RELEASE_PATTERN \
    || asdf list-all $tool               | grep $FINAL_RELEASE_PATTERN | tail -1
}

function update_all_installed_tools() {
  asdf current 2>&1 | while read entry; do
    tool_and_current_v=($entry)
    tool=${tool_and_current_v[0]}
    current_v=${tool_and_current_v[1]}
    latest_v=$(latest_v_of $tool $current_v)
    if [ -z "$latest_v" ]; then
      printf "Current \e[4m$tool\e[24m version (\e[4m$current_v\e[24m) "
      printf "is still installed —— no latest version available\n"
      continue
    fi

    if [ "$current_v" == "$latest_v" ]; then
      printf "Latest \e[4m$tool\e[24m (\e[4m$latest_v\e[24m) is "
      printf "already installed\n"
      continue
    fi

    update_tool_to_version $tool $latest_v $current_v
  done
}

function update_plugins() {
  printf "Updating plugins ...\n"
  printf "\e[2m"                                                  \
  asdf plugin-update --all
  local result=$?
  printf "\e[0m"
  handle_result $result
  if [ $result -eq 0 ]; then
    printf "Successfully updated plugins\n"
  fi
}

function update_tool_to_version() {
  tool=$1
  to_v=$2
  from_v=$3
  printf "Updating \e[4m$tool\e[24m from \e[4m$from_v\e[24m to \e[4m$to_v\e[24m ...\n"
  printf "\e[2m"
  asdf install $tool $to_v \
    && asdf global $tool $to_v
  local result=$?
  printf "\e[0m"
  handle_result $result
  if [ $result -eq 0 ]; then
    printf "Successfully updated \e[4m$tool\e[24m from \e[4m$from_v\e[24m to \e[4m$to_v\e[24m\n"
  fi
}

update_plugins
update_all_installed_tools
