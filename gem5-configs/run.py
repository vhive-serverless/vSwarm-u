import sys

import m5
from m5.objects import *

# sys.path.append('configs/common/') # For the next line...
# import SimpleOpts
import argparse

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


def boot_linux():
    '''
    Output 1: False if errors occur, True otherwise
    Output 2: exit cause
    '''
    print("Booting Linux")
    exit_event = m5.simulate()
    exit_cause = exit_event.getCause()
    exit_code = exit_event.getCode()
    success = exit_cause == "m5_exit instruction encountered"
    if success:
        print("Exit cause: %s | code: %d" % (exit_cause, exit_code))
    print("Booting done")
    return success, exit_cause


def simulateUntilExitEvent():
    '''
    return: True if m5_exit event occur, False otherwise
    '''
    print("Start simulation...")
    exit_event = m5.simulate()
    exit_cause = exit_event.getCause()
    success = exit_cause == "m5_exit instruction encountered"
    if success:
        print("Exit cause: %s | code: %d" % (exit_cause, exit_event.getCode()))
    return success

def run_function():
    '''
    Output 1: False if errors occur, True otherwise
    Output 2: exit cause
    '''
    print("Run the invoker to drive the function")
    exit_event = m5.simulate()
    exit_cause = exit_event.getCause()
    exit_code = exit_event.getCode()
    success = exit_cause == "m5_exit instruction encountered"
    if success:
        print("Exit cause: %s | code: %d" % (exit_cause, exit_code))
    print("Invoker completed")
    return success, exit_cause


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

    # Boot Linux using Kvm
    success = simulateUntilExitEvent()
    if not success:
        print("An error occurred while booting linux")

    # Switch CPU.
    print("Switch to detailed core")
    system.switchToDetailedCpus()

    # Before starting the invoker reset all stats
    m5.stats.reset()
    # Now start the simulation again.
    # The next step in the script will be executed which is
    # running the invoker
    success = simulateUntilExitEvent()
    if not success:
        print("An error occurred while invoking the function")

    # Once the script sends the next exit command we know that
    # the invoker is finish.
    # Dump the stats and exit the simulation
    m5.stats.dump()

    print ("Simulation done ... ;)")

    # run_function()
