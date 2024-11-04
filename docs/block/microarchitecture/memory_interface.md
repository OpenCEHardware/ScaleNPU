# Memory Interface Unit

## Description

The `hs_npu_memory_interface` module is designed to handle the AXI4 Burst transactions between the NPU's `hs_npu_memory_ordering` control module and the system memory. Acting as an intermediary, it translates read and write requests from the memory ordering module into AXI-compatible burst operations, enabling data transfers. This module is structured as a state machine, using the AXI protocol to facilitate reliable data flow in compliance with the timing and control requirements. Serving as a slave to the memory ordering module and as a master on the AXI interface, it manages data transfers to and from the NPU.

### Overview and Responsibilities

1. **AXI Protocol Compliance**:
    - The `hs_npu_memory_interface` observes the AXI protocol's handshaking and burst requirements, ensuring correct signal sequences during read and write operations. It aligns its burst sizes (`BURST_SIZE`) and lengths (`BURST_LEN`) with memory ordering specifications for each transfer.

2. **State Machine Operation**:
    - This module cycles through states—`IDLE`, `READ`, `READ_WAIT`, and `WRITE`—to control read and write processes. Each state is configured for a specific function, including waiting for AXI readiness signals, initiating data transfers, and managing burst counters.

3. **Data Tracking and Control**:
    - During write operations, the module tracks progress with internal signals (`clear_done`, `aw_done`, and `w_done`). For read operations, it maintains data availability and outputs `mem_valid_o` once data is ready, signaling to the memory ordering module that memory contents are valid.

4. **Internal Data Buffers and Tracking**:
    - The module uses internal buffers to hold burst data, including `memory_data_in_ff` for incoming memory data and `memory_data_out` for outgoing data. Burst counters track the current position within each transfer, while write control signals (`axi.awvalid`, `axi.wvalid`, `axi.wlast`) handle the finalization of AXI transactions.

### State Descriptions

- **IDLE**: 
    - Awaits instructions from the memory ordering unit. If `mem_read_ready_i` is asserted, the state transitions to `READ`. For write operations (`mem_write_valid_i`), it moves to `WRITE`. If `mem_invalidate` is asserted, any ongoing read is canceled.

- **READ**:
    - Initiates an AXI read burst from the address specified in `request_address`. If the request is invalidated, it returns to `IDLE`. Otherwise, once the AXI read address is accepted (`axi.arready`), it transitions to `READ_WAIT`.

- **READ_WAIT**:
    - Manages data retrieval from the AXI bus. As each data beat is received, it updates `memory_data_out` for use by the memory ordering module. When the burst read completes (signaled by `axi.rlast`), it returns to `IDLE` with `mem_valid_o` asserted to indicate data validity.

- **WRITE**:
    - Initiates an AXI write burst to the address in `request_address`, setting `axi.awaddr` and `axi.wdata` for each data word. The module continues writing until the final transfer (`axi.wlast`). After completion, it resets the state to `IDLE` for the next transfer.

### Control Signal Assignments

- **mem_valid_o**: Indicates when data is valid for the memory ordering module post-read.
- **mem_ready_o**: Signals readiness to accept new requests when in `IDLE`.
- **axi.arvalid, axi.awvalid, axi.wvalid**: Control signals for AXI read and write initiation.
- **axi.wlast**: Signals the last data transfer in a write burst.
- **burst_counter and burst_counter_ff**: Track the current position within each burst transfer.

### Data Buffers and Burst Handling

- `memory_data_in` and `memory_data_out` are used to store data to/from memory. Burst counters manage the progression of data transfers within each burst, with `STRB` defining the byte lanes to be written during each AXI cycle.

## I/O Table

### Input Signals

| Input Name           | Direction | Type                     | Description                                                                 |
|----------------------|-----------|--------------------------|-----------------------------------------------------------------------------|
| `clk`                | Input     | `logic`                  | Clock signal for synchronous logic in the module.                           |
| `rst_n`              | Input     | `logic`                  | Active-low reset signal for initializing the module’s internal state.       |
| `mem_read_ready_i`   | Input     | `logic`                  | Indicates that the memory ordering module is ready to read data.            |
| `mem_write_valid_i`  | Input     | `logic`                  | Indicates a write request from the memory ordering module.                  |
| `mem_invalidate`     | Input     | `logic`                  | Signal to cancel any ongoing read operation.                                |
| `memory_data_in`     | Input     | `logic [BURST_SIZE-1:0]` | Data from the memory ordering module for write operations.                  |
| `request_address`    | Input     | `logic [ADDR_WIDTH-1:0]` | Address from the memory ordering module to initiate a memory read or write. |

### Output Signals

| Output Name          | Direction | Type                     | Description                                                                         |
|----------------------|-----------|--------------------------|-------------------------------------------------------------------------------------|
| `mem_valid_o`        | Output    | `logic`                  | Indicates that the data in `memory_data_out` is valid for reading.                  |
| `mem_ready_o`        | Output    | `logic`                  | Indicates that the memory interface is ready to accept a new read or write request. |
| `memory_data_out`    | Output    | `logic [BURST_SIZE-1:0]` | Data read from memory, sent to the memory ordering module.                          |

### AXI4 Interface Signals

| AXI Signal           | Direction | Type                       | Description                                                      |
|----------------------|-----------|----------------------------|------------------------------------------------------------------|
| `axi.arid`           | Output    | `logic [ID_WIDTH-1:0]`     | Read transaction ID. Set to 0.                                   |
| `axi.awid`           | Output    | `logic [ID_WIDTH-1:0]`     | Write transaction ID. Set to 0.                                  |
| `axi.araddr`         | Output    | `logic [ADDR_WIDTH-1:0]`   | Read address for the transaction.                                |
| `axi.awaddr`         | Output    | `logic [ADDR_WIDTH-1:0]`   | Write address for the transaction.                               |
| `axi.arburst`        | Output    | `logic [1:0]`              | Burst type for reads; set to `INCR` (incrementing burst).        |
| `axi.awburst`        | Output    | `logic [1:0]`              | Burst type for writes; set to `INCR` (incrementing burst).       |
| `axi.arsize`         | Output    | `logic [BURST_SIZE-1:0]`   | Data transfer size for reads.                                    |
| `axi.awsize`         | Output    | `logic [BURST_SIZE-1:0]`   | Data transfer size for writes.                                   |
| `axi.arlen`          | Output    | `logic [BURST_LEN-1:0]`    | Number of data transfers per burst for reads.                    |
| `axi.awlen`          | Output    | `logic [BURST_LEN-1:0]`    | Number of data transfers per burst for writes.                   |
| `axi.arvalid`        | Output    | `logic`                    | Indicates that the read address and control signals are valid.   |
| `axi.awvalid`        | Output    | `logic`                    | Indicates that the write address and control signals are valid.  |
| `axi.wdata`          | Output    | `logic [DATA_WIDTH-1:0]`   | Write data for the memory interface.                             |
| `axi.wstrb`          | Output    | `logic [DATA_WIDTH/8-1:0]` | Write strobe to indicate valid bytes in write data.              |
| `axi.wvalid`         | Output    | `logic`                    | Indicates that write data is valid.                              |
| `axi.bready`         | Output    | `logic`                    | Signal to acknowledge completion of write transactions.          |
| `axi.rready`         | Output    | `logic`                    | Signal to acknowledge receipt of read data from memory.          |
| `axi.rdata`          | Input     | `logic [DATA_WIDTH-1:0]`   | Read data returned from the memory interface.                    |
| `axi.rid`            | Input     | `logic [ID_WIDTH-1:0]`     | ID tag for the read transaction.                                 |
| `axi.rresp`          | Input     | `logic [1:0]`              | Read response code indicating the result of the transaction.     |
| `axi.rvalid`         | Input     | `logic`                    | Indicates that the read data and response are valid.             |
| `axi.bresp`          | Input     | `logic [1:0]`              | Write response code indicating the result of the transaction     |
| `axi.bid`            | Input     | `logic [ID_WIDTH-1:0]`     | ID tag for the write transaction response.                       |
| `axi.bvalid`         | Input     | `logic`                    | Indicates that the write response is valid.                      |


## State machine diagram

{!diagrams/memory_interface.html!}

## Related Files

| File Name                                                                                                             | Type           |
|-----------------------------------------------------------------------------------------------------------------------|----------------|
| [hs_npu_memory_interface](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_memory_interface.sv) |Top module      |

## Additional Comments

This module's biggest complication is the correct usage of the AXI4 protocol, specially when taking into account that simulation and on-device behaviours can differ. If this module is edited make sure to maintain compliance with said protocol. 

