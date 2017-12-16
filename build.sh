#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

xport OPENSTACK_VERSION=${OPENSTACK_VERSION:-"newton"}
export CONTRAIL_VERSION=${CONTRAIL_VERSION:-"4.2.0.0-1"}
export CONTRAIL_RELEASE=`echo $CONTRAIL_VERSION | cut -d '-' -f 1`
export CONTRAIL_BUILD=`echo $CONTRAIL_VERSION | cut -d '-' -f 2`
export WORKSPACE=${WORKSPACE:-$HOME}
logdir="$WORKSPACE/logs/"
mkdir -p $logdir

if [ -f $my_dir/reporevisions ] ; then
  # use predefined file
  cp $my_dir/reporevisions $WORKSPACE/reporevisions
else
  # else freeze state for now
  for i in `grep -rh "gitclone" $my_dir/scripts/* | grep -Eo "https://[a-zA-Z0-9./?=_-]*" | sort | uniq` ; do
    r=$(git ls-remote $i refs/heads/master | awk '{print $1}')

    # for cloned repos we can get SHA by date:
    #pushd $(echo $i | awk -F"/" 'NF>1{print $NF}')
    #r=$(git rev-list -n 1 --before="2017-12-10 00:00:00" master)
    #popd

    echo "$i $r" >> $WORKSPACE/reporevisions
  done
fi

touch $logdir/build.log
for item in '01' '02' '03' '04' '05' '06' '10' '11' ; do
  echo "INFO: start time of step $item  $(date)" | tee -a $logdir/build.log
  cat "$my_dir/scripts/$item/descript.ion" | tee -a $logdir/build.log
  $my_dir/scripts/$item/run.sh
  echo "INFO: end time of step $item  $(date)" | tee -a $logdir/build.log
done