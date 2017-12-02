#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source $my_dir/../common/functions

echo "INFO: start time $(date)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE

pushd "$my_dir"

export CONTRAIL_INSTALL_PACKAGES_URL="$WORKSPACE/contrail-install-packages-$CONTRAIL_VERSION-$OPENSTACK_VERSION.tgz"

gitclone https://github.com/juniper/contrail-container-builder

pushd contrail-container-builder/containers
./setup-for-build.sh
echo "INFO: Run build  $(date)"
sudo -E ./build.sh || /bin/true
sudo docker images | grep "$CONTRAIL_VERSION"
popd

popd

echo "INFO: end time $(date)"
