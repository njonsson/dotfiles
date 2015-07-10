#! /usr/bin/env sh

find="$1"
replace="$2"
echo "Replacing all occurrences of '$find' with '$replace'"
for file in $(git grep --name-only "$find")
do
  sed -i '' "s/$find/$replace/g" "$file"
done
