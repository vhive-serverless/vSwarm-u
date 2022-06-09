---
layout: default
title: Quick Start
nav_order: 2
has_children: false
---

# vSwarm-u: Quickstart with Serverless and gem5

This guide describes how to quickly setup your machine and run the first cycle accurate simulations of serverless functions using gem5.

## Setup Machine

Before experimenting with gem5 and serverless functions several things need to be installed downloaded.
For a quick start use the `setup/setup_host.sh` script to install everything.
Brew yourself a coffee in the meantime. ;-) It can take its time to to set everything up for you. Four your notice the script will:

1. **Install all dependencies** *(~5 min)*

2. **Download and build gem5** *(~15 min - 70 min)*

   *Note the compile time can vary a lot depending on your machine. The stated compile times are with a 10 core, 20 hyper threads machine using 64GiB memory and a two core machine using 7GB memory respectively.*

3. **Download latest release artifacts** *(~4 min)*

   With vSwarm-u we distribute a compiled kernel, client and ready to use and tested disk image. Refer to the release page in the github repo. Use the

   For more details refer to the [setup](setup/) section in the documentation.

## Setup working directory
Once the setup pr


The following describes the setup process in more detail. For a quick start use `setup_host.sh` script to install everything at once.





