---
layout: default
title: Home
nav_order: 1
has_children: true
---

# vSwarm-&mu; Documentation


>## Note
>vSwarm-&mu; is still in beta state but will be released soon for the ISCA'22 conference.

## Mission

Serverless computing has emerged as a widely used paradigm for deploying services in the cloud. In serverless, developers organize their application as a set of functions, which are invoked on-demand in response to a trigger, such as user request or an invocation by another function.

Recent studies of production data  reveal drastic differences in the characteristics of serverless workloads compared to conventional cloud workloads: short execution time and infrequent invocation of function instances. Performance studies  further finds that serverless workloads are inefficient when running on modern CPUs designed for traditional long-running workloads. To make serverless workload execution efficient, there is a strong need to understand more about the detailed implications serverless workload characteristics have on modern hardware.

However, existing platforms that support the required level of detail make significant simplifications in the test setup and the software stack to achieve feasible simulation times. Prior work often lacks the key layers of the serverless software stack, such as containerization and HTTP-level communication fabric, to simplify and increase the simulation speed. However, the short execution time of serverless functions leads to a significant fraction of execution time spent in system layers. Such simplifications may result in wrong experimental data and, consequently, mislead the systems researchers.

With vSwarm-&mu; we are addressing the challenges of serverless host server simulation and allow researchers to conduct experiments with systems representative of a modern serverless cloud. To achieve this, the vSwarm-u framework integrates various serverless workloads packages as containerized functions and featuring the full communication stack with gem5, the state-of-the-art research platform for system- and microarchitecture. This allows researcher to perform cycles accurate simulation of the representative serverless software stack in gem5’s full system mode.

Furthermore, vSwarm-u&mu includes the infrastructure to drive function instances running on the simulated serverless host server without interfering or simplifying the complexity of the test system. The robust evaluation methodology allows benchmarking and microarchitecture analysis in a realistic scenario.