# -*- coding: utf-8 -*-
# Copyright (c) 2016 Jason Lowe-Power
# Copyright (c) 2022 EASE lab, University of Edinburgh
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

import os
import sys

import m5
import m5.ticks
from m5.objects import *
from m5.util import addToPath, fatal, warn


import m5
from m5.objects import *

from . import x86


class DriveSystem(System):

    def __init__(self, kernel, disk, no_kvm=False):
        super(DriveSystem, self).__init__()
        # driver system CPU is always simple, so is the memory
        # Note this is an assignment of a class, not an instance.
        DriveCPUClass = AtomicSimpleCPU
        drive_mem_mode = 'atomic'
        DriveMemClass = SimpleMemory

        self._no_kvm = no_kvm
        self._host_parallel = True

        # Set up the clock domain and the voltage domain
        self.clk_domain = SrcClockDomain()
        self.clk_domain.clock = '3.5GHz'
        self.clk_domain.voltage_domain = VoltageDomain()

        mem_size = "2GB"

        self.mem_ranges = [AddrRange(mem_size)]

        # Create the main memory bus
        # This connects to main memory
        self.membus = SystemXBar(width = 64) # 64-byte width
        self.membus.badaddr_responder = BadAddr()
        self.membus.default = Self.badaddr_responder.pio

        # Set up the system port for functional access from the simulator
        self.system_port = self.membus.cpu_side_ports


        # This will initialize most of the x86-specific system parameters
        # This includes things like the I/O, multiprocessor support, BIOS...
        x86.initFS(self, self.membus, 1)

        # The first disk is the root disk. The second could be used for swap
        # or anything else.
        self.setDiskImages(disk, disk)

        # Set the kernel
        self.workload.object_file = kernel
        # Options specified on the kernel command line
        boot_options = ['earlyprintk=ttyS0', 'console=ttyS0', 'lpj=7999923',
                         'root=/dev/hda2',
                        #  'isolcpus=1',
                        ]

        self.workload.command_line = ' '.join(boot_options)

        # Create the CPUs for our system.
        print("Drive system: {} {} cores".format(1,DriveCPUClass))
        self.createCPU()

        # Set up the interrupt controllers for the system (x86 specific)
        self.setupInterrupts()
        self.connectCPUDirectly()


        # Create the memory controller for the sytem
        self.createMemoryControllers()


    def getHostParallel(self):
        return self._host_parallel

    def totalInsts(self):
        return sum([cpu.totalInsts() for cpu in self.cpu])

    def createCPUThreads(self, cpu):
        for c in cpu:
            c.createThreads()

    def createCPU(self):

        # KVM core for booting and setup
        # Note KVM needs a VM and atomic_noncaching
        self.cpu = [X86KvmCPU(clk_domain=self.clk_domain,
                            cpu_id = 0,
                            switched_out = False)]
        self.createCPUThreads(self.cpu)
        self.kvm_vm = KvmVM()
        self.mem_mode = 'atomic_noncaching'

        # Create atomic cpu for driving the test
        self.atomicCpu = [AtomicSimpleCPU(clk_domain=self.clk_domain,
                                        cpu_id = 0,
                                        switched_out = True)]
        self.createCPUThreads(self.atomicCpu)




    def switchCpus(self, old, new):
        assert(new[0].switchedOut())
        m5.switchCpus(self, list(zip(old, new)))

    def setDiskImages(self, img_path_1, img_path_2):
        disk0 = CowDisk(img_path_1)
        disk2 = CowDisk(img_path_2)
        # self.pc.south_bridge.ide.disks = [disk0, disk2]
        self.pc.south_bridge.ide.disks = [disk0]


    def connectCPUDirectly(self):
        self.llc_bus = L2XBar(width = 64,
                            snoop_filter = SnoopFilter(max_capacity='32MB'))

        # Add a tiny cache. This cache is required when switching CPUs
        # for the classic memory model for coherence
        self.llc_cache = Cache(assoc=8,
                                tag_latency = 5,
                                data_latency = 5,
                                response_latency = 5,
                                mshrs = 20,
                                size = '4MB',
                                tgts_per_mshr = 12,)
        self.llc_cache.mem_side = self.membus.cpu_side_ports
        self.llc_cache.cpu_side = self.llc_bus.mem_side_ports

        for cpu in self.cpu:
            for port in [cpu.icache_port, cpu.dcache_port]:
                self.llc_bus.cpu_side_ports = port
            for tlb in [cpu.mmu.itb, cpu.mmu.dtb]:
                self.llc_bus.cpu_side_ports = tlb.walker.port



    def setupInterrupts(self):
        for cpu in self.cpu:
            # create the interrupt controller CPU and connect to the membus
            cpu.createInterruptController()

            # For x86 only, connect interrupts to the memory
            # Note: these are directly connected to the memory bus and
            #       not cached
            cpu.interrupts[0].pio = self.membus.mem_side_ports
            cpu.interrupts[0].int_requestor = self.membus.cpu_side_ports
            cpu.interrupts[0].int_responder = self.membus.mem_side_ports



    def createMemoryControllers(self):
        """ Create the memory controller for the system """

        # Just create a controller for the first range, assuming the memory
        # size is < 3GB this will work. If it's > 3GB or if you want to use
        # mulitple or interleaved memory controllers then this should be
        # updated accordingly
        self.mem_cntrl = SimpleMemory(range = self.mem_ranges[0],
                                       port = self.membus.mem_side_ports)


class CowDisk(IdeDisk):
    """ Wrapper class around IdeDisk to make a simple copy-on-write disk
        for gem5. Creates an IDE disk with a COW read/write disk image.
        Any data written to the disk in gem5 is saved as a COW layer and
        thrown away on the simulator exit.
    """

    def __init__(self, filename):
        """ Initialize the disk with a path to the image file.
            @param filename path to the image file to use for the disk.
        """
        super(CowDisk, self).__init__()
        self.driveID = 'device0'
        self.image = CowDiskImage(child=RawDiskImage(read_only=True),
                                  read_only=False)
        self.image.child.image_file = filename