#!/bin/bash -xe

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

export WORKSPACE=${WORKSPACE:-$HOME}
cd $WORKSPACE
export CONTRAIL_BUILD_DIR=$WORKSPACE/build
export CONTRAIL_BUILDROOT_DIR=$WORKSPACE/buildroot

# Preparing Centos 7 for building contrail

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or via sudo"
  exit
fi

mkdir -p $CONTRAIL_BUILD_DIR
mkdir -p $CONTRAIL_BUILDROOT_DIR
OWNUSER=`who am i | awk '{print $1}'`
chown $OWNUSER $CONTRAIL_BUILD_DIR
chown $OWNUSER $CONTRAIL_BUILDROOT_DIR

PACKAGES="autoconf automake bison boost-devel bzip2 cmake cppunit-devel cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib flex gcc gcc-c++ git kernel-devel libcurl-devel libnl-devel libnl3-devel libpcap libpcap-devel libxml2-devel lz4-devel make net-snmp-python openssl-devel patch protobuf protobuf-compiler protobuf-devel python-devel python-lxml python-setuptools python-sphinx rpm-build scons tbb-devel unzip vim wget zlib-devel libtool rpmdevtools tokyocabinet-devel libevent-devel gperf libxml2-python python-virtualenv libxslt-devel"

yum -y install epel-release
yum -y update
yum -y install $PACKAGES

KVD=`rpm -q kernel-devel --queryformat "%{VERSION}-%{RELEASE}.x86_64\n"|sort -n`
a=( ${KVD//./ } )
KV="${a[0]}.${a[1]}.${a[2]}.${a[5]}.${a[6]}"
ln -s /usr/src/kernels/$KVD /usr/src/kernels/$KV

cd $HOME
rpmdev-setuptree
cp "$my_dir/zookeeper.spec" ~/rpmbuild/SPECS/
spectool -g -R ~/rpmbuild/SPECS/zookeeper.spec
rpmbuild -ba ~/rpmbuild/SPECS/zookeeper.spec

rpm -ivh ~/rpmbuild/RPMS/x86_64/libzookeeper-*.rpm

wget http://downloads.datastax.com/cpp-driver/centos/7/dependencies/libuv/v1.8.0/libuv-1.8.0-1.el7.centos.x86_64.rpm
wget http://downloads.datastax.com/cpp-driver/centos/7/dependencies/libuv/v1.8.0/libuv-devel-1.8.0-1.el7.centos.x86_64.rpm
wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-2.4.2-1.el7.centos.x86_64.rpm
wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-devel-2.4.2-1.el7.centos.x86_64.rpm

rpm -ivh cassandra-cpp-*.rpm libuv-*.rpm

git clone https://github.com/edenhill/librdkafka
cd librdkafka/
./configure
make && make install
cd $HOME

wget http://sourceforge.net/projects/libipfix/files/libipfix/libipfix_110209.tgz
tar -xzf libipfix_110209.tgz
cd libipfix_110209
./configure
make && make install
cd $HOME

wget https://github.com/jordansissel/grok/tarball/master -O grok.tar.gz
tar -xzf grok.tar.gz
cd jordansissel-grok-*
make && make install

ldconfig

echo "Contrail build dir set to $CONTRAIL_BUILD_DIR "
echo "Contrail build root dir set to $CONTRAIL_BUILDROOT_DIR "
echo "Reboot the system if kernel has been updated."

tar -czf step-1.tgz $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR
rm -rf $CONTRAIL_BUILD_DIR $CONTRAIL_BUILDROOT_DIR

