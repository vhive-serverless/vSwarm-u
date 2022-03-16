
import m5
from m5.objects import *
from m5.util import convert

import x86

from caches import *

class MySystem(System):

    def __init__(self, kernel, disk, num_cpus=2, CPUModel=AtomicSimpleCPU):
        super(MySystem, self).__init__()

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

        # Set up the interrupt controllers for the system (x86 specific)
        self.setupInterrupts()
        # Create the cache heirarchy for the system.
        self.createCacheHierarchy()

        # Create the memory controller for the sytem
        self.createMemoryControllers()

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
        self.llc_cache.mem_side = self.membus.cpu_side_ports
        self.llc_cache.cpu_side = self.llc_bus.mem_side_ports

        for cpu in self.cpu:
            for port in [cpu.icache_port, cpu.dcache_port]:
                self.llc_bus.cpu_side_ports = port
            for tlb in [cpu.mmu.itb, cpu.mmu.dtb]:
                self.llc_bus.cpu_side_ports = tlb.walker.port

    def createCacheHierarchy(self):
        """ Create a simple cache heirarchy with a shared LLC"""

        # Create an L3 cache (with crossbar)
        self.llcbus = L2XBar(width = 64)
        self.llc = LLCCache()

        # Connect the LLC
        self.llc.connectCPUSideBus(self.llcbus)
        self.llc.connectMemSideBus(self.membus)


        for cpu in self.cpu:
            # Create an L1 instruction and data cache
            cpu.icache = L1ICache()
            cpu.dcache = L1DCache()

            # Connect the instruction and data caches to the CPU
            cpu.icache.connectCPU(cpu)
            cpu.dcache.connectCPU(cpu)

            # Hook the CPU ports up to the llcbus
            cpu.icache.connectBus(self.llcbus)
            cpu.dcache.connectBus(self.llcbus)

            # Connect the CPU TLBs directly to the mem.
            cpu.mmu.itb.walker.port = self.membus.cpu_side_ports
            cpu.mmu.dtb.walker.port = self.membus.cpu_side_ports


    def createMemoryControllers(self):
        """ Create the memory controller for the system """

        # Just create a controller for the first range, assuming the memory
        # size is < 3GB this will work. If it's > 3GB or if you want to use
        # mulitple or interleaved memory controllers then this should be
        # updated accordingly
        self.mem_cntrl = SimpleMemory(range = self.mem_ranges[0],
                                       port = self.membus.mem_side_ports)

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