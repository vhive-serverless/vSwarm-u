#!/bin/bash

ARCH=X86
GEM5_DIR=gem5/

# Setup on Ubuntu 20.04
sudo apt update
sudo apt install -y build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev python3-six python-is-python3 libboost-all-dev pkg-config


git clone https://gem5.googlesource.com/public/gem5 $GEM5_DIR

pushd $GEM5_DIR

## Build gem5
scons build/$ARCH/gem5.opt -j $(nproc)
popd

###
## Build the terminal
pushd $GEM5_DIR/util/term
make
popd

## the path for x86 is slightly different
if [ $ARCH == X86 ]; then ARCH=x86; fi

## Build m5 tools
pushd $GEM5_DIR/util/m5
scons build/$ARCH/out/m5
popd

export GEM5_DIR=$PWD/$GEM5_DIR

sudo sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> /etc/profile"
sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> $HOME/.bashrc"
