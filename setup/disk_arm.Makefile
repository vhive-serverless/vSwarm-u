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
# Adopted from: https://github.com/brennancheung/playbooks/blob/master/cloud-init-lab/


MKFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(MKFILE))/../)

## User specific inputs
BUILD_DIR   ?= wkdir_install/
RESOURCES 	?=$(ROOT)/resources/
OUTPUT		?=

DISK_SIZE   := 16G
MEMORY      := 8G
CPUS        := 4


UBUNTU_VERSION 		?= focal

ifeq ($(UBUNTU_VERSION), focal)
	CLOUD_IMAGE_FILE     := ubuntu-20.04.3-live-server-arm64.iso
	CLOUD_IMAGE_BASE_URL := https://releases.ubuntu.com/20.04.3/
	CLOUD_IMAGE_HASH	 := d6fea1f11b4d23b481a48198f51d9b08258a36f6024cb5cec447fe78379959ce
else ifeq ($(UBUNTU_VERSION), jammy)
	CLOUD_IMAGE_FILE     := ubuntu-22.04.1-live-server-arm64.iso
	CLOUD_IMAGE_BASE_URL := https://cdimage.ubuntu.com/releases/22.04/release/
	CLOUD_IMAGE_HASH	 := bc5a8015651c6f8699ab262d333375d3930b824f03d14ae51e551d89d9bb571c
else
	@echo "Unsupported ubuntu version $(UBUNTU_VERSION)"
endif


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

# Resource files
RESRC_BASE_IMAGE 	:= $(RESOURCES)/disk-image.qcow2

## Dependencies -------------------------------------------------
## Check and install all dependencies necessary to perform function
##
dep_install:
	sudo apt-get update \
  	&& sudo apt-get install -y \
        python3-pip \
        curl lsof \
        qemu-kvm bridge-utils qemu-system-arm
	python3 -m pip install --user uploadserver

dep_check_qemu:
	@$(call check_dep, qemu-kvm)
	@$(call check_dep, lsof)
	@$(call check_py_dep, uploadserver)


build: | $(BUILD_DIR) $(INITRD) $(DISK_IMAGE_FILE) $(INSTALL_CONFIG) $(FLASH0) $(FLASH1)
	@$(call print_config)


## Do the actual installation
# The command will boot from the iso file.
# Then it will listen to port 3003 to retive further files.
# If such provided the install process will automatically done for you.


# Prepare bootloader flashes
FLASH0 := $(BUILD_DIR)/flash0.img
FLASH1 := $(BUILD_DIR)/flash1.img

$(FLASH0):
	cp /usr/share/qemu-efi-aarch64/QEMU_EFI.fd $@
	truncate -s 64M $@

$(FLASH1):
	truncate -s 64M $@




install_kvm: build $(FLASH0) $(FLASH1)
	$(MAKE) -f $(MKFILE) serve_start
	sudo qemu-system-aarch64 \
		-nographic \
		-M virt \
		-cpu host -enable-kvm \
		-smp ${CPUS} -m ${MEMORY} \
		-no-reboot \
		-drive file=$(DISK_IMAGE_FILE),format=qcow2 \
		-cdrom $(CLOUD_IMAGE_FILE) \
		-kernel $(KERNEL) \
		-initrd $(INITRD) \
		-drive file=$(FLASH0),format=raw,if=pflash -drive file=$(FLASH1),format=raw,if=pflash \
		-append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'
	$(MAKE) -f $(MKFILE) serve_stop


install_no_kvm: build
	$(MAKE) -f $(MKFILE) serve_start
	sudo qemu-system-aarch64 \
		-nographic \
		-machine virt -cpu cortex-a72 \
		-smp ${CPUS} \
		-m ${MEMORY} \
		-no-reboot \
		-drive file=$(DISK_IMAGE_FILE),format=qcow2 \
		-cdrom $(CLOUD_IMAGE_FILE) \
		-kernel $(KERNEL) \
		-initrd $(INITRD) \
		-append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'
	$(MAKE) -f $(MKFILE) serve_stop


install: install_kvm

# ## Finalize installation.
# # First boot will do the final step of cloud-init
# # Afterwards we can disable it.
# run_emulator:
# 	sudo qemu-system-x86_64 \
# 		-nographic \
# 		-cpu host -enable-kvm \
# 		-smp ${CPUS} \
# 		-m ${MEMORY} \
# 		-drive file=$(DISK_IMAGE_FILE),format=raw \
# 		-kernel $(KERNEL) \
# 		-append 'console=ttyS0 root=/dev/hda2'



## Finalize installation.
# First boot will do the final step of cloud-init
# Afterwards we can disable it.

## Run Emulator -------------------------------------------------
# Do the actual emulation run
# The command will boot an instance.
# Then it will listen to port 3003 to retive a run script
# This run script will be the one we provided.
run_emulator:
	sudo qemu-system-aarch64 \
		-nographic \
		-M virt \
		-cpu host -enable-kvm \
		-smp ${CPUS} -m ${MEMORY} \
		-device e1000,netdev=net0 \
    	-netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
		-drive file=$(DISK_IMAGE_FILE),format=qcow2 \
		-drive file=$(FLASH0),format=raw,if=pflash -drive file=$(FLASH1),format=raw,if=pflash \
		-kernel $(KERNEL) \
		-append 'console=ttyAMA0 earlyprintk=ttyAMA0 root=/dev/vda2'

run: run_emulator

# run_emulator_arm:
# 	sudo qemu-system-aarch64 \
# 		-nographic \
# 		-M virt \
# 		-cpu host -enable-kvm \
# 		-smp ${CPUS} \
# 		-m ${MEMORY} \
# 		-drive file=$(DISK_IMAGE_FILE),format=qcow2 \
# 		-kernel /users/dschall/vSwarm-u/wkdir//Image \
# 		-append 'console=ttyAMA0 earlyprintk=ttyAMA0 lpj=7999923 root=/dev/vda2'




install_finalize:
	cp $(CONFIGS_DIR)/finalize.sh $(BUILD_DIR)/run.sh
	$(MAKE) -f $(MKFILE) serve_start
	$(MAKE) -f $(MKFILE) run
	$(MAKE) -f $(MKFILE) serve_stop
	rm $(BUILD_DIR)/run.sh



## Save the created files to the resource directory
save: $(DISK_IMAGE_FILE)
	cp $(DISK_IMAGE_FILE) $(RESRC_BASE_IMAGE)

## Save the created files to the resource directory
save_output:
	cp $(DISK_IMAGE_FILE) $(OUTPUT)


$(RUN_SCRIPT): $(BUILD_DIR)
	sed 's|<__IMAGE_NAME__>|$(IMAGE_NAME)|g' $(RUN_SCRIPT_TEMPLATE) > $@



$(INSTALL_CONFIG): $(BUILD_DIR)
	cp $(CONFIGS_DIR)/autoinstall-arm64.yaml $@
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
	echo "$(CLOUD_IMAGE_HASH) *$(CLOUD_IMAGE_FILE)" | shasum -a 256 --check; \



$(BUILD_DIR):
	$(call spacing,"Create folder: $(BUILD_DIR)")
	mkdir -p $@
	cp $(CONFIGS_DIR)/* $@

##
# Create the disk image file
$(DISK_IMAGE_FILE): | $(BUILD_DIR)
	$(call spacing,"Build main disk image: $(DISK_SIZE)")
	qemu-img create -f qcow2 $@ $(DISK_SIZE)


# Extract the initrd file from the install disk
$(INITRD): $(CLOUD_IMAGE_FILE)
	mkdir -p iso
	sudo mount -r $(CLOUD_IMAGE_FILE) iso

	cp iso/casper/vmlinuz $(KERNEL)
	cp iso/casper/initrd $(BUILD_DIR)/initrd

	sudo umount iso
	rm -rf iso


####
# File server
serve_start:
	PID=$$(lsof -t -i :3003); \
	if [ ! -z $$PID ]; then kill -9 $$PID; fi

	python3 -m uploadserver -d $(BUILD_DIR) 3003 > server.log 2>&1 &  \
	sleep 2

	@PID=$$(lsof -t -i :3003); \
	if [ -z $$PID ]; then \
	echo "Fail to start server"; $$(cat server.log); exit; \
	else echo "Run server: $$PID"; fi

serve_stop:
	PID=$$(lsof -t -i :3003); \
	if [ ! -z $$PID ]; then kill -9 $$PID; fi



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