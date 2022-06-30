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


mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(mkfile_path))/../)

## User specific inputs
RESOURCES 	?=$(ROOT)/resources/

LINUX_DIR 	:= linux/
KERNEL_OUT 	?= $(RESOURCES)/vmlinux
OUTPUT		?=

KVERSION	:= v5.4.84
ARCH		?= arm64
KERNEL_CONFIG_GEM5 := $(ROOT)/configs/linux-configs/$(KVERSION)-$(ARCH).config
KERNEL_CONFIG := $(LINUX_DIR)/.config


.PONY: all config

all: build save

## Dependencies -------------------------------------------------
## Install all dependencies to build linux kernel
##
dep_install:
	sudo apt-get update \
  	&& sudo apt-get install -y \
        git build-essential ncurses-dev xz-utils libssl-dev bc \
    	flex libelf-dev bison

## Get sources --
$(LINUX_DIR):
	git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $@

## Make config
config: $(LINUX_DIR)
	cd $(LINUX_DIR); \
	git checkout $(KVERSION)
	cp $(KERNEL_CONFIG_GEM5) $(KERNEL_CONFIG)


## Build
build: $(LINUX_DIR) config
	@$(call print_config)
	cd $(LINUX_DIR); \
	make -j $$(nproc)


BUILD_OBJ := $(LINUX_DIR)/vmlinux
ifeq ($(ARCH), arm64)
	BUILD_OBJ := $(LINUX_DIR)/arch/arm64/boot/Image
endif


save: build
	cp $(BUILD_OBJ) $(KERNEL_OUT)

save_output:
	cp $(BUILD_OBJ) $(OUTPUT)


clean:
	rm -rf $(LINUX_DIR)

clean_all: clean
	rm $(KERNEL)

RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

define print_config
	printf "\n=============================\n"; \
	printf "${GREEN} Build Linux kernel for gem5 ${NC}\n"; \
	printf " ---\n"; \
	printf "kernel version: $(KVERSION)\n"; \
	printf "Output: $(KERNEL)\n"; \
	printf "=============================\n\n";
endef