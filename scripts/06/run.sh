#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-5.tgz

pushd "$my_dir"
ln -s $CONTRAIL_BUILD_DIR build
ln -s $CONTRAIL_BUILDROOT_DIR buildroot

git clone https://github.com/juniper/contrail-build tools/build

scons --root=$CONTRAIL_BUILDROOT_DIR install
scons --root=$CONTRAIL_BUILDROOT_DIR nova-contrail-vif

popd

tar -czPf step-6.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

