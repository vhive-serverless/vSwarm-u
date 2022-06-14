---
layout: default
title: Install Function manually
parent: Simulation
nav_order: 50
---


## Install Function manually
1. Make a copy of the disk image in your working directory

2. Start the emulator with the following command:
```bash
sudo qemu-system-x86_64 \
    -nographic \
    -cpu host -enable-kvm \
    -smp 4 -m 8GB \
    -device e1000,netdev=net0 \
    -netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
    -drive format=raw,file=<path/to/disk/image> \
    -kernel <path/to/kernel> \
    -append 'earlyprintk=ttyS0 console=ttyS0 lpj=7999923 root=/dev/hda2'
```
Qemu will boot linux from the disk image you specified. Once booted login as `root` (password `root`).

Now you are able to pull function images onto base disk image. We will use the the `vhiveease/fibonacci-go` function image as example:
```bash
# Pull your containerized function image
docker pull  vhiveease/fibonacci-go
```
Pull all images you want to benchmark.

Once all images are installed you can shutdown qemu with `shutdown -h now`. However, to make sure that the disk image is properly installed and works from a software perspective the `test-client` we put onto the image to perform a quick test.
   > Note you can find the source code of the client together with your hands out material.

```bash
# 1. Start your function container
# -d detaches the process and we can continue in the same console.
# -p must be set to export the ports
docker run -d --name mycontainer -p 50051:50051 vhiveease/fibonacci-go

# run the client with the port you export in docker as well as the number of invocations you want to run.
# -addr is the address and port we where exporting with the docker command
# -n is the number of invocations the client should perform
./client -addr localhost:50051 -n 100
```
The client should print its progress after every 10 invocations.
Now the disk image is ready for the Gem5 simulator. Stop the container and shutdown qemu.
```
docker stop mycontainer && docker rm mycontainer
shutdown -h now
```
> Note: Qemu breaks the line wrapping you might want to reset the console by executing `reset`.
