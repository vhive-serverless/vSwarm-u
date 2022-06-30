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
# Install dependencies

set -e

# Allow root to login with ssh
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Do a full upgrade
apt update
# apt full-upgrade -y
apt install -y net-tools
# apt full-upgrade -y
# sudo apt-get -y install \
#     gcc \
#     g++ \
#     make

ARCH=amd64
if [ $(uname -i) == "aarch64" ]; then ARCH=arm64 ; fi

##### GEM5 specific setup #####
## Prepare gem5 utility tool
wget http://_gateway:3003/m5.${ARCH}
mv m5.${ARCH} /sbin/m5
chmod +x /sbin/m5

## Create and enable the gem5 init service
wget -P /sbin/ http://_gateway:3003/gem5init
chmod +x /sbin/gem5init

cat > /lib/systemd/system/gem5.service <<EOF
[Unit]
Description=gem5 init script
Documentation=http://gem5.org
After=getty.target

[Service]
Type=idle
ExecStart=/sbin/gem5init
StandardOutput=tty
StandardInput=tty-force
StandardError=tty

[Install]
WantedBy=default.target
EOF

# Enable gem5 service
systemctl enable gem5.service



##### Serverless specific setup #####

# Install docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
&& add-apt-repository \
    "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
&& apt-get update \
&& apt-get install -y docker-ce docker-ce-cli containerd.io


# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
&& chmod +x /usr/local/bin/docker-compose


# Install golang
VERSION=1.16.4
GO_BUILD="go${VERSION}.linux-${ARCH}"

wget --continue --quiet https://golang.org/dl/${GO_BUILD}.tar.gz
sudo tar -C /usr/local -xzf ${GO_BUILD}.tar.gz
export PATH=$PATH:/usr/local/go/bin
sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"

## Get the client binary
wget -P /root/ http://_gateway:3003/client-${ARCH}
chmod +x /root/client

