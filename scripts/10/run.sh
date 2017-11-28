#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source $my_dir/../common/functions

echo "INFO: start time $(date)"

logdir="$WORKSPACE/logs/rpm/"
mkdir -p $logdir

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-6.tgz

pushd "$my_dir"
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

gitclone https://github.com/juniper/contrail-packages tools/packages

KVD=`rpm -q kernel-devel --queryformat "%{VERSION}-%{RELEASE}.x86_64\n" | sort -n`
a=(${KVD//./ })
kver="${a[0]}.${a[1]}.${a[2]}.${a[5]}.${a[6]}"
cat >tools/packages/rpm/contrail/dkms.conf.in <<EOF
PACKAGE_NAME=vrouter
PACKAGE_VERSION="__VERSION__"
PRE_BUILD="utils/dkms/gen_build_info.sh __VERSION__ $dkms_tree/vrouter/__VERSION__/build"
MAKE[0]="'make' -C . KERNELDIR=/lib/modules/${kver}/build"
CLEAN[0]="'make' -C . KERNELDIR=/lib/modules/${kver}/build"
BUILT_MODULE_NAME[0]="vrouter"
DEST_MODULE_LOCATION[0]="/kernel/net/vrouter"
AUTOINSTALL="yes"
EOF

CMD="rpmbuild -ba --define '_srcVer ${CONTRAIL_RELEASE:-4.0.0.0}' --define '_buildTag ${CONTRAIL_BUILD:-1}' --define '_sbtop $my_dir' --define '_prebuilddir $CONTRAIL_BUILDROOT_DIR'"
SPEC_DIR="$my_dir/rpm"

# eval must be here. rpmbuild can't manage escaped quotes in defines
eval $CMD \"$SPEC_DIR/contrail.spec\" |& tee $logdir/rpm-contrail.spec

# build other packages:
# TODO: remove all these clones.
# now it's needed for init files.
gitclone https://github.com/juniper/contrail-packaging tools/packaging
# this repo is used for taking another init files
gitclone https://github.com/juniper/contrail-controller controller
# these repos are used for building node/npm packages
gitclone https://github.com/juniper/contrail-web-controller
gitclone https://github.com/juniper/contrail-web-core
gitclone https://github.com/juniper/contrail-webui-third-party
# these items are used to build rpm-s
cp -r contrail-web-controller $HOME/rpmbuild/SOURCES/
cp -r contrail-web-core $HOME/rpmbuild/SOURCES/
# fetch packages do not ini node-saas module
patch -i web-core.patch contrail-web-core/dev-install.sh
# source code for neutron-plugin
gitclone https://github.com/juniper/contrail-neutron-plugin openstack/neutron_plugin

set +e
# contrail-setup
eval $CMD \"$SPEC_DIR/contrail-setup.spec\" |& tee $logdir/rpm-contrail-setup.log
# openstack plugins
for pkg in neutron-plugin-contrail ; do
  eval $CMD \"$SPEC_DIR/$pkg.spec\" |& tee $logdir/rpm-$pkg.log
done
# vrouter
for pkg in vrouter-common vrouter-dpdk vrouter-dpdk-init vrouter-init ; do
  eval $CMD \"$SPEC_DIR/contrail-$pkg.spec\" |& tee $logdir/rpm-contrail-$pkg.log
done
# nodemgr
eval $CMD --define \"_builddir $CONTRAIL_BUILD_DIR\" \"$SPEC_DIR/contrail-nodemgr.spec\" |& tee $logdir/rpm-contrail-nodemgr.log
# webui
pushd contrail-web-core
make package REPO=../contrail-web-controller,webController |& tee $logdir/rpm-contrail-web.log
popd
for pkg in web-controller web-core ; do
  eval $CMD \"$SPEC_DIR/contrail-$pkg.spec\" |& tee $logdir/rpm-contrail-$pkg.log
done
#openstack
for pkg in analytics config config-common control vrouter webui ; do
  eval $CMD --define \"_skuTag $OPENSTACK_VERSION\" \"$SPEC_DIR/contrail-openstack-$pkg.spec\" |& tee $logdir/rpm-contrail-openstack-$pkg.log
done

popd

echo "INFO: end time $(date)"
