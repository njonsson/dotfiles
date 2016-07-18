#! /usr/bin/env bash

case $1 in
  "" | "--help" | "-h")
    echo Usage:
    echo "  git hotfix-start HOTFIXNAME"
    echo "  git hotfix-start TAG HOTFIXNAME"
    echo "  git hotfix-start --help"
    echo "  git hotfix-start -h"
    exit
    ;;
esac

announce() {
  echo -e -n "*** $1 ... "
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

if [ $2 ]; then
  HOTFIX=$2
  TAG=$1
else
  HOTFIX=$1
  announce "Finding the most recent tag on the current branch"
  perform "git describe --abbrev=0 --tags"
  TAG=$output
fi

announce "Starting a new hotfix \033[4m$HOTFIX\033[0m from \033[4m$TAG\033[0m (\033[4m`git show $TAG --format=format:%h --no-patch`\033[0m)"
perform "git checkout -b $HOTFIX $TAG"

exit 0
