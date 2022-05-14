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

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(mkfile_path))/../)


## User specific inputs
IMAGE_NAME  		?=vhiveease/aes-go
RESOURCES 			?=$(ROOT)/resources/
WORKING_DIR 		?=wkdir/

## Machine parameter
MEMORY 	:= 2G
CPUS    := 2


## Required resources
RESRC_KERNEL 		:= $(RESOURCES)/vmlinux
RESRC_BASE_IMAGE 	:= $(RESOURCES)/base-disk-image.img
RESRC_CLIENT	 	:= $(RESOURCES)/test-client

INSTALL_SCRIPT      := $(ROOT)/benchmarks/install_function.sh
FUNCTION_YAML_TMPL  := $(ROOT)/benchmarks/functions.yaml

GEM5				:= $(RESOURCES)/gem5/build/X86/gem5.opt
SIM_SCRIPT_TMPL  	:= $(ROOT)/benchmarks/run_sim.sh

GEM5_CONFIG  		:= $(ROOT)/benchmarks/run_sim.py

KERNEL 				:= $(WORKING_DIR)/kernel
DISK_IMAGE 			:= $(WORKING_DIR)/disk.img
RUN_SCRIPT			:= $(WORKING_DIR)/run.sh
TEST_CLIENT			:= $(WORKING_DIR)/test-client
RESULTS				:= $(WORKING_DIR)/install.log
SERVE 				:= $(WORKING_DIR)/server.pid
FUNCTION_YAML       := $(WORKING_DIR)/functions.yaml
FUNCTIONS 			:= $(WORKING_DIR)/functions.list


SIM_SCRIPT          := $(WORKING_DIR)/start_simulations.sh

FUNCTION_NAME 		:= $(shell echo $(IMAGE_NAME) | awk -F'/' '{print $$NF}')
FUNCTION_DISK_IMAGE := $(RESOURCES)/$(FUNCTION_NAME)-disk.img


## Dependencies -------------------------------------------------
## Check and install all dependencies necessary to perform function
##
dep_install:
	sudo pip install -U niet

## Run Emulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
run_emulator:
	sudo qemu-system-x86_64 \
		-nographic \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(DISK_IMAGE),format=raw \
		-kernel $(KERNEL) \
		-append 'console=ttyS0 root=/dev/hda2'

run: run_emulator

install_functions: build_wkdir
	$(MAKE) serve_start
	$(MAKE) run_emulator
	$(MAKE) serve_stop



## Run Simulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then check if for a run script using a magic instruction
# This run script will be the one we provided.

run_simulator:
	sudo $(GEM5) \
		--outdir=$(WORKING_DIR) \
			$(GEM5_CONFIG) \
				--kernel $(KERNEL) \
				--disk $(DISK_IMAGE) \
				--script $(RUN_SCRIPT)

# run: run_simulator

# setup_all_simulations:
# 	$(eval BMS := $(shell cat $(FUNCTIONS)))
# 	for i in $(BMS); \
# 		OUTDIR=$BASE_OUTDIR/${i}/

#     ## Create output directory
#     mkdir -p $OUTDIR
# start_all_simulations:










## Build the working directory ----------------------------
build_wkdir: $(WORKING_DIR) $(DISK_IMAGE) $(KERNEL) $(TEST_CLIENT) $(FUNCTION_YAML) $(FUNCTIONS) $(RUN_SCRIPT)

$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

$(KERNEL): $(RESRC_KERNEL)
	cp $< $@

$(TEST_CLIENT): $(RESRC_CLIENT)
	cp $< $@

# Create the disk image from the base image
$(DISK_IMAGE): $(RESRC_BASE_IMAGE)
	cp $< $@

$(FUNCTION_YAML): $(FUNCTION_YAML_TMPL)
	cp $< $@

$(RUN_SCRIPT): $(INSTALL_SCRIPT)
	cp $< $@

$(FUNCTIONS): $(FUNCTION_YAML)
	python -m niet "services.*.container_name" $< > $@


$(SIM_SCRIPT): $(SIM_SCRIPT_TMPL)
	cat $< | \
	sed 's|<__GEM5__>|$(GEM5)|g' | \
	sed 's|<__KERNEL__>|$(KERNEL)|g' | \
	sed 's|<__DISK_IMAGE__>|$(DISK_IMAGE)|g' | \
	sed 's|<__GEM5_CONFIG__>|$(GEM5_CONFIG)|g' | \
	sed 's|<__RUN_SCRIPT_TEMPLATE__>|$(RUN_SCRIPT_TEMPLATE)|g' \
	> $@
	chmod +x $@

test: $(SIM_SCRIPT)

######################################
#### UTILS

####
# File server
$(SERVE):
	PID=$$(lsof -t -i :3003); \
	if [ ! -z $$PID ]; then kill -9 $$PID; fi

	python3 -m uploadserver -d $(WORKING_DIR) 3003 &  \
	echo "$$!" > $@ ;
	sleep 2
	@echo "Run server: $$(cat $@ )"

serve_start: $(SERVE)

serve_stop:
	if [ -e $(SERVE) ]; then kill `cat $(SERVE)` && rm $(SERVE) 2> /dev/null; fi
	PID=$$(lsof -t -i :3003); \
	if [ ! -z $$PID ]; then kill -9 $$PID; fi


kill_qemu:
	$(eval PIDS := $(shell pidof qemu-system-x86_64))
	for p in $(PIDS); do echo $$p; sudo kill $$p; done

kill_gem5:
	$(eval PIDS := $(shell pidof $(GEM5)))
	for p in $(PIDS); do echo $$p; sudo kill $$p; done

clean: serve_stop kill_qemu
	@echo "Clean up"
	sudo rm -rf $(WORKING_DIR)


# test: serve_start
# 	$(MAKE) serve_stop



RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

