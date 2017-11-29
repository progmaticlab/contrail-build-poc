#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

CONTRAIL_VERSION=${CONTRAIL_VERSION:-"4.0.2.0-35"}
export CONTRAIL_RELEASE=`echo $CONTRAIL_VERSION | cut -d '-' -f 1`
export CONTRAIL_BUILD=`echo $CONTRAIL_VERSION | cut -d '-' -f 2`
export WORKSPACE=${WORKSPACE:-$HOME}

test -f $WORKSPACE/reporevisions && rm -f $WORKSPACE/reporevisions
for i in `grep -rh "gitclone" $my_dir/scripts/* | grep -Eo "https://[a-zA-Z0-9./?=_-]*" | sort | uniq` ; do
   r=$(git ls-remote $i refs/heads/master | awk '{print $1}')
   echo "$i $r" >> $HOME/reporevisions
done
#mv $HOME/reporevisions $HOME/reporevisions.bak
#cp $my_dir/reporevisions-4.1 $HOME/reporevisions
#echo "INFO: Repo revisions diff for now for R4.1"
#diff $HOME/reporevisions.bak $HOME/reporevisions || /bin/true

touch $HOME/build.log
for item in '01' '02' '03' '04' '05' '06' '10' ; do
  echo "INFO: start time of step $item  $(date)" | tee -a $HOME/build.log
  cat "$my_dir/scripts/$item/descript.ion" | tee -a $HOME/build.log
  $my_dir/scripts/$item/run.sh
  echo "INFO: end time of step $item  $(date)" | tee -a $HOME/build.log
done
