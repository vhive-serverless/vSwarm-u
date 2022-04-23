#!/bin/bash

## Define the image name of your function.
IMAGE_NAME=<__IMAGE_NAME__>
FUNCTION_NAME=<__FUNCTION_NAME__>

## Log everything to a empty log file
rm results.log 2> /dev/null
touch results.log

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1> results.log 2>&1

echo "TEST: ${FUNCTION_NAME} --> Image: ${IMAGE_NAME}"

## Download the test client.
curl  "http://10.0.2.2:3003/test-client" -f -o /root/test-client
chmod 755 /root/test-client

## Pull the image from regestry
docker pull $IMAGE_NAME

## Spin up Container
echo "Start the container..."
docker run -d --rm --name mycontainer -p 50051:50051 $IMAGE_NAME && DOCKER_START_RES=$?

sleep 5

## Now start the invoker
# Modify the invoker parameters depending on your need.
# /root/test-client -addr localhost:50051 -n 20 && INVOKER_RES=$?
/root/test-client \
    -function-name test \
    -url localhost \
    -port 50051 \
    -n 20 \
    && INVOKER_RES=$?



## Stop container
docker stop mycontainer && DOCKER_STOP_RES=$?


if [ $INVOKER_RES ] && [ $DOCKER_START_RES ] && [ $DOCKER_STOP_RES ] ; then
    echo "SUCCESS: All commands completed successfully"
else
    echo "FAIL: Commands failed"
fi

# Restore file descriptors
exec 2>&4 1>&3

## Upload the log file.
curl  "http://10.0.2.2:3003/upload" -F 'files=@results.log'

shutdown -h now
