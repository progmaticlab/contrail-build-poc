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
tar -xPf step-5.tgz

pushd "$my_dir"
tar -xPf step-6-repos.tgz
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

gitclone https://github.com/juniper/contrail-build tools/build

gitclone https://github.com/juniper/contrail-nova-vif-driver openstack/nova_contrail_vif
gitclone https://github.com/juniper/contrail-packaging tools/packaging
gitclone https://github.com/juniper/contrail-controller controller
gitclone https://github.com/juniper/contrail-web-controller
gitclone https://github.com/juniper/contrail-web-core
gitclone https://github.com/juniper/contrail-webui-third-party
# source code for neutron-plugin
gitclone https://github.com/juniper/contrail-neutron-plugin openstack/neutron_plugin
# additional code for contrail-setup package
gitclone https://github.com/Juniper/contrail-provisioning tools/provisioning
gitclone https://github.com/juniper/contrail-packages tools/packages

# fetch packages do not ini node-saas module
patch -i web-core.patch contrail-web-core/dev-install.sh

scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR install
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR nova-contrail-vif

pushd contrail-web-core
make package REPO=../contrail-web-controller,webController |& tee rpm-contrail-web.log
popd

rm -rf tools/build openstack/nova_contrail_vif contrail-ceilometer-plugin
tar -czPf $WORKSPACE/step-6-repos.tgz tools/packaging controller contrail-web-controller contrail-web-core contrail-webui-third-party openstack/neutron_plugin tools/provisioning tools/packages 
rm -rf tools/packaging controller contrail-web-controller contrail-web-core contrail-webui-third-party openstack/neutron_plugin tools/provisioning tools/packages

popd

tar -czPf step-6.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR 
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR 
echo "INFO: end time $(date)"
