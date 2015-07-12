#! /usr/bin/env sh

set -o pipefail

display_usage() {
  printf "Usage: $(basename $0) [--help|-h] [--verbose|-v] [REMOTE] [BRANCH]\n"
}

fetch_local_commit_hash() {
  local result=$(git show --format=%H --no-patch "$remote/$branch" 2>/dev/null)
  if [ $? -eq 0 ]; then
    printf "$result"
    return
  fi

  printf "\033[31mError!\033[0m " >&2
  git show --format=%H --no-patch "$remote/$branch" 2>&1 | head -1
  return 3
}

fetch_remote_commit_hash() {
  git ls-remote --exit-code "$remote" "$branch" &>/dev/null
  if [ $? -eq 0 ]; then
    git ls-remote "$remote" "$branch" | cut -f1
    return
  fi

  printf "\033[31mError!\033[0m " >&2
  local error=$(git ls-remote "$remote" "$branch" 2>&1)
  if [ "$error" == '' ]; then
    local error="no branch \033[4m$branch\033[0m on remote \033[4m$remote\033[0m"
  fi
  printf "$error\n" >&2
  return 2
}

main() {
  parse_arguments "$@"

  # Using `local` always sets `$?` to 0, so work around that.
  _result=$(fetch_remote_commit_hash)
  local status=$?
  local remote_commit_hash="$_result"
  unset _result

  if [ $status -ne 0 ]; then
    exit $status
  fi

  # Using `local` always sets `$?` to 0, so work around that.
  _result=$(fetch_local_commit_hash)
  local status=$?
  local local_commit_hash="$_result"
  unset _result

  if [ $status -ne 0 ]; then
    exit $status
  fi

  if [ "$remote_commit_hash" == "$local_commit_hash" ]; then
    printf "\033[32mOK\033[0m"
    if [ "$VERBOSE" == 'true' ]; then
      printf " because \033[4m$remote\033[0m’s $remote_commit_hash == \033[4m$branch\033[0m’s"
    fi
    printf "\n"
    exit 0
  else
    printf "\033[31mFetch required\033[0m"
    if [ "$VERBOSE" == 'true' ]; then
      printf " because \033[4m$remote\033[0m’s $remote_commit_hash != local $local_commit_hash"
    fi
    printf "\n"
    exit 1
  fi
}

parse_arguments() {
  for argument in $@; do
    case "$argument" in
      --help | -h)
        display_usage
        exit 0
        ;;
      --verbose | -v)
        VERBOSE=true
        ;;
      *)
        if [ "$branch" == '' ]; then
          branch="$argument"
        elif [ "$remote" == '' ]; then
          remote="$branch"
          branch="$argument"
        else
          display_usage
          exit -1
        fi
        ;;
    esac
  done

  if [ "$remote" == '' ]; then
    remote=origin
  fi

  if [ "$branch" == '' ]; then
    branch="$(git rev-parse --abbrev-ref HEAD)"
    if [ "$branch" == 'HEAD' ]; then
      printf "\033[31mNo branch appears to be checked out\033[0m\n" >&2
      exit 4
    fi
  fi
}

main "$@"
