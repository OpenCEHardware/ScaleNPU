# Branching Unit

## Description

The `hsv_core_branch` module is within the core designed to handle branch operations. It determines the flow of program execution by evaluating branch conditions, computing branch targets, and managing jumps, including conditional and unconditional branches. This module interfaces with other parts of the processor pipeline, receiving branch-related inputs, processing them, and outputting results that guide the execution path of the processor. This unit also determines whether a prediction is correct or not, and sets the flush signal if mispredicted.

!!! note

    This core doesn't actually predict branches, it always assumes the PC+4 as the next instruction. This means a uncoditional branch will always be mispredicted. Despite of this, our branching unit is capable of handling predictions with the `predicted` input pointer. 

#### Functionality
The module operates in multiple substages to handle the branch processing:

- **Branch Condition and Target Calculation (`hsv_core_branch_cond_target`)**:
    - This submodule evaluates the conditions for conditional branches, such as equality or less-than comparisons between source operands (`rs1` and `rs2`).
    - It determines whether the branch should be taken based on the condition codes and potential negations.
    - If the branch is taken, it calculates the target address, which is the destination of the branch. This target address can be relative to the current program counter (`pc`) or an absolute value depending on the type of branch.

- **Branch Jump Execution (`hsv_core_branch_jump`)**:
    - The jump submodule uses the results from the conditional target stage to decide the final program counter (`pc`) value. If the branch is taken, it uses the target address; otherwise, it defaults to the next sequential address.
    - It also checks for potential mispredictions by comparing the computed target address to the predicted address, allowing the processor to correct its path if necessary.
    - An alignment check ensures that the branch target aligns with the processor's word boundaries, raising execution exceptions (traps) if a misaligned address is detected.

- **Output Buffering (`hs_skid_buffer`)**:
    - The results from the branch jump stage are passed through a buffering pipeline that manages flow control signals (`ready` and `valid`). This pipeline ensures that the output data is appropriately synchronized with the processor's broader execution pipeline, accommodating stalls and flush requests.

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

{!diagrams/uarch-branch.drawio.html!}


