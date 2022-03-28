#!/bin/bash


### Build kernel for gem5 supporting running docker images
KVERSION=5.4.84
TARGET_DIR=../workload/

git build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
sudo apt-get install -y libncurses5-dev \
                        gcc make git exuberant-ctags bc libssl-dev

# Get sources
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux
pushd linux
git checkout v${KVERSION}

# Apply the configuration
cp ../configs/linux-${KVERSION}.config .config

## build kernel
make -j $(nproc)

## place in ouput folder
mkdir -p $TARGET_DIR
cp vmlinux $TARGET_DIR
popd

## Clean up the linux sources
# rm -rf ../linux

