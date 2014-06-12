#! /usr/bin/env bash

case $1 in
  "--help" | "-h")
    echo Usage:
    echo "  git rebase-onto-latest-origin-master"
    echo "  git rebase-onto-latest-origin-master BRANCH"
    echo "  git rebase-onto-latest-origin-master --help"
    echo "  git rebase-onto-latest-origin-master -h"
    exit
    ;;
esac

announce() {
  echo -n "*** $1 ... "
}

git_current_branch() {
  git rev-parse --abbrev-ref HEAD
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

BRANCH=$1
if [ -z $BRANCH ]; then
  BRANCH=$(git_current_branch)
fi

announce "Determining whether my $BRANCH has unpushed commits"
if [ `git ls-remote origin $BRANCH | cut -f 1` == \
     `git show $BRANCH --format=format:%H --no-patch` ]; then
  echo -e "\033[32mNO\033[0m"
else
  echo -e "\033[31mYES\033[0m"
  exit 1
fi

announce "Fetching master and $BRANCH from origin"
perform  "git fetch origin master $BRANCH"

announce "At origin, determining whether $BRANCH is already based on latest HEAD of master"
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

if [ "$BRANCH" != git_current_branch ]; then
  announce "Checking out $BRANCH"
  perform  "git checkout $BRANCH"
fi

announce "Forcibly resetting my $BRANCH to origin/$BRANCH (was `git show $BRANCH --format=format:%h --no-patch`)"
perform  "git reset --hard origin/$BRANCH"

announce "Rebasing my $BRANCH onto origin/master"
perform  "git rebase origin/master $BRANCH"

announce "Forcibly pushing my $BRANCH to origin (was `git ls-remote origin $BRANCH | cut -c 1-7`)"
perform  "git push origin $BRANCH --force"

exit 0
