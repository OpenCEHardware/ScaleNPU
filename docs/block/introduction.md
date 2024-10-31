# Introduction

The **ScaleNPU** is an AI accelerator designed to efficiently handle simple matrix multiplication operations for neural network inference. It is architected for integration in heterogeneous CPU+accelerator systems, providing a dedicated block for accelerating machine learning tasks. The design is modular, scalable, and configurable, focusing on optimizing system resources and performance.

## Blackbox Top-level Diagram

![blackbox-npu_l](../diagrams/blackbox_npu_l.png#only-light)  
![blackbox-npu_d](../diagrams/blackbox_npu_d.png#only-dark)

## Goals and Non-Goals

### Goals
- Efficiently accelerate matrix operations, primarily for neural network inference.
- Seamlessly integrate with CPU-based systems on FPGA platforms.
- Optimize resource usage in FPGA environments, minimizing memory consumption while maximizing throughput.

### Non-Goals
- ScaleNPU is **not** designed for floating-point operations or general-purpose computing.
- It is **not** intended to replace the CPU, but rather to complement it in specific AI-related tasks.

## Features

The main function of the ScaleNPU block is to efficiently perform neural network (NN) inference. Key capabilities include:

- **Matrix multiplication**: Support for matrix multiplication of any size.
- **Bias accumulation**: Support for adding bias vectors at the layer level.
- **Non-linear activation function**: Support for ReLU (Rectified Linear Unit) activation.
- **Re-quantization during inference**: Support for symmetric power-of-two quantization of results.

## Debugging Features

The ScaleNPU includes several features to aid in debugging:

- **Status registers**: Provide visibility into the internal state of the NPU for monitoring.
- **Testbench support**: A verification environment using cocotb and other simulation tools to ensure functional correctness.

## Integration and System Context

ScaleNPU is designed to be integrated into larger heterogeneous computing systems, particularly within the H-SCALE framework, which combines a RISC-V CPU with AI accelerators for educational purposes. It communicates with the CPU and memory systems using standard protocols like AXI, and uses DMA for efficient data transfers during matrix operations. The unit is controlled via configuration registers (CSRs), allowing the CPU to manage operations and initiate tasks.

### Standard Protocols

The ScaleNPU uses the following standard communication protocols:
- **AXI Protocol**: AXI4 Burst for high-speed memory access and AXI4-Lite for control signal exchanges between the accelerator and the system.
- **CSR (Control and Status Registers)**: Provides configuration and control mechanisms for interfacing with the host CPU.
- **IRQ Line**: Provides an interrupt request output line for CPU or peripheral IRQs.

!!! note

    Performance is highly dependent on the actual parameters of the implementation and the characteristics of the FPGA. Memory speed, register availability, and clock speeds will impact the overall performance of the block.
