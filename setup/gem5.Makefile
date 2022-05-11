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
RESOURCES 	?=$(ROOT)/resources/
ARCH		:= X86

GEM5_DIR 	:= $(RESOURCES)/gem5/
GEM5 		:= $(RESOURCES)/build/$(ARCH)/gem5.opt


.PONY: all gem5 term m5

all: gem5 term m5


## Dependencies -------------------------------------------------
## Install all dependencies to build gem5
##
dep_install:
	sudo apt-get update \
  	&& sudo apt-get install -y \
        build-essential git m4 scons zlib1g zlib1g-dev \
    	libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    	python3-dev python3-six python-is-python3 libboost-all-dev pkg-config


## Clone repo --
$(GEM5_DIR):
	git clone https://gem5.googlesource.com/public/gem5 $@


## Build

gem5: $(GEM5_DIR)
	@$(call print_config)
	cd $(GEM5_DIR); \
	scons build/$(ARCH)/gem5.opt -j $$(nproc) --install-hooks


## Build the terminal
term: $(GEM5_DIR)
	@printf "$\n{GREEN}Build gem5 terminal${NC}\n"
	cd $(GEM5_DIR)/util/term; \
	make


_ARCH=x86
ifeq ($(ARCH), X86)
	_ARCH =x86
endif

## Build m5 tools
m5: $(GEM5_DIR)
	@printf "\n${GREEN}Build gem5's m5 binaries${NC}\n"
# $(eval $(if [ $(ARCH) == X86 ]; then _ARCH :=x86; fi))
	cd $(GEM5_DIR)/util/m5; \
	scons build/$(_ARCH)/out/m5


RED=\033[0;31m
GREEN=\033[0;32m
NC=\033[0m # No Color

define print_config
	printf "\n=============================\n"; \
	printf "${GREEN}  Build gem5 ${NC}\n"; \
	printf " ---\n"; \
	printf "Architecture: $(ARCH)\n"; \
	printf "Output: $(GEM5_DIR)\n"; \
	printf "=============================\n\n";
endef