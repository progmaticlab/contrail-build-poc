#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export WORKSPACE=$(pwd)

if [ ! -f $WORKSPACE/reporevisions ] ; then
  for i in `grep -rh "gitclone" $my_dir/scripts/* | grep -Eo "https://[a-zA-Z0-9./?=_-]*" | sort | uniq` ; do
    r=$(git ls-remote $i refs/heads/master | awk '{print $1}')

    # for cloned repos we can get SHA by date:
    #pushd $(echo $i | awk -F"/" 'NF>1{print $NF}')
    #r=$(git rev-list -n 1 --before="2017-12-10 00:00:00" master)
    #popd

    echo "$i $r" >> $WORKSPACE/reporevisions
  done
fi
