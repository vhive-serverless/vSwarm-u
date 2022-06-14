---
layout: default
title: Create Basic Disk Image
parent: Setup
nav_order: 3
---
# Disk Image

As we will run linux in gem5 we need to provide it with a disk with a root filesystem installed on it. There are several ways to create disk images for gem5 all described [here](https://www.gem5.org/documentation/general_docs/fullsystem/disks).

We recommend to follow the instructions in option 3) and use `qemu` to create your first disk images. Using `qemu` enables you to configure your disk image with your serverless function play around a bit and test all your setup from the software side before switching to the actual simulation.

> *Note: Setting up a disk image from scratch can be tricky to get it right and also installation costs a lot of time. To get around this we distribute ready to use disk-images with every vSwarm-u release. Refer to the [download](./resources.md) section in the setup guide.*


## Install OS and packages

We compiled a `Makefile` which will use the [autoinstall](https://ubuntu.com/server/docs/install/autoinstall) feature in ubuntu to bake a new disk image with all tools required for your experiments

The installer will:
1. Create a empty disk image with
1. Install Ubuntu 20.04 as operating system
2. Create users **root** (password _root_) and **ubuntu** (password _root_) with privileged permissions to all resources.
3. Setup ssh-login for both users.
4. Install the `m5` binary and gem5 init service.
5. Install the docker engine, docker-compose and the golang tools.


```bash
# Install dependencies
make -f setup/disk.Makefile dep_install
# Download the installation medium for Ubuntu server 20.04
make -f setup/disk.Makefile download
# Run the installation
make -f setup/disk.Makefile install
# Save the disk into $RESOURCES/base-disk-image.img
make -f setup/disk.Makefile save
```

> Note: The installation will take a while therefore we recommend to make a backup of this disk image once the installation has completed.

## Test Installation




## Use the disk image
Once you have baked your basic disk image you can test and play around with it using the `qemu` emulator. To start the emulator use the command:
```bash
sudo qemu-system-x86_64 \
    -nographic \
    -cpu host -enable-kvm \
    -smp <Number of CPUs> \
    -m <MEMORY size> \
    -drive file=<path/to/disk/image>,format=raw \
    -kernel <path/to/kernel> \
    -append 'console=ttyS0 root=/dev/hda2'
```




## Gem5 binary
The `m5` binary is a useful tool to execute magic instructions from the running system. After installation you can use this tool in scripts or even in the command line to for example take a snapshot or exit the simulation. Type `m5 -h` for available subcommands. More information about the `m5` binary you will find [here](https://www.gem5.org/documentation/general_docs/m5ops/).

Btw. by using the `gem5.Makefile` will already build the m5 utility tool for you.

## Gem5 init service.
The gem5 init service is a neat way to automatically start execution a workload as soon as linux is fully booted. This service is very general in that it uses the `m5` tool retrieve any script you can specify in your gem5-config file and execute it. Just check the `--run-script` argument in the `gem5-config/run.py` file to see how such a script is send to the simulator and the `config/gem5init` file to find out how the linux obtains and execute it.


## Useful Links
- [Create disk image for gem5](http://www.lowepower.com/jason/setting-up-gem5-full-system.html)
- [About the m5 binary](https://www.gem5.org/documentation/general_docs/m5ops/)
- [How to build a kernel in general](https://kernelnewbies.org/KernelBuild)
- [Ubuntu auto install](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Cloud-init data sources](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#datasource-nocloud)