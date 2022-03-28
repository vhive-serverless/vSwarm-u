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


DISK_IMG=${1:-$ROOT/workload/disk-image.img}
KERNEL=${2:-$ROOT/workload/vmlinux}
RAM=8G
CPUS=4

sudo qemu-system-x86_64 \
    -nographic \
    -cpu host -enable-kvm \
    -smp ${CPUS} \
    -m ${RAM} \
    -device e1000,netdev=net0 \
    -netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
    -drive format=raw,file=$DISK_IMG \
    -kernel $KERNEL \
    -append 'earlyprintk=ttyS0 console=ttyS0 lpj=7999923 root=/dev/hda2'

