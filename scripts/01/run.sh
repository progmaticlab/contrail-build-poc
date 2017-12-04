#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source $my_dir/../common/functions

echo "INFO: start time $(date)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot

# Preparing Centos 7 for building contrail

mkdir -p $CONTRAIL_BUILD_DIR
mkdir -p $CONTRAIL_BUILDROOT_DIR
rm -rf $HOME/rpmbuild
mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS,TOOLS}
mkdir -p $HOME/rpmbuild/RPMS/x86_64

PACKAGES="autoconf automake bison boost-devel bzip2 cmake cppunit-devel cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib flex gcc gcc-c++ git kernel-devel libcurl-devel libnl-devel libnl3-devel libpcap libpcap-devel libuv libuv-devel libxml2-devel lz4-devel make mock net-snmp-python nodejs openssl-devel patch protobuf protobuf-compiler protobuf-devel python-devel python-lxml python-setuptools python-sphinx rpm-build scons tbb-devel unzip vim wget zlib-devel libtool rpmdevtools tokyocabinet-devel libevent-devel gperf libxml2-python python-virtualenv libxslt-devel"

sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install $PACKAGES

cd $my_dir

# install third-party packages
if ! yum info nodejs | grep -q installed ; then
  mkdir tmp
  pushd tmp
  wget -nv https://s3-us-west-2.amazonaws.com/contrailrhel7/third-party-packages.tgz
  tar -xvf third-party-packages.tgz
  sudo yum install -y nodejs-0.10.35-1contrail.el7.x86_64.rpm
  popd
  rm -rf tmp
fi

KVD=`rpm -q kernel-devel --queryformat "%{VERSION}-%{RELEASE}.x86_64\n" | sort -n`
a=(${KVD//./ })
KV="${a[0]}.${a[1]}.${a[2]}.${a[5]}.${a[6]}"
if [ ! -e "/usr/src/kernels/$KV" ] ; then
  sudo ln -s /usr/src/kernels/$KVD /usr/src/kernels/$KV
fi

# TODO: at first we must only install libzookeeper to the system and do not create rpm file
# at last step we must pack it to rpm and leave in RPMS folder
spectool -g -R ./zookeeper.spec
rpmbuild -ba ./zookeeper.spec
if ! yum info libzookeeper-devel | grep -q installed ; then
  sudo yum install -y $HOME/rpmbuild/RPMS/x86_64/libzookeeper-*.rpm
fi
rm -f $HOME/rpmbuild/RPMS/x86_64/zookeeper*

# TODO: if it is not needed for build then move it to last step. if it is needed then leave here copying to the system only.
spectool -g -R ./python-consistent_hash.spec
rpmbuild -ba ./python-consistent_hash.spec
if ! yum info python-consistent_hash | grep -q installed ; then
  sudo yum install -y $HOME/rpmbuild/RPMS/x86_64/python-consistent_hash-1.0-1.0contrail.x86_64.rpm
fi

# TODO: pass version like ">=2.8 && <2.9" to last step for including to spec file
# and download it again at last step to place it to RPMS folder
wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.7.1/cassandra-cpp-driver-2.7.1-1.el7.centos.x86_64.rpm
wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.7.1/cassandra-cpp-driver-devel-2.7.1-1.el7.centos.x86_64.rpm
cp cassandra-cpp-*.rpm $HOME/rpmbuild/RPMS/x86_64/
if ! yum info cassandra-cpp-driver | grep -q installed ; then
  sudo yum install -y cassandra-cpp-driver*.rpm
fi

git clone https://github.com/edenhill/librdkafka
pushd librdkafka/
./configure
make && sudo make install
# TODO: move these two calls to last step. for ability to it we must copy sources to build/src/
sudo make rpm
cp packaging/rpm/pkgs-0.11.1-1-default/librdkafka1-0.11.1-1.el7.centos.x86_64.rpm $HOME/rpmbuild/RPMS/x86_64/
popd $HOME

wget http://sourceforge.net/projects/libipfix/files/libipfix/libipfix_110209.tgz
tar -xzf libipfix_110209.tgz
pushd libipfix_110209
./configure
make && sudo make install
popd $HOME

# TODO: think about building rpm for these sources at last step
wget https://github.com/jordansissel/grok/tarball/master -O grok.tar.gz
tar -xzf grok.tar.gz
pushd jordansissel-grok-*
make && sudo make install
popd

sudo ldconfig

echo "Contrail build dir set to $CONTRAIL_BUILD_DIR "
echo "Contrail build root dir set to $CONTRAIL_BUILDROOT_DIR "
echo "Reboot the system if kernel has been updated."

cd $WORKSPACE
# TODO: remove packing rpmbuild to cached artifacts !!!
echo "INFO: start packing time $(date)"
tar -czPf step-1.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild/RPMS
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR $HOME/rpmbuild

echo "INFO: end time $(date)"
