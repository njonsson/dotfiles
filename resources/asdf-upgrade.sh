#! /usr/bin/env sh

set -Eeuo pipefail

printf "Updating \e[4masdf\e[24m and its plugins ...\n"              \
  && printf "\e[2m"                                                  \
  && asdf update                                                     \
  && printf "\e[0m"                                                  \
  && printf "\e[2m"                                                  \
  && asdf plugin-update --all                                        \
  && printf "\e[0m"                                                  \
  && printf "Successfully updated \e[4masdf\e[24m and its plugins\n" \
  && asdf current 2>&1 | while read entry; do
    tool_and_current_v=($entry)
    tool=${tool_and_current_v[0]}
    current_v=${tool_and_current_v[1]}
    latest_v=$(asdf latest $tool)
    if [ -z "$latest_v" ]; then
      latest_v=$(asdf latest $tool $current_v)
    fi
    if [ -z "$latest_v" ]; then
      printf "Current \e[4m$tool\e[24m version (\e[4m$current_v\e[24m) "
      printf "is still installed —— no latest version available\n"
      continue
    fi

    if [ "$current_v" = "$latest_v" ]; then
      printf "Latest \e[4m$tool\e[24m (\e[4m$latest_v\e[24m) is "
      printf "already installed\n"
      continue
    fi

    printf "Installing \e[4m$tool\e[24m \e[4m$latest_v\e[24m ...\n" \
      && printf "\e[2m"                                             \
      && asdf install $tool $latest_v                               \
      && asdf global $tool $latest_v                                \
      && printf "\e[0m"                                             \
      && printf "Successfully installed "                           \
      && printf "\e[4m$tool\e[24m \e[4m$latest_v\e[24m\n"           \
      || break
  done
printf "\e[0m"
