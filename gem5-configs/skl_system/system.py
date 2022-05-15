# -*- coding: utf-8 -*-
# Copyright (c) 2016 Jason Lowe-Power
# Copyright (c) 2022 EASE lab, University of Edinbursh
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
import m5
from m5.objects import *
from m5.util import convert

import x86

from caches import *

class SklSystem(System):

    def __init__(self, kernel, disk, num_cpus=2, CPUModel=AtomicSimpleCPU):
        super(SklSystem, self).__init__()

        self._host_parallel = False if num_cpus == 1 else True

        # Set up the clock domain and the voltage domain
        self.clk_domain = SrcClockDomain()
        self.clk_domain.clock = '2.5GHz'
        self.clk_domain.voltage_domain = VoltageDomain()

        # For x86, there is an I/O gap from 3GB to 4GB.
        # We can have at most 3GB of memory unless we do something special
        # to account for this I/O gap. For simplicity, this is omitted.
        mem_size = '2GB'
        self.mem_ranges = [AddrRange(mem_size)]

                        #    AddrRange(0xC0000000, size=0x100000), # For I/0
                        #    ]

        # Create the main memory bus
        # This connects to main memory
        self.membus = SystemXBar(width = 64) # 64-byte width
        self.membus.badaddr_responder = BadAddr()
        self.membus.default = Self.badaddr_responder.pio


        # Set up the system port for functional access from the simulator
        self.system_port = self.membus.cpu_side_ports

        # This will initialize most of the x86-specific system parameters
        # This includes things like the I/O, multiprocessor support, BIOS...
        x86.initFS(self, self.membus, num_cpus)

        # Change this path to point to the kernel you want to use
        # Set disk image
        self.setDiskImage(disk)

        # Set the kernel
        self.workload.object_file = kernel
        # Options specified on the kernel command line
        boot_options = ['earlyprintk=ttyS0', 'console=ttyS0', 'lpj=7999923',
                         'root=/dev/hda2',
                         'isolcpus=1',
                        'cloud-init=disabled',
                        ]

        self.workload.command_line = ' '.join(boot_options)

        # Create the CPU for our system.
        self.createCPU(num_cpus=num_cpus, CPUModel=CPUModel)
        # Create the CPUs for our system.
        print("Test system: {} {} cores".format(num_cpus, CPUModel))
        self.createCPU(num_cpus, CPUModel)
        # Set up the interrupt controllers for the system (x86 specific)
        self.setupInterrupts()
        # Create the cache heirarchy for the system.
        self.createCacheHierarchy()

        # Create the memory controller for the sytem
        # self.createMemoryControllers()
        # n_dram_cntrl = 1 if simple else 4
        # if simple:
        n_dram_cntrl = 1
        self.createMemoryController(n_dram_cntrl)
        # else:
        #     self.createMemoryControllersDDR4(n_dram_cntrl)


        if self._host_parallel:
            # To get the KVM CPUs to run on different host CPUs
            # Specify a different event queue for each CPU
            for i,cpu in enumerate(self.cpu):
                for obj in cpu.descendants():
                    obj.eventq_index = 0
                cpu.eventq_index = i + 1

    def getHostParallel(self):
        return self._host_parallel

    def createCPU(self, num_cpus=2, CPUModel=AtomicSimpleCPU):
        """ Create the CPUs for the system """

        # Beside the CPU we use for simulation we will use
        # KVM booting linux and spinning up the function.
        # Note KVM needs a VM and atomic_noncaching
        self.cpu = [X86KvmCPU(cpu_id = i)
                    for i in range(num_cpus)]
        self.createCPUThreads(self.cpu)
        self.kvm_vm = KvmVM()
        self.mem_mode = 'atomic_noncaching'


        # Create the CPUs for our detailed simulations.
        # By default this is a simple atomic CPU. Using other CPU models
        # and using timing memory is possible as well.
        # Also, changing this to using multiple CPUs is also possible
        # Note: If you use multiple CPUs, then the BIOS config needs to be
        #       updated as well.
        #
        self.detailed_cpu = [CPUModel(cpu_id = i,
                                     switched_out = True)
                   for i in range(num_cpus)]
        self.createCPUThreads(self.detailed_cpu)


        # # KVM core for booting and setup
        # # Note KVM needs a VM and atomic_noncaching
        # self.cpu = [X86KvmCPU(clk_domain=self.clk_domain,
        #                     cpu_id = 0,
        #                     switched_out = False)]
        # self.createCPUThreads(self.cpu)
        # self.kvm_vm = KvmVM()
        # self.mem_mode = 'atomic_noncaching'

        # # Create atomic cpu for driving the test
        # self.detailed_cpu = [AtomicSimpleCPU(clk_domain=self.clk_domain,
        #                                 cpu_id = 0,
        #                                 switched_out = True)]
        # self.createCPUThreads(self.detailed_cpu)


    def createCPUThreads(self, cpu):
        for c in cpu:
            c.createThreads()

    def switchToDetailedCpus(self):
        m5.switchCpus(self, list(zip(self.cpu, self.detailed_cpu)))

    def switchToKvmCpus(self):
        m5.switchCpus(self, list(zip(self.detailed_cpu, self.cpu)))

    def setDiskImage(self, img_path):
        """ Set the disk image
            @param img_path path on the host to the image file for the disk
        """
        # Can have up to two master disk images.
        # This can be enabled with up to 4 images if using master-slave pairs
        disk0 = CowDisk(img_path)
        self.pc.south_bridge.ide.disks = [disk0]


    def createCacheHierarchy(self):
        # Create an L3 cache (with crossbar)
        self.l3bus = L2XBar(width = 64,
                            snoop_filter = SnoopFilter(max_capacity='32MB'))
        self._caches = []

        for cpu in self.cpu:
            # Create a memory bus, a coherent crossbar, in this case
            cpu.l2bus = L2XBar()

            # Create an L1 instruction and data cache
            cpu.icache = L1ICache()
            cpu.dcache = L1DCache()
            cpu.mmucache = MMUCache()
            self._caches += [cpu.icache, cpu.dcache, cpu.mmucache]

            # Connect the instruction and data caches to the CPU
            cpu.icache.connectCPU(cpu)
            cpu.dcache.connectCPU(cpu)
            cpu.mmucache.connectCPU(cpu)

            # Hook the CPU ports up to the l2bus
            cpu.icache.connectBus(cpu.l2bus)
            cpu.dcache.connectBus(cpu.l2bus)
            cpu.mmucache.connectBus(cpu.l2bus)

            # Create an L2 cache and connect it to the l2bus
            cpu.l2cache = L2Cache()
            self._caches += [cpu.l2cache]
            cpu.l2cache.connectCPUSideBus(cpu.l2bus)

            # Connect the L2 cache to the L3 bus
            cpu.l2cache.connectMemSideBus(self.l3bus)

        self.l3cache = L3Cache()
        self._caches += [self.l3cache]
        self.l3cache.connectCPUSideBus(self.l3bus)

        # Connect the L3 cache to the membus
        self.l3cache.connectMemSideBus(self.membus)


    def connectCPUDirectly(self):
        self.llc_bus = L2XBar(width = 64,
                            snoop_filter = SnoopFilter(max_capacity='32MB'))

        # Add a tiny cache. This cache is required when switching CPUs
        # for the classic memory model for coherence
        self.llc_cache = Cache(assoc=8,
                                tag_latency = 50,
                                data_latency = 50,
                                response_latency = 50,
                                mshrs = 20,
                                size = '1kB',
                                tgts_per_mshr = 12,)
        self._caches = [self.llc_cache]
        self.llc_cache.mem_side = self.membus.cpu_side_ports
        self.llc_cache.cpu_side = self.llc_bus.mem_side_ports

        for cpu in self.cpu:
            for port in [cpu.icache_port, cpu.dcache_port]:
                self.llc_bus.cpu_side_ports = port
            for tlb in [cpu.mmu.itb, cpu.mmu.dtb]:
                self.llc_bus.cpu_side_ports = tlb.walker.port


    def flushCaches(self):
        m5.drain()

        for cache in self._caches:
            print("Flush: ", cache)
            cache.memWriteback()
            cache.memInvalidate()



    def createSimpleMemoryController(self):
        """ Create the memory controller for the system """

        # Just create a controller for the first range, assuming the memory
        # size is < 3GB this will work. If it's > 3GB or if you want to use
        # mulitple or interleaved memory controllers then this should be
        # updated accordingly
        self.mem_cntrl = SimpleMemory(range = self.mem_ranges[0],
                                       port = self.membus.mem_side_ports)


    def createMemoryController(self, n_dram_cntrl=1):
        self._createMemoryControllers(n_dram_cntrl, DDR4_2400_16x4)

    def _createMemoryControllers(self, n_dram_cntrl=1, dram_cls=SimpleMemory):
        ranges = self._getInterleaveRanges(self.mem_ranges[0], n_dram_cntrl, 7, 20)
        self.mem_cntrls = [
            MemCtrl(dram = dram_cls(range = ranges[i]), port = self.membus.mem_side_ports)
                for i in range(n_dram_cntrl)
        ]

    def _getInterleaveRanges(self, rng, num, intlv_low_bit, xor_low_bit):
        from math import log
        bits = int(log(num, 2))
        if 2**bits != num:
            m5.fatal("Non-power of two number of memory controllers")

        intlv_bits = bits
        ranges = [
            AddrRange(start=rng.start,
                      end=rng.end,
                      intlvHighBit = intlv_low_bit + intlv_bits - 1,
                      xorHighBit = xor_low_bit + intlv_bits - 1,
                      intlvBits = intlv_bits,
                      intlvMatch = i)
                for i in range(num)
            ]

        return ranges




    def setupInterrupts(self):
        """ Create the interrupt controller for the CPU """
        for cpu in self.cpu:
            # create the interrupt controller CPU and connect to the membus
            cpu.createInterruptController()

            # For x86 only, connect interrupts to the memory
            # Note: these are directly connected to the memory bus and
            #       not cached
            cpu.interrupts[0].pio = self.membus.mem_side_ports
            cpu.interrupts[0].int_requestor = self.membus.cpu_side_ports
            cpu.interrupts[0].int_responder = self.membus.mem_side_ports

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