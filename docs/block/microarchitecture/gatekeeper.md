# Gatekeeper Module

## Description

The Gatekeeper module (`hs_npu_gatekeeper`) in the ScaleNPU serves as a control sub-unit that regulates data flow to and from the NPU's computational units, ensuring synchronization based on specified enable cycles. It manages data forwarding based on a configurable number of cycles (`enable_cycles_in`) during which it remains active. The Gatekeeper operates by receiving input data (`input_data`) and either passes this data through to the next stage (`output_data`) or discards it (sets `output_data` to 0), depending on its active state.

The `start_in` signal (which should only last one cycle) triggers the gatekeeper to initiate the enable cycle countdown. When active, the `output_data` mirrors the `input_data`. The `start_out` signal propagates the start signal to subsequent gatekeepers (with a one cycle delay), enabling a chain of controlled data handoffs across processing units.

Key functionality includes the `active` signal, which behaves like a ready or valid flag and indicates when data can be processed by/from the module.

The `DATA_WIDTH` parameter defines the bit width of both input and output data, making the Gatekeeper adaptable to a range of data sizes, from small (e.g., 8-bit) to larger values (e.g., 32-bit).

The Gatekeeper module is implemented as an array to form the "sequencer" blocks shown in the ScaleNPU diagram. The Gatekeeper was specifically designed to achieve the "diagonal delay" in the inputs of the systolic array and to manage its corresponding "diagonal" output. This functionality will be discussed in more detail in later sections.

## I/O Table

### Input Table

| Input Name         | Direction | Type                        | Description                                                   |
|--------------------|-----------|-----------------------------|---------------------------------------------------------------|
| `clk`              | Input     | `logic`                     | Clock signal for synchronization.                             |
| `rst_n`            | Input     | `logic`                     | Active-low reset signal to initialize Gatekeeper state.       |
| `input_data`       | Input     | `logic [DATA_WIDTH-1:0]`    | Data input to be controlled by the Gatekeeper.                |
| `enable_cycles_in` | Input     | `uword`                     | Number of cycles for which the Gatekeeper remains active.     |
| `start_in`         | Input     | `logic`                     | Start signal to initiate the Gatekeeper enable cycles.        |

### Output Table

| Output Name       | Direction | Type                        | Description                                                   |
|-------------------|-----------|-----------------------------|---------------------------------------------------------------|
| `output_data`     | Output    | `logic [DATA_WIDTH-1:0]`    | Data output to be passed to the next module.                  |
| `start_out`       | Output    | `logic`                     | Propagates the start signal to subsequent Gatekeepers.        |
| `active`          | Output    | `logic`                     | Indicates if the Gatekeeper is active and ready to output data.|

## Submodule Diagram

The following diagram illustrates the Gatekeeper module, its inputs, outputs, and internal signal paths.

{!diagrams/gatekeeper.html!}

## Related Files

| File Name                     | Type       |
|-------------------------------|------------|
| [hs_npu_gatekeeper](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_gatekeeper.sv) | Top        |