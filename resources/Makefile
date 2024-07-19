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


VERSION 	:= v0.3.0
TAG 		:= $(VERSION)-$(shell git rev-parse --short HEAD)
ARCH		:= amd64
OS_VERSION 	:= focal



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
KERNEL 			?= $(RESOURCES)/kernel
BASE_DISK		?= $(RESOURCES)/base-disk-image.qcow2
DISK 			?= $(RESOURCES)/disk-image.qcow2
TEST_CLIENT 	?= $(RESOURCES)/test-client

## Build fresh kernel
build-kernel:
	@echo "\nBuild Kernel..."
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile build
	OUTPUT=$(KERNEL) $(MAKE) -f ${ROOT}/setup/kernel.Makefile save_output

## Bake new base disk image
build-disk:
	@echo "\nBuild Disk ..."
	make -f ${ROOT}/setup/disk.Makefile dep_install
	make -f ${ROOT}/setup/disk.Makefile download
	make -f ${ROOT}/setup/disk.Makefile install_no_kvm
	OUTPUT=$(BASE_DISK) make -f ${ROOT}/setup/disk.Makefile save_output

# Build client from source
build-client:
	@echo "\nBuild Test client ..."
	cd $(ROOT)/tools/client/; \
	$(MAKE) all; \
	cp client $(TEST_CLIENT)


clean-build:
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile clean
	$(MAKE) -f ${ROOT}/setup/disk.Makefile clean


build-resources: build-kernel build-disk
build-release-resources: build-kernel build-disk build-client


clean-release:
	rm -rf $(KERNEL)
	rm -rf $(DISK)
	rm -rf $(TEST_CLIENT)


# ### ----- DOWNLOAD RESOURCES ----- ###
# # download-resources:
# # 	$(call download_artifact,$(ARTIFACT_KERNEL),$(KERNEL))
# # 	$(call download_artifact,$(ARTIFACT_DISK),$(ARTIFACT_DISK))
# # 	$(call decompress,$(ARTIFACT_DISK))
# # 	$(call download_artifact,$(ARTIFACT_CLIENT),$(TEST_CLIENT))



### ----- TEST RESOURCES ----- ###
test-emu:
	echo "Perform emulator test..."
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile dep_install
	KERNEL=$(KERNEL) DISK=$(BASE_DISK) TEST_CLIENT=$(TEST_CLIENT) \
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile build
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile run_test_nokvm
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile check
	OUTPUT=$(DISK) $(MAKE) -f ${ROOT}/test/emu_test.Makefile save_output


test-release-resources: test-emu



## ARTIFACTS ---------------------- ###
ARTIFACT_KERNEL 	:= vmlinux-$(OS_VERSION)-$(ARCH)
ARTIFACT_DISK 		:= disk-image-$(OS_VERSION)-$(ARCH)
ARTIFACT_CLIENT 	:= test-client-$(ARCH)


download-resources:
	./artifacts.sh download $(KERNEL) $(ARTIFACT_KERNEL)
	./artifacts.sh download $(TEST_CLIENT) $(ARTIFACT_CLIENT)
	./artifacts.sh download-disk $(BASE_DISK) $(ARTIFACT_DISK)




## Upload artifacts to release ##
GITHUB_TOKEN ?=
RELEASE_ID ?= 68604631
UPLOAD_URL ?= https://uploads.github.com/repos/vhive-serverless/vSwarm-u/releases/$(RELEASE_ID)

define upload_artifact
	curl -X POST \
		-H "Content-Type: $(shell file -b --mime-type $1)" \
    	-T "$1" \
    	-H "Authorization: token $(GITHUB_TOKEN)" \
    	-H "Accept: application/vnd.github.v3+json" \
    	$(UPLOAD_URL)/assets?name=$2 > response 2>&1;
	@if $$(grep -q created_at response) ; then \
		echo "Upload successfull" ; \
	else \
		echo "Upload fail"; cat response; exit 1; \
	fi
endef


upload_all_artifacts:
	./artifacts.sh upload $(KERNEL) $(ARTIFACT_KERNEL)
	./artifacts.sh upload $(TEST_CLIENT) $(ARTIFACT_CLIENT)
	./artifacts.sh upload-disk $(DISK) $(ARTIFACT_DISK)




## Download Artifacts ---------------------
RELEASE_URL := https://github.com/vhive-serverless/vSwarm-u/releases/download/$(VERSION)
RELEASE_URL := https://github.com/vhive-serverless/vSwarm-u/releases/download/v0.0.1

define download_artifact
	curl -L $(RELEASE_URL)/$1 \
    -o $2
endef

download_all_artifact:
	$(call download_artifact,$(ARTIFACT_KERNEL),$(KERNEL))
	$(call download_artifact,$(ARTIFACT_DISK),$(ARTIFACT_DISK))
	$(call uncompress,$(ARTIFACT_DISK))
	$(call download_artifact,$(ARTIFACT_CLIENT),$(TEST_CLIENT))






### ------ RELEASE ------- ###

get-resoures-from-artifact-cache:
	cp $(ROOT)/artifacts/kernel $(KERNEL)
	cp $(ROOT)/artifacts/disk.img $(DISK)
	cp $(ROOT)/artifacts/test-client $(TEST_CLIENT)

check-release:
	$(call check_file, $(KERNEL))
	$(call check_file, $(DISK))
	$(call check_file, $(TEST_CLIENT))


release-artifacts:
	@echo '::set-output name=KERNEL::$(KERNEL)'
	@echo '::set-output name=DISK_IMAGE::$(DISK)'
	@echo '::set-output name=TEST_CLIENT::$(TEST_CLIENT)'
	@echo '::set-output name=VERSION::$(VERSION)'
	@echo '::set-output name=TAG::$(TAG)'

release-version:
	@echo $(VERSION)
	@echo '"test=hello" >> $$GITHUB_OUTPUT'

release:
	git tag $(VERSION)
	git push origin $(VERSION)








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



test_all:



## Upload artifacts to release ##

ACTIONS_URL = https://api.github.com/repos/vhive-serverless/vSwarm-u/actions/artifacts

define get_wf_artifacts
	curl -X POST \
		-H "Accept: application/vnd.github+json" \
    	-H "Authorization: token $(GITHUB_TOKEN)" \
    	-H "X-GitHub-Api-Version: 2022-11-28" \
    	$(ACTIONS_URL) > artifacts.json
endef


get_all_workflow_artifacts:
	$(call get_wf_artifacts)





