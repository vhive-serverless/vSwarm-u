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
ROOT="$( cd $DIR && cd ../.. && pwd)"


## Set the path to the directory where
## all resources should be placed
## - gem5
## - kernel
## - base disk image

if [[ -z "${RESOURCES}" ]]; then
  echo "Warning: RESOURCES environmental variable is not set."
  echo "Warning: Will be set to default `resources/`"
  RESOURCES=$ROOT/resources/
  mkdir -p $RESOURCES
  export RESOURCES=$RESOURCES
  sudo sh -c  "echo 'export RESOURCES=${RESOURCES}' >> /etc/profile"
fi

echo "Install all resources to: ${RESOURCES}"

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update >> /dev/null
sudo apt-get -y upgrade



# Install docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
&& sudo apt-get update \
&& sudo apt-get install -y docker-ce docker-ce-cli containerd.io


# Install golang
wget --continue --quiet https://golang.org/dl/go1.16.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.16.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
sudo sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"

source /etc/profile

## Now prepare the base setup to run the functions.

echo "Build Kernel..."
make -f ${ROOT}/setup/kernel.Makefile dep_install
make -f ${ROOT}/setup/kernel.Makefile build
make -f ${ROOT}/setup/kernel.Makefile save

echo "Build gem5..."
make -f ${ROOT}/setup/gem5.Makefile dep_install
make -f ${ROOT}/setup/gem5.Makefile all

echo "Build disk image..."
make -f ${ROOT}/setup/disk.Makefile dep_install
make -f ${ROOT}/setup/disk.Makefile download
make -f ${ROOT}/setup/disk.Makefile install
make -f ${ROOT}/setup/disk.Makefile save

make -f ${ROOT}/setup/disk.Makefile clean

# Build the test client
pushd ${ROOT}/tools/
make test-client
cp client/test-client ${RESOURCES}/test-client
popd


