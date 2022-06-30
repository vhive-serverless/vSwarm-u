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

MKFILE 		:= $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(MKFILE))/../)


## User specific inputs
RESOURCES 	?= $(ROOT)/resources/
WORKING_DIR ?= $(ROOT)/wkdir/
GEM5_DIR	?= $(RESOURCES)/gem5/
ARCH		?= arm64

ifeq ($(ARCH), amd64)
	_ARCH=X86
else ifeq ($(ARCH), arm64)
	_ARCH=ARM
endif


## Machine parameter
MEMORY 	:= 2G
CPUS    := 2


## Required resources
KERNEL 		?= $(RESOURCES)/kernel-${ARCH}
DISK		?= $(RESOURCES)/disk-image-${ARCH}.qcow2
GEM5		?= $(RESOURCES)/gem5/build/${ARCH}/gem5.opt




## Dependencies -------------------------------------------------
## Check and install all dependencies necessary to perform function
##
# dep_install:
# 	sudo pip install -U niet



##################################################################
## Build the working directory ----------------------------
#
WK_KERNEL 	:= $(WORKING_DIR)/Image
WK_DISK 	:= $(WORKING_DIR)/disk.img
WK_CLIENT	:= $(WORKING_DIR)/test-client

build-wkdir: $(WORKING_DIR) \
	$(WK_DISK) $(WK_KERNEL) \
	templates

build-two-machine: build-wkdir
	cat $(TEMPLATES_DIR)/run_sim_two_machine.tmpl.py | \
	sed 's|<__ROOT__>|$(ROOT)|g' \
	> $(GEM5_CONFIG)



$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

$(WK_KERNEL): $(KERNEL)
	cp $< $@

# Create the disk image from the base image
$(WK_DISK): $(DISK)
	qemu-img convert $< $@


## Build test client from sources
$(WK_CLIENT):
	cd $(ROOT)/tools/client/ &&	$(MAKE) all
	cp $(ROOT)/tools/client/client $@


#
## Generate the scripts from templates -------
# Templates
TEMPLATES_DIR 		:= $(ROOT)/simulation/wkdir-tmpl

# Target scripts
SERVE 				:= $(WORKING_DIR)/server.pid
FUNCTIONS_YAML      := $(WORKING_DIR)/functions.yaml
FUNCTIONS_LIST		:= $(WORKING_DIR)/functions.list
GEM5_CONFIG  		:= $(WORKING_DIR)/run_sim.py
SIM_ALL_SCRIPT      := $(WORKING_DIR)/sim_all_functions.sh
SIM_FN_SCRIPT       := $(WORKING_DIR)/sim_function.sh

templates: $(SIM_ALL_SCRIPT) $(SIM_FN_SCRIPT) $(GEM5_CONFIG) $(FUNCTIONS_YAML) $(FUNCTIONS_LIST)


$(WORKING_DIR)/functions.%: $(ROOT)/simulation/functions/functions.%
	cp $< $@


test3: $(FUNCTIONS_YAML)

# $(FUNCTIONS): $(FUNCTION_YAML)
# 	python -m niet "services.*.container_name" $< > $@


$(WORKING_DIR)/%.py: $(TEMPLATES_DIR)/%.tmpl.py
	cat $< | \
	sed 's|<__ROOT__>|$(ROOT)|g' \
	> $@

$(WORKING_DIR)/%.sh: $(TEMPLATES_DIR)/%.tmpl.sh
	cat $< | \
	sed 's|<__GEM5__>|$(GEM5)|g' \
	> $@
	chmod +x $@








## Run Emulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
# run_emulator:
# 	sudo qemu-system-x86_64 \
# 		-nographic \
# 		-cpu host -enable-kvm \
# 		-smp ${CPUS} \
# 		-m ${MEMORY} \
# 		-drive file=$(WK_DISK),format=raw \
# 		-kernel $(WK_KERNEL) \
# 		-append 'console=ttyS0 root=/dev/hda2'

FLASH0 := $(WORKING_DIR)/flash0.img
FLASH1 := $(WORKING_DIR)/flash1.img

$(FLASH0):
	cp /usr/share/qemu-efi-aarch64/QEMU_EFI.fd $@
	truncate -s 64M $@

$(FLASH1):
	truncate -s 64M $@


run_emulator_arm:
	sudo qemu-system-aarch64 \
		-nographic \
		-M virt \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(WK_DISK),format=raw \
		-kernel $(WK_KERNEL) \
		-append 'console=ttyAMA0 earlyprintk=ttyAMA0 lpj=7999923 root=/dev/vda2'

# run_emulator_arm:
# 	sudo qemu-system-aarch64 -M virt -enable-kvm -cpu host -m 2048 \
# 		-kernel $(WK_KERNEL) \
# 		-append 'console=ttyAMA0 earlyprintk=ttyAMA0 lpj=7999923 root=/dev/vda2 rw' \
# 		-drive file=wkdir/disk.img,format=raw,id=hd \
# 		-no-reboot \
# 		-device e1000,netdev=net0 \
# 		-netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
# 		-nographic

run: run_emulator_arm


## Run Simulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then check if for a run script using a magic instruction
# This run script will be the one we provided.

run_simulator:
	sudo $(GEM5) \
		--outdir=$(WORKING_DIR) \
			$(GEM5_CONFIG) \
				--kernel $(WK_KERNEL) \
				--disk $(WK_DISK)





## Install functions --------------------------------------
#
LOGFILE    := $(WORKING_DIR)/install.log

create_install_script: $(ROOT)/simulation/install_functions.sh
	cp $< $(WORKING_DIR)/run.sh

delete_run_script: $(WORKING_DIR)/run.sh
	rm $(WORKING_DIR)/run.sh


install_functions: build-wkdir
	if [ -f $(LOGFILE) ]; then rm $(LOGFILE); fi
	$(MAKE) -f $(MKFILE) create_install_script
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run_emulator_arm
	$(MAKE) -f $(MKFILE) serve_stop
	$(MAKE) -f $(MKFILE) delete_run_script


## Test the results file
install_check: $(LOGFILE)
	$(eval fn_inst := $(shell cat $(FUNCTIONS_LIST) | sed '/^\s*#/d;/^\s*$$/d' | wc -l))
	$(eval fn_res := $(shell grep -c "SUCCESS" $< ))
	echo "Tryed to install $(fn_inst) functions. $(fn_res) installed and tested successful"
	@if [ $(fn_inst) -eq $(fn_res) ] ; then \
		printf "${GREEN}==================\n Install successful\n==================${NC}\n"; \
	else \
		printf "${RED}==================\n"; \
		printf "Install failed\n"; \
		printf "Check $<\n"; \
		printf "==================${NC}\n"; \
		exit 1; \
	fi




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

