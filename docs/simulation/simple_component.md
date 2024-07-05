---
layout: default
title: Simple Simulation with gem5 Component Library
parent: Simulation
nav_order: 1
---

# Simulation Methodology
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

<!-- ## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc} -->


---

Gem5 offers a wide range of prebuild configurations, aka. standard library, for cpus, boards, caches, etc. To simplify the configuration process we provide a configuration script that is mostly constructed out the component models provided by gem5. This script is called `vswarm_simple.py` and will be copied into your working directory.

After installing the functions on the disk you can perform the *setup* step with the following command:

```bash
<gem5_root>/build/<ALL/X86>/gem5.opt vswarm_simple.py --kernel kernel --disk disk.img --mode setup --atomic-warming=50 --num-invocations=20
```

This will boot the kernel, function, invoke the function for 50 times and then create a checkpoint. The simulation will exit or can be killed otherwise

Once the checkpoint is created the simulation can be performed with:

```bash
<gem5_root>/build/<ALL/X86>/gem5.opt vswarm_simple.py --kernel kernel --disk disk.img --mode evaluation --atomic-warming=50 --num-invocations=20
```

The script was tested with ATOMIC,TIMING and O3 core which can be configured commenting the corresponding lines in the script
```
eval_core = CPUTypes.<TIMING/ATOMIC/O3>
```