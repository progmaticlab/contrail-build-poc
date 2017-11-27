#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

CONTRAIL_VERSION=${CONTRAIL_VERSION:-"4.0.2.0-35"}
export CONTRAIL_RELEASE=`echo $CONTRAIL_VERSION | cut -d '-' -f 1`
export CONTRAIL_BUILD=`echo $CONTRAIL_VERSION | cut -d '-' -f 2`

test -f $my_dir/reporevisions && rm -f reporevisions
for i in `grep -rh "gitclone" scripts/* | grep -Eo "https://[a-zA-Z0-9./?=_-]*" | sort | uniq` ; do
   r=$(git ls-remote $i refs/heads/master | awk '{print $1}')
   echo "$i $r" >> $my_dir/reporevisions
done

touch $HOME/build.log
for item in '01' '02' '03' '04' '05' '06' '10' ; do
  echo "INFO: start time of step $item  $(date)" | tee -a $HOME/build.log
  cat "$my_dir/scripts/$item/descript.ion" | tee -a $HOME/build.log
  $my_dir/scripts/$item/run.sh
  echo "INFO: end time of step $item  $(date)" | tee -a $HOME/build.log
done
