# Memory Unit

## Description

The `hsv_core_mem` module is memory interface unit designed to handle memory transactions in the processor core. It interacts with memory through an AXI interface and manages both read and write requests with control over timing and sequencing to ensure correct execution and memory consistency. The unit is structured with multiple internal modules, each serving a specific role to facilitate the overall functionality and effiency of the memory unit.

### Module Overview

- **hsv_core_mem_address**:
    - This module is responsible for generating memory access requests. It processes incoming memory data and validates the requests based on the input signals. The `address_stage` module generates transactions for read and write operations and sends these transactions to the request and response pipelines.

- **Request and Response FIFOs**:
    - These FIFO modules are used to buffer transactions between the various stages of the memory interface. They help in managing data flow and preventing stalls in the pipeline by providing temporary storage for read and write requests (`request_fifo`) and responses (`response_fifo`). The FIFO depth is configurable via a parameter (`FIFO_DEPTH`), allowing tuning for different workloads and system requirements.

- **hsv_core_mem_request**:
    - This module handles the dispatch of memory requests to the AXI interface (`dmem`). It tracks pending read and write operations using internal counters (`pending_reads`, `pending_writes`, `write_balance`) to ensure proper ordering and management of transactions. This module ensures that reads and writes do not interfere with each other and that write operations are properly serialized when required. It also manages the stalling conditions for the AXI write and read channels.

- **hsv_core_mem_response**:
     - The `hsv_core_mem_response` module manages the reception of responses from the memory system. It processes read and write completions, updates the status counters (`pending_reads`, `pending_writes`, `write_balance`), and handles error conditions such as unaligned addresses or memory access faults. This module also prepares the data to be committed back to the processor core, ensuring that memory operations are completed in the correct order and without errors.

- **hsv_core_mem_counter (Pending Reads, Pending Writes, Write Balance Counters)**:
    - These counter modules track the number of outstanding read and write transactions as well as the balance of committed but unexecuted writes. The `pending_reads` counter increments for each read request and decrements upon completion, while `pending_writes` behaves similarly for write requests. The `write_balance` counter helps in managing write serialization by keeping track of writes that have been committed but not yet executed.

- **hs_skid_buffer (Commit Data Buffer)**:
     - This buffer module connects the output of the `response_stage` to the processor core's commit interface. It temporarily holds data until the core is ready to receive it, managing backpressure and ensuring smooth data transfer. The skid buffer prevents data loss in case of stalling conditions at the commit interface.

### Key Functionalities

- **Transaction Management**: The memory unit uses FIFOs and counters to manage the flow of memory transactions, ensuring that operations are executed in the correct order and that pipeline stalls are minimized.
- **Flush Control**: The memory unit can handle flush requests, which are used to clear pending transactions and reset the unit’s state. A flush can only proceed when all counters (`pending_reads`, `pending_writes`, `write_balance`) are zero, ensuring that no transactions are left in an incomplete state.
- **Stall and Backpressure Handling**: The unit is designed to handle backpressure from the memory system gracefully, using FIFOs to buffer transactions and controlling flow with stall signals.
- **Error Handling**: The `response_stage` module includes mechanisms for detecting and managing errors such as non existent or misaligned addresses.

## I/O Table

Detail the submodule's input and output signals, including their name, direction, type, and description.

### Input Table

| Input Name           | Direction | Type    | Description                    |
|----------------------|-----------|---------|--------------------------------|
| `input_signal_1`     | Input     | `logic` | Description of `input_signal_1`|
| `input_signal_2`     | Input     | `logic` | Description of `input_signal_2`|

### Output Table

| Output Name          | Direction | Type    | Description                    |
|----------------------|-----------|---------|--------------------------------|
| `output_signal_1`    | Output    | `logic` | Description of `output_signal_1`|
| `output_signal_2`    | Output    | `logic` | Description of `output_signal_2`|


## Submodule Diagram

{!diagrams/uarch-memory.drawio.html!}
