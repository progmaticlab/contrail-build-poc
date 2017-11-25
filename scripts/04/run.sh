#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

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

mkdir -p build/debug/tools/sandesh/library/c/protocol
mkdir -p build/debug/tools/sandesh/library/c/transport
cp src/contrail-common/sandesh/library/c/protocol/*.c  build/debug/tools/sandesh/library/c/protocol/
cp src/contrail-common/sandesh/library/c/transport/*.c  build/debug/tools/sandesh/library/c/transport/
cp src/contrail-common/sandesh/library/c/*.c  build/debug/tools/sandesh/library/c/
cp src/contrail-common/sandesh/library/c/*.h  build/debug/tools/sandesh/library/c/
mkdir -p build/include/vrouter

patch -i vrouter.patch vrouter/linux/vr_host_interface.c

scons --root=$CONTRAIL_BUILDROOT_DIR build-kmodule

# TODO: these steps must be in SConscript
cp vrouter/include/*.h build/include/vrouter/
cp vrouter/sandesh/vr.sandesh build/debug/vrouter/sandesh/

rm -rf tools vrouter

popd

tar -czPf step-4.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

