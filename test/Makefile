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
RUN_SCRIPT_TEMPLATE := $(ROOT)/test/run_emu_test.template.sh


KERNEL 				:= $(WORKING_DIR)/kernel
DISK_IMAGE 			:= $(WORKING_DIR)/disk.img
RUN_SCRIPT			:= $(WORKING_DIR)/run.sh
TEST_CLIENT			:= $(WORKING_DIR)/test-client
RESULTS				:= $(WORKING_DIR)/results.log
SERVE 				:= $(WORKING_DIR)/server.pid

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
	$(call check_file, $(RESRC_KERNEL))
	$(call check_file, $(RESRC_BASE_IMAGE))
	$(call check_file, $(RESRC_CLIENT))
	$(call check_dep, qemu-kvm)
	$(call check_dep, lsof)
	$(call check_py_dep, uploadserver)


test:
	$(call check_file, README.md)
	$(call check_dir, README.mdd)
	$(call check_dep, python3)
	$(call check_py_dep, uploadserver)


## Run Emulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
run_emulator: build serve_start
	sudo qemu-system-x86_64 \
		-nographic \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(DISK_IMAGE),format=raw \
		-kernel $(KERNEL) \
		-append 'console=ttyS0 root=/dev/hda2'

run: run_emulator


## Test the results file
check: $(RESULTS)
	@cat $<;
	@if grep -q "SUCCESS" $< ; then \
		printf "${GREEN}==================\n Test successful\n==================${NC}\n"; \
	else \
		printf "${RED}==================\n Test failed\n==================${NC}\n"; \
		exit 1; \
	fi



## Build the test setup ----------------------------
build: $(WORKING_DIR) $(DISK_IMAGE) $(KERNEL) $(RUN_SCRIPT) $(TEST_CLIENT)

$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

$(RUN_SCRIPT): $(WORKING_DIR)
	sed 's|<__IMAGE_NAME__>|$(IMAGE_NAME)|g' $(RUN_SCRIPT_TEMPLATE) > $@

$(KERNEL): $(RESRC_KERNEL)
	cp $< $@

$(TEST_CLIENT): $(RESRC_CLIENT)
	cp $< $@

# Create the disk image from the base image
$(DISK_IMAGE): $(RESRC_BASE_IMAGE)
	cp $< $@


####
# File server
$(SERVE):
	PID=$$(lsof -t -i :3003); \
	if [ $$PID > 0 ]; then kill -9 $$PID; fi

	python3 -m uploadserver -d $(WORKING_DIR) 3003 &  \
	echo "$$!" > $@ ;
	sleep 2
	@echo "Run server: $$(cat $@ )"

serve_start: $(SERVE)

serve_stop: $(SERVE)
	kill `cat $<` && rm $< 2> /dev/null
	PID=$$(lsof -t -i :3003); \
	if [ $$PID > 0 ]; then kill -9 $$PID; fi


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