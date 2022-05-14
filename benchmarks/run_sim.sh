#!/bin/bash

set -x

GEM5=<__GEM5__>
KERNEL=<__KERNEL__>
DISK_IMAGE=<__DISK_IMAGE__>
GEM5_CONFIG=<__GEM5_CONFIG__>
RUN_SCRIPT_TEMPLATE=<__RUN_SCRIPT_TEMPLATE__>


################################################################################
# if [ $CPU_TYPE == X86KvmCPU ] ;
# then
sudo chown $USER /dev/kvm


BMS="aes-go aes-nodejs"

# Define the output file of your run
BASE_OUTDIR=../results/


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
