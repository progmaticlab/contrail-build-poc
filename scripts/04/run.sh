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

tar -xPf step-3.tgz

pushd "$my_dir"
gitclone https://github.com/juniper/contrail-build tools/build
gitclone https://github.com/juniper/contrail-vrouter vrouter
# TODO: rework to do not use src/contrail-common
gitclone https://github.com/juniper/contrail-common src/contrail-common

test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

patch -i vrouter.patch vrouter/linux/vr_host_interface.c

scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR build-kmodule
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR --opt=production vrouter/dpdk
# needed for vrouter-utils
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR install

# TODO: these steps must be in SConscript
mkdir -p build/include/vrouter
cp vrouter/include/*.h build/include/vrouter/
cp vrouter/sandesh/vr.sandesh build/debug/vrouter/sandesh/

rm -rf tools vrouter src

popd

tar -czPf step-4.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild/RPMS
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild

echo "INFO: end time $(date)"
