---
layout: default
title: Function benchmarks from vSwarm
parent: Simulation
nav_order: 40
---

# Function Benchmarks from vSwarm

Currently we support and tested 21 functions from our benchmark suite vSwarm
{: .fs-6 .fw-300 }



## Standalone kernels
The benchmark suite contains three functions that implement the same functionality in different runtime. With this the difference in the runtime's can be explored. The runtime's golang, nodejs, python are most common used for serverless and are representatives for a compiled, JIT-compiled and interpreted language. Details about the functions can be found in [vSwarm](https://github.com/ease-lab/vSwarm/tree/main/benchmarks)


| Benchmark      | Name | Languages implemented  | gem5 support |
|----------------|------|------------------------|--------------|
| AES            | `aes-<rt>` | python, golang, nodejs | ✓           |
| Authentication | `auth-<rt>` | python, golang, nodejs | ✓           |
| Fibonacci      | `fibonacci-<rt>` | python, golang, nodejs | ✓           |
> <small>`<rt>` stands for runtime: python, nodejs, go)</small>
{: .fs-4 .fw-300 }


## Hotel Reservation app
Functions from DeathStarBenchs hotel reservation app. Description of the benchmarks can be found in [vSwarm](https://github.com/ease-lab/vSwarm/tree/main/benchmarks/hotel-app)

| Benchmark | Dependent on | Knative infra | Tracing | Gem5 support | Runtimes | Languages implemented  |
|---|---|---|---|---|---|---|
| Geo            | Serving | database | ✓ | ✓ | docker, knative | golang |
| Profile        | Serving | database, memcached |✓ | ✓ | docker, knative | golang |
| Rate           | Serving | database, memcached | ✓ | ✓ | docker, knative | golang |
| Recommendation | Serving | database | ✓ | ✓ | docker, knative | golang |
| Reservation    | Serving | database, memcached | ✓ | ✓ | docker, knative | golang |
| User           | Serving | database | ✓ | ✓ | docker, knative | golang |
| Search         | Serving | Geo, Profile, Rate | ✓ | ✕ | docker, knative | golang |

## Online Shop
Function kernels from online shop example from google. Description of the benchmarks can be found in [vSwarm](https://github.com/ease-lab/vSwarm/tree/main/benchmarks/online-shop)

| Benchmark | Language | gem5 support |
|---|---|---|
| cartservice | C# | ✕  |
| productcatalogservice | Go | ✓ |
| currencyservice| Node.js  | ✓ |
| paymentservice | Node.js  |✓ |
| shippingservice | Go  | ✓ |
| emailservice | Python  | ✓ |
| checkoutservice | Go  | ✕ |
| recommendationservice | Python   | ✓ |
| adservice | Java | ✕ |
