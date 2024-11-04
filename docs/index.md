# Home

Welcome to the documentation for **OpenCEHardware’s ScaleNPU** hardware module. This resource provides a comprehensive guide to understanding and working with the ScaleNPU block, detailing its current capabilities, configurations, and design specifications.

## Navigation

To help you get the most out of this documentation, we've organized it into the following sections:

<div class="grid cards" markdown>

- :fontawesome-solid-book: [Revisions](block/revisions.md): Documentation on previous versions and changes made.
- :fontawesome-solid-gavel: [Document Conventions](block/conventions.md): Definitions and abbreviations used in the document.
- :fontawesome-solid-lightbulb: [Introduction](block/introduction.md): General description of the ScaleNPU and its features.
- :fontawesome-solid-diagram-project: [Block Diagram](block/diagram.md): Visual representation of the ScaleNPU microarchitecture.
- :fontawesome-solid-gear: [Configuration](block/configuration.md): Information about parameters, typedefs, and RTL interfaces.
- :fontawesome-solid-network-wired: [Protocols](block/protocols.md): Details of communication and operation protocols.
- :fontawesome-solid-memory: [Memory Map](block/memory.md): Distribution of memory and resource allocation.
- :fontawesome-solid-clipboard-list: [Registers](block/registers.md): Description of the registers used in the system.
- :fontawesome-solid-clock: [Clock Domains](block/clocks.md): Information about clocks and their management in the system.
- :fontawesome-solid-wave-square: [Reset Domains](block/resets.md): Information about reset mechanisms and their domains.
- :fontawesome-solid-bell: [Interrupts](block/interrupts.md): Management and handling of interrupts in the system.
- :fontawesome-solid-flag: [Arbitration](block/arbitration.md): Arbitration mechanisms for access to shared resources.
- :fontawesome-solid-bug: [Debugging](block/debugging.md): Techniques and tools for system debugging.
- :fontawesome-solid-table: [Synthesis](block/synthesis.md): Summary and results of the design synthesis.
- :fontawesome-solid-table: [Verification](block/verification.md): Test environments, verification and testbenches applied to the system.
- :fontawesome-solid-info:[Microarquitecture Preamble](block/microarchitecture/preamble.md): Overview of the teorical principles, data flow, and design rationale behind the ScaleNPU’s microarchitecture.
- **Microarchitecture:**
    - :fontawesome-solid-cube: [MAC](block/microarchitecture/mac.md): Multiply-accumulate unit for core computational operations.
    - :fontawesome-solid-cube: [FIFO](block/microarchitecture/fifo.md): First-In-First-Out buffers for data handling and synchronization.
    - :fontawesome-solid-cube: [Gatekeeper](block/microarchitecture/gatekeeper.md): Access control and resource management.
    - :fontawesome-solid-cube: [Accumulator](block/microarchitecture/accumulator.md): Accumulation of computation results.
    - :fontawesome-solid-cube: [Activation](block/microarchitecture/activation.md): Activation function application for inference.
    - :fontawesome-solid-cube: [Systolic Array](block/microarchitecture/systolic.md): Systolic data flow for matrix operations.
    - :fontawesome-solid-cube: [Inference](block/microarchitecture/inference.md): Management of inference processes.
    - :fontawesome-solid-cube: [Memory Ordering](block/microarchitecture/memory_ordering.md): Ordering and management of memory requests.
    - :fontawesome-solid-cube: [Memory Interface](block/microarchitecture/memory_interface.md): Interface for accessing external memory resources.
    - :fontawesome-solid-cube: [Executive](block/microarchitecture/executive.md): Control and orchestration of the ScaleNPU’s operations.
    
</div>

## Acknowledgements

Please check the [References](block/references.md) section for more information.