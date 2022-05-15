# -*- coding: utf-8 -*-
# Copyright (c) 2016 Jason Lowe-Power
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer;
# redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution;
# neither the name of the copyright holders nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Authors: Jason Lowe-Power, David Schall

""" Caches with options for a gem5 configuration script

This file contains L1 I/D, L2 and LLC caches to be used in the simple
gem5 configuration script.  It uses the SimpleOpts wrapper to set up command
line options from each individual class.
"""

from math import degrees
import m5
from m5.objects import Cache, L2XBar, WriteAllocator, SubSystem, TreePLRURP, TaggedPrefetcher
from m5.params import AddrRange, AllMemory, MemorySize
from m5.util.convert import toMemorySize

# Some specific options for caches
# For all options see src/mem/cache/BaseCache.py

class NextLinePrefetcher(TaggedPrefetcher):
    degree = 1
    queue_size = 2

class PrefetchCache(Cache):

    def __init__(self):
        super(PrefetchCache, self).__init__()

        self.prefetcher = NextLinePrefetcher()
        self.prefetcher.on_inst = True
        self.replacement_policy = TreePLRURP()


class L1Cache(PrefetchCache):
    """Simple L1 Cache with default values"""

    assoc = 8

    tag_latency = 1
    data_latency = 1
    response_latency = 1

    mshrs = 10
    tgts_per_mshr = 16
    write_buffers = 32
    demand_mshr_reserve = 5

    def __init__(self):
        super(L1Cache, self).__init__()

    def connectBus(self, bus):
        """Connect this cache to a memory-side bus"""
        self.mem_side = bus.cpu_side_ports

    def connectCPU(self, cpu):
        """Connect this cache's port to a CPU-side port
           This must be defined in a subclass"""
        raise NotImplementedError

class L1ICache(L1Cache):
    """Simple L1 instruction cache with default values"""

    # Set the default size
    size = '32kB'
    assoc = 8

    tag_latency = 1
    data_latency = 1

    is_read_only=True

    def __init__(self):
        super(L1ICache, self).__init__()

    def connectCPU(self, cpu):
        """Connect this cache's port to a CPU icache port"""
        self.cpu_side = cpu.icache_port
        # self.prefetcher.listenFromProbeRetiredInstructions(cpu)

class L1DCache(L1Cache):
    """L1 data cache with Skylake parameters"""

    # Set the default size
    size = '32kB'
    assoc = 8

    write_buffers = 12

    write_allocator = WriteAllocator()
    write_allocator.coalesce_limit = 2
    write_allocator.no_allocate_limit = 8
    write_allocator.delay_threshold = 8

    def __init__(self):
        super(L1DCache, self).__init__()

    def connectCPU(self, cpu):
        """Connect this cache's port to a CPU dcache port"""
        self.cpu_side = cpu.dcache_port

class MMUCache(PrefetchCache):
    # Default parameters
    size = '8kB'
    assoc = 4
    tag_latency = 1
    data_latency = 1
    response_latency = 1
    mshrs = 32
    tgts_per_mshr = 1
    write_buffers = 32

    def __init__(self):
        super(MMUCache, self).__init__()

    def connectCPU(self, cpu):
        """Connect the CPU itb and dtb to the cache
           Note: This creates a new crossbar
        """
        self.mmubus = L2XBar()
        self.cpu_side = self.mmubus.mem_side_ports
        for tlb in [cpu.mmu.itb, cpu.mmu.dtb]:
            self.mmubus.cpu_side_ports = tlb.walker.port

    def connectBus(self, bus):
        """Connect this cache to a memory-side bus"""
        self.mem_side = bus.cpu_side_ports

class L2Cache(Cache):
    """L2 Cache with Skylake parameters"""

    # Skylake
    size = '1MB'
    assoc = 8
    tag_latency = 12
    data_latency = 12
    response_latency = 6
    mshrs = 32
    tgts_per_mshr = 1
    write_buffers = 56


    def __init__(self):
        super(L2Cache, self).__init__()

    def connectCPUSideBus(self, bus):
        self.cpu_side = bus.mem_side_ports

    def connectMemSideBus(self, bus):
        self.mem_side = bus.cpu_side_ports

class L3Cache(Cache):
    """Simple L3 Cache bank with default values
       This assumes that the L3 is made up of multiple banks. This cannot
       be used as a standalone L3 cache.
    """

    ## Skylake parameter
    size = '8MB'
    assoc = 16
    tag_latency = 36
    data_latency = 36
    response_latency = 1
    mshrs = 32
    tgts_per_mshr = 2
    write_buffers = 64


    def __init__(self):
        super(L3Cache, self).__init__()

    def connectCPUSideBus(self, bus):
        self.cpu_side = bus.mem_side_ports

    def connectMemSideBus(self, bus):
        self.mem_side = bus.cpu_side_ports

