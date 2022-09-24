---
layout: default
title: Quick Start
nav_order: 2
has_children: false
---

# vSwarm-&mu;: Quickstart with Serverless and gem5

This guide describes how to quickly setup your machine and run the first cycle accurate simulations of serverless functions using gem5.

## Setup Machine

Before experimenting with gem5 and serverless functions several things need to be installed downloaded.
For a quick start use the `setup/setup_host.sh` script to install everything.
Brew yourself a coffee ☕️😉 in the meantime. It can take its time to to set everything up for you. Four your notice the script will:

1. **Install all dependencies** *(~5 min)*

2. **Download and build gem5** *(~15 min - 70 min)*

   *Note the compile time can vary a lot depending on your machine. The stated compile times are with a 10 core, 20 hyper threads machine using 64GiB memory and a two core machine using 7GB memory respectively.*

3. **Download latest release artifacts** *(~3 min)*

   With vSwarm-&mu; we distribute a compiled kernel, client and ready to use and tested disk image. You can find the latest release of those resources on the [release page](https://github.com/ease-lab/vSwarm-u/releases) of the repo. Refer to the [resources](./setup/resources.md#download-resources-artifacts) section in the documentation for more details how to download and use them.


### Test Downloads
In case you want to make sure and check the downloads you can quickly use our test setups to perform a small test run with
```bash
# Perform test run with wit emulator.
make -f test/Makefile all_emu
# Clean everything afterwards
make -f test/Makefile clean
```

For more information about the test setups refer to our [CI testing](./test/function_test.md#function-integration-test)

## Perform simulations
Once the setup has completed you are ready to perform the first simulations.
Here we just show the basic steps to be done. Please refer to [simulation](./simulation/basics.md#first-simulation-with-gem5-and-serverless) section for more details and customization.


#### 1. Setup working directory

The first step is to create and setup a initial working directory. Use the `Makefile` in `simulation/` with:
```bash
make -f simulation/Makefile build-wkdir
```
to create the directory `wkdir/` and copy all necessary things into this directory.

#### 2. Install functions on disk

The disk image we provide does not contain any function image so we need to pull an image from a registry. Use the `install_functions` and `install_check` recipe to pull the images and verify the that the installation was successful. By default we install the three functions `fibonacci-go`, `fibonacci-nodejs`, `fibonacci-python`. Refer to [here](./simulation/basics.md) to find out how to install others.
```bash
## Pull, and test function containers on empty disk image
make -f simulation/Makefile install_functions
## Verify installation
make -f simulation/Makefile install_check
```
The installation will happen using the qemu simulator and will take a few minutes to complete. *(~ 2min)*

#### 3. Boot System with the Simulator (kvm)

Now everything is setup to switch to the simulator. At this point the "machine" we want to simulate is in power off state and we need to boot.
For booting and starting the container the kvm core is used. Once booted and the function is started a checkpoint is taken.

For convenience we generated a script with all the parameters set for gem5 in you working directory. Use it to simulate one of the functions.
```bash
cd wkdir
./setup_function.sh <function> <results/dir>
```
Use for example `fibonacci-go` and `results/` as parameters.
Once started you can attach to the simulator with the [m5 terminal](https://www.gem5.org/documentation/general_docs/fullsystem/m5term) `$GEM5_DIR/util/term/m5term localhost 3456`. The simulator will boot linux, start the container and invoke the function and take a checkpoint. After 20 invocations the simulator will exit. Check [here](./simulation/basics.md#simulations) for more details.


#### 4. Simulate function

Finally the simulator is in a state to do the exciting stuff. With the checkpoint that was generated during the previous step we can start detailed simulations from a deterministic state of the our system. Your working dir contains again a script with all the parameters set to start from the checkpoint with the detailed core.
```bash
cd wkdir
./sim_function.sh <function> <results/dir>
```
This time the simulator will not use the kvm but an simple core to perform some warming of the caches. Then it switches to the most detailed core in gem5, the O3CPU and simulate 10 further very detailed invocations.

#### 5. Analyze Results
After the simulation you can find results and statistics in the `results/` folder.

Yippee 😀 You are done. Your first simulation of a serverless function with gem5. Please refer to our [simulation basics](./simulation/basics.md) page to find out more how everything works.