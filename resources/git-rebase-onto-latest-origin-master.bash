#! /usr/bin/env bash

case $1 in
  "" | "--help" | "-h")
    echo Usage:
    echo "  git rebase-onto-latest-origin-master BRANCH"
    echo "  git rebase-onto-latest-origin-master --help"
    echo "  git rebase-onto-latest-origin-master -h"
    exit
    ;;
esac

BRANCH=$1

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
    echo -e "\033[31mERROR!\033[0m"
    echo -e "$output" >&2
    exit $result
  fi
}

announce "Fetching \033[4mmaster\033[0m and \033[4m$BRANCH\033[0m from \033[4morigin\033[0m"
perform  "git fetch origin master $BRANCH"

announce "At \033[4morigin\033[0m, determining whether \033[4m$BRANCH\033[0m is already based on latest HEAD of \033[4mmaster\033[0m"
# Bash understands the <(COMMAND) syntax, whereas sh does not.
diff <(git merge-base origin/master origin/$BRANCH) \
     <(git ls-remote origin master | cut -f 1)      \
     >/dev/null                                     \
     2>&1
if [[ $? -eq 0 ]]; then
  echo -e "\033[32mYES\033[0m"
  exit 0
else
  echo -e "\033[31mNO\033[0m"
fi

announce "Ensuring working tree is clean"
perform  "git diff --exit-code"

announce "Checking out \033[4m$BRANCH\033[0m"
perform  "git checkout $BRANCH"

announce "Forcibly resetting my \033[4m$BRANCH\033[0m to \033[4morigin/$BRANCH\033[0m (was \033[4m`git show $BRANCH --format=format:%h --no-patch`\033[0m)"
perform  "git reset --hard origin/$BRANCH"

announce "Rebasing my \033[4m$BRANCH\033[0m onto \033[4morigin/master\033[0m"
perform  "git rebase origin/master $BRANCH"

announce "Forcibly pushing my \033[4m$BRANCH\033[0m to \033[4morigin\033[0m (was \033[4m`git ls-remote origin $BRANCH | cut -c 1-7`\033[0m)"
perform  "git push origin $BRANCH --force"

exit 0
