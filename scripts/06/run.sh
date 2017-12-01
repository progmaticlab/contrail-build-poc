#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source $my_dir/../common/functions

echo "INFO: start time $(date)"

logdir="$WORKSPACE/logs/build/"
mkdir -p $logdir

export JOBS_COUNT=${JOBS_COUNT:-$(grep -c processor /proc/cpuinfo || echo 1)}
export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-5.tgz

pushd "$my_dir"
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

gitclone https://github.com/juniper/contrail-build tools/build

gitclone https://github.com/juniper/contrail-nova-vif-driver openstack/nova_contrail_vif
#gitclone https://github.com/juniper/contrail-neutron-plugin openstack/neutron_plugin
#gitclone https://github.com/juniper/contrail-nova-extensions openstack/nova_extensions
#gitclone https://github.com/juniper/contrail-heat openstack/contrail-heat
#gitclone https://github.com/juniper/contrail-ceilometer-plugin contrail-ceilometer-plugin

scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR install
scons -j $JOBS_COUNT --root=$CONTRAIL_BUILDROOT_DIR nova-contrail-vif

# these repos are used for building node/npm packages
gitclone https://github.com/juniper/contrail-web-controller $CONTRAIL_BUILD_DIR/src/contrail-web-controller
gitclone https://github.com/juniper/contrail-web-core $CONTRAIL_BUILD_DIR/src/contrail-web-core
gitclone https://github.com/juniper/contrail-webui-third-party $CONTRAIL_BUILD_DIR/src/contrail-webui-third-party
# fetch packages do not initialize node-saas module
pushd $CONTRAIL_BUILD_DIR/src
# controller/src/schema is needed
gitclone https://github.com/juniper/contrail-controller controller
gitclone https://github.com/juniper/contrail-generateDS tools/generateds
pushd contrail-web-core
patch -i $my_dir/web-core.patch dev-install.sh
make package REPO=../contrail-web-controller,webController &> $logdir/rpm-make-contrail-webController.log || echo "ERROR: some errors occured in web-controller build"
make package REPO=../contrail-web-core &> $logdir/rpm-make-contrail-webCore.log || echo "ERROR: some errors occured in web-core build"
popd
popd

rm -rf tools openstack contrail-ceilometer-plugin $CONTRAIL_BUILD_DIR/src/contrail-webui-third-party

popd

tar -czPf step-6.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild/RPMS
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild

echo "INFO: end time $(date)"
