#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( cd $DIR && cd .. && pwd)"

DISK_IMG=$ROOT/workload/disk-image.img
KERNEL=$ROOT/workload/vmlinux
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

