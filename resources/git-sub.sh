#! /usr/bin/env sh

find=$1
replace=$2
for file in $(git grep --name-only "$find")
do
  sed -i '' "s/$find/$replace/g" $file
done
