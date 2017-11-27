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

PACKAGES="autoconf automake bison boost-devel bzip2 cmake cppunit-devel cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib flex gcc gcc-c++ git kernel-devel libcurl-devel libnl-devel libnl3-devel libpcap libpcap-devel libuv libuv-devel libxml2-devel lz4-devel make net-snmp-python nodejs openssl-devel patch protobuf protobuf-compiler protobuf-devel python-devel python-lxml python-setuptools python-sphinx rpm-build scons tbb-devel unzip vim wget zlib-devel libtool rpmdevtools tokyocabinet-devel libevent-devel gperf libxml2-python python-virtualenv libxslt-devel"

sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install $PACKAGES

KVD=`rpm -q kernel-devel --queryformat "%{VERSION}-%{RELEASE}.x86_64\n" | sort -n`
a=(${KVD//./ })
KV="${a[0]}.${a[1]}.${a[2]}.${a[5]}.${a[6]}"
if [ ! -e "/usr/src/kernels/$KV" ] ; then
  sudo ln -s /usr/src/kernels/$KVD /usr/src/kernels/$KV
fi

cd $my_dir
if ! yum info libzookeeper-devel | grep installed ; then
  # rpmbuild is always created in $HOME
  rpmdev-setuptree
  spectool -g -R ./zookeeper.spec
  rpmbuild -ba ./zookeeper.spec
  sudo rpm -ivh $HOME/rpmbuild/RPMS/x86_64/libzookeeper-*.rpm
  rm -rf $HOME/rpmbuild
fi

wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-2.4.2-1.el7.centos.x86_64.rpm
wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-devel-2.4.2-1.el7.centos.x86_64.rpm
sudo rpm -ivh cassandra-cpp-*.rpm 

git clone https://github.com/edenhill/librdkafka
pushd librdkafka/
./configure
make && sudo make install
popd $HOME

wget http://sourceforge.net/projects/libipfix/files/libipfix/libipfix_110209.tgz
tar -xzf libipfix_110209.tgz
pushd libipfix_110209
./configure
make && sudo make install
popd $HOME

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
tar -czPf step-1.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

echo "INFO: end time $(date)"
