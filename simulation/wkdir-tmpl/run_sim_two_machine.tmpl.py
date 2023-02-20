# MIT License
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


import m5
from m5.objects import *

# sys.path.append('configs/common/') # For the next line...
# import SimpleOpts
import os
from pathlib import Path
ROOT = '<__ROOT__>'
print(ROOT)

import sys
sys.path.append(ROOT +'/gem5utils/systems/') # For the next line...
from skylake.system import SklSystem
from skylake.core import SklTunedCPU
from simple.system import SimpleSystem
from drive.system import DriveSystem

import argparse
def parse_arguments():
    parser = argparse.ArgumentParser(description=
                        "gem5 config file to run vSwarm benchmarks")
    parser.add_argument("--kernel", type = str, help = "Path to vmlinux")
    parser.add_argument("--disk", type = str,
                  help = "Path to the disk image containing your function image")
    parser.add_argument("-s", "--script", action="store", type=str, default="",
                        help="""Specify a script that will be executed automatically
                            after booting from the gem5init service.""")
    parser.add_argument("-f", "--function", action="store", type=str, default="",
                        help="""Specify a function that should run in the simulator.""")
    parser.add_argument("--cpu", type=str, default="SklTunedCPU",
                        help="""Define the system to be used.""")
    parser.add_argument("--atomic-warming", type=int, default=0,
                        help="""Perform warming of the cache hierarchy using the atomic core.""")
    parser.add_argument("--num-invocations", type=int, default=5,
                        help="""Number of invocation to be measured.""")
    parser.add_argument("--mode", type=str, default="setup",choices=["setup", "evaluation",],
                        help="""Setup mode: Will boot linux using the kvm core, perform functional
                                warming and then take a snapshot.
                                Evaluation mode: Will start from a previously taken checkpoint
                                do some """)
    parser.add_argument("--take-checkpoints", action="store_true", default=False,
                        help="""Take a checkpoint after system is configured and ready
                            to start the proper simulation""")
    parser.add_argument("--use-checkpoint", type=str, default="warm",choices=["boot", "warm",],
                        help="""Choose from which checkpoint to start from
                                boot: taken after booting. warm: taken after functional warming.""")
    parser.add_argument("--checkpoint-dir", type = str, default="cpt_2m/",
                        help = "Directory of")
    parser.add_argument(
        "--etherdump", action="store", type=str, dest="etherdump",
        help="Specify the filename to dump a pcap capture of the"
        "ethernet traffic")
    return parser.parse_args()


_f = int(1e12)
_us = _f/int(1e6)
_ms = _f/int(1e3)
_s = _f/1



def create_system(linux_kernel_path, disk_image_path, detailed_cpu_model, kvm=False):

    # create the system we are going to simulate
    system = SklSystem(kernel = linux_kernel_path,
                    disk = disk_image_path,
                    num_cpus = 2, # run the benchmark in a single thread
                    CPUModel = detailed_cpu_model,
                    kvm = kvm)
    # For workitems to work correctly
    # This will cause the simulator to exit simulation when the first work
    # item is reached and when the first work item is finished.
    system.exit_on_work_items = True
    # system.work_item_id = 1
    # system.work_begin_exit_count = 1
    # system.work_end_exit_count = 1
    system.m5ops_base = int("ffff0000",16)
    return system

def create_drive_system(linux_kernel_path, disk_image_path, kvm=False):
    # create the system we are going to simulate
    drv_sys = DriveSystem(kernel = linux_kernel_path,
                    disk = disk_image_path, kvm=kvm)
    drv_sys.exit_on_work_items = True
    drv_sys.m5ops_base = int("ffff0000",16)
    return drv_sys


def makeDualRoot(full_system, testSystem, driveSystem, dumpfile,kvm=False):
    self = Root(full_system = full_system)
    self.testsys = testSystem
    self.drivesys = driveSystem

    # Required for running kvm on multiple host cores.
    # Uses gem5's parallel event queue feature
    # Note: The simulator is quite picky about this number!
    # setting this number to low will cause a lot of switches
    # between the cores and we will see no progress. On the other
    # hand when setting to high our dual core system has problems.
    #
    # Therefore we only do booting and functional warming with kvm.
    # Then we take a checkpoint and exit.
    # For the measurement we start from the checkpoint. Now
    # we can have only one event queue and no need for a simulation
    # quantum > 0 anymore.

    f = int(1e12)
    # Set the sim quatum
    # 1ms for kvm. 0 if no kvm is used
    q = 1000 if kvm else 0
    sq = int(1000 * _us)
    print(f"Tick freq = {f} ticks/sec. Set sim quantum to {sq} ticks/sec => {q}µs")
    self.sim_quantum = sq

    # Connect the two system with a wire.
    # ! Ensure that the delay is larger than the simQuantum.
    # This is really important otherwise you might receive packets in the same
    # quantum as you send the packet. This can result in strange behaviours
    # that the receiving core process it already before it is actually send.
    latency = f"{2*q}us"
    self.etherlink = EtherLink(delay=latency)

    if hasattr(testSystem, "pc"):
        self.etherlink.int0 = Parent.testsys.pc.ethernet.interface
        self.etherlink.int1 = Parent.drivesys.pc.ethernet.interface
    else:
        fatal("Don't know how to connect these system together")

    if dumpfile:
        self.etherdump = EtherDump(file=dumpfile, maxlen=2048)
        self.etherlink.dump = Parent.etherdump
    return self




def writeDriveScript(dir, function):
    drive_ip = "10.0.2.18"
    test_ip = "10.0.2.17"
    device = "enp0s2"
    n_invocations=50
    n_warming=20000

    tmpl = f"""
#!/bin/bash

echo "\nExecute m5 exit to indicate boot complete"
m5 exit

## Configure network interface
echo "Config: {device} with ipaddress {drive_ip} "
ifconfig {device} {drive_ip}
ifconfig {device} up

# -------------------------------------------
m5 fail 10 ## 10: Start client

## Now start the actual measurement of the function
/root/test-client \
    -function-name {function} \
    -url {test_ip} \
    -port 50000 -random \
    -n {n_invocations} \
    -w {n_warming} \
    -m5ops \
    -input 10

m5 fail 11 ## 11: Stop client
# -------------------------------------------


## M5 fail -1 will exit the simulations
m5 fail -1 ## 5: Test done

"""
    input_file_name = '{}/{}'.format(dir, "run_drive.sh")
    with open(input_file_name, "w") as f:
        f.write(tmpl)
    return input_file_name



def writeRunScript(dir, function, cpu=1):
    test_ip = "10.0.2.17"
    device_name = "enp0s2"
    tmpl = f"""
#!/bin/bash

m5 fail 1 ## 1: BOOTING complete

## Configure network interface
echo "Config: {device_name} with ipaddress {test_ip} "
ifconfig {device_name} {test_ip}

## Spin up Container
echo "Start the container..."
docker-compose -f /root/functions.yaml up -d {function}
m5 fail 2 ## 2: Started container

echo "Pin function container to core {cpu}"
docker update function --cpuset-cpus {cpu}

sleep 5
m5 fail 3 ## 3: Pinned container

echo "Container is running. Turn on network IF {device_name}"
ifconfig {device_name} up

"""
    input_file_name = '{}/{}'.format(dir, "run.sh")
    with open(input_file_name, "w") as f:
        f.write(tmpl)
    return input_file_name



def prRed(skk): print("\033[91m {}\033[00m" .format(skk))
def prGreen(skk): print("\033[92m {}\033[00m" .format(skk))
def prYellow(skk): print("\033[93m {}\033[00m" .format(skk))

FAIL_CODES = {
    1:"1: BOOTING complete",
    2:"2: Started container",
    3:"3: Pinned container",
    4:"4: Warming done",
    6:"6: Container stop",
    10: "10: Start client",
    11: "11: Stop client",
    21: "21: Send request  ->",
    22: "22: Recv response <-",
    31: "31: Start warming",
    32: "32: Stop warming",
    -1: "Exit simulation",
}


inv_to_warm = -1
inv_to_measure = -1

def workitem(begin, id):
    global inv_to_warm,inv_to_measure
    id -= 100
    if args.mode != "evaluation":
        return

    if begin:
        prYellow(f"Start invokation: {id}")

        ## Perform warming if needed
        if inv_to_warm > 0:
            return
        if inv_to_warm == 0:
            prGreen("Warming done")
            system.switchToMainCpu()
            drive_sys.switchToMainCpu()
            inv_to_warm = -1
            m5.stats.reset()

        # if inv_to_measure > 0:
        #     m5.stats.reset()

    else:
        prYellow(f"End invokation: {id}")

        if inv_to_warm > 0:
            inv_to_warm -= 1
            return

        if inv_to_measure > 0:
            # m5.stats.dump()
            inv_to_measure -= 1

        if inv_to_measure == 0:
            prGreen("Measuring done")
            m5.stats.dump()
            return True



def executeM5FailCode(code):
    if code not in FAIL_CODES:
        print("Nothing to do for fail code: %s", code)
        return False

    prYellow(FAIL_CODES[code])

    # Take checkpoints after booting and warming
    # if code == 1 or code == 32:
    if code == 32:
        ckp_name = "boot" if code == 1 else \
                    "warm" if code == 32 else "xx"
        ckp="{}/{}/cpt.{}".format(args.checkpoint_dir, args.function, ckp_name)
        print("Create checkpoint: ", ckp)
        m5.checkpoint(ckp)

    if code == -1:
        prGreen("Simulation done.")
        return True


def simulate():
    '''
    --- Main simulation loop ---
    Run the simulator until either
    - user exits
    - or the run script exits with fail code -1
    '''
    _exit=False
    while not _exit:
        print("Start simulation...")
        exit_event = m5.simulate()

        if exit_event.getCause() == "m5_fail instruction encountered":
            _exit=executeM5FailCode(exit_event.getCode())

        elif exit_event.getCause() == "workbegin":
            _exit=workitem(True,exit_event.getCode())
        elif exit_event.getCause() == "workend":
            _exit=workitem(False,exit_event.getCode())

        elif exit_event.getCause() == "user interrupt received":
            print("Received user interrupt. Exit simulation")
            _exit=True

        else:
            print("Exit cause: %s | code: %d" % (exit_event.getCause(), exit_event.getCode()))

    prGreen("Simulation done.")

if __name__ == "__m5_main__":

    args = parse_arguments()

    if args.take_checkpoints or args.mode == "setup":
        Path("{}/{}".format(args.checkpoint_dir, args.function)).mkdir(parents=True, exist_ok=True)

    kvm = True if args.mode == "setup" else False

    # Create the system we are going to simulate
    system = create_system(args.kernel, args.disk, SklTunedCPU,kvm=kvm)

    dual_system = True
    if dual_system:
        drive_sys = create_drive_system(args.kernel, args.disk,kvm=kvm)
        root = makeDualRoot(True, system, drive_sys, args.etherdump, kvm=kvm)
    else:
        root = Root(full_system=True, system=system)


    # Gem5 will automatically start a run script once booted.
    # The script is retrieved from `readfile`.
    # if we specify the function argument we generate this run script from the
    # template.
    # For the dual system setup we need to generate separate scripts for the
    # driving and test system.
    # - The test system only spin up the container and pin it to a core
    # - The drive system runs the client and invoke the other system calling its ip.

    if dual_system:
        system.readfile = writeRunScript(m5.options.outdir, args.function, 1)
        drive_sys.readfile = writeDriveScript(m5.options.outdir, args.function)
    else:
        system.readfile = args.script

    # instantiate all of the objects we've created above
    if args.mode == "setup":
        print("--- Setup Mode ---")
        # In setup mode we do not exit on work items
        m5.instantiate()


    elif args.mode == "evaluation":
        print("--- Evaluation Mode ---")

        ckp="{}/{}/cpt.{}".format(args.checkpoint_dir, args.function, args.use_checkpoint)
        print("Instantiate checkpoint: ", ckp)

        ## Run just for a few instructions with the main CPU
        ## to setup everything. The we can optionally switch to atomic
        for i in range(len(system.cpu)):
            system.cpu[i].switched_out = False
            system.cpu[i].max_insts_any_thread = 1
            system.atomic_cpu[i].switched_out = True

        # instantiate all of the objects we've created above
        # and the checkpoint previously taken
        m5.instantiate(ckp)
        exit_event = m5.simulate()

        ## If needed switch to the atomic core to warm the caches
        if args.atomic_warming > 0:
            system.switchToAtomicCpu()
            drive_sys.switchToAtomicCpu()
            inv_to_warm = args.atomic_warming

        inv_to_measure = args.num_invocations
        prGreen(f"Warming for {inv_to_warm} invocations")
        prGreen(f"Measure for {inv_to_measure} invocations")

    else:
        fatal("Invalid mode")

    simulate()