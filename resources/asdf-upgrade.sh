#! /usr/bin/env sh

set -o pipefail

printf "*** Updating \e[3masdf\e[23m ...\n"
printf "\e[2m"
asdf update \
  && asdf plugin-update --all \
  && printf "\e[22m" \
  && printf "*** Successfully updated \e[3masdf\e[23m\n"

echo "\n*** Listing available Elixir versions ..."
# Include only versions rather than branches.
# Exclude release-candidate versions.
asdf list-all elixir \
  | grep '^\d' \
  | grep --invert-match '\brc\b' \
  | tail -3

echo "\n*** Listing available Erlang versions ..."
asdf list-all erlang \
  | tail -3

echo "\n*** Listing available Java versions ..."
asdf list-all java \
  | grep oracle \
  | tail -3

echo "\n*** Listing available Ruby versions ..."
# Include only MRI versions.
asdf list-all ruby \
  | grep --extended-regexp --line-regexp '[0-9.]+' \
  | tail -3

echo "\n*** Listing available Rust versions ..."
asdf list-all rust \
  | tail -3

printf "\n*** Active versions via \e[3masdf\e[23m:\n"
asdf current
