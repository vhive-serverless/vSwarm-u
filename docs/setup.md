---
layout: default
title: Setup
nav_order: 2
has_children: false
---

# Setup Resources for Full-System Simulation in gem5

{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

Before experimenting with gem5 and serverless functions several things need to be setup.
The following describes the setup process in more detail. For a quick start use `setup_host.sh` script to install everything at once.
```bash
./setup/setup_host.sh
```

## Install components individually

In oder to run full system simulations gem5 requires three basic components.
### Essential:
1. Compiled gem5 sources
2. Compiled linux kernel configured for gem5
3. Disk image with root file system installed


By having gem5 compiled, a kernel binary and a disk image you have already everything you need to boot linux with gem5. However, for evaluation and automation of your simulation workflow we recommend to also do the two additional step to the `m5` binaries and create a m5 init service.

### Additional:
1. Add `m5` binaries
2. Create m5init service

## Resource directory
We use the `RESOURCES` environmental variable in all our scripts to define in which directory all resources should be installed. If you want to specify this directory yourself set and expose this variable yourself.
```bash
export RESOURCES=<your/resources/dir>
echo 'export RESOURCES=${RESOURCES}' >> ${HOME}/.bashrc
```


## Build gem5 sources
To run simulation models with gem5 the gem5 repo must be cloned and the sources build. Follow [this](https://www.gem5.org/documentation/learning_gem5/part1/building/) build steps. For convenience we put all the steps together in the a `Makefile`.
Use the `setup/gem5.Makefile` to install all dependencies and build the sources with:
```bash
# Install dependencies
make -f setup/gem5.Makefile dep_install
# Build gem5
make -f setup/gem5.Makefile all
```
This script will install all pre requirements, pull the gem5 repo into $RESOURCES/gem5 and build all components of gem5. Depending on your machine and the number of cores you use to build this can take from 10 minutes to hours.

## Build linux kernel
Gem5 requires a binary that is executed on the simulated hardware system. In our case this is the linux kernel. To build a custom kernel configured for gem5 you can follow the setup steps [here](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/src/linux-kernel/). From this site you also get kernel configs with all required modules enabled that gem5 can execute it.

However, since we want to not only run bare linux but containerized workloads we need further additional modules enabled. The `configs/linux-configs/` folder contains a configuration for a linux kernel version `5.4.84` that can run container workloads in gem5.
We put together another `Makefile` that will use this config to build a fresh kernel for you:

```bash
# Install all build tools
make -f setup/kernel.Makefile dep_install
# Build the kernel
make -f setup/kernel.Makefile build
# Save the kernel binary `vmlinux` into $RESOURCES/vmlinux
make -f setup/kernel.Makefile save
```


### Customize linux kernel
If you need to enable additional modules you may want to customize the kernel config. For this the easiest way is to start from one of the existing pre-configurations. For this overwrite the good `.config` file in the linux repo with the config you want and start the configuration process as usual with `make oldconfig`.
> Note: Gem5 cannot load modules at runtime therefore all modules need to be build into the binary.

### Check kernel config for container workloads
To find out if your kernel is ready to run container workloads the developers from the moby project provided neat [script](https://github.com/moby/moby/raw/master/contrib/check-config.sh).
This [blog post](https://blog.hypriot.com/post/verify-kernel-container-compatibility/) explains very nicely how to use this script to verify your kernel config for compatibility.


## Create basic ubuntu disk image
The last essential component is a disk image with a root file system installed on it. There are several ways to create disk images all described [here](https://www.gem5.org/documentation/general_docs/fullsystem/disks).

We recommend to follow the instructions in option 3) and use `qemu` to create your first disk images. Using `qemu` enables you to configure your disk image with your serverless function play around a bit and test all your setup before switching to the actual simulation.

Again, we compiled a `Makefile` for you that will use the [autoinstall](https://ubuntu.com/server/docs/install/autoinstall) feature in ubuntu to install ubuntu 20.04 on a fresh new disk with all other tools that are required for your experiments.

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

Addition this script will also perform the optional steps we just mentioned to [add the gem5 binary](#add-gem5-binary) and [create a gem5 service](#create-an-gem5-init-service).



## Optional Setups specifically for Gem5
The following two steps are optional but recommend to do for enhancing your simulation workflow.

### Add gem5 binary
The `m5` binary is a useful tool to execute magic instructions from the running system. After installation you can use this tool in scripts or even in the command line to for example take a snapshot or exit the simulation. Type `m5 -h` for available subcommands. More information about the `m5` binary you will find [here](https://www.gem5.org/documentation/general_docs/m5ops/).

Btw. by using the gem5 Makefile will already build the m5 utility tool for you.

### Create an gem5 init service.
The gem5 init service is a neat way to automatically start execution a workload as soon as linux is fully booted. This service is very general in that it uses the `m5` tool retrieve any script you can specify in your gem5-config file and execute it. Just check the `--run-script` argument in the `gem5-config/run.py` file to see how such a script is send to the simulator and the `config/gem5init` file to find out how the linux obtains and execute it.


## Useful Links
- [Create disk image for gem5](http://www.lowepower.com/jason/setting-up-gem5-full-system.html)
- [About the m5 binary](https://www.gem5.org/documentation/general_docs/m5ops/)
- [How to build a kernel in general](https://kernelnewbies.org/KernelBuild)
- [Ubuntu auto install](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Cloud-init data sources](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#datasource-nocloud)