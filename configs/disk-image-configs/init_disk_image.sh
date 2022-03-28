#!/bin/bash


# Allow root to login with ssh
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Do a full upgrade
apt update
apt full-upgrade -y
sudo apt-get -y install \
    gcc \
    g++ \
    make


##### GEM5 specific setup #####
## Prepare gem5 utility tool
wget http://_gateway:3003/m5.x86
mv m5.x86 /sbin/m5
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
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
&& apt-get update \
&& apt-get install -y docker-ce docker-ce-cli containerd.io


# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
&& chmod +x /usr/local/bin/docker-compose


# Install golang
wget --continue --quiet https://golang.org/dl/go1.16.4.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.16.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
sh -c  "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"


# # Clone the vSwarm repo
# git clone https://github.com/ease-lab/vSwarm.git

## Get the client binary
wget -P /root/ http://_gateway:3003/client
chmod +x /root/client

