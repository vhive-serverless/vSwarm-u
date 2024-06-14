#
# Copyright (c) 2022 David Schall and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Install dependencies

"""
This script further shows an example of booting an ARM based full system Ubuntu
disk image. This simulation boots the disk image using 2 TIMING CPU cores. The
simulation ends when the startup is completed successfully (i.e. when an
`m5_exit instruction is reached on successful boot).

Usage
-----

```
scons build/ARM/gem5.opt -j<NUM_CPUS>
./build/ARM/gem5.opt arm-vswarm.py
    --mode <setup/evaluation> --function <function-name>
    --kernel <path-to-vmlinux> --disk <path-to-disk-image>
    --atomic-warming <num-inv-to-warm> --num-invocations <num-inv-to-simulate>
```

"""
import m5
from m5.objects import (
    Armv83,
    ArmDefaultRelease,
    VExpress_GEM5_V1,
    VExpress_GEM5_Foundation,
)

from gem5.coherence_protocol import CoherenceProtocol
from gem5.components.boards.arm_board import ArmBoard
from gem5.components.memory import DualChannelDDR4_2400
from gem5.components.memory.simple import SingleChannelSimpleMemory
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource,KernelResource,DiskImageResource
from gem5.simulate.exit_event import ExitEvent
from gem5.simulate.simulator import Simulator
from gem5.utils.requires import requires

# This runs a check to ensure the gem5 binary is compiled for ARM.
requires(isa_required=ISA.ARM)

from gem5.components.cachehierarchies.classic.private_l1_private_l2_cache_hierarchy import (
    PrivateL1PrivateL2CacheHierarchy,
)

import os
from pathlib import Path


import argparse
def parse_arguments():
    parser = argparse.ArgumentParser(description=
                        "gem5 config file to run vSwarm benchmarks")
    parser.add_argument("--kernel", type = str, help = "Path to vmlinux")
    parser.add_argument("--disk", type = str,
                  help = "Path to the disk image containing your function image")
    parser.add_argument("-f", "--function", action="store", type=str, default="fibonacci-go",
                        help="""Specify a function that should run in the simulator.""")
    parser.add_argument("--atomic-warming", type=int, default=0,
                        help="""Perform warming of the cache hierarchy using the atomic core.""")
    parser.add_argument("--num-invocations", type=int, default=5,
                        help="""Number of invocation to be measured.""")
    parser.add_argument("--mode", type=str, default="setup",choices=["setup", "evaluation",],
                        help="""Setup mode: Will boot linux using the kvm core, perform functional
                                warming and then take a snapshot.
                                Evaluation mode: Will start from a previously taken checkpoint
                                do some """)
    parser.add_argument("--checkpoint-dir", type = str, default="checkpoints/",
                        help = "Directory of")
    return parser.parse_args()


args = parse_arguments()

if args.mode == "setup":
    Path("{}/{}".format(args.checkpoint_dir, args.function)).mkdir(parents=True, exist_ok=True)



# Here we setup the parameters of the l1 and l2 caches.
cache_hierarchy = PrivateL1PrivateL2CacheHierarchy(
    l1d_size="16kB", l1i_size="16kB", l2_size="256kB"
)

# Memory: Dual Channel DDR4 2400 DRAM device.
memory = DualChannelDDR4_2400(size="2GB")

# Here we setup the processor. For booting we take the KVM core and
# for the evaluation we take the Atomic core.
processor = SimpleProcessor(
    cpu_type=CPUTypes.KVM if args.mode=="setup" else CPUTypes.ATOMIC,
    isa=ISA.ARM,
    num_cores=2,
)


# The ArmBoard requires a `release` to be specified. This adds all the
# extensions or features to the system. We are setting this to Armv8
# (ArmDefaultRelease) in this example config script.
# release = Armv83()
release = ArmDefaultRelease.for_kvm()

# The platform sets up the memory ranges of all the on-chip and off-chip
# devices present on the ARM system. ARM KVM only works with VExpress_GEM5_V1
# on the ArmBoard at the moment.
platform = VExpress_GEM5_V1()
# platform = VExpress_GEM5_Foundation()

def _build_kvm(options, system, cpus):
    system.kvm_vm = KvmVM()
    system.release = ArmDefaultRelease.for_kvm()

    if options.kvm_userspace_gic:
        # We will use the simulated GIC.
        # In order to make it work we need to remove the system interface
        # of the generic timer from the DTB and we need to inform the
        # MuxingKvmGic class to use the gem5 GIC instead of relying on the
        # host interrupt controller
        GenericTimer.generateDeviceTree = SimObject.generateDeviceTree
        system.realview.gic.simulate_gic = True

    # Assign KVM CPUs to their own event queues / threads. This
    # has to be done after creating caches and other child objects
    # since these mustn't inherit the CPU event queue.
    if len(cpus) > 1:
        device_eq = 0
        first_cpu_eq = 1
        for idx, cpu in enumerate(cpus):
            # Child objects usually inherit the parent's event
            # queue. Override that and use the same event queue for
            # all devices.
            for obj in cpu.descendants():
                obj.eventq_index = device_eq
            cpu.eventq_index = first_cpu_eq + idx



# Here we setup the board. The ArmBoard allows for Full-System ARM simulations.
board = ArmBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
    release=release,
    platform=platform,
)


def writeRunScript(function_name):
    n_invocations=args.num_invocations
    n_warming=args.atomic_warming
    return f"""
#!/bin/bash

## Define the image name of your function.

# We use the 'm5 exit' magic instruction to indicate the
# python script where in workflow the system currently is.

m5 --addr=0x10010000 exit ## 1: BOOTING complete

## Spin up Container
echo "Start the container..."
docker-compose -f /root/functions.yaml up -d {function_name}
m5 --addr=0x10010000 exit ## 2: Started container

echo "Pin function container to core 1"
docker update function --cpuset-cpus 1

sleep 5
m5 --addr=0x10010000 exit ## 3: Pinned container


# # The client will perform some functional warming
# and then send a fail code before invoking the
# function again for the actual measurement.
# /root/test-client  -function-name aes -url localhost -port 50000 -n 10 -w 100 -m5ops -input 10
# /root/test-client  -function-name fibonacci -url localhost -port 50000 -n 2 -w 2 -m5ops -v -input 10
/root/test-client \
    -function-name {function_name} \
    -url localhost \
    -port 50000 \
    -n {n_invocations} \
    -w {n_warming} \
    -m5ops \
    -input 10


m5 --addr=0x10010000 exit ## 4: Stop client
# -------------------------------------------


## Stop container
#docker-compose -f /root/functions.yaml down
m5 --addr=0x10010000 exit ## 5: Container stop


## exit the simulations
m5 --addr=0x10010000 exit ## 6: Test done

"""


def workbegin() -> bool:
    print("Begin")
    return False

def workend() -> bool:
    print("End")
    return False


def executeExit() -> bool:

    if args.mode == "setup":

        print("1: BOOTING complete")
        yield False

        print("2: Started container")
        yield False

        print("3: Pinned container")
        yield False

        print("4: Stop client")
        yield False

        print("5: Stop container")
        yield False

        print("6: Stop simulation")
        yield False
        yield False
        yield False
        yield False
        yield False

    else:
        print("Simulation done")
        m5.stats.dump()
        m5.exit()



def executeFail() -> bool:
    print("1: Client started")
    yield False
    print("1: Function warming starts")
    yield False
    print("1: Function warming done")
    # processor.switch()
    if args.mode == "setup":
        m5.checkpoint("{}/{}".format(args.checkpoint_dir, args.function))

    yield False

    while True:
        print("1: Function warming done")
        yield False



# Here we set a full system workload. The "arm64-ubuntu-20.04-boot" boots
# Ubuntu 20.04. We use arm64-bootloader (boot.arm64) as the bootloader to use
# ARM KVM.
board.set_kernel_disk_workload(
    kernel=KernelResource(args.kernel),
    disk_image=DiskImageResource(args.disk),
    bootloader=obtain_resource("arm64-bootloader"),
    readfile_contents=writeRunScript(args.function),
    kernel_args=["console=ttyAMA0",
                 "lpj=19988480", "norandmaps",
                 "root=/dev/vda2", "disk_device=/dev/vda2",
                 'isolcpus=1',
                 "rw", "mem=2147483648"
                ],
    checkpoint=Path("{}/{}".format(args.checkpoint_dir, args.function)) if args.mode=="evaluation" else None,
)
# We define the system with the aforementioned system defined.
simulator = Simulator(
    board=board,
    on_exit_event={
        # ExitEvent.EXIT: (func() for func in [processor.switch]),
        # ExitEvent.WORKBEGIN: workbegin(),
        # ExitEvent.WORKEND: workend(),
        ExitEvent.EXIT: executeExit(),
        ExitEvent.FAIL: executeFail(),
        },
)

# Once the system successfully boots, it encounters an
# `m5_exit instruction encountered`. We stop the simulation then. When the
# simulation has ended you may inspect `m5out/board.terminal` to see
# the stdout.
simulator.run()
