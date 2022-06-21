---
layout: default
title: Systems
parent: Simulation
nav_order: 4
---

# Simulated Systems Models

At the moment we provide two systems setups ready to use. A simple and a complex model. The complex system is base on Intel Skylake parameters and was adopted from [here](https://github.com/darchr/gem5-skylake-config)

In the following the two systems and the main parameters. For all details refer to the configs in `gem5utils/systems/`.

### Simple System

|  | Parameters |
|---|---|
| <img src="{{ site.baseurl }}/figures/simple_system.jpg" title="Two Machine" hight=100/> | **Core:** TimingSimpleCPU<br> **L1-I/D:** 32KB <br>**LLC:** 128KB<br>**Memory:** 2GB

### Complex Skylake System

The complex model is the Intel Skylake CPU and its parameters are taken from the reference setup in [here](https://github.com/darchr/gem5-skylake-config).

|  | Parameters |
|---|---|
| <img src="{{ site.baseurl }}/figures/skylake-system.jpg" title="Two Machine" hight=200/> | **Core:** Intel Skylake<br> **L1-I/D:** 32KB <br>**L2: 1MB**  <br>**LLC:** 8MB<br>**Memory:** 2GB, DDR4, 2400, 16x4.


## Two Machine Model
For a truly isolated server-client communication we also provide a two machine setup. In order to use it build our initial working directory with `make -f simulation/Makefile build-two-machine` setup. The only difference is that it will use a different template to create the `run_sim.py` config file

|  | Parameters |
|---|---|
| <img src="{{ site.baseurl }}/figures/two-machine.jpg" title="Two Machine" hight=200/>| **Detailed Node:** Skylake system model <br> <br> **Driving Node:** TimingSimpleCPU, 8MB LLC, 2GB SimpleMemory |

In the two machine setup the client is started on the driving node and the function on the detailed node. To communicate both nodes are connected via gem5 EthernetLink model. To make it work two different workflows need to be defined one for the client and one for the server respectively.

| Client workflow | Server workflow |
|---|---|
| 1. Booting linux <br>2. Spinning up the container<br>3. Pin the container to core 1<br>4. Enable network interface and assign ip | 1. Booting linux <br>2. Wait until server ip is reachable<br>3. Run the invoker to warm the function container.<br>5. Reset the gem5 stats<br>6. <font color="red">Invoker the function</font><br>7. Dump stats and exit |

> Note: We enable the network interface not before the function is started. This allows the synchronization between server and client.
