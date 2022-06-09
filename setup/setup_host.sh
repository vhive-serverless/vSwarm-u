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

START=$(date +%s.%N)

## Set the path to the directory where
## all resources should be placed
## - gem5
## - kernel
## - base disk image

if [[ -z "${RESOURCES}" ]]; then
  echo "Warning: RESOURCES environmental variable is not set."
  echo "Warning: Will be set to default `resources/`"
  RESOURCES=$ROOT/resources/
  export RESOURCES=$RESOURCES
  sudo sh -c  "echo 'export RESOURCES=${RESOURCES}' >> /etc/profile"
  sudo sh -c  "echo 'export RESOURCES=${RESOURCES}' >> ${HOME}/.bashrc"
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
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
&& sudo apt-get update >> /dev/null \
&& sudo apt-get install -y docker-ce docker-ce-cli containerd.io

## Install also docker compose
sudo apt install -y python3-pip
sudo pip3 install -r ${ROOT}/setup/requirements.txt

# Install golang
wget --continue --quiet https://golang.org/dl/go1.16.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.16.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
sudo sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"
sudo sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> ${HOME}/.bashrc"

source ${HOME}/.bashrc

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
${ROOT}/resources/artifacts.py \
    --file ${ROOT}/resources/release.json \
    --version

${ROOT}/resources/artifacts.py \
    --file ${ROOT}/resources/release.json \
    --download --output ${ROOT}/resources/

END=$(date +%s.%N)
printf "\Download artifacts complete. Took: $(echo "$END - $START" | bc) sec.\n"
