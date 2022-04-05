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

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( cd $DIR && cd .. && pwd)"


ARCH=X86
GEM5_DIR=${1:-$ROOT/gem5/}

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "
=============================
${GREEN}  Build gem5 ${NC}
---
Architecture: $ARCH
Output: $GEM5_DIR
=============================\n\n"



# Setup on Ubuntu 20.04
sudo apt update
sudo apt install -y build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev python3-six python-is-python3 libboost-all-dev pkg-config


git clone https://gem5.googlesource.com/public/gem5 $GEM5_DIR

pushd $GEM5_DIR

## Build gem5
scons build/$ARCH/gem5.opt -j $(nproc) --install-hooks
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

# Export absolute path
export GEM5_DIR=$GEM5_DIR

sudo sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> /etc/profile"
sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> $HOME/.bashrc"
