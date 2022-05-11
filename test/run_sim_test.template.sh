#!/bin/bash

## Define the image name of your function.
IMAGE_NAME=<__IMAGE_NAME__>
FUNCTION_NAME=<__FUNCTION_NAME__>


## Log everything to a empty log file
rm /tmp/results.log 2> /dev/null
touch /tmp/results.log

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1> /tmp/results.log 2>&1


echo "TEST: ${FUNCTION_NAME} --> Image: ${IMAGE_NAME} on gem5"

# We use the fail code magic instruction to indicate the
# python script where in test process we are.

m5 fail 1 ## 1: BOOTING complete


## Spin up Container
echo "Start the container..."
docker run -d --rm --name mycontainer -p 50051:50051 $IMAGE_NAME && DOCKER_START_RES=$?
m5 fail 2 ## 2: Started container

echo "Pin to core 1"
docker update  mycontainer --cpuset-cpus 1

sleep 5
m5 fail 3 ## 3: Pinned container


## Now start the invoker
# Modify the invoker parameters depending on your need.
# /root/test-client -addr localhost:50051 -n 20 && INVOKER_RES=$?
/root/test-client \
    -function-name ${FUNCTION_NAME} \
    -url localhost \
    -port 50051 \
    -n 20 \
    && INVOKER_RES=$?

m5 fail 4 ## 4: Invoking done

## Stop container
docker stop mycontainer && DOCKER_STOP_RES=$?
m5 fail 5 ## 5: Container stop


if [ $INVOKER_RES ] && [ $DOCKER_START_RES ] && [ $DOCKER_STOP_RES ] ; then
    echo "SUCCESS: All commands completed successfully"
else
    echo "FAIL: Commands failed"
fi

# Restore file descriptors
exec 2>&4 1>&3

m5 writefile /tmp/results.log results_sim.log


## M5 fail -1 will exit the simulations
m5 fail -1 ## 5: Test done
