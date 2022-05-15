#!/bin/bash

set -x

GEM5=<__GEM5__>
KERNEL=kernel
DISK_IMAGE=disk.img
GEM5_CONFIG=run_sim.py



################################################################################
# if [ $CPU_TYPE == X86KvmCPU ] ;
# then
sudo chown $USER /dev/kvm


BMS="$(cat functions.list)"

# Define the output file of your run
BASE_OUTDIR=results/experiment1/


for i in $BMS ;
do
    OUTDIR=$BASE_OUTDIR/${i}/

    ## Create output directory
    mkdir -p $OUTDIR

    sudo $GEM5 \
        --outdir=$OUTDIR \
            $GEM5_CONFIG \
                --kernel $KERNEL \
                --disk $DISK_IMAGE \
                --function ${i} \
            > $OUTDIR/gem5.log 2>&1 \
            &

done
