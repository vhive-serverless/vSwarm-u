#!/bin/bash

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

# Execute this script using
#   ./sim_all_functions.sh <results>

set -x

GEM5=<__GEM5__>
KERNEL=kernel
DISK_IMAGE=disk.img
GEM5_CONFIG=run_sim.py



################################################################################
sudo chown $USER /dev/kvm


## Parse the functions.list file
## Functions can be commented out with '#'
FUNCTIONS=$(cat functions.list | sed '/^\s*#/d;/^\s*$/d')


# Define the output file of your run
RESULTS_DIR=${1:-results}


for fn in $FUNCTIONS ;
do
    OUTDIR=$RESULTS_DIR/${fn}/

    ## Create output directory
    mkdir -p $OUTDIR

    sudo $GEM5 \
        --outdir=$OUTDIR \
            $GEM5_CONFIG \
                --kernel $KERNEL \
                --disk $DISK_IMAGE \
                --function ${fn} \
                --mode=evaluation \
                --atomic-warming 10 \
                --num-invocation 10 \
            > $OUTDIR/gem5.log 2>&1 \
            &

done
