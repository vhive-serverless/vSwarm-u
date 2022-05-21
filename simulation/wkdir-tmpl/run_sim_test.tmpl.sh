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

## Define the image name of your function.
FUNCTION_NAME=<__FUNCTION_NAME__>

# We use the fail code magic instruction to indicate the
# python script where in test process we are.

m5 fail 1 ## 1: BOOTING complete


## Spin up Container
echo "Start the container..."
docker-compose -f functions.yaml up -d ${FUNCTION_NAME} &&DOCKER_START_RES=$?
m5 fail 2 ## 2: Started container

echo "Pin to core 1"
docker update  ${FUNCTION_NAME} --cpuset-cpus 1

sleep 5
m5 fail 3 ## 3: Pinned container


## Now start the invoker
# Modify the invoker parameters depending on your need.
# /root/test-client -addr localhost:50051 -n 20 && INVOKER_RES=$?
/root/test-client \
    -function-name ${FUNCTION_NAME} \
    -url localhost \
    -port 50000 \
    -n 5 -input 1 \
    && INVOKER_RES=$?

m5 fail 4 ## 4: Invoking done

## Stop container
docker-compose -f functions.yaml down && DOCKER_STOP_RES=$?
m5 fail 5 ## 5: Container stop


if [ $INVOKER_RES ] && [ $DOCKER_START_RES ] && [ $DOCKER_STOP_RES ] ; then
    echo "SUCCESS: All commands completed successfully"
else
    echo "FAIL: Commands failed"
fi

## M5 fail -1 will exit the simulations
m5 fail -1 ## 5: Test done
