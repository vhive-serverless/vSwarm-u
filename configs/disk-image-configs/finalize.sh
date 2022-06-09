#!/bin/bash

set -e

## Wait until cloud-init is finish

sleep 15;

while [ ! -f  /var/lib/cloud/instance/boot-finished ];
do echo wait; sleep 5;
done

# Prevent start by creating an empty file
touch /etc/cloud/cloud-init.disabled

# Or Uninstall the package and delete the folders

# sudo dpkg-reconfigure cloud-init
# sudo apt-get purge cloud-init
# sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/

shutdown -h now