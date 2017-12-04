#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export OPENSTACK_VERSION=${OPENSTACK_VERSION:-"newton"}
export CONTRAIL_VERSION=${CONTRAIL_VERSION:-"4.2.0.0-1"}
export CONTRAIL_RELEASE=`echo $CONTRAIL_VERSION | cut -d '-' -f 1`
export CONTRAIL_BUILD=`echo $CONTRAIL_VERSION | cut -d '-' -f 2`
export WORKSPACE=${WORKSPACE:-$HOME}
logdir="$WORKSPACE/logs/"
mkdir -p $logdir

test -f $WORKSPACE/reporevisions && rm -f $WORKSPACE/reporevisions
for i in `grep -rh "gitclone" $my_dir/scripts/* | grep -Eo "https://[a-zA-Z0-9./?=_-]*" | sort | uniq` ; do
   r=$(git ls-remote $i refs/heads/master | awk '{print $1}')
   echo "$i $r" >> $WORKSPACE/reporevisions
done

touch $logdir/build.log
for item in '01' '02' '03' '04' '05' '06' '10' '11' ; do
  echo "INFO: start time of step $item  $(date)" | tee -a $logdir/build.log
  cat "$my_dir/scripts/$item/descript.ion" | tee -a $logdir/build.log
  $my_dir/scripts/$item/run.sh
  echo "INFO: end time of step $item  $(date)" | tee -a $logdir/build.log
done
