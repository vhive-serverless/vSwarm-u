
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
FUNCTIONS_UNDER_TEST  	?= fibonacci-go aes-go
FUNCTION 				?=aes-go
RESOURCES 			  	?=$(ROOT)/resources/
WORKING_DIR 		  	?=test_dir/

## Machine parameter
MEMORY 	:= 2G
CPUS    := 2


## Required resources
KERNEL 			?= $(RESOURCES)/kernel
DISK 			?= $(RESOURCES)/disk-image.qcow2
TEST_CLIENT		?= $(RESOURCES)/client
GEM5_CONFIG 	:= $(ROOT)/test/run_sim_test.py
GEM5_DIR		?= $(RESOURCES)/gem5/
GEM5			:= $(RESOURCES)/gem5/build/X86/gem5.opt

OUTPUT			?=




### Run everything

all_emu:
	$(MAKE) -f $(MKFILE) build
	$(MAKE) -f $(MKFILE) run_emu_test
	$(MAKE) -f $(MKFILE) check_emu

all_sim:
	$(MAKE) -f $(MKFILE) run_sim_test
	$(MAKE) -f $(MKFILE) check_sim

all:
	$(MAKE) -f $(MKFILE) all_emu
	$(MAKE) -f $(MKFILE) all_sim
	$(MAKE) -f $(MKFILE) clean






## Infrastructure setup ##########################################
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

dep_check_gem5:
	$(call check_file, $(WK_KERNEL))
	$(call check_file, $(WK_DISK))
	$(call check_file, $(WK_DISK_IMG))
	$(call check_file, $(GEM5))
	$(call check_dep, qemu-kvm)

dep_check: dep_check_qemu dep_check_gem5





## Build the test setup ----------------------------
# Internal files in the test directory
WK_KERNEL 			:= $(WORKING_DIR)/kernel
WK_DISK 			:= $(WORKING_DIR)/disk.qcow2
# qemu can use qcow2 images but gem5 cannot
WK_DISK_IMG			:= $(WORKING_DIR)/disk.img
WK_CLIENT			:= $(WORKING_DIR)/test-client
# Emulator files
LOGFILE_EMU			:= $(WORKING_DIR)/test.log
SERVE 				:= $(WORKING_DIR)/server.pid
FUNCTIONS_LIST		:= $(WORKING_DIR)/functions.list
FUNCTIONS_YAML      := $(WORKING_DIR)/functions.yaml
FUNCTIONS_REF_YAML	:= $(ROOT)/simulation/functions/all_vswarm_functions.yaml
# Simulator files
STATS_FILE			:= $(WORKING_DIR)/stats.txt
LOGFILE_SIM			:= $(WORKING_DIR)/system.pc.com_1.device


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

# Convert the disk image
convert_disk:
	if [ -f $(WK_DISK_IMG) ]; then rm $(WK_DISK_IMG); fi
	qemu-img convert $(WK_DISK) $(WK_DISK_IMG)


$(WK_CLIENT): $(TEST_CLIENT)
	cp $< $@


## Save the disk after test
save_disk:
	cp $(WK_DISK) $(OUTPUT)

save_output:
	cp $(WK_DISK) $(OUTPUT)

## Clean up everything
clean: serve_stop kill_qemu kill_gem5
	@echo "Clean up"
	sudo rm -rf $(WORKING_DIR)



### TEST RUN ########################################################

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

## Emulator Test run ----------------------------------------------------
#
# Files for emulator test run
RUN_SCRIPT_TEMPLATE   := $(ROOT)/test/run_emu_test.template.sh


create_run_script: $(RUN_SCRIPT_TEMPLATE)
	cp $< $(WORKING_DIR)/run.sh

delete_run_script:
	if [ -f $(WORKING_DIR)/run.sh ]; then rm $(WORKING_DIR)/run.sh; fi



run_test_no_kvm:
	if [ -f $(LOGFILE_EMU) ]; then rm $(LOGFILE_EMU); fi
	$(MAKE) -f $(MKFILE) create_run_script
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run_no_kvm
	$(MAKE) -f $(MKFILE) serve_stop
	$(MAKE) -f $(MKFILE) delete_run_script

run_test:
	if [ -f $(LOGFILE_EMU) ]; then rm $(LOGFILE_EMU); fi
	$(MAKE) -f $(MKFILE) create_run_script
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run_kvm
	$(MAKE) -f $(MKFILE) serve_stop
	$(MAKE) -f $(MKFILE) delete_run_script

run_emu_test: run_test


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
				--disk $(WK_DISK_IMG) \
				--function $(FUNCTION)
	sudo $(MAKE) -f $(MKFILE) delete_run_script

run_sim_test:
	$(MAKE) -f $(MKFILE) convert_disk
	$(MAKE) -f $(MKFILE) run_simulator



###################################################################
## Test results checks
## Emulator log file
check_emu_log: $(LOGFILE_EMU)
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


## Check simulator log file
check_sim_log: $(LOGFILE_SIM)
	@cat $<;
	@if grep -q "SUCCESS: Calling functions for 5 times" $< ; then \
		printf "${GREEN}\n==================\n Test successful\n==================${NC}\n"; \
	else \
		printf "${RED}==================\n Test failed\n==================${NC}\n"; \
		exit 1; \
	fi

## Check gem5 stats
check_sim_stats: $(STATS_FILE)
	$(eval inst := $(shell awk '/system.detailed_cpu1.exec_context.thread_0.numInsts/ {print $$2; exit;}' $(STATS_FILE)))
	$(eval cycles := $(shell awk '/system.detailed_cpu1.numCycles/ {print $$2; exit;}' $(STATS_FILE)))

	$(eval ipc := $(shell echo $(inst) $(cycles) | awk '{ tmp=$$1/$$2 ; printf"%0.4f\n", tmp }'))

	@if [ $(cycles) ]; then \
		printf "${GREEN}==================\n"; \
		printf "Simulation successful:\n"; \
		printf " $(inst) instructions\n"; \
		printf " $(cycles) cycles\n"; \
		printf " IPC: $(ipc) \n"; \
		printf "==================${NC}\n"; \
	else \
		printf "${RED}==================\n Test failed\n==================${NC}\n"; \
		exit 1; \
	fi


check_emu: check_emu_log
check_sim: check_sim_log check_sim_stats






######################################
#### UTILS

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