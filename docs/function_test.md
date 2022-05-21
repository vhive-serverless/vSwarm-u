---
layout: default
title: Integration test
nav_order: 2
has_children: false
---

# Function Integration test

{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

---


The functionalities in the `test/` folder aim to test if functions can run on the base image in the qemu emulator and later in gem5.


## Test setup
To order to perform tests several requirements need to be fulfilled:
- Our custom **linux kernel**
- Our **base disk image**
> Both of these files can be build in advance by following the instructions [here](./setup.md#build-linux-kernel) and [here](./setup.md#create-base-di).

The environmental variable `RESOURCES` is used to let the tests find all required base files. After building the resources place them into the default `resources` folder or setting the path of this variable accordingly.

Futhermore for Emulator tests [qemu](https://www.qemu.org/docs/master/) need to be installed as well as the python uploadserver.
> Use `make dep_check_qemu` to check if all requirements are fulfilled.

## Test flow
The test is composed of the following steps
1. Build test setup
The first step is to build a new working directory where we perform the test. A new disk image must be created from the `base-disk-image.img` from the resource folder.
Furthermore, the run script template for the test run must be adjusted to
the **function under test (FUT)**. For this rename or copy `run_test.template.sh` to your working directory `run.sh` and replace `<__IMAGE_NAME__>` with the image name of the FUT.

Build the test setup with the `IMAGE_NAME=<FUT> make build` command.

2. Test run
The test run is fully automated will basically perform the following steps:
    1. Pull the FUT image.
    1. Start the FUT container.
    1. Run a test client locally that issues request to the FUT container.
    1. Stop the FUT container
    1. Check if all previous commands have been executed properly
    1. Upload the log file.
    1. Shutdown the machine.

3. Result check
To let the host system know if the test has completed successfully qemu uploads back the log file as `results.log`. The final step is now to parse this file for failures.


## Workflow automation

The underlying concept of the automation is the gem5.service. After boot this service will try to fetch a run script from a predefined resource depending on the CPU model.

### Gem5 simulator
In case `gem5.service` encounters the `M5 Simulator` as cpu model it will use the magic instruction `m5 readfile`. This instruction is the counter part of the `.readfile` parameter in the `m5.System` object.

> Example how to set the script in the gem5 config
> ```python
> system = System()
> system.readfile = <"path/to/your/run/script">
> ```


### Qemu Emulator
When the gem5.service encounters another cpu type it knows that not a simulation but emulation is running. In here we do not have the magic instruction functionality. Instead we use the network interface and qemu's gateway connection to the host system. For accessing the host network from within qemu via the gateway the network address `10.0.2.2` or the variable `_gateway` is used. See [networking](https://wiki.qemu.org/Documentation/Networking) for more details.

Using the gateway the `gem5.service` will try to download the run script (`run.sh`) from a http server at port `3003`.

> The exact address is: `http://_gateway:3003/run.sh`

In case such file is found it will be automatically executed by the service with `root` privileges. If none such server or file is found the service terminate.

With this entry point (`run.sh`) any arbitrary complex workflow can be implemented and automatically executed by the emulator. Only this script need to be served by the host system at port 3003. One easiest way to do this is to use the [python http server](https://docs.python.org/3/library/http.server.html).
I.e. `python -m http.server 3003` will serve files from the current directory at port 3003. Use `-d` to defined another directory to be served.
The folder can contain more files but the run script that can be downloaded if neccessary with `curl` or `wget`.

> In oder to get feedback from the emulator one can use pythons [upload server](https://pypi.org/project/uploadserver/) to not just download but also upload files.
> ```python
> python3 -m uploadserver -d tmp/ 3003
> ```
> Will serve the directory `tmp` at port 3003 for GET and PUT request. The emulator can now not just download more files that remain in this folder. I.e. `curl  "http://10.0.2.2:3003/config.json" -f -o config.json` will download config.json from the host and save it as config.json at the guest. But also files can be uploaded from the guest to this tmp folder in the host. I.e. `curl  "http://10.0.2.2:3003/upload" -F 'files=@results.log'` will upload results.log.



