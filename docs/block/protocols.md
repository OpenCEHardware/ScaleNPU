# Protocols

This section outlines the protocols used by the ScaleNPU for inter-module communication and interaction with external components. Both standard protocols are described to ensure clarity in data transfer and control sequences across the NPU. Standard protocols are linked to their specifications.

## Standard Protocols

### AXI4 Burst Protocol

- **Description**: The AXI4 (Advanced eXtensible Interface 4) Burst protocol is used for  memory access, allowing data to be transferred in bursts to optimize bandwidth. In the ScaleNPU, AXI4 Burst is used by the **Memory Interface** to interact with **RAM** for loading input data and storing output results.
- **Specification**: [AXI4 Burst Protocol Specification](https://developer.arm.com/documentation/ihi0022/g)

### AXI4-Lite Protocol

- **Description**: AXI4-Lite is a lightweight version of the AXI4 protocol, intended for simpler control and configuration transactions with low bandwidth requirements. The ScaleNPU uses AXI4-Lite for communication between the **Control-Status Registers (CSR)** and the **CPU**, allowing the CPU to configure the NPU’s operation and retrieve status information.
- **Specification**: [AXI4-Lite Protocol Specification](https://developer.arm.com/documentation/ihi0022/g)

### Ready-Valid Protocol

- **Description**: Internally, ScaleNPU loosely follows a **Ready-Valid** protocol for handshaking between modules. This protocol is widely used across the NPU’s modules to coordinate the exchange of data and control signals. Most modules have a `ready` and `valid` signals, though they are not always used. This is due manly because of the predictable behavoir of the unit, allowing for logic simplifications and cycle efficiency. 

!!! note

    Here are some great videos to undertand this protocols: [AXI tutorial](https://www.youtube.com/watch?v=1zw1HBsjDH8&list=PLkqJVNOiuuHtNrVaNK4O1BSgczja4obeW)
