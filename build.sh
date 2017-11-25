#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

touch $HOME/build.log
for item in '01' '02' '03' '04' '05' '06' '10' ; do
  echo "INFO: start time of step $item  $(date)" | tee -a $HOME/build.log
  cat $my_dir/scripts/$item/descript.ion | tee -a $HOME/build.log
  $my_dir/scripts/$item/run.sh
  echo "INFO: end time of step $item  $(date)" | tee -a $HOME/build.log
done
