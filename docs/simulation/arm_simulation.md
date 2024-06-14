---
layout: default
title: Simple Simulation on Arm machines
parent: Simulation
nav_order: 1
---

# Simulation Methodology
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

<!-- ## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc} -->


---

We also support running serverless functions on an Arm machine.
> Note: Since we require kvm acceleration to boot the kernel and the function, we only support running the simulation on an host machine with an Arm CPU.

## Preliminary

The setup steps are the same as the x86 simulation. The `setup/setup_host.sh` setup script should work for Arm machines as well.
Also preparation of the working directory, installation of the functions on the disks are the same as for x86 machines. The only difference is that you need to use the `arm.Makefile` instead of the `Makefile` in the `simulation/` directory.

In the following we will list the commands needed to setup and perform the simulation on an Arm machine. For details refer to the [x86 simulation](.simulation.md).

### Build initial working directory for Arm


```bash
make -f simulation/arm.Makefile build-wkdir
```
Will create the new folder `wkdir/` and copy the necessary files to this directory.:

1. Kernel and base disk image.
2. Templates of `function.yaml` and `function.list` to define your functions.
5. A basic gem5 config script.

In the following the files and their usage will be described in more detail.
> Note: In case you want to don't want to use the default location you can use the `WORKING_DIR` environmental variable to change the location.


## Install Function images on disk

Use the command to install all functions defined in the `functions.list/yaml` files on the disk.:
```bash
make -f simulation/arm.Makefile install_functions
```

### Verify successful installation
The installation will generate a log file of the installation process. Use the recipe `install_check` to verify that everything was installed successfully.



## Simulations
To perform simulations on an Arm machine you can use the `vswarm_simple_arm.py` script in the working directory. The script leverages the gem5 component library and is the same as `vswarm_simple.py` but for Arm instead of x86.

To boot the kernel and the function and perform functional warming of the container - for JIT'ed functions - you can use the following command:
```bash
cd wkdir
## Perform setup
<gem5_root>/build/ARM/gem5.opt vswarm_simple_arm.py --kernel kernel --disk disk.img --mode=setup --atomic-warming=50 --num-invocations=20
```

Once the checkpoint is created the simulation can be performed with:
```bash
## Perform evaluation
<gem5_root>/build/ARM/gem5.opt vswarm_simple_arm.py --kernel kernel --disk disk.img --mode=evaluation --atomic-warming=50 --num-invocations=20
```

The script was tested with ATOMIC,TIMING and O3 core which can be configured commenting the corresponding lines in the script
```
eval_core = CPUTypes.<TIMING/ATOMIC/O3>
```