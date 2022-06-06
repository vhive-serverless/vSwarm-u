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

# Adopted from: https://github.com/brennancheung/playbooks/blob/master/cloud-init-lab/


mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(mkfile_path))/../)

## User specific inputs
IMAGE_NAME  := gem5-disk-image
BUILD_DIR   ?= wkdir/
RESOURCES 	?=$(ROOT)/resources/

DISK_SIZE   := 8G
MEMORY      := 8G
CPUS        := 4

# CLOUD_IMAGE_FILE     := focal-server-cloudimg-amd64-disk-kvm.img
# CLOUD_IMAGE_BASE_URL := https://cloud-images.ubuntu.com/focal/current

CLOUD_IMAGE_FILE     := ubuntu-20.04.3-live-server-amd64.iso
CLOUD_IMAGE_BASE_URL := https://releases.ubuntu.com/20.04.3/

IMAGE_NAME        	 := disk


CLOUD_IMAGE_URL     := $(CLOUD_IMAGE_BASE_URL)/$(CLOUD_IMAGE_FILE)
DISK_IMAGE_FILE     := $(BUILD_DIR)/$(IMAGE_NAME).img
SEED_IMAGE_FILE     := $(BUILD_DIR)/$(IMAGE_NAME)-seed.img

CONFIGS_DIR         := $(ROOT)/configs/disk-image-configs/
RUN_SCRIPT			:= $(BUILD_DIR)/run.sh
RUN_SCRIPT_TEMPLATE := $(ROOT)/scripts/run_function.sh


INSTALL_CONFIG 		:= $(BUILD_DIR)/user-data
KERNEL 				:= $(BUILD_DIR)/vmlinux
INITRD 				:= $(BUILD_DIR)/initrd
SERVE 				:= $(BUILD_DIR)/server.pid

# Resource files
RESRC_BASE_IMAGE 	:= $(RESOURCES)/base-disk-image.img

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
	@$(call check_dep, qemu-kvm)
	@$(call check_dep, lsof)
	@$(call check_py_dep, uploadserver)


build: | $(BUILD_DIR) $(INITRD) $(DISK_IMAGE_FILE) $(INSTALL_CONFIG)
	@$(call print_config)


## Do the actual installation
# The command will boot from the iso file.
# Then it will listen to port 3003 to retive further files.
# If such provided the install process will automatically done for you.
install: build $(SERVE)
	sudo qemu-system-x86_64 \
		-nographic \
		-cpu host -enable-kvm \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-no-reboot \
		-drive file=$(DISK_IMAGE_FILE),format=raw \
		-cdrom $(CLOUD_IMAGE_FILE) \
		-kernel $(KERNEL) \
		-initrd $(INITRD) \
		-append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'


## Save the created files to the resource directory
save: $(DISK_IMAGE_FILE)
	cp $(DISK_IMAGE_FILE) $(RESRC_BASE_IMAGE)


$(RUN_SCRIPT): $(BUILD_DIR)
	sed 's|<__IMAGE_NAME__>|$(IMAGE_NAME)|g' $(RUN_SCRIPT_TEMPLATE) > $@



$(INSTALL_CONFIG): $(BUILD_DIR)
	cp $(CONFIGS_DIR)/autoinstall.yaml $@
	touch $(BUILD_DIR)/meta-data
	touch $(BUILD_DIR)/vendor-data


## Get and create the image file -------
download:
	@if [ -f $(CLOUD_IMAGE_FILE) ]; then \
		echo "$(CLOUD_IMAGE_FILE) exists."; \
	else \
		echo "$(CLOUD_IMAGE_FILE) does not exist. Download it..."; \
		wget $(CLOUD_IMAGE_URL); \
	fi

	echo "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98 *$(CLOUD_IMAGE_FILE)" | shasum -a 256 --check


$(BUILD_DIR):
	$(call spacing,"Create folder: $(BUILD_DIR)")
	mkdir -p $@
	cp $(CONFIGS_DIR)/* $@

##
# Create the disk image file
$(DISK_IMAGE_FILE): | $(BUILD_DIR)
	$(call spacing,"Build main disk image: $(DISK_SIZE)")
	qemu-img create $@ $(DISK_SIZE)


# Extract the initrd file from the install disk
$(INITRD): $(CLOUD_IMAGE_FILE)
	mkdir -p iso
	sudo mount -r $(CLOUD_IMAGE_FILE) iso

	cp iso/casper/vmlinuz $(BUILD_DIR)/vmlinux
	cp iso/casper/initrd $(BUILD_DIR)/initrd

	sudo umount iso
	rm -rf iso


####
# File server
$(SERVE):
	PID=$$(lsof -t -i :3003); \
	if [ $$PID > 0 ]; then kill -9 $$PID; fi

	python3 -m uploadserver -d $(BUILD_DIR) 3003 &  \
	echo "$$!" > $@ ;
	sleep 2
	@echo "Run server: $$(cat $@ )"

serve_start: $(SERVE)

serve_stop: $(SERVE)
	kill `cat $<` && rm $< 2> /dev/null
	PID=$$(lsof -t -i :3003); \
	if [ $$PID > 0 ]; then kill -9 $$PID; fi



clean: serve_stop
	@echo "Remove build directory"
	sudo rm -rf $(BUILD_DIR)


define spacing
	@echo "\n===== $(if $1,$1,$@) ====="
endef


RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

define print_config
	printf "\n=============================\n"; \
	printf "${GREEN} Build disk image for gem5 ${NC}\n"; \
	printf " ---\n"; \
	printf "ISO: $(CLOUD_IMAGE_FILE)\n"; \
	printf "Disk name: $(DISK_IMAGE_FILE)\n"; \
	printf "Disk size: $(DISK_SIZE)\n"; \
	printf "=============================\n\n";
endef