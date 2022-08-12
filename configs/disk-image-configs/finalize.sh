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

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

shutdown -h now