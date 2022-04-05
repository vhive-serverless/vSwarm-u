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

## User specific inputs
OUTDIR=${1:-../workload/}

INSTALL_ISO=ubuntu-20.04.3-live-server-amd64.iso
DISK_IMG=base-disk-image.img
DISK_SIZE=4G
RAM=8G
CPUS=4

printf "
=============================
\033[0;32m Build base disk image for gem5 \033[0m
---
INSTALL_ISO: $INSTALL_ISO
Disk size: $DISK_SIZE
Output: $OUTDIR/$DISK_IMG
=============================\n\n"


## Install dependencies
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils wget

if [ $(uname -i) != "x86_64" ] ;
then
 echo "Target platform is not x86"
 exit
fi


## Get and mount Ubuntu 20.04
if [ -f "$INSTALL_ISO" ]; then
    echo "$INSTALL_ISO exists."
else
    echo "$INSTALL_ISO does not exist. Download it..."
    wget https://releases.ubuntu.com/20.04.3/$INSTALL_ISO
    echo "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98 *${INSTALL_ISO}" | shasum -a 256 --check
fi

mkdir -p iso
sudo mount -r $INSTALL_ISO iso

## Serve all files for the setup over a http server.
mkdir -p tmp/
cp -r ${ROOT}/configs/disk-image-configs/* tmp/

## Rename the autoconfig to user-data
mv tmp/autoinstall.yaml tmp/user-data
touch tmp/meta-data
touch tmp/vendor-data

python3 -m http.server -d tmp 3003 &
SERVER_PID=$!


#### Create the disk image
qemu-img create disk.img $DISK_SIZE


## Do the actual installation
# The command will boot from the iso file.
# Then it will listen to port 3003 to retive the autoconfig files.
# If such provided the install process will automatically done for you.
sudo qemu-system-x86_64 \
    -nographic \
    -cpu host -enable-kvm \
    -smp ${CPUS} \
    -m ${RAM} \
    -no-reboot \
    -drive file=disk.img,format=raw \
    -cdrom $INSTALL_ISO \
    -kernel iso/casper/vmlinuz \
    -initrd iso/casper/initrd \
    -append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'

## To get the full output of the install process add
## 'earlyprintk=ttyS0 console=ttyS0 lpj=7999923' to the
## kernel commands (-append flag)

echo "Ubuntu installed on disk image"

## Cleanup everything
kill "$SERVER_PID"

sudo umount iso
rm -r iso *.iso tmp


# Move the final ready to use disk image to the workload folder
mkdir -p $OUTDIR
mv disk.img $OUTDIR/$DISK_IMG


