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

if [ $(uname -i) == "aarch64" ];
then
    ARCH=arm64
else
    ARCH=amd64
fi

START=$(date +%s.%N)

## Set the path to the directory where
## all resources should be placed
## - gem5
## - kernel
## - base disk image

if [[ -z "${RESOURCES}" ]]; then
  echo "Warning: RESOURCES environmental variable is not set."
  echo "Warning: Will be set to the default `resources/` in this repo"
  RESOURCES=$ROOT/resources/
  export RESOURCES=$RESOURCES
  sudo sh -c  "echo 'export RESOURCES=${RESOURCES}' >> /etc/profile"
  sudo sh -c  "echo 'export RESOURCES=${RESOURCES}' >> ${HOME}/.bashrc"
fi

if [[ -z "${GEM5_DIR}" ]]; then
  echo "Warning: GEM5_DIR environmental variable is not set."
  echo "Warning: Will be set to the default `resources/` in this repo"
  GEM5_DIR=$ROOT/resources/gem5/
  export GEM5_DIR=$GEM5_DIR
  sudo sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> /etc/profile"
  sudo sh -c  "echo 'export GEM5_DIR=${GEM5_DIR}' >> ${HOME}/.bashrc"
fi

echo "Install all resources to: ${RESOURCES}"

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update >> /dev/null
sudo apt-get -y upgrade

END=$(date +%s.%N)
echo "Took now:" $(echo "$END - $START" | bc)

# Install docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
&& sudo apt-get update >> /dev/null \
&& sudo apt-get install -y docker-ce docker-ce-cli containerd.io

## Install also docker compose
sudo apt install -y python3-pip
sudo pip3 install -r ${ROOT}/setup/requirements.txt

## Install qemu
make -f ${ROOT}/setup/disk.Makefile dep_install


# Install golang
GO_VERSION=1.21.4
GO_BUILD="go${GO_VERSION}.linux-${ARCH}"

wget --continue https://golang.org/dl/${GO_BUILD}.tar.gz

sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf ${GO_BUILD}.tar.gz
rm ${GO_BUILD}.tar.gz

export PATH=$PATH:/usr/local/go/bin
sudo sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"
sudo sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> ${HOME}/.bashrc"

source ${HOME}/.bashrc
echo "Installed: $(go version)"

END=$(date +%s.%N)
printf "\nInstalling dependencies completed successfully after: $(echo "$END - $START" | bc) sec.\n"



## Now prepare the base setup to run the functions.
START=$(date +%s.%N)
echo "Build gem5..."
make -f ${ROOT}/setup/gem5.Makefile dep_install
make -f ${ROOT}/setup/gem5.Makefile all

END=$(date +%s.%N)
printf "\nBuilding gem5 completed after: $(echo "$END - $START" | bc) sec.\n"


## Download the most recent release artifacts
START=$(date +%s.%N)
echo "Download Release artifacts from: "

${ROOT}/resources/artifacts.py --output ${ROOT}/resources/

END=$(date +%s.%N)
printf "\nDownload artifacts complete. Took: $(echo "$END - $START" | bc) sec.\n"
