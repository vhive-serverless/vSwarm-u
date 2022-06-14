---
layout: default
title: Build Linux Kernel
parent: Setup
nav_order: 2
---

# Build Linux Kernel

Gem5 requires a binary that is executed on the simulated hardware system. In our case this is the linux kernel. To build a custom kernel configured for gem5 you can follow the setup steps [here](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/src/linux-kernel/). From this site you also get kernel configs with all required modules enabled that gem5 can execute it.

However, since we want to not only run bare linux but containerized workloads we need further additional modules enabled. The `configs/linux-configs/` folder contains a configuration for a linux kernel version `5.4.84` which can run container workloads in gem5.
We put together a `Makefile` that will use this config to build a fresh kernel for you:

```bash
# Install all build tools
make -f setup/kernel.Makefile dep_install
# Build the kernel
make -f setup/kernel.Makefile build
# Save the kernel binary `vmlinux` into $RESOURCES/vmlinux
make -f setup/kernel.Makefile save
# Or save the kernel binary to wherever you want
OUTPUT=<path/you/want> make -f setup/kernel.Makefile save_output
```


## Customize linux kernel
If you need to enable additional modules you may want to customize the kernel config. For this the easiest way is to start from one of the existing pre-configurations. For this overwrite the good `.config` file in the linux repo with the config you want and start the configuration process as usual with `make oldconfig`.
> Note: Gem5 cannot load modules at runtime therefore all modules need to be build into the binary.

## Check kernel config for container workloads
To find out if your kernel is ready to run container workloads the developers from the moby project provide a neat [script](https://github.com/moby/moby/raw/master/contrib/check-config.sh).
This [blog post](https://blog.hypriot.com/post/verify-kernel-container-compatibility/) explains nicely how to use this script in detail to check your kernel config for compatibility with containers.

In the linux-config folder you can find a copy of this script. Execute the following command to check your kernel config:
```bash
./configs/linux-configs/check-config.sh <path/to/your/kernel.config>
```