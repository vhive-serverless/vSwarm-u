---
layout: default
title: Resources
parent: Setup
nav_order: 1
---


# Required Resources

In order to run serverless simulations with gem5 you will need we will need a few more ingredients apart of gem5 and vSwarm-u. First of all a compiled linux kernel configured for gem5 and containers. Secondly a disk image with a root file system and all components installed to run serverless workloads. Finally a client we will use to drive the functions during simulation.

Setting up and building all those resources from scratch can be tricky to get it right and is also quite time consuming therefore we distribute together with vSwarm-u an up to date and pre-configured disk image as well as a compiled kernel and test client. For quickly ramping up your system follow the easy steps [here](#download-resources-artifacts) to download those resources. For more advanced use and customization find out all the details how we build and configure the resources yourself in related documentation ([kernel](./kernel.md), [disk-image](./disk-image.md))


## Environmental Variables
We use the `RESOURCES` environmental variable in all our scripts to define where they can find the resources: kernel, base disk image and the client. Furthermore we `GEM5_DIR` to define where gem5 will be downloaded and installed. If you want to specify your own paths set and expose this variables before running one of the scripts.
```bash
export RESOURCES=<your/resources/dir>
echo 'export RESOURCES=${RESOURCES}' >> ${HOME}/.bashrc
```
The default paths are `resources/` and `${RESOURCES}/gem5` for `RESOURCES` and `GEM5_DIR` respectively.


## Download Resources Artifacts

To download resource artifact use the `artifacts.py` script in `resources/` with:
```bash
./resources/artifacts.py
```
The script will fetch the latest kernel, disk-image and client from github. In case you want another version use the `--version` argument.
Note that the size of the disk image is a few GiB. Furthermore, Github has a limit of 2GiB per asset. We compress and split the disk image. But no worries the script will do everything for you ;). Downloading merging and decompression. *Usually it took about three minutes. (2.5min for download and 30s for decompressing)*

By default the resources will be stored in the `resources/`

### Released Artifacts
In addition to the stable disk images Ubuntu 20.04 and Kernel 5.4.84 for x86/amd64 architecture we distribute also images for Ubuntu 22.04 as well as kernels and disk images for arm based architectures.
To download another artifact then the default set the arguments `--arch <arm64/amd64>` and `--os-version <focal/jammy>` when downloading with the `./resources/artifacts.py` script.

> {: .warning }
> So far only all resources work with qemu but there is NO support for gem5 simulation yet. All but the stable artifacts we therefore distribute for experimentation reasons. We try to add support in the future and welcome any help. For further information about missing support ask David: [GitHub](https://github.com/dhschall).


#### Kernel

| Version | Architecture | State | Qemu support | gem5 support |
|:---|---|---|---|---|
| v5.4.84 | x86/amd64 | stable | ✓ | ✓ |
| v5.15.59 | x86/amd64 | experimental | ✓ | ✕ |
| v5.4.84 | arm64 | experimental | ✓ | ✓ |
| v5.15.59 | arm64 | experimental | ✓ | ✕ |

#### Disk Image

| Version | Architecture | State | Qemu support | gem5 support |
|---|---|---|---|---|
| Ubuntu 20.04 (focal) | x86/amd64 | stable | ✓ | ✓ |
| Ubuntu 22.04 (jammy) | x86/amd64 | experimental | ✓ | ✕ |
| Ubuntu 20.04 (focal) | arm64 | experimental | ✓ | ✓ |
| Ubuntu 22.04 (jammy) | arm64 | experimental | ✓ | ✕ |

#### Test-client

| Architecture | State | Qemu support | gem5 support |
|---|---|---|---|
| x86/amd64 | stable | ✓ | ✓ |
| arm64 | stable | ✓ | ✓ |




### Disk format qcow2 and raw
We distribute the disk image in qemu's [`qcow2` compressed format](https://qemu.readthedocs.io/en/latest/system/images.html#disk-image-file-formats). This has the advantage that the disk image is smaller. However gem5 cannot use qcow2 but only raw. Therefore, after downloading and decompression you will need to convert the disk image before using it with gem5. The scripts does all the work from you in the back however you can use `qemu-img` to convert the disk yourself:
```bash
# Convert disk image from qcow2 -> raw format
qemu-img convert <src/disk/path> <tgt/disk/path>
```


