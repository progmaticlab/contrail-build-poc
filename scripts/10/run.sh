#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

echo "INFO: start time $(date)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot
tar -xPf step-6.tgz

pushd "$my_dir"
test -L "./build" || ln -s $CONTRAIL_BUILD_DIR build
test -L "./buildroot" || ln -s $CONTRAIL_BUILDROOT_DIR buildroot

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

rpmbuild -ba --define "_srcVer 4.0.1" --define "_buildTag 1" --define "_sbtop $(pwd)" --define "_prebuilddir $CONTRAIL_BUILDROOT_DIR" "$my_dir/rpm/contrail.spec"

# build other packages:
# TODO: remove this clone. now it's needed for init files.
git clone https://github.com/juniper/contrail-packaging tools/packaging
git clone https://github.com/juniper/contrail-controller controller

set +x
logdir="$WORKSPACE/log"
mkdir -p $logdir

CMD="rpmbuild -ba --define '_srcVer 4.0.1' --define '_buildTag 1' --define '_sbtop $(pwd)' --define '_prebuilddir $CONTRAIL_BUILDROOT_DIR'"
SPEC_DIR="$my_dir/rpm"
# openstack plugins
for pkg in neutron-plugin-contrail ; do
  $CMD "$SPEC_DIR/$pkg.spec" &> $logdir/rpm-$pkg.log
done
# vrouter
for pkg in vrouter-common vrouter-dpdk vrouter-dpdk-init vrouter-init ; do
  $CMD "$SPEC_DIR/contrail-$pkg.spec" &> $logdir/rpm-contrail-$pkg.log
done
# nodemgr
$CMD --define "_builddir $CONTRAIL_BUILD_DIR" "$SPEC_DIR/contrail-nodemgr.spec" &> $logdir/rpm-contrail-nodemgr.log
# webui
for pkg in web-controller web-core ; do
  $CMD "$SPEC_DIR/contrail-$pkg.spec" &> $logdir/rpm-contrail-$pkg.log
done
#openstack
for pkg in analytics config config-common control vrouter webui ; do
  $CMD "$SPEC_DIR/contrail-openstack-$pkg.spec" &> $logdir/rpm-contrail-openstack-$pkg.log
done

popd

echo "INFO: end time $(date)"
