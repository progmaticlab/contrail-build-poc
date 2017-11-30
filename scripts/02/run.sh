#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source $my_dir/../common/functions

echo "INFO: start time $(date)"

export JOBS_COUNT=${JOBS_COUNT:-$(grep -c processor /proc/cpuinfo || echo 1)}
export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot

tar -xPf step-1.tgz

pushd "$my_dir"
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR ./build
test -L "./buildroot" ||  ln -s $CONTRAIL_BUILDROOT_DIR ./buildroot
test -L "./third_party" || ln -s contrail-third-party ./third_party

python contrail-third-party/fetch_packages.py
# TODO: i think only install target is needed - check it
scons -j $JOBS_COUNT
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR install

mkdir -p $CONTRAIL_BUILD_DIR/third_party/fysom-1.0.8/fysom
cp third_party/fysom-1.0.8/fysom/__init__.py build/third_party/fysom-1.0.8/fysom/
cp -r third_party/go build/third_party/
cp -r third_party/cni_go_deps build/third_party/

popd
tar -czPf step-2.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild/RPMS
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild

echo "INFO: end time $(date)"
