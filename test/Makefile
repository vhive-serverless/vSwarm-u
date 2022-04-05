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
BASE_TEMPLATES_DIR 	?=$(ROOT)/workload/
WORKING_DIR 		?=wkdir/

## Machine parameter
MEMORY 	:= 2G
CPUS    := 2


## Base Image
KERNEL 				:= $(BASE_TEMPLATES_DIR)/vmlinux
BASE_IMAGE 			:= $(BASE_TEMPLATES_DIR)/base-disk-image.img
RUN_SCRIPT_TEMPLATE := $(ROOT)/test/run_test.template.sh

DISK_IMAGE_FILE 	:= $(WORKING_DIR)/disk.img
RUN_SCRIPT			:= $(WORKING_DIR)/run.sh
RESULTS				:= $(WORKING_DIR)/results.log
SERVE 				:= $(WORKING_DIR)/server.pid



build: $(WORKING_DIR) $(DISK_IMAGE_FILE) $(RUN_SCRIPT)

install_dependencies:
	apt-get update \
  	&& apt-get install -y \
        python3-pip \
        curl lsof \
        qemu-kvm bridge-utils
	python3 -m pip install --user uploadserver


## Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
run: build serve_start
	sudo qemu-system-x86_64 \
		-nographic \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-drive file=$(DISK_IMAGE_FILE),format=raw \
		-kernel $(KERNEL) \
		-append 'console=ttyS0 root=/dev/hda2'



## Test the results file
check: $(RESULTS)
	@if grep -q "SUCCESS" $< ; then \
		echo "==================\n Test successful\n=================="; \
	else \
		echo "==================\n Test failed\n=================="; \
		# cat $<; \
		exit 1; \
	fi



$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@


$(RUN_SCRIPT): $(WORKING_DIR)
	sed 's|<__IMAGE_NAME__>|$(IMAGE_NAME)|g' $(RUN_SCRIPT_TEMPLATE) > $@



##
# Create the disk image from the base image
$(DISK_IMAGE_FILE): | $(WORKING_DIR) $(BASE_TEMPLATES_DIR)
	@echo "Build test disk image"
	cp $(BASE_IMAGE) $@


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



clean: serve_stop
	@echo "Clean up"
	sudo rm -rf $(WORKING_DIR)
