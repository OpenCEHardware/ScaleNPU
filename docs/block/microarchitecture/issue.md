# Issue Unit

## Description

The `hsv_core_issue` module represents the stage in the processor pipeline where instructions are prepared and distributed one of the various execution units. It acts as a bridge between the instruction fetch and decode stages and the execution and memory stage, ensuring that instructions are correctly scheduled, hazards are managed, and data dependencies are resolved before sending instructions to the appropriate execution units. Below is an explanation of the pipeline stages within the `hsv_core_issue` module, including their functions, roles, and design considerations:

### Module Overview

- **Hazard Mask Generation Stage:**
    - This stage identifies potential hazards by examining the register usage of the incoming instruction. It generates a hazard mask that marks registers currently in use by ongoing instructions, preventing conflicts and incorrect data usage.
    - It checks for read-after-write (RAW) hazards by comparing the registers being read in the current instruction with those being written by in-flight instructions.
    - The output of this stage is a register mask (`rd_mask`) and a valid signal (`valid_o`).

- **Fork Stage:**
    - The fork stage enroutes instruction data to the appropriate execution unit (ALU, branch, control-status, and memory) based on the instruction type.
    - It manages stalls across different units by selectively stalling data flow to prevent overflow or resource conflicts. Each execution unit can independently stall if it is not ready to accept new data.
    - This stage must manage the timing and synchronization of data between multiple execution units, accounting for variations in ready signals and stalls from each unit.

- **Buffering Stage (Skid Buffers):**
    - The buffering stage uses skid buffers to temporarily hold data for each execution unit (ALU, branch, control-status, and memory). This buffering smooths out the flow of data and allows the system to handle back-pressure when units are not ready to receive data immediately.
    - The skid buffers manage ready and valid signals between the fork stage and execution units, allowing each unit to consume data at its own pace without stalling the entire issue pipeline.


### Design Features and Considerations

- **Stall Management:** The issue pipeline uses a combination of stall signals (`alu_stall`, `branch_stall`, `ctrl_status_stall`, `mem_stall`) to control the flow of data through the pipeline. The overall pipeline stall (`stall`) is determined by aggregating the stalls from individual units.
- **Flush Handling:** The pipeline includes flush logic to clear in-flight instructions when incorrect paths are detected or when a pipeline reset is necessary. The `flush_req` and `flush_ack` signals coordinate this action.
- **Data Path Management:** Registers and data paths are managed to ensure that the correct data is available to each execution unit when needed. This includes handling special cases such as register x0 (always zero).

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
