
#!/bin/bash

# MIT License
#
# Copyright (c) 2022 EASE lab, University of Edinburgh
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
#
# Authors: David Schall


LOGFILE=test.log

function start_logging {
  ## Log everything to a empty log file
  [ -e $LOGFILE ] && rm -- $LOGFILE
  touch $LOGFILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1> $LOGFILE 2>&1
}
function end_logging {
  # Restore file descriptors
  exec 2>&4 1>&3
}




function pull_test_function {
    FUNCTION_NAME=$1

    echo "Test: ${FUNCTION_NAME} "

    ## Pull the image from regestry
    docker-compose -f functions.yaml pull ${FUNCTION_NAME}
    docker-compose -f functions.yaml up -d --remove-orphans ${FUNCTION_NAME} && DOCKER_START_RES=$?

    sleep 5

    ## Now start the invoker
    # Modify the invoker parameters depending on your need.
    # /root/test-client -addr localhost:50051 -n 20 && INVOKER_RES=$?
    /root/test-client \
        -function-name ${FUNCTION_NAME} \
        -url localhost \
        -port 50000 \
        -n 20 -input 1 \
        && INVOKER_RES=$?

    ## Stop container
    docker-compose -f functions.yaml down && DOCKER_STOP_RES=$?
    CONTAINERS="$(docker ps -a -q)"
    if [ $(expr length "$CONTAINERS") -gt 0 ];
    then
      docker stop $CONTAINERS
      docker rm $CONTAINERS
    fi

    if [ $INVOKER_RES ] && [ $DOCKER_START_RES ] && [ $DOCKER_STOP_RES ] ; then
        echo "SUCCESS: All commands completed successfully"
    else
        echo "FAIL: Commands failed"
    fi
}


start_logging
{
# set -e
## Download the test client.
curl  "http://10.0.2.2:3003/test-client" -f -o /root/test-client
chmod 755 /root/test-client

## Download the function yaml and list.
curl  "http://10.0.2.2:3003/functions.yaml" -f -o functions.yaml
curl  "http://10.0.2.2:3003/functions.list" -f -o functions.list


# docker-compose -f functions.yaml pull

## List all functions, can be commented out
FUNCTIONS=$(cat functions.list | sed '/^\s*#/d;/^\s*$/d')

for f in $FUNCTIONS
  do
    pull_test_function $f
  done

## Catch for failiure ----------
} || {
  echo "\033[0;31m----------------"
  echo "FAIL"
  echo "----------------\033[0m"
  cat results.log
}
# set +e
end_logging

## Upload the log file.
curl  "http://10.0.2.2:3003/upload" -F "files=@${LOGFILE}"

shutdown -h now
