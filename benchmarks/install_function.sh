#!/bin/bash

set -x

LOGFILE=results.log

function start_logging {
  ## Log everything to a empty log file
  [ -e $LOGFILE ] && rm -- $LOGFILE
  touch $LOGFILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1> $LOGFILE 2>&1
}
function end_logging {
  Restore file descriptors
  exec 2>&4 1>&3
}


function pull_test_function {
    FUNCTION_NAME=$1

    echo "Install and test: ${FUNCTION_NAME} "

    ## Pull the image from regestry
    docker-compose -f functions.yaml pull ${FUNCTION_NAME}
    docker-compose -f functions.yaml up -d ${FUNCTION_NAME}

    sleep 5

    ## Now start the invoker
    /root/test-client \
        -function-name ${FUNCTION_NAME} \
        -url localhost \
        -port 50000 \
        -n 5 -input 1

    ## Stop container
    docker-compose -f functions.yaml down
}


start_logging
{
set -e
## Download the test client.
curl  "http://10.0.2.2:3003/test-client" -f -o /root/test-client
chmod 755 /root/test-client

## Download the function yaml and list.
curl  "http://10.0.2.2:3003/functions.yaml" -f -o functions.yaml
curl  "http://10.0.2.2:3003/functions.list" -f -o functions.list


# docker-compose -f functions.yaml pull

FUNCTIONS=$(cat functions.list)

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
set +e
end_logging

## Upload the log file.
curl  "http://10.0.2.2:3003/upload" -F "files=@${LOGFILE}"

shutdown -h now
