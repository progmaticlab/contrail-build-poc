#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

echo "INFO: start time $(date)"

export JOBS_COUNT=${JOBS_COUNT:-$(grep -c processor /proc/cpuinfo || echo 1)}
export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-5.tgz

pushd "$my_dir"
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

git clone https://github.com/juniper/contrail-build tools/build

git clone https://github.com/juniper/contrail-nova-vif-driver openstack/nova_contrail_vif
git clone https://github.com/juniper/contrail-neutron-plugin openstack/neutron_plugin
#git clone https://github.com/juniper/contrail-nova-extensions openstack/nova_extensions
#git clone https://github.com/juniper/contrail-heat openstack/contrail-heat
#git clone https://github.com/juniper/contrail-ceilometer-plugin contrail-ceilometer-plugin

scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR install
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR nova-contrail-vif

rm -rf tools openstack contrail-ceilometer-plugin

popd

tar -czPf step-6.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

echo "INFO: end time $(date)"
