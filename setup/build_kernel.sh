#!/bin/bash

# MIT License
#
# Copyright (c) 2022 David Schall and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Install dependencies

set -e -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( cd $DIR && cd .. && pwd)"


### Build kernel for gem5 supporting running docker images
KVERSION=v5.4.84
OUTDIR=${1:-$ROOT/workload/}

## Install dependencies
sudo apt-get install -y \
    git build-essential ncurses-dev xz-utils libssl-dev bc \
    flex libelf-dev bison

# Get sources
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux
pushd linux
git checkout ${KVERSION}

# Apply the configuration
cp ${ROOT}/configs/linux-configs/${KVERSION}.config .config

## build kernel
make -j $(nproc)

## place in ouput folder
mkdir -p $OUTDIR
cp vmlinux $OUTDIR
popd

## Clean up the linux sources
# rm -rf ../linux

