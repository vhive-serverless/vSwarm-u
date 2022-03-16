#!/bin/bash

## Define the image name of your function.
IMAGE_NAME=<your function image>

## Spin up Container
echo "Start the container..."
docker run -d --name mycontainer -p 50051:50051 $IMAGE_NAME

echo "Pin to core 1"
docker update  mycontainer --cpuset-cpus 1

sleep 5

# Booting Linux and starting the invoker
# is completed. Break out of the simulation and switch CPU
echo "Execute m5 exit to indicate boot complete"
m5 exit

## Now start the invoker
# Modify the invoker parameters depending on your need.

/root/client -addr localhost:50051 -n 20

## Call exit again to end the simulation
m5 exit