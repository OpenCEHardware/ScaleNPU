# Commit Unit

## Description

The `hsv_core_commit` module is responsible for handling the final commit stage in the CPUs processing pipeline, where results of executed operations are finalized and made visible to the rest of the system. It primary works on handling the results from the multiple parallel execution units (ALU, branch, memory, control-status, and the custom blank unit `foo`). 

### Function and Role
The main function of the `hsv_core_commit` module is to receive the results from the various execution units and decide whether these results should be committed to the architectural state of the processor (e.g., registers, memory). This module also handles control signals related to traps (exceptions), interrupts, and pipeline flushes.

**Key Features:**
- **Commit Decisions:** The module evaluates if each execution unit's data is ready and valid, and then checks for any traps (errors or exceptions) associated with the data. If the data is valid and free of traps, the module generates commit signals for each respective execution unit.

!!! note

    At the moment the core does not use this commit signals on their own apart from `mem_commit_o`, the other output signals where added for symmetry and future uses, if necesarry.

- **Token Mechanism:** A token-based system is employed to synchronize the commit stage with the execution units. Tokens help ensure that data from the execution units is processed in the correct order.

- **Writeback Control:** This module generates signals for writing back data to the register file, including the register address, the data to be written, and whether the write should occur. 

- **Trap Handling:** It manages trap signals, which occur when there are exceptions or errors in the execution units, and generates appropriate control signals such as `ctrl_trap`, `ctrl_trap_cause`, and `ctrl_trap_value`. It also manages the next program counter (`ctrl_next_pc`) when a trap or jump occurs.

- **Commit Mask:** A commit mask is generated for tracking which registers are affected by the commit process, ensuring issue can clear out any RAW stalls once the instruction has been commited.

#### Design Considerations
- **Synchronization with Execution Units:** Each execution unit provides a valid signal (`alu_valid_i`, `branch_valid_i`, etc.) and a ready signal from the commit stage (`alu_ready_o`, `branch_ready_o`, etc.). The synchronization is handled via a token mechanism that matches tokens from the execution units to the commit stage, ensuring correct data flow.
  
- **Trap and Exception Management:** The module handles traps by blocking the commit process for data with associated traps, thus preventing erroneous state updates.

- **Performance and Scalability:** The use of parallel commit lines and token management helps maintain high performance by enabling parallel processing of results from multiple execution units.

- **Flush Mechanism:** The `flush_req` and `flush_ack` signals allow the module to control when to reset the pipeline.

- **Control Signals:** The module manages several critical control signals that dictate the overall flow of execution and responses to exceptional events within the core, like interrupts or pipeline flushes.

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

Include a diagram of the submodule here, showing its inputs, outputs, and how they are connected internally. Ensure the diagram is clear and properly labeled to facilitate understanding.

{!diagrams/sub1.html!}
