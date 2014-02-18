#! /usr/bin/env sh

me=`basename $0`
case $@ in
  "--help"|"-h" )
    echo Usage:
    echo "  $me [FILE ...]"
    exit
    ;;
esac

metadata=`find $1 -ls 2>/dev/null`
if [[ $metadata == "" ]]; then
  echo $me: $1: No such file or directory
  exit -1
fi

current_hash=`echo $metadata | md5`
abs_path_to_arg=$(cd $(dirname $1); pwd)/$(basename $1)
echo $abs_path_to_arg
hash_file=`dirname $abs_path_to_arg`/.`basename $abs_path_to_arg`.$me.md5
echo $hash_file
if [[ -r $hash_file && $current_hash == `cat $hash_file` ]]; then
  exit 0
else
  echo $current_hash > $hash_file
  exit 1
fi
