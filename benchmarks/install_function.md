> [Main](../README.md) ▸ **Benchmarks**
# Install function images on a disk image

### Build initial working directory
Once you defined your functions in the yaml the next step is to setup a working directory. The `build_wkdir` recipe will make it convenient to build the initial setup.
```bash
make build_wkdir
```
The initial working directory will contain a setup with all you will need to run simulations.
1. Kernel and base disk image
2. A template of the function.yaml and function.list to define your functions.
3. A `start_simulation.sh` script for starting a simulation for each function you define in the `functions.list` file.
4. A basic gem5 config script.


## Defining Function Benchmarks

For managing the functions to be benchmarked during the simulation we use docker-compose. docker compose allows predefining even complexer setups with several connected functions.

The functions to be benchmarks need to be defined in the `benchmarks/function.yaml` as [docker-compose](https://docs.docker.com/compose/compose-file/) configuration. The simulation workflows has several requirements on the configuration.
1. The client to drive the invocations will connect port `50000`. Therefore make sure to forward the function port to this host port.
2. All functions you


In `benchmarks/all_vswarm_functions.yaml` we predefined the correct config for all functions we currently supported in our benchmarks suite [vSwarm](https://github.com/ease-lab/vSwarm/. Use it as a reference or simply copy the config to the `function.yaml`


Hints:
1.
2. For all simulations the same disk image is used. Therefore define all functions in this file.



### Install Function images on disk
Once all setup steps are completed your initial working directory should contain a raw base disk image. On this base image all necessary packages i.e. docker, python,.. are preinstalled. However, the disk image does not contain the container images of the benchmarks we want to run. Therefore, before starting simulation the base image need to be augmented with the container images.

To do this we use the qemu emulator as it has access to the internet for pulling the most recent image.
We provide a make recepie to automatically install all functions defined in the functions.yaml file run the `install_functions` recipe.
```bash
make install_functions
```
It will take a while depending on how many functions and how large the images are.
> Note the base disk image has a size of XXGB with XXGB already used. Make sure that all container images will not exceed the total size available on the disk. If you need a larger disk you can extend the disk image with `qemu image resize`. Note you also need to [extend the root file system](https://computingforgeeks.com/extending-root-filesystem-using-lvm-linux/) afterwards.




## Run simulations
As soon as the functions are installed on disk its finally time to turn our attention to gem5.

The initial working directory will contain gem5 config file that defines a basic system workflow the benchmark one of the function.

### Workflow

1. Spinning up the container
2. Pin the container to core 1
3. Reset the gem5 stats
4. Start the invoker.
5. Dump the gem5 stats
6. Exit the simulation.
















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
