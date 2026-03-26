#!/usr/bin/env bash
export YCSB_HOME=/mnt/kvs/YCSB
export PEBBLESDB_HOME=/mnt/kvs/pebblesdb
export PEBBLESDBJNI_HOME=/mnt/kvs/pebblesdbjni
export SNAPPY_HOME=/usr/lib/x86_64-linux-gnu
export PLATFORM=linux64

# apply pebblesdb patch (makes Slice members public for JNI access, adds -fPIC)
pushd $PEBBLESDB_HOME
git apply $PEBBLESDBJNI_HOME/pebblesdb.patch 2>/dev/null || true

# build pebblesdb
mkdir -p build
pushd build
cmake ..
make -j 16
popd
popd

# setup and build jni
pushd $PEBBLESDBJNI_HOME
./setup.sh

# LEVELDB_HOME must point to the local copy created by setup.sh
export LEVELDB_HOME=$PEBBLESDBJNI_HOME/pebblesdb
mvn clean install -P download -P $PLATFORM
popd

# rm old libs
rm -rf $YCSB_HOME/pebblesdb/lib
mkdir -p $YCSB_HOME/pebblesdb/lib
cp $PEBBLESDBJNI_HOME/leveldbjni/target/*.jar $YCSB_HOME/pebblesdb/lib
cp $PEBBLESDBJNI_HOME/leveldbjni-$PLATFORM/target/*.jar $YCSB_HOME/pebblesdb/lib
mvn -pl site.ycsb:pebblesdb-binding -am clean package
