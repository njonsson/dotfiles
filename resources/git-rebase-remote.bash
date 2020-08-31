#! /usr/bin/env bash

set -Eeuo pipefail

announce() {
  echo -e -n "*** $1 ... "
}

default_branch_upstream() {
  # TODO: Raise an error if 'master' branch does not exist
  echo -n master
}

default_remote() {
  # TODO: Raise an error if 'origin' remote does not exist
  echo -n origin
}

display_help() {
  echo Usage:
  echo "  git $(basename $0 .bash) [REMOTE] BRANCH-UPSTREAM BRANCH-DOWNSTREAM"
  echo "  git $(basename $0 .bash) --help"
  echo "  git $(basename $0 .bash) -h"
}

perform() {
  command=$1
  output=`$command 2>&1`
  result=$?
  if [[ $result -eq 0 ]]; then
    echo -e "\033[32mOK\033[0m"
  else
    echo -e "\033[31merror!\033[0m"
    echo -e "$output" >&2
    exit $result
  fi
}

perform_discarding_stderr() {
  command=$1
  output=`$command 2>/dev/null`
  result=$?
  if [[ $result -eq 0 ]]; then
    echo -e "\033[32mOK\033[0m"
  else
    echo -e "\033[31merror!\033[0m"
    echo -e "$output" >&2
    exit $result
  fi
}

case "${1-}" in
  "" | "--help" | "-h")
    display_help
    exit
    ;;
esac

if [[ "$3" == "" ]]; then
  REMOTE=$(default_remote)
fi

if [[ "$2" == "" ]]; then
  display_help
  exit 1
else
  BRANCH_UPSTREAM=$1
  BRANCH_DOWNSTREAM=$2
fi

announce "Fetching \033[4m$BRANCH_UPSTREAM\033[0m and \033[4m$BRANCH_DOWNSTREAM\033[0m from \033[4m$REMOTE\033[0m"
perform  "git fetch $REMOTE $BRANCH_UPSTREAM $BRANCH_DOWNSTREAM"

announce "At \033[4m$REMOTE\033[0m, determining whether \033[4m$BRANCH_DOWNSTREAM\033[0m is already based on latest HEAD of \033[4m$BRANCH_UPSTREAM\033[0m"
# Bash understands the <(COMMAND) syntax, whereas sh does not.
diff <(git merge-base $REMOTE/$BRANCH_UPSTREAM $REMOTE/$BRANCH_DOWNSTREAM) \
     <(git ls-remote $REMOTE $BRANCH_UPSTREAM 2>/dev/null | cut -f 1)      \
     &>/dev/null
if [[ $? -eq 0 ]]; then
  echo -e "\033[32myes\033[0m"
  exit 0
else
  echo -e "\033[31mno\033[0m"
fi

announce "Ensuring working tree is clean"
perform  "git diff --exit-code"

announce "Checking out \033[4m$BRANCH_DOWNSTREAM\033[0m"
perform  "git checkout $BRANCH_DOWNSTREAM"

announce "Forcibly resetting my \033[4m$BRANCH_DOWNSTREAM\033[0m to \033[4m$REMOTE/$BRANCH_DOWNSTREAM\033[0m (was \033[4m`git show $BRANCH_DOWNSTREAM --format=format:%h --no-patch`\033[0m)"
perform  "git reset --hard $REMOTE/$BRANCH_DOWNSTREAM"

announce "Rebasing my \033[4m$BRANCH_DOWNSTREAM\033[0m onto \033[4m$REMOTE/$BRANCH_UPSTREAM\033[0m"
perform  "git rebase $REMOTE/$BRANCH_UPSTREAM $BRANCH_DOWNSTREAM"

announce "Forcibly pushing my \033[4m$BRANCH_DOWNSTREAM\033[0m to \033[4m$REMOTE\033[0m (was \033[4m`git ls-remote $REMOTE $BRANCH_DOWNSTREAM 2>/dev/null | cut -c 1-7`\033[0m)"
perform_discarding_stderr  "git push $REMOTE $BRANCH_DOWNSTREAM --force"

exit 0
