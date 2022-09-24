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


from distutils.log import fatal
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
    parser.add_argument("--system", type=str, default="simple",choices=["simple", "skylake",],
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
    parser.add_argument("--checkpoint-dir", type = str, default="cpt_1m/",
                        help = "Directory of")
    return parser.parse_args()



def writeRunScript(dir, function_name):
    n_invocations=20
    n_warming=5000
    FN_NAME=function_name
    tmpl = f"""
#!/bin/bash

## Define the image name of your function.

# We use the 'm5 fail <code>' magic instruction to indicate the
# python script where in workflow the system currently is.

m5 fail 1 ## 1: BOOTING complete

## Spin up Container
echo "Start the container..."
docker-compose -f /root/functions.yaml up -d {FN_NAME}
m5 fail 2 ## 2: Started container

echo "Pin function container to core 1"
docker update function --cpuset-cpus 1

sleep 5
m5 fail 3 ## 3: Pinned container



m5 fail 10 ## 10: Start client

## The client will perform some functional warming
# and then send a fail code before invoking the
# function again for the actual measurement.
/root/test-client \
    -function-name {FN_NAME} \
    -url localhost \
    -port 50000 \
    -n {n_invocations} \
    -w {n_warming} \
    -m5ops \
    -input 10

m5 fail 11 ## 11: Stop client
# -------------------------------------------


## Stop container
docker-compose -f /root/functions.yaml down
m5 fail 6 ## 6: Container stop


## M5 fail -1 will exit the simulations
m5 fail -1 ## 5: Test done

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



if __name__ == "__m5_main__":

    args = parse_arguments()

    if args.take_checkpoints or args.mode == "setup":
        Path("{}/{}".format(args.checkpoint_dir, args.function)).mkdir(parents=True, exist_ok=True)

    kvm = True if args.mode == "setup" else False

    # create the system we are going to simulate
    if args.system =="skylake":
        system = SklSystem(args.kernel, args.disk, CPUModel=SklTunedCPU,kvm=kvm)
    else:
        system = SimpleSystem(args.kernel, args.disk, CPUModel=TimingSimpleCPU)

    system.m5ops_base = int("ffff0000",16)

    # For workitems to work correctly
    # This will cause the simulator to exit simulation when the first work
    # item is reached and when the first work item is finished.
    system.exit_on_work_items = True
    # system.work_item_id = 2
    # system.work_begin_exit_count = 1
    # system.work_end_exit_count = 1

    # Gem5 will automatically start a run script once booted.
    # The script is retrieved from `readfile`.
    # if we specify the function argument we generate this run script from the
    # template.
    if args.function:
        system.readfile = writeRunScript(m5.options.outdir, args.function)
    else:
        system.readfile = args.script


    # set up the root SimObject and start the simulation
    root = Root(full_system = True, system = system)

    if system.getHostParallel():
        # Required for running kvm on multiple host cores.
        # Uses gem5's parallel event queue feature
        # Note: The simulator is quite picky about this number!
        root.sim_quantum = int(1e9) # 1 ms


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
            inv_to_warm = args.atomic_warming

        inv_to_measure = args.num_invocations
        prGreen(f"Warming for {inv_to_warm} invocations")
        prGreen(f"Measure for {inv_to_measure} invocations")

    else:
        fatal("Invalid mode")

    simulate()