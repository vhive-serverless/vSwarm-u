> [Main](../README.md) ▸ **Benchmarks**
# Install function images on a disk image


## Function benchmarks

For managing the functions to be benchmarked during the simulation we use docker-compose. docker compose allows predefining even complexer setups with several connected functions.

The functions to be benchmarks need to be defined in the `benchmarks/function.yaml` as [docker-compose](https://docs.docker.com/compose/compose-file/) configuration. In `benchmarks/all_vswarm_functions.yaml` we predefined the correct confib for all functions we currently supported in our benchmarks suite [vSwarm](https://github.com/ease-lab/vSwarm/. Use it as a reference or simply copy the config to the `function.yaml`

Hints:
1. The client to drive the invocations will connect port `50000`. Therefore make sure to forward the function port to this host port.
2. For all simulations the same disk image is used. Therefore define all functions in this file.

### Build working dir
```bash
make build_wkdir
```

```bash
make build_wkdir
```

### Install the images
Once all setup steps are completed the `RESOURCE` folder should contain a raw base disk image. On this base image all necessary packages i.e. docker, python,.. are preinstalled. However, the disk image does not contain the container images of the benchmarks we want to run. Therefore, before starting simulation the base image need to be augmented with the container images.

For installing all functions defined in the functions.yaml file run the `install_functions` recipe.
```bash
make install_functions
```




To do this use the qemu emulator as it has access to the internet for pulling the most recent image. The image installation can be done manually or with the make recipes we provide.

## Automatic install.
For installing functions automatically on a base disk image the functions need to be defined in the `benchmarks/function.yaml` file.




## Manual installation
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
