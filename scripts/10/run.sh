#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-6.tgz

pushd "$my_dir"
ln -s $CONTRAIL_BUILD_DIR build
ln -s $CONTRAIL_BUILDROOT_DIR buildroot

git clone https://github.com/e-kuznetsov/build-contrail-rpms.git
git clone https://github.com/juniper/contrail-packages tools/packages

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

rpmbuild -ba --define "_srcVer 4.0.1" --define "_buildTag 1" --define "_sbtop $(pwd)" --define "_prebuilddir $CONTRAIL_BUILDROOT_DIR" "$my_dir/contrail.spec"

popd
