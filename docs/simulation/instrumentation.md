---
layout: default
title: Workload Instrumentation
parent: Simulation
nav_order: 10
---

# Workload Instrumentation
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

---

In contrast to conventional workloads serverless function run for short amount of time. Furthermore we might want to run several invocations to compare different inputs. The challenge is that now the intervals where to do measurements need to defined more precise.

<figure>
  <img src="../figures/trigger-points.jpg" title="Instrumentation points" />
    <figcaption> <i><b>Figure 1:</b> Overall simulation flow and several intervals to be measured.</i></figcaption>
</figure>

Figure 1 show the the overall simulation and different intervals that are interesting to do measurements. The following describe how different points in this flow are instrumented.

## M5 fail codes
For driving the simulator `m5 fail <code>` codes are executed at various points during the simulation. Using `m5 fail` instead of `m5 exit` has the advantage to send also a code which can encode more information. Refer to the templates in your initial working directory.


## Client side instrumentation
Using the `m5` binary is fine for rough trigger points. However, it is not very precise as some OS interaction is involved when executing a command. (Need to load the binary, allocate memory,...)

In order to get around this issue and get more precise trigger points the repo includes a instrumented to client in `tools/client/`. Under to hood it takes advantage of the [`m5ops`]() magic instruction. Refer to the gem5 documentation to for more information how magic instructions work.

For convenience we wrap gem5's magic instructions in a go package to be found in the m5 subfolder of the client.

To run the client with instrumentation set the flag `-m5ops` when running the client.
Note that m5 magic instruction take advantage of `mmap` which is only available with root permissions. This is not an issue issue when running the client on the disk image as we have root permissions there. However, it will raise a warning when running the client on your local machine.


## Server side instrumentation
For the server side we instrumented the linux scheduler by hooking up a `FuncEvent` on the `__schedule` symbol. With compiling also the `thread_info` into the kernel we can get the previous and next PID for every scheduling event.
This enables us to react on certain scheduling events.

However, this is still work in progress and will be rolled out soon.