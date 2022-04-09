> [Main](../README.md) ▸ **Setup**
# Setup Gem5 for Full-System simulation

In oder to run full system simulations gem5 requires three essential components.
## Essential:
1. Compiled gem5 sources
2. Compiled linux kernel configured for gem5
3. Disk image with root file system installed

By having gem5 compiled, a kernel binary and a disk image you have already everything you need to boot linux with gem5. However, for evaluation and automation of your simulation workflow we recommend to also do the two additional step to the `m5` binaries and create a m5 init service.

## Additional:
1. Add `m5` binaries
2. Create m5init service


## Build gem5 resources
To run simulation models with gem5 first all resources need to be build. Follow [this](https://www.gem5.org/documentation/learning_gem5/part1/building/) build steps. For convenience we put all the steps together in the the `build_gem5.sh` script. Just execute the following command and wait..
```bash
./setup/build_gem5.sh
```
This script will install all pre requirements, pull the gem5 repo and build all components of gem5. Depending on our machine and the number of cores you use to build this can take minutes to hours.

## Build linux kernel
Gem5 requires a binary that is executed on the simulated hardware system. In our case this is the linux kernel. To build a custom kernel configured for gem5 you can follow the setup steps [here](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/src/linux-kernel/). From this site you can also get kernel configs with all required modules enabled that gem5 can execute it.

However, since we want to not only want to run bare linux but containerized workloads we need further additional modules enabled. The `config/` folder contains a configuration for a linux kernel version 5.4.84 that can run container workloads in gem5. Use this config in the following commands to build your own kernel.
```
# Build kernel for gem5 supporting containerized workloads
KVERSION=5.4.84
ARCH=amd64

sudo apt install libelf-dev libncurses-dev -y

# Get sources
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git ../linux
pushd ../linux
git checkout v${KVERSION}

# apply the configuration
cp ../config/linux-${KVERSION}.config .config

## build kernel
make -j $(nproc)
popd
```

For your convenience we put again all the commands in the `build_kernel.sh` script. If you feel lazy to copy past just execute it and it will do the steps for you. The final executable will be placed into the `workload/` folder.
```
./scripts/build_kernel.sh
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

Again, we compiled all the ubuntu install process in a [script](scripts/build_disk_image) and config files. Executing it will hopefully make your live easier my doing those very first steps for you:

1. Create disk image
2. Get installation medium for Ubuntu server 20.04
3. Start the ubuntu installation
4. Create a `root` user for with password `root`

Addition this script will also perform the optional steps we just mentioned to [add the gem5 binary](#add-gem5-binary) and [create a gem5 service](#create-an-gem5-init-service).


## Optional Setups specifically for Gem5
The following two steps are optional but recommend to do for enhancing your simulation workflow.

### Add gem5 binary
The `m5` binary is a useful tool to execute magic instructions from the running system. After installation you can use this tool in scripts or even in the command line to for example take a snapshot or exit the simulation. Type `m5 -h` for available subcommands. More information about the `m5` binary you will find [here](https://www.gem5.org/documentation/general_docs/m5ops/).

Btw. by using the `build_gem5.sh` script we already build the m5 utility tool for you.

### Create an gem5 init service.
The gem5 init service is a neat way to automatically start execution a workload as soon as linux is fully booted. This service is very general in that it uses the `m5` tool retrieve any script you can specify in your gem5-config file and execute it. Just check the `--run-script` argument in the `gem5-config/run.py` file to see how such a script is send to the simulator and the `config/gem5init` file to find out how the linux obtains and execute it.


## Useful resources
[Create disk image for gem5](http://www.lowepower.com/jason/setting-up-gem5-full-system.html)
[About the m5 binary](https://www.gem5.org/documentation/general_docs/m5ops/)
[How to build a kernel in general](https://kernelnewbies.org/KernelBuild)

[Ubuntu auto install](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
[Cloud-init data sources](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#datasource-nocloud)