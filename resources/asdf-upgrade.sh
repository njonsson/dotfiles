#! /usr/bin/env sh

set -o pipefail

printf "*** Updating \e[4masdf\e[24m and its plugins ...\n"
printf "\e[2m"
asdf update                   \
  && printf "\e[0m"           \
  && printf "\e[2m"           \
  && asdf plugin-update --all \
  && printf "\e[0m"           \
  && printf "*** Successfully updated \e[4masdf\e[24m and its plugins\n"

asdf current 2>&1 | while read entry; do
  tool_and_current_version=($entry)
  tool=${tool_and_current_version[0]}
  current_version=${tool_and_current_version[1]}
  latest_version=$(asdf latest $tool)
  if [ -z "$latest_version" ]; then
    printf "*** Current \e[4m$tool\e[24m version "
    printf "(\e[4m$current_version\e[24m) still installed —— "
    printf "no latest version available\n"
    continue
  fi

  if [ "$current_version" = "$latest_version" ]; then
    printf "*** Latest \e[4m$tool\e[24m (\e[4m$latest_version\e[24m) "
    printf "already installed\n"
    continue
  fi

  printf "*** Installing \e[4m$tool\e[24m \e[4m$latest_version\e[24m ...\n"
  printf "\e[2m"
  asdf install $tool $latest_version        \
    && asdf global $tool $latest_version    \
    && printf "\e[0m"                       \
    && printf "*** Successfully installed " \
    && printf "\e[4m$tool\e[24m \e[4m$latest_version\e[24m\n"
done
