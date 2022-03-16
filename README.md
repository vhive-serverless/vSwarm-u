# Microarchitectural Research

[![Build kernel](https://github.com/ease-lab/vGem5/actions/workflows/build_kernel.yml/badge.svg?branch=main)](https://github.com/ease-lab/vGem5/actions/workflows/build_kernel.yml)

## Preliminary

In order to simulate containerized functions using gem5 several general steps need to be done before your first experiments.
Due to time limits and long compile time we already preinstalled all required base components on to the GCP image you go from us.

In order to setup those base by your own later on, we created a separate hands on [here](setup.md) where you can find all instructions to do so.

## Customize the simulator
At this point You are are ready to customize the base components onto your own needs and start your microarchitectual research.
In the following we will guide you through all the necessary step you need to do before starting the simulator:
1. Configure your system
2. Augment base disk image with your own custom containerized function.
3. Adapt the `run_script.sh` to your function.

### 1. Configure the hardware system you want to simulate
Gem5 is a collection of models and in order to let the simulator know how which models we want to use and how to combine them it needs a config file(s). Because teaching how to creating the config file is not the intention of this tutorial we did the configuration you already. You can find it in the `gem5-configs/` folder.
> Note: The [gem5 documentation](https://www.gem5.org/documentation/learning_gem5/introduction/) provide a lot of information and some nice tutorials how those config file works and how to setup one by your own.

The system we configured consists of a dual in-order core machine. Each core has their private 16kB I and D-cache and is clocked at 2.5Ghz. Both core share a common 128kB LLC and a 2GB of memory.
Because we are only interested in the characteristics of the function itself
By using linux's `isolcpus` feature we isolate core 1 from the rest of the system to run only the function container on it. With that we can exclusively measure the workload characteristics of our function without any interferences from other parts of the system. On core 0 we will run a small client to drive our function.


### 2. Augment disk image and setup your function
Before running the simulator you need to install your own containerized function onto the base disk image.
For this we will use the qemu emulator as it faster and has access to the internet for pulling the image. Run the long command for qemu by executing in the `run_qemu.sh` script.
```bash
./scripts/run_qemu.sh
```
Qemu will boot the base disk image `workload/` folder.
As soon as the system is booted you can login as `root` (password `root`).
Now you are able to pull your function onto base disk image. Use for this tutorial the `vhiveease/aes-go` function image as example:
```bash
# Pull your containerized function image
docker pull  vhiveease/aes-go
```
In order to test if your function actually works from a software perspective use the client we put onto the image to perform a quick test.
   > Note you can find the source code of the client together with your hands out material.

```bash
# 1. Start your function container
# -d detaches the process and we can continue in the same console.
# -p must be set to export the ports
docker run -d --name mycontainer -p 50051:50051 vhiveease/aes-go

# run the client with the port you export in docker as well as the number of invocations you want to run.
# -addr is the address and port we where exporting with the docker command
# -n is the number of invocations the client should perform
./client -addr localhost:50051 -n 100
```
The client should print its progress after every 10 invocations.
Now the disk image is ready for the Gem5 simulator. Stop the container and shutdown qemu.
```
docker stop mycontainer && docker rm mycontainer
shutdown -h now
```
> Note: Qemu breaks the line wrapping you might want to reset the console by executing `reset`.

### 3. Define the run script.

Finally we need to define a run script. Its a script that say's linux what to do after booting completes. The steps we want to perform are similar to the steps we did with qemu except pulling the container.

1. Spinning up the container
2. Pin the container to core 1
3. Reset the gem5 stats
4. Start the invoker.
5. Dump the gem5 stats
6. Exit the simulation.

The `run_function.sh` script provides a skeleton for the commands to perform those steps. You only need to specify the name of your function image at very top of the script. In our case this is `vhiveease/aes-go`.


## Simulating serverless workloads with gem5

Finally everything is set to start the actual simulations with the command:
```bash
./gem5/build/X86/gem5.opt --outdir=results gem5-configs/run.py  --kernel workload/vmlinux --disk workload/disk-image.img --script scripts/run_function.sh
```
Gem5 will now start, boot linux and then execute the run script we just modified. Note simulating HW is usually very time consuming. Booting linux using one of the detailed or even the atomic core could easily take hours. In order to fast forward this booting gem5 provides the nice feature to use kvm instead of any other CPU model. We will use this feature for booting and starting the function. Then we "magically" ;) switch to a more detailed core model.

While the simulation is running we can inspect what is happening by connecting the terminal tool provided by gem5. To use it open a second terminal (Ctr+b % will create a second tmux plane for you.) and connect with:
```bash
./gem5/util/term/m5term localhost 3456
```
> Note: Infos about how to use `m5term` you can find [here](https://www.gem5.org/documentation/general_docs/fullsystem/m5term).

In this terminal you should see first how linux boots and then how the gem5 service will start your run-script.

As soon as the simulation is completed gem5 will exit and a stats will be written to the results directory `results`. The stats file contain a lot of statistic counter which where collected during the simulation. As example we will search the cycles and instructions to see how well your system perform to execute our function.
```bash
grep "system.detailed_cpu1.numCycles" results/stats.txt \
&& grep "system.detailed_cpu1.exec_context.thread_0.numInsts" results/stats.txt
```
We also put a small bash script that does the math for you and calculate CPI (or IPC) for you directly.
```
# A small bash script that does the math for us.
./scripts/cpi.sh results/stats.txt
```
Now you are done :) Congratulation you just did your first simulation of a containerized function using the gem5 simulator. You can now start with your own research and to play with the configurations or your own functions images.

### Additional example: Modify the config file
This example should show you how easy it can be to modify the configuration of your hardware system. To get a bit more performance out of our system we want to increase the cache size and associativity of the LLC. For that:

1. Open the `cache.py` file in the gem5-config folder. Change the LLCCache's default parameter for size and associativity to for example 2MB and 16 respectively. Save and close the file.
2. Run the same command as in the previous step to run the simulation.
```bash
./gem5/build/X86/gem5.opt --outdir=results gem5-configs/run.py  --kernel workload/vmlinux --disk workload/disk-image.img --script scripts/run_function.sh
```
3. Finally inspect the stats file. The larger cache and higher associativity should have a improved the IPC of your function. In case you are interested can also search for the number of cache misses to see how your larger LLC improved its MPKI (misses per kilo instruction).
```bash
grep "system.detailed_cpu1.numCycles" results/stats.txt && \
grep "system.detailed_cpu1.exec_context.thread_0.numInsts" results/stats.txt
# A small bash script that does the math for us.
./scripts/cpi.sh results/stats.txt
```

