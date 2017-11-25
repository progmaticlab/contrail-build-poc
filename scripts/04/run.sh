#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

echo "INFO: start time $(date)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot

tar -xPf step-3.tgz

pushd "$my_dir"
git clone https://github.com/juniper/contrail-build tools/build
git clone https://github.com/juniper/contrail-vrouter vrouter

ln -s $CONTRAIL_BUILD_DIR build
ln -s $CONTRAIL_BUILDROOT_DIR buildroot

patch -i vrouter.patch vrouter/linux/vr_host_interface.c

scons --root=$CONTRAIL_BUILDROOT_DIR build-kmodule
scons --root=$CONTRAIL_BUILDROOT_DIR install

# TODO: these steps must be in SConscript
mkdir -p build/include/vrouter
cp vrouter/include/*.h build/include/vrouter/
cp vrouter/sandesh/vr.sandesh build/debug/vrouter/sandesh/

rm -rf tools vrouter

popd

tar -czPf step-4.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

echo "INFO: end time $(date)"
