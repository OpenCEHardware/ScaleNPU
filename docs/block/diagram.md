# Top-Level Block Diagram

This diagram provides a simplified view (in terms of signals) of the top-level `.sv` file of the system. 

{!diagrams/XPU-Top-lvl.html!}

!!!note 

    All blocks share common clock and reset signals, which are omitted in the diagram to improve visual clarity.

### 1. **Control-Status Registers (CSR)**
   - **Function**: Interfaces with the **CPU** to configure and control the NPU's operations. The CPU uses these registers to send control signals, such as initializing tasks, specifying memory addresses, and setting matrix dimensions. The CSR block also triggers interrupts (IRQ) back to the CPU to signal task completion.
   - **Interface**: Communicates with the CPU via **AXI4 Lite** (control signals) and sends **IRQ** signals to notify task completions.

### 2. **Executive**
   - **Function**: Acts as the central controller for the NPU, interpreting commands received from the **Control-Status Registers** and coordinating tasks across the NPU blocks. It issues control signals to manage data movement and computation.
   - **Communication**: Receives hardware control signals from the **Control-Status Registers** and sends control signals to the **Memory Ordering** block.

### 3. **Memory Ordering**
   - **Function**: Manages memory requests and organizes the sequence of operations, ensuring correct order in memory access. It coordinates the loading of input data and weights and the storing of output data, managing communication between the **Memory Interface** and the **Inference** block. And the exection timings of the inference block.
   - **Communication**: Exchanges **control** signals with the **Executive**, manages data flow from the **Memory Interface**, and directs output data to the **Inference** block.

### 4. **Memory Interface**
   - **Function**: Transfers data between external memory (RAM) and the NPU, using the **AXI4 Burst** protocol to retrieve inputs (such as matrices and weights) and store output data.
   - **Communication**: Connects to **RAM** using the **AXI4 Burst** protocol for high-speed data access and exchanges control and data signals with the **Memory Ordering** block.

### 5. **Inference Block**
   - **Function**: The computational core of the NPU, performing matrix operations like multiplication and accumulation. It processes data loaded from memory (inputs, weights, bias, etc.) to produce the final inference results.
   - **Communication**: Receives **data** and **control** signals from the **Memory Ordering** block and outputs results after completing computations.

### 6. **RAM**
   - **Function**: External memory that stores data such as matrices, weights, and (if required) intermediate results. The **Memory Interface** retrieves and writes data to RAM during NPU operations.

### 7. **CPU**
   - **Function**: The host processor that configures and controls the NPU. It sets up tasks through the **Control-Status Registers** and responds to **IRQ** signals from the NPU to manage overall system operation.

## Microarchitecture Diagram

This diagram offers a closer, yet more abstract, view of the NPU. While it doesn’t map 1:1 to specific `.sv` files or individual hardware blocks, it represents a high-level simplification of the NPU architecture, highlighting key components and their interactions.

{!diagrams/XPU-Uarch.html!}
