#!/bin/bash


### Build kernel for gem5 supporting running docker images
KVERSION=5.4.84

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
cp vmlinux ../workload/
popd

## Clean up the linux sources
# rm -rf ../linux

