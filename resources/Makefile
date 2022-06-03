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
TAG 	:= $(VERSION)-$(shell git rev-parse --short HEAD)
ARCH	:= amd64



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
RESRC_CLIENT 	:= $(RESOURCES)/test-client

## Build fresh kernel
build-kernel:
	echo "Build Kernel..."
	echo "test kernel asset" > $(RESRC_KERNEL)

# $(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile build
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile save

## Bake new base disk image
build-disk:
	echo "Build Disk ..."
	echo "test disk asset" > $(RESRC_DISK)
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile build
# $(MAKE) -f ${ROOT}/setup/kernel.Makefile save


# Build client from source
build-client:
	echo "Build Test client ..."
	cd $(ROOT)/tools/client/; \
	$(MAKE) all; \
	cp client $(RESRC_CLIENT)








build-resources: build-kernel build-disk
build-release-resources: build-kernel build-disk build-client

clean-release:
	rm -rf $(RESRC_KERNEL)
	rm -rf $(RESRC_DISK)
	rm -rf $(RESRC_CLIENT)


### ----- DOWNLOAD RESOURCES ----- ###
# RELEASE_URL := https://github.com/ease-lab/vSwarm-u/releases/download/refs%2Fpull%2F18%2Fmerge/

# Download the newest the test client
# from the proto repo.
# curl -L https://github.com/ease-lab/vSwarm-proto/releases/download/v0.1.3-e9087ac/client-linux-amd64 \
#     -o ${RESOURCES}/test-client
# chmod +x ${RESOURCES}/test-client

download-base-image:
	curl -L $(RELEASE_URL)/$(ARTIFACT_DISK) \
    -o $(RESRC_DISK).tst

download-kernel:
	curl -L $(RELEASE_URL)/vmlinux-$(ARCH) \
    -o $(RESRC_KERNEL).tst

download-resources: download-base-image download-kernel



### ----- TEST RESOURCES ----- ###
test-emu:
	echo "Perform emulator test..."
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile build
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile run_test
# $(MAKE) -f ${ROOT}/test/emu_test.Makefile check



test-release-resources: test-emu



# # Download the newest the test client
# # from the proto repo.
# curl -L https://github.com/ease-lab/vSwarm-proto/releases/download/v0.1.3-e9087ac/client-linux-amd64 \
#     -o ${RESOURCES}/test-client



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

# release-artifacts: check-release
# 	@echo '::set-output name=KERNEL::$(RESRC_KERNEL)'
# 	@echo '::set-output name=DISK_IMAGE::$(RESRC_DISK)'


test_upload:
	$(call upload_artifact,$(RESRC_KERNEL),kernel-test,$(GITHUB_TOKEN))


ARTIFACT_KERNEL := vmlinux-$(ARCH).tst
ARTIFACT_DISK 	:= disk-$(ARCH).tst
ARTIFACT_CLIENT := test-client-$(ARCH).tst



## Upload artifacts to release ##

GITHUB_TOKEN ?=
RELEASE_ID ?=
UPLOAD_URL ?= https://uploads.github.com/repos/ease-lab/vSwarm-u/releases/$(RELEASE_ID)

define upload_artifact
	curl -X POST \
		-H "Content-Type: $(shell file -b --mime-type $1)" \
    	-T "$1" \
    	-H "Authorization: token $(GITHUB_TOKEN)" \
    	-H "Accept: application/vnd.github.v3+json" \
    	$(UPLOAD_URL)/assets?name=$2
endef


upload_all_artifacts:
	$(call upload_artifact,$(RESRC_KERNEL),$(ARTIFACT_KERNEL))
	$(call upload_artifact,$(RESRC_DISK),$(ARTIFACT_DISK))
	$(call upload_artifact,$(RESRC_CLIENT),$(ARTIFACT_CLIENT))


## Download Artifacts

RELEASE_URL := https://github.com/ease-lab/vSwarm-u/releases/download/$(VERSION)
# RELEASE_URL := https://github.com/ease-lab/vSwarm-u/releases/download/v0.0.1-cf9662b/

define download_artifact
	curl -L $(RELEASE_URL)/$1 \
    -o $2
endef

download_all_artifact:
	$(call download_artifact,$(ARTIFACT_KERNEL),$(RESRC_KERNEL).tst2)
	$(call download_artifact,$(ARTIFACT_DISK),$(RESRC_DISK).tst2)
	$(call download_artifact,$(ARTIFACT_CLIENT),$(RESRC_CLIENT).tst2)




release-artifacts:
	@echo '::set-output name=KERNEL::$(RESRC_KERNEL)'
	@echo '::set-output name=DISK_IMAGE::$(RESRC_DISK)'
	@echo '::set-output name=TEST_CLIENT::$(RESRC_CLIENT)'
	@echo '::set-output name=VERSION::$(VERSION)'
	@echo '::set-output name=TAG::$(TAG)'

release-version:
	@echo $(VERSION)

release:
	git tag $(TAG)
	git push origin $(TAG)



RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

define check_file
	@if [ -f $1 ]; \
	then printf "$1 ${GREEN}exists${NC}\n"; \
	else printf "$1 ${RED}missing${NC}\n"; fi
endef








test_upload:
	$(call upload_artifact,kernel,kernel-test,$(GITHUB_TOKEN))


upload_all_artifact:


test_all:
