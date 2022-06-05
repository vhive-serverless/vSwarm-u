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


VERSION := v0.0.4
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
RESRC_BASE_DISK	:= $(RESOURCES)/base-disk-image.qcow2
RESRC_DISK 		:= $(RESOURCES)/disk-image.qcow2
RESRC_CLIENT 	:= $(RESOURCES)/test-client

## Build fresh kernel
build-kernel:
	@echo "\nBuild Kernel..."
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile dep_install
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile build
	OUTPUT=$(RESRC_KERNEL) $(MAKE) -f ${ROOT}/setup/kernel.Makefile save_output

## Bake new base disk image
build-disk:
	@echo "\nBuild Disk ..."
	make -f ${ROOT}/setup/disk.Makefile dep_install
	make -f ${ROOT}/setup/disk.Makefile download
	make -f ${ROOT}/setup/disk.Makefile install_no_kvm
	OUTPUT=$(RESRC_BASE_DISK) make -f ${ROOT}/setup/disk.Makefile save_output

# Build client from source
build-client:
	@echo "\nBuild Test client ..."
	cd $(ROOT)/tools/client/; \
	$(MAKE) all; \
	cp client $(RESRC_CLIENT)


# ## Build fresh kernel
# build-kernel:
# 	@echo "Build Kernel..."
# 	echo "Test kernel" > $(RESRC_KERNEL)

# ## Bake new base disk image
# build-disk:
# 	@echo "Build Disk ..."
# 	echo "Test Disk" > $(RESRC_DISK)


# ## Bake new base disk image
# build-disk:
# 	@echo "\nBuild Disk ..."
# 	cp ../wkdir/disk.img.bak $(RESRC_DISK)

# # Build client from source
# build-client:
# 	echo "Build Test client ..."
# 	echo "Test Disk" > $(RESRC_CLIENT)


clean-build:
	$(MAKE) -f ${ROOT}/setup/kernel.Makefile clean
	$(MAKE) -f ${ROOT}/setup/disk.Makefile clean


build-resources: build-kernel build-disk
build-release-resources: build-kernel build-disk build-client


clean-release:
	rm -rf $(RESRC_KERNEL)
	rm -rf $(RESRC_DISK)
	rm -rf $(RESRC_CLIENT)


# ### ----- DOWNLOAD RESOURCES ----- ###
# # download-resources:
# # 	$(call download_artifact,$(ARTIFACT_KERNEL),$(RESRC_KERNEL))
# # 	$(call download_artifact,$(ARTIFACT_DISK),$(ARTIFACT_DISK))
# # 	$(call decompress,$(ARTIFACT_DISK))
# # 	$(call download_artifact,$(ARTIFACT_CLIENT),$(RESRC_CLIENT))

download-resources:
	./artifacts.sh download $(RESRC_KERNEL) $(ARTIFACT_KERNEL)
	./artifacts.sh download $(RESRC_CLIENT) $(ARTIFACT_CLIENT)
	./artifacts.sh download-disk $(RESRC_BASE_DISK) $(ARTIFACT_DISK)



### ----- TEST RESOURCES ----- ###
test-emu:
	echo "Perform emulator test..."
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile dep_install
	KERNEL=$(RESRC_KERNEL) DISK=$(RESRC_BASE_DISK) TEST_CLIENT=$(RESRC_CLIENT) \
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile build
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile run_test
	$(MAKE) -f ${ROOT}/test/emu_test.Makefile check
	OUTPUT=$(RESRC_DISK) $(MAKE) -f ${ROOT}/test/emu_test.Makefile save_output


test-release-resources: test-emu



## ARTIFACTS ---------------------- ###
ARTIFACT_KERNEL 	:= vmlinux-$(ARCH)
ARTIFACT_DISK 		:= test-disk-image-$(ARCH)
ARTIFACT_CLIENT 	:= test-client-$(ARCH)

## Upload artifacts to release ##

GITHUB_TOKEN ?=
RELEASE_ID ?= 68604631
UPLOAD_URL ?= https://uploads.github.com/repos/ease-lab/vSwarm-u/releases/$(RELEASE_ID)

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
	./artifacts.sh upload $(RESRC_KERNEL) $(ARTIFACT_KERNEL).new2
	./artifacts.sh upload $(RESRC_CLIENT) $(ARTIFACT_CLIENT).new2
	./artifacts.sh upload-disk $(RESRC_DISK) $(ARTIFACT_DISK).new2


upload_base:
	$(call upload_artifact,disk.zip,$(ARTIFACT_DISK))


## Compress and decompress artifacts
# define compress
# 	tar -cJf $1.tar.xz $1
# endef

# define decompress
# 	tar -xvf $1.tar.xz
# endef

# define compress
# 	tar -czf $1.tar.gz $1
# endef

# define decompress
# 	tar -xvf $1.tar.gz
# endef

# define compress
# 	zip -9 $2 $1
# endef

# define decompress
# 	unzip $1
# endef

# test-compress:
# 	$(call compress,test,$(ARTIFACT_DISK))
# 	$(call decompress,$(ARTIFACT_DISK))





# # define compress-split
# # 	shasum -a 256 $1 > $2.sums
# # 	zip -4 tmp.zip $1
# # 	zip tmp.zip --out $2.zip -s 2m
# # endef


# # define decompress-split
# # 	zip -s0 $1.zip --out existing.zip
# # 	unzip existing.zip
# # 	shasum -a 256 -c $2.sums
# # endef


# define compress-split
# 	shasum -a 256 $1 > $2.sums
# 	tar cvzf tmp.tar.gz $1
# 	split -b 1m tmp.tar.gz $2.tar.gz.
# endef


# define decompress-split
# 	cat $1.tar.gz.* > tmp2.tar.gz
# 	tar xzvf tmp2.tar.gz
# 	shasum -a 256 -c $1.sums
# endef

# # define upload_all
# # 	for f in $1.tar.gz.*; do \
# # 	echo Upload $$f; \
# # 	$(eval $(call upload_artifact,$$f,$$f)); \
# # 	done
# # endef



# define upload_all
# 	$(eval $(files := $(wildcard $1.tar.gz.*)))
# 	echo $(files)
# 	$(foreach f,$(files),echo $(f))
# endef




# test-disk:
# 	cp vmlinux vmtest
# 	$(call compress-split,vmtest,vmart)
# 	$(call upload_all,vmart)
# 	rm vmtest
# 	$(call decompress-split,vmart,vmtest)








## Download Artifacts ---------------------

RELEASE_URL := https://github.com/ease-lab/vSwarm-u/releases/download/$(VERSION)
RELEASE_URL := https://github.com/ease-lab/vSwarm-u/releases/download/v0.0.1

define download_artifact
	curl -L $(RELEASE_URL)/$1 \
    -o $2
endef

download_all_artifact:
	$(call download_artifact,$(ARTIFACT_KERNEL),$(RESRC_KERNEL))
	$(call download_artifact,$(ARTIFACT_DISK),$(ARTIFACT_DISK))
	$(call uncompress,$(ARTIFACT_DISK))
	$(call download_artifact,$(ARTIFACT_CLIENT),$(RESRC_CLIENT))






### ------ RELEASE ------- ###

check-release:
	$(call check_file, $(RESRC_KERNEL))
	$(call check_file, $(RESRC_DISK))
	$(call check_file, $(RESRC_CLIENT))




release-artifacts:
	@echo '::set-output name=KERNEL::$(RESRC_KERNEL)'
	@echo '::set-output name=DISK_IMAGE::$(RESRC_DISK)'
	@echo '::set-output name=TEST_CLIENT::$(RESRC_CLIENT)'
	@echo '::set-output name=VERSION::$(VERSION)'
	@echo '::set-output name=TAG::$(TAG)'

release-version:
	@echo $(VERSION)

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


upload_all_artifact:


test_all:
