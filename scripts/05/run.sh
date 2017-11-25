#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-4.tgz

pushd "$my_dir"
git clone https://github.com/juniper/contrail-build tools/build
git clone https://github.com/juniper/contrail-common src/contrail-common
git clone https://github.com/juniper/contrail-controller
git clone https://github.com/juniper/contrail-generateDS tools/generateds

ln -s $CONTRAIL_BUILD_DIR build
ln -s $CONTRAIL_BUILDROOT_DIR buildroot

mkdir -p third_party
ln -s ../build/third_party/go third_party/go
ln -s ../build/third_party/cni_go_deps third_party/cni_go_deps

scons --root=$CONTRAIL_BUILDROOT_DIR install

popd

tar -czPf step-5.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

