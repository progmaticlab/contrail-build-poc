#!/bin/bash

if test -z "$1"
 then
  CONTRAIL_BUILD_DIR="/usr/local/src/contrail/build"
 else
  CONTRAIL_BUILD_DIR="$1"
fi

if test ! -d "$CONTRAIL_BUILD_DIR"
 then
  echo "Build dir not found"
  exit 1
 else
  if test ! -L "./build"
   then
    ln -s $CONTRAIL_BUILD_DIR ./build
  fi
fi

if test ! -L "./third_party"
 then
  ln -s contrail-third-party third_party
fi

python contrail-third-party/fetch_packages.py
scons -j ${JOBS_COUNT:-$(grep -c processor /proc/cpuinfo || echo 1)}
