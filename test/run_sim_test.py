import m5
from m5.objects import *

# sys.path.append('configs/common/') # For the next line...
# import SimpleOpts
import os
ROOT = os.path.abspath(os.path.dirname(os.path.realpath(__file__)) + "/../")
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

    return parser.parse_args()



def writeRunScript(dir, function_name):
    n_invocations=5
    n_warming=5000
    FN_NAME=function_name
    tmpl = f"""
#!/bin/bash


m5 fail 1 ## 1: BOOTING complete

## Spin up Container
echo "Start the container..."
docker-compose -f functions.yaml up -d {FN_NAME} &&DOCKER_START_RES=$?
m5 fail 2 ## 2: Started container

echo "Pin to core 1"
docker update function --cpuset-cpus 1

sleep 5
m5 fail 3 ## 3: Pinned container


## Now start the warming of the function
/root/test-client \
    -function-name {FN_NAME} \
    -url localhost \
    -port 50000 \
    -n {n_warming} -input 10 \
    && INVOKER_RES=$?

m5 fail 4 ## 4: Warming done

# -------------------------------------------
m5 fail 10 ## 10: Start invoking

## Now start the actual measurement of the function
/root/test-client \
    -function-name {FN_NAME} \
    -url localhost \
    -port 50000 \
    -n {n_invocations} -input 10 \
    && INVOKER_RES=$?

m5 fail 11 ## 11: Stop invoking
# -------------------------------------------


## Stop container
docker-compose -f functions.yaml down && DOCKER_STOP_RES=$?
m5 fail 6 ## 6: Container stop

sleep 5

if [ $INVOKER_RES ] && [ $DOCKER_START_RES ] && [ $DOCKER_STOP_RES ] ; then
    echo "SUCCESS: All commands completed successfully"
else
    echo "FAIL: Commands failed"
fi

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
    10: "10: Start invoking",
    11: "11: Stop invoking",
    -1: "Exit simulation",
}


def executeM5FailCode(code):
    if code not in FAIL_CODES:
        print("Nothing to do for fail code: %s", code)
        return

    prYellow(FAIL_CODES[code])

    # Before invoking we switch to detailed core
    if code == 10:
        print("Switch detailed core")
        system.switchToDetailedCpus()
        m5.stats.reset()

    if code == 11:
        print("Switch to kvm core")
        system.switchToKvmCpus()
        m5.stats.dump()
        m5.stats.reset()

    if code == -1:
        prGreen("Simulation done.")
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
    if args.system =="skylake":
        system = SklSystem(args.kernel, args.disk, CPUModel=SklTunedCPU)
    else:
        system = SimpleSystem(args.kernel, args.disk, CPUModel=TimingSimpleCPU)


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

    # instantiate all of the objects we've created above
    m5.instantiate()

    # Run the simulator
    simulate()
