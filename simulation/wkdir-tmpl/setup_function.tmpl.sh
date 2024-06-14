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
#   ./sim_function.sh <function> <results>


set -x

GEM5=<__GEM5__>
KERNEL=kernel
DISK_IMAGE=disk.img
GEM5_CONFIG=<__GEM5_CONFIG__>



################################################################################

sudo chown $USER /dev/kvm

# Define the results directory and the function for your run.
FN=${1:-fibonacci-go}
RESULTS_DIR=${2:-results}


OUTDIR=$RESULTS_DIR/${FN}/
## Create output directory
mkdir -p $OUTDIR

sudo $GEM5 \
    --outdir=$OUTDIR \
        $GEM5_CONFIG \
            --kernel $KERNEL \
            --disk $DISK_IMAGE \
            --function ${FN} \
            --mode=setup
