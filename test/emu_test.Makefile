
#!/bin/bash

# MIT License
#
# Copyright (c) 2022 EASE lab, University of Edinburgh
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
#
# Authors: David Schall

MKFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT   := $(abspath $(dir $(MKFILE))/../)


## User specific inputs
FUNCTIONS_UNDER_TEST  ?= fibonacci-go aes-go
RESOURCES 			  ?=$(ROOT)/resources/
WORKING_DIR 		  ?=wkdir_emu/

## Machine parameter
MEMORY 	:= 2G
CPUS    := 2


## Required resources
KERNEL 		?= $(RESOURCES)/kernel
DISK 		?= $(RESOURCES)/base-image.img
TEST_CLIENT	?= $(RESOURCES)/client

OUTPUT		?=


WK_KERNEL 			:= $(WORKING_DIR)/kernel
WK_DISK 			:= $(WORKING_DIR)/disk.img
WK_CLIENT			:= $(WORKING_DIR)/test-client
LOGFILE				:= $(WORKING_DIR)/test.log
SERVE 				:= $(WORKING_DIR)/server.pid

FUNCTION_DISK_IMAGE := $(RESOURCES)/test-disk.img


## Dependencies -------------------------------------------------
## Check and install all dependencies necessary to perform function
##
dep_install:
	sudo apt-get update \
  	&& sudo apt-get install -y \
        python3-pip \
        curl lsof \
        qemu-kvm bridge-utils
	python3 -m pip install --user uploadserver

dep_check_qemu:
	$(call check_file, $(KERNEL))
	$(call check_file, $(DISK))
	$(call check_file, $(TEST_CLIENT))
	$(call check_dep, qemu-kvm)
	$(call check_dep, lsof)
	$(call check_py_dep, uploadserver)



## Run Emulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
run_kvm:
	sudo qemu-system-x86_64 \
		-nographic \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(WK_DISK) \
		-kernel $(WK_KERNEL) \
		-append 'console=ttyS0 root=/dev/hda2'


run_no_kvm:
	sudo qemu-system-x86_64 \
		-nographic \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(WK_DISK) \
		-kernel $(WK_KERNEL) \
		-append 'console=ttyS0 root=/dev/hda2'

run_emulator: run_no_kvm
run: run_emulator

install_finalize:
	cp $(ROOT)/configs/disk-image-configs/finalize.sh $(WORKING_DIR)/run.sh
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run
	$(MAKE) -f $(MKFILE) serve_stop
	rm $(BUILD_DIR)/run.sh

## Test run ----------------------------------------------------
#
# Files for test run
FUNCTIONS_LIST		  := $(WORKING_DIR)/functions.list
FUNCTIONS_YAML        := $(WORKING_DIR)/functions.yaml
FUNCTIONS_REF_YAML    := $(ROOT)/simulation/functions/all_vswarm_functions.yaml
RUN_SCRIPT_TEMPLATE   := $(ROOT)/test/run_emu_test.template.sh


create_run_script: $(RUN_SCRIPT_TEMPLATE)
	cp $< $(WORKING_DIR)/run.sh

delete_run_script: $(WORKING_DIR)/run.sh
	rm $(WORKING_DIR)/run.sh



run_test_no_kvm:
	if [ -f $(LOGFILE) ]; then rm $(LOGFILE); fi
	$(MAKE) -f $(MKFILE) create_run_script
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run_no_kvm
	$(MAKE) -f $(MKFILE) serve_stop
	$(MAKE) -f $(MKFILE) delete_run_script

run_test:
	if [ -f $(LOGFILE) ]; then rm $(LOGFILE); fi
	$(MAKE) -f $(MKFILE) create_run_script
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run_kvm
	$(MAKE) -f $(MKFILE) serve_stop
	$(MAKE) -f $(MKFILE) delete_run_script


## Test the log file
check: $(LOGFILE)
	@cat $<
	$(eval fn_inst := $(shell cat $(FUNCTIONS_LIST) | sed '/^\s*#/d;/^\s*$$/d' | wc -l))
	$(eval fn_res := $(shell grep -c "SUCCESS: All commands completed successfully" $< ))
	echo "Tested $(fn_inst) functions. $(fn_res) installed and tested successful"
	@if [ $(fn_inst) -eq $(fn_res) ] ; then \
		printf "${GREEN}==================\n Test successful\n==================${NC}\n"; \
	else \
		printf "${RED}==================\n"; \
		printf "Test failed\n"; \
		printf "Check $<\n"; \
		printf "==================${NC}\n"; \
		exit 1; \
	fi



save_disk:
	cp $(WK_DISK) $(FUNCTION_DISK_IMAGE)

save_output:
	cp $(WK_DISK) $(OUTPUT)



## Build the test setup ----------------------------
build: $(WORKING_DIR) \
	$(WK_DISK) $(WK_KERNEL) \
	$(WK_CLIENT) \
	$(FUNCTIONS_YAML) $(FUNCTIONS_LIST)


$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

$(FUNCTIONS_YAML): $(FUNCTIONS_REF_YAML)
	cp $< $@

$(FUNCTIONS_LIST):
	> $@
	for fn in $(FUNCTIONS_UNDER_TEST); \
	do echo $$fn >> $@; done;

$(WK_KERNEL): $(KERNEL)
	cp $< $@

# Create the disk image from the base image
$(WK_DISK): $(DISK)
	cp $< $@

$(WK_CLIENT): $(TEST_CLIENT)
	cp $< $@

# DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ease-lab/vSwarm-proto/releases/latest \
# 	| grep browser_download_url \
# 	| grep swamp_amd64 \
# 	| cut -d '"' -f 4)

# $(WK_CLIENT):
# 	curl -s -L -o $@ $(TEST_CLIENT)
# 	chmod +x $@


all:
	$(MAKE) -f $(MKFILE) build
	$(MAKE) -f $(MKFILE) run_test
	$(MAKE) -f $(MKFILE) check
	$(MAKE) -f $(MKFILE) clean


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

clean: serve_stop kill_qemu
	@echo "Clean up"
	sudo rm -rf $(WORKING_DIR)



RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color


define check_dep
	@if [ $$(dpkg-query -W -f='$${Status}' $1 2>/dev/null | grep -c "ok installed") -ne 0 ]; \
	then printf "$1 ${GREEN}installed ok${NC}\n"; \
	else printf "$1 ${RED}not installed${NC}\n"; fi
endef
#	# @if [[ $$(python -c "import $1" &> /dev/null) -eq 0]];
define check_py_dep
	@if [ $$(eval pip list | grep -c $1) -ne 0 ] ; \
	then printf "$1 ${GREEN}installed ok${NC}\n"; \
	else printf "$1 ${RED}not installed${NC}\n"; fi
endef



define check_file
	@if [ -f $1 ]; \
	then printf "$1 ${GREEN}exists${NC}\n"; \
	else printf "$1 ${RED}missing${NC}\n"; fi
endef

# define check_file
# 	printf "$1: ${GREEN}exists${NC}";
# 	$(call print_result, $$(test -f $1))
# endef

define check_dir
	@if [ -d $1 ]; \
	then printf "$1 ${GREEN}exists${NC}\n"; \
	else printf "$1 ${RED}missing${NC}\n"; fi
endef

define print_result
	if [ $1 ]; \
	then printf " ${GREEN}ok${NC}\n"; \
	else printf " ${RED}fail${NC}\n"; fi
endef