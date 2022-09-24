#!/usr/bin/env python3
from itertools import count
import os
import re
import argparse

ROOT = os.path.abspath(os.path.dirname(os.path.realpath(__file__)) + "/../")


def parse_arguments():
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("dir", type = str, help = "Results directory")
    return parser.parse_args()


def prRed(skk): print("\033[91m {}\033[00m" .format(skk))
def prGreen(skk): print("\033[92m {}\033[00m" .format(skk))



args = parse_arguments()
subdirs = [s for s in os.listdir(args.dir) if os.path.isdir(args.dir + s)]
subdirs.sort()

rerun_cmds = []
results = []


for subdir in subdirs[:]:
    filename = "{}/{}/gem5.log".format(args.dir,subdir)
    cmd = ""
    success = False

    if os.path.exists(filename):
        with open(filename) as f:
            start_tick = 0
            count = 0
            for line in f:
                if line[:14] == "command line: ":
                    cmd = line[14:].strip()
                # if "'fwait'" in line:
                #     print("{} stopped with 'fwait'".format(subdir))
                if "Simulation done" in line:
                    success = True
                    break
                if "End invokation:" in line:
                    count += 1

            if success:
                if count < 20:
                    status = "\033[93m WARN\033[00m"
                else:
                    status = "\033[92m succeed\033[00m"

            else:
                status= "\033[91m fail\033[00m"
            print(f"{subdir:>25} > {count} : {status}")
            rerun_cmds += [(success, f"{cmd} > {filename} 2>&1 &")]

total = len(rerun_cmds) -1
with open("rerun.sh", "w") as f:
    for success,cmd in rerun_cmds:
        comment = "# " if success else ""
        f.write(f"{comment} sudo {cmd} \n")

