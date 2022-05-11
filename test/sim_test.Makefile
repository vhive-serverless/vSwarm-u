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
WORKING_DIR 		?=wkdir_sim/
# WORKING_DIR 		?=wkdir/

FUNCTION_NAME 		:= $(shell echo $(IMAGE_NAME) | awk -F'/' '{print $$NF}')

## Required resources
FUNCTION_DISK_IMAGE := $(RESOURCES)/$(FUNCTION_NAME)-disk.img
RESRC_KERNEL 		:= $(RESOURCES)/vmlinux
RUN_SCRIPT_TEMPLATE := $(ROOT)/test/run_sim_test.template.sh
GEM5_CONFIG 		:= $(ROOT)/test/run_sim_test.py
GEM5_DIR			:= $(RESOURCES)/gem5/
GEM5				:= $(RESOURCES)/gem5/build/X86/gem5.opt


KERNEL 				:= $(WORKING_DIR)/kernel
DISK_IMAGE 			:= $(WORKING_DIR)/disk.img
RUN_SCRIPT			:= $(WORKING_DIR)/run_sim.sh
RESULTS				:= $(WORKING_DIR)/results_sim.log
STATS_FILE			:= $(WORKING_DIR)/stats.txt

## Dependencies -------------------------------------------------
## Check all dependencies necessary to perform function test
##


dep_check_gem5:
	$(call check_file, $(KERNEL))
	$(call check_file, $(DISK_IMAGE))
	$(call check_file, $(GEM5))
	$(call check_dep, qemu-kvm)




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

run: run_simulator



## Test the results file
check: $(RESULTS) check_stats
	@cat $<;
	@if grep -q "SUCCESS" $< ; then \
		printf "${GREEN}==================\n Test successful\n==================${NC}\n"; \
	else \
		printf "${RED}==================\n Test failed\n==================${NC}\n"; \
		exit 1; \
	fi



## Build the test setup ----------------------------
build: $(WORKING_DIR) $(DISK_IMAGE) $(KERNEL) $(RUN_SCRIPT)

$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

# $(WORKING_DIR):
# 	@if [ ! -d $< ]; \
# 	then printf " ${RED}ERROR: WORKING_DIR not ready. Run emulator test first${NC}\n"; fi

$(RUN_SCRIPT): $(WORKING_DIR)
	cat $(RUN_SCRIPT_TEMPLATE) | \
	sed 's|<__IMAGE_NAME__>|$(IMAGE_NAME)|g' | \
	sed 's|<__FUNCTION_NAME__>|$(FUNCTION_NAME)|g' \
	> $@

$(KERNEL): $(RESRC_KERNEL)
	cp $< $@

# The disk image most be prepared for with the function. Pull that function
# with qemu.
# Then we can copy it into the working directory
$(FUNCTION_DISK_IMAGE):
	@if [ ! -d $@ ]; then \
		printf "${RED}ERROR: "; \
		printf "No disk image for this function found: "; \
		printf "$(FUNCTION_NAME)\n"; \
		printf "First customize a base image with this function or run the emulator test.\n"; \
		printf "${NC}\n"; \
		exist 1; \
	fi;

$(DISK_IMAGE): $(FUNCTION_DISK_IMAGE)
	cp $< $@




kill_gem5:
	$(eval PIDS := $(shell pidof $(GEM5)))
	for p in $(PIDS); do echo $$p; sudo kill $$p; done

clean: kill_gem5
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

check_stats: $(STATS_FILE)
	$(eval inst := $(shell awk '/system.detailed_cpu1.exec_context.thread_0.numInsts/ {print $$2; exit;}' $(STATS_FILE)))
	$(eval cycles := $(shell awk '/system.detailed_cpu1.numCycles/ {print $$2; exit;}' $(STATS_FILE)))

	$(eval ipc := $(shell echo $(inst) $(cycles) | awk '{ tmp=$$1/$$2 ; printf"IPC:\t%0.4f\n", tmp }'))

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
