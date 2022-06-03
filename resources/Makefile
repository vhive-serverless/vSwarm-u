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


VERSION := v0.0.1
TAG 	:= "$(VERSION)-$$(git rev-parse --short HEAD)"



.PONY: all config

all: build save

## Dependencies -------------------------------------------------

# dep_install:
# 	sudo apt-get update \
#   	&& sudo apt-get install -y \








## Protocol buffer


BIN_DIR=build-dir



.PHONY: build test installclean release bin-dir


# VERSION ?=LOCAL


# if [ -z "$(shell git status --porcelain)" ]; then \
# 	sed -i "s|LOCAL|$$(git rev-parse --short HEAD)|" ./cmd/version.go; \
# 	go build -o $(BIN_DIR)/$(BIN) cmd/*; \
# 	git checkout -- ./cmd/version.go; \
# else \
# 	echo Working directory not clean, commit changes; \
# fi

## Client for all proto buffer

# client: test-client/main.go
# 	sed -i "s|LOCAL|$(VERSION)|" $<;
# 	go mod tidy
# 	go build -o $@ $<

# build-disk-image-release: disk-dir
# echo "Build disk image..."
# make -f ${ROOT}/setup/disk.Makefile dep_install
# make -f ${ROOT}/setup/disk.Makefile download
# make -f ${ROOT}/setup/disk.Makefile install
# make -f ${ROOT}/setup/disk.Makefile save


### ----- BUILD RESOURCES ----- ###
RESRC_KERNEL 	:= $(RESOURCES)/kernel
RESRC_DISK 		:= $(RESOURCES)/base-disk-image.qcow2


build-kernel:
	echo "Build Kernel..."
	echo "test kernel asset" > $(RESRC_KERNEL)

# $(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile build
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile save


build-disk:
	echo "Build Disk ..."
	echo "test disk asset" > $(RESRC_DISK)

# $(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile build
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile save


build-resources: build-kernel build-disk
build-release-resources: build-kernel build-disk



### ----- TEST RESOURCES ----- ###
test-emu:
	echo "Perform emulator test..."
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile build
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile run_test
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile check



test-release-resources: test-emu





### ------ RELEASE ------- ###


RELEASE_DIR 	:= release-dir
RELEASE_KERNEL 	:= $(RELEASE_DIR)/kernel
RELEASE_DISK 	:= $(RELEASE_DIR)/base-disk-image.img

# build-release: $(RELEASE_DIR)
# 	$(call check_file, $(RESRC_KERNEL))
# 	$(call check_file, $(RESRC_DISK))
# 	cp $(RESRC_KERNEL) $(RELEASE_KERNEL)
# 	cp $(RESRC_DISK) $(RELEASE_DISK)


# build-release: $(RELEASE_DIR)
# 	$(call check_file, $(RESRC_KERNEL))
# 	cp $(RESRC_KERNEL) $(RELEASE_KERNEL)






%-dir:
	mkdir -p $@

clean:
	if [ -d $(BIN_DIR) ]; then rm -rf $(BIN_DIR); fi

# release: build-release
# 	VERSION=$$($(BIN_DIR)/$(BIN) --version); \
# 	git tag $$VERSION;

check-release:
	$(call check_file, $(RESRC_KERNEL))
	$(call check_file, $(RESRC_DISK))

release-artifacts: check-release
	@echo '::set-output name=KERNEL::$(RESRC_KERNEL)'
	@echo '::set-output name=DISK_IMAGE::$(RESRC_DISK)'

release-version:
	@echo $(TAG)

release:
	echo git tag $(TAG);



RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

define check_file
	@if [ -f $1 ]; \
	then printf "$1 ${GREEN}exists${NC}\n"; \
	else printf "$1 ${RED}missing${NC}\n"; fi
endef