import sys

import m5
from m5.objects import *

# sys.path.append('configs/common/') # For the next line...
# import SimpleOpts

import argparse

sys.path.append('../gem5-configs/') # For the next line...
from system import MySystem



def parse_arguments():
    parser = argparse.ArgumentParser(description=
                        "gem5 config file to run vSwarm benchmarks")
    parser.add_argument("--kernel", type = str, help = "Path to vmlinux")
    parser.add_argument("--disk", type = str,
                  help = "Path to the disk image containing your function image")
    parser.add_argument("-s", "--script", action="store", type=str, default="",
                        help="""Specify a script that will be executed automatically
                            after booting from the gem5init service.""")
    return parser.parse_args()



def prRed(skk): print("\033[91m {}\033[00m" .format(skk))
def prGreen(skk): print("\033[92m {}\033[00m" .format(skk))
def prYellow(skk): print("\033[93m {}\033[00m" .format(skk))

FAIL_CODES = {
    1:"1: BOOTING complete",
    2:"2: Started container",
    3:"3: Pinned container",
    4:"4: Invoking done",
    5:"5: Container stop",
    -1: "Exit simulation",
}


def executeM5FailCode(code):
    if code not in FAIL_CODES:
        print("Nothing to do for fail code: %s", code)
        return

    prYellow(FAIL_CODES[code])

    Before invoking we switch to detailed core
    if code == 3:
        print("Switch detailed core")
        system.switchToDetailedCpus()
        m5.stats.reset()

    if code == 4:
        print("Switch to kvm core")
        system.switchToKvmCpus()
        m5.stats.dump()
        m5.stats.reset()

    if code == -1:
        prGreen("Test simulation done.")
        exit(0)



def simulate():
    '''
    --- Main simulation loop ---
    Run the simulator until either
    - user exits
    - or the run script exits with fail code -1
    '''

    while True:
        print("Start simulation...")
        exit_event = m5.simulate()

        if exit_event.getCause() == "m5_fail instruction encountered":
            executeM5FailCode(exit_event.getCode())

        elif exit_event.getCause() == "user interrupt received":
            print("Received user interrupt. Exit simulation")
            exit(1)

        else:
            print("Exit cause: %s | code: %d" % (exit_event.getCause(), exit_event.getCode()))




if __name__ == "__m5_main__":

    args = parse_arguments()

    # create the system we are going to simulate
    system = MySystem(args.kernel, args.disk, CPUModel=TimingSimpleCPU)

    # Read in the script file passed in via an option.
    # This file gets read and executed by the simulated system after boot.
    # Note: The disk image needs to be configured to do this.
    system.readfile = args.script

    # set up the root SimObject and start the simulation
    root = Root(full_system = True, system = system)

    if system.getHostParallel():
        # Required for running kvm on multiple host cores.
        # Uses gem5's parallel event queue feature
        # Note: The simulator is quite picky about this number!
        root.sim_quantum = int(1e9) # 1 ms

    # instantiate all of the objects we've created above
    m5.instantiate()

    # Run the simulator
    simulate()
