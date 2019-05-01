#! /usr/bin/env sh

set -o pipefail

SLEEP_INT_SECS=1

display_usage() {
  printf "Usage: \033[4m$(basename $0) [<options>]\033[24m\n"
  printf "\n"
  printf "    -h, --help                 Show usage help\n"
  printf "    -m, --message <message>    Specify commit message\n"
  printf "    -v, --verbose              Display verbose output\n"
  printf "\n"
}

parse_arguments() {
  COMMIT_MESSAGE="$0"
  if [[ -n "$*" ]]; then
    COMMIT_MESSAGE="$COMMIT_MESSAGE $*"
  fi
  COMMIT_MESSAGE="Automatic commit by \`$COMMIT_MESSAGE\`"
  VERBOSE=false

  local expect_message=false
  for argument in "$@"; do
    case "$argument" in
      -h | --help)
        display_usage
        exit 0
        ;;
      -m | --message)
        if [[ $expect_message != false ]]; then
          display_usage
          exit -1
        fi

        local expect_message=true
        ;;
      -v | --verbose)
        VERBOSE=true
        ;;
      *)
        if [[ $expect_message != true ]]; then
          display_usage
          exit -1
        fi

        local expect_message=false
        COMMIT_MESSAGE="$argument"
        ;;
    esac
  done
  if [[ $expect_message == true ]]; then
    display_usage
    exit -1
  fi

  print_verbose "In verbose mode\n"
  print_verbose "Using commit message \033[4m$COMMIT_MESSAGE\033[24m\n"
}

print_verbose() {
  [[ $VERBOSE == true ]] && printf "$*"
}

stat_commit_loop() {
  git diff --quiet &>/dev/null || git init # Ensure pwd has a repository.
  printf "Watching \033[4m$(pwd)\033[24m\n"
  local cr=false
  while true; do
    git add --all \
      && git diff --exit-code --staged &>/dev/null
    if [[ $? != 0 ]]; then
      local output=$(git diff --staged --stat)
      [[ $cr == true ]] && printf "\n"
      git commit --message "$COMMIT_MESSAGE" --quiet \
        && printf "Committed:\n"         \
        && printf "$output\n"
    fi
    print_verbose '.'
    if [[ $VERBOSE == true ]]; then
      local cr=true
    fi
    sleep $SLEEP_INT_SECS
  done
}

parse_arguments "$@"
stat_commit_loop
