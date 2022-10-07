---
layout: default
title: Methodology
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

Here we describe the basic methodology of simulations with gem5 and serverless functions.

## Build initial working directory
For doing the simulations we use a separate working directory. A initial working directory can be setup with the `Makefile` in `simulation/`.
```bash
make -f simulation/Makefile build-wkdir
```
By default it will create the new folder `wkdir/` and copies a bunch of files into it which you need or might find useful to start experimenting including:

1. Kernel and base disk image. *We make a copy that we always have a clean base image in case we mess up things*
2. Templates of `function.yaml` and `function.list` to define your functions.
3. A `sim_function.sh` script for running simulation for a particular function.
4. A `sim_all_functions.sh` script for starting a simulation of each function defined in the `functions.list` file.
5. A basic gem5 config script.
6. ...

In the following the files and their usage will be described in more detail.
> Note: In case you want to don't want to use the default location you can use the `WORKING_DIR` environmental variable to change the location.


## Defining Function Benchmarks

For managing the functions to be benchmarked during the simulation we use docker-compose. docker compose allows predefining even complexer setups with several connected functions.

The functions to be benchmarked need to be defined in the `function.yaml` in your working directory as [docker-compose](https://docs.docker.com/compose/compose-file/) configuration. The simulation workflows has several requirements on the configuration.
1. The client to drive the invocations will connect port `50000`. Therefore make sure to forward the function port to this host port.
   ```yaml
    ports:
      - target: <grpc/port>
        published: 50000
   ```
2. Some functions might depend on other functions or on a database. In order to let the simulator now which container to benchmark you need to name those containers `function`.
   ```yaml
    container_name: function
   ```
    With this simulation script is able to pin this container to an isolated core during the simulation.

The initial working directory contains a template of this config file. Use it as a reference and quick start guide. Furthermore we predefined the correct config of all functions supported in gem5 from our benchmarks suite [vSwarm](https://github.com/vhive-serverless/vSwarm) in `simulation/functions/all_vswarm_functions.yaml`. Use it as a reference or simply copy the config to the `functions.yaml` file in your working directory.

In addition to the config file we use a second file `functions.list` to control which functions to benchmark in a particular run. You might not always benchmark all function at once. You can comment out functions in this list and the scripts will not spawn a simulation for this one.

> Notes:
> - For all simulations the same disk image is used. Therefore define all functions in this file.
> - Each time you changed the functions.yaml file you need to run `make install_functions`. Only then the updated yaml file will be downloaded on the disk. To ensure the the config worked you can check the `install.log` once the command has completed.


## Install Function images on disk

In your initial working directory you will find a raw base disk image. On this base image all necessary packages i.e. docker, python,.. are preinstalled. However, the disk image does not contain the container images of the benchmarks we want to run. Therefore, before starting simulation the base image need to be augmented with the container images. Furthermore we need to bring the `functions.yaml` config on this image.

To do this we use the qemu emulator as it has access to the internet for pulling the most recent images.
We provide a make recipe to automatically install all functions defined in the `functions.list/yaml` files. Run:
```bash
make -f simulation/Makefile install_functions
```

It may take a while depending on how many functions and how large the images are that need to be pulled.

> **Warning**: the base disk image has a size of 16GiB with 6GiB already used. Make sure that all container images will not exceed the total size available on the disk. In case a larger disk is required the size can be increased with `qemu image resize`. Note that afterwards the file system need to be [extended](https://computingforgeeks.com/extending-root-filesystem-using-lvm-linux/).

### Verify Installation success
The installation will generate a log file of the installation process. Use the recipe `install_check` to verify that everything was installed successfully.



## Simulations
As soon as the functions are installed on disk its finally time to turn our attention to gem5.

The initial working directory will contain gem5 config file `run_sim.py` that defines a system and a basic workflow to benchmark one serverless function.

### Workflow
A workflow defines what is happening during the simulation. Remember that before the simulation the machine is shutdown so in before we can start measuring we need to boot and start the container. To do this automated we use [workflow automation concept](./../test/function_test.md#workflow-automation).

Basically, what we need to do is to define a run script and send it to the simulator.

Here a snipped of the workflow defined in the `run_sum.py` file:
```bash
m5 fail 1 ## 1: BOOTING complete
## Spin up Container
echo "Start the container..."
docker-compose -f functions.yaml up -d {FN_NAME} &&DOCKER_START_RES=$?
m5 fail 2 ## 2: Started container
```
Using the `m5` binary we can indicate the gem5 simulator where in the workflow the system currently is. Each time the `m5` instruction is executed the simulator will break out of the simulation. That give the chance to react on certain events or modify the simulation. In this case i.e. we use for booting and starting the container the KVM core to accelerate this process. Just before the invocation we switch the core to a detail model for the actual measurement. Booting linux and the container with a detailed model would take hours to days.

Here are snippets where we exit the simulation and switch the CPU as we encounter `m5 fail 10`
```python
def executeM5FailCode(code):
    ...
    # Before invoking we switch to detailed core
    if code == 10:
        print("Switch detailed core")
        system.switchToDetailedCpus()
        m5.stats.reset()

...
# Simulate until m5 instruction is encountered
exit_event = m5.simulate()
if exit_event.getCause() == "m5_fail instruction encountered":
   executeM5FailCode(exit_event.getCode())
```


In general its easy to switch cores in gem5. However the kvm core is a bit picky and requires different event queues which makes gem5 much more unstable. Often things break. The best way to switch from kvm to another core is to take a checkpoint, exit the simulation and then start the simulation with another core.

Another advantage of this flow is that you need to do the booting and warming just once and then do your experimentation from a clearly defined point. We implemented the run script with two modes `setup` and `evaluation`. Running the script with `--mode=setup` will instantiate the kvm core to boot, warm and checkpoint the system. `--mode=evaluation` will instantiate a detailed core and start from the checkpoint taken with setup. The checkpoint that setup mode generates is pre-required to run the evaluation mode. The director where checkpoints are written can be changed using the `--checkpoint-dir` flag.

A full workflow is defined in `run_sim.py` and does the following:

**_Setup_** mode:
1. Booting linux
2. Spinning up the container
3. Pin the container to core 1
4. Run the invoker to warm the function container.
5.

**_Evaluation_** mode:

5. Reset the gem5 stats
6. <font color="red">Invoker the function</font>
7. Dump the gem5 stats
8. Exit the simulation.

Only the red part of the flow is the part we are actually measuring in detailed mode.



### System
The different systems we use to run these simulations on are is defined `gem5-configs/systems/`. By default we use a simple system. Use the `--system` argument to define the system you want to use.

| Diagram | Parameters |
|---|---|
| <img src="{{ site.baseurl }}/figures/simple_system.jpg" title="Two Machine" height=100/> | **Core:** TimingSimpleCPU<br> **L1-I/D:** 36KB <br>**LLC:** 128KB<br>**Memory:** 2GB |

### Setup Simulation
The initial working directory will contain two scripts to setup your simulator. It will automatically boot linux, spin up the container and take a checkpoint.
The first script starts the simulator for only one particular function and keeps attached to the process.
```bash
./setup_function.sh <function> <results>
```
The second script will parse the `functions.list` file and spawn a simulation for each function defined and not commented out in the list.
```bash
./setup_all_functions.sh <results>
```

### Evaluations with the Simulator
In the same manor two scripts for evaluation mode are provided which you can use to start from a checkpoint taken in setup mode.
```bash
./sim_function.sh <function> <results>
# Or
./sim_all_functions.sh <results>
```
The results of simulation as well as the log files will be written to `results/function/`
> Note: The default values for `results` and `function` are `fibonacci-go` and `results/` respectively

### Ending Simulation
If everything goes right the simulation will end by itself with `Simulation done`
> Note: In case you use the second script to run more simulations in the background the gem5 log is redirected as `gem5.log` in the specific directory.

When you realize that the simulator got stuck at some point. Which is not very unlikely, you need to kill and restart the simulation.
> Note: In order to run the kvm core the simulator runs with `sudo`. So you also need to kill the process as sudo.

You can check if the simulations completed successfully using the script `analysis/check_simulations.py`. I.e. use `python ../analysis/check_simulations.py <results/dir>` to check your results folder.
The script will also create a `rerun.sh` script for you with that will contain the shell commands to rerun the experiments that fail.

### Analyzing Results
The folder `results/function/` will contain the results of the simulation. Please refer to the [gem5 documentation](https://www.gem5.org/documentation/learning_gem5/part1/gem5_stats/) or the [analysis](./../analysis/analysis.md) section to find out how you can process the results.
