# Matrix Multiply Unit (MM Unit) Module

## Description

The Matrix Multiply Unit (`hs_npu_mm_unit`) is designed to execute matrix multiplication operations efficiently as part of the ScaleNPU, leveraging a scalable systolic array structure. This module orchestrates data flow from input FIFOs to a systolic array, managing matrix inputs and controlling data propagation with gatekeepers to achieve a "diagonal delay," which enables proper timing and alignment of data across matrix rows and columns during computation.

The systolic array structure allows Matrix A (input data) to flow horizontally and Matrix B (weight data) to flow vertically through the array, with each multiplication and accumulation taking place synchronously at each node. The data comes from internal memory units implemented as a array of FIFOs and the results are re-organized by gatekeeper modules at the end of the systolic array.

!!! note

    For a deeper understanding of systolic architectures and how matrix multiplication is implemented in this design, see [this reference article](https://www.telesens.co/2018/07/30/systolic-architectures/). This is one of the most important and uselful sources the designers used to create the whole NPU!!

## Parameters

| Parameter Name        | Type | Default | Description                                                     |
|-----------------------|------|---------|-----------------------------------------------------------------|
| `SIZE`                | int  | 8       | Size of the systolic array (dimensions `SIZE x SIZE`).         |
| `INPUT_DATA_WIDTH`    | int  | 16      | Width of input data for Matrix A (int8).                        |
| `OUTPUT_DATA_WIDTH`   | int  | 32      | Width of output data (int32).                                   |
| `WEIGHT_DATA_WIDTH`   | int  | 16      | Width of weight data for Matrix B (int8).                       |
| `INPUT_FIFO_DEPTH`    | int  | 10      | Depth of input FIFOs.                                           |
| `WEIGHT_FIFO_DEPTH`   | int  | 8       | Depth of weight FIFOs (generally set equal to or greater than the systolic array size). |

By default 16 bit are is used to prevent overflow, yet all the weight and input data should be 8 bit.

## I/O Table

### Input Table

| Input Name           | Direction | Type                         | Description                                                       |
|----------------------|-----------|------------------------------|-------------------------------------------------------------------|
| `clk`                | Input     | `logic`                      | Clock signal for synchronization.                                 |
| `rst_n`              | Input     | `logic`                      | Reset signal, active-low.                                         |
| `flush_input_fifos`  | Input     | `logic`                      | Flush signal for input FIFOs.                                     |
| `flush_weight_fifos` | Input     | `logic`                      | Flush signal for weight FIFOs.                                    |
| `input_matrix_row`   | Input     | `logic[INPUT_DATA_WIDTH-1:0][SIZE]` | Row of the input matrix (Matrix A) for FIFO input.              |
| `input_fifo_valid_i` | Input     | `logic`                      | Valid signal for input FIFOs.                                     |
| `weight_matrix_row`  | Input     | `logic[WEIGHT_DATA_WIDTH-1:0][SIZE]` | Row of the weight matrix (Matrix B) for FIFO input.            |
| `weight_fifo_valid_i`| Input     | `logic`                      | Valid signal for weight FIFOs.                                    |
| `input_sums`         | Input     | `logic[OUTPUT_DATA_WIDTH-1:0][SIZE]` | Initial sum values for systolic array computation.              |
| `enable_weights`     | Input     | `logic`                      | Enable signal for weights input to the systolic array.            |
| `start_input_gatekeeper` | Input | `logic`                      | Start signal for the first input gatekeeper, cascading the start for others. |
| `start_output_gatekeeper` | Input | `logic`                     | Start signal for the first output gatekeeper, cascading the start for others. |
| `enable_cycles_in`   | Input     | `uword`                      | Number of cycles to enable gatekeepers for synchronized data flow. |

### Output Table

| Output Name          | Direction | Type                         | Description                                                       |
|----------------------|-----------|------------------------------|-------------------------------------------------------------------|
| `input_fifo_ready_o` | Output    | `logic[SIZE]`                | Ready signal array for input FIFOs.                               |
| `weight_fifo_ready_o`| Output    | `logic[SIZE]`                | Ready signal array for weight FIFOs.                              |
| `output_data`        | Output    | `logic[OUTPUT_DATA_WIDTH-1:0][SIZE]` | Computed output data from the systolic array.                |
| `valid_o`            | Output    | `logic[SIZE]`                | Valid signal array for output data availability.                  |

## Module Behavior and Data Flow

- **Input FIFOs and Gatekeepers:** Each element of Matrix A (input data) flows through an input FIFO and gatekeeper before reaching the systolic array. Gatekeepers create a "diagonal delay" effect, allowing data to arrive in staggered cycles, so that the systolic array aligns row and column inputs correctly for matrix multiplication.
  
- **Weight FIFOs:** Each element of Matrix B (weight data) flows directly from a FIFO into the systolic array. The weights propagate vertically through columns without delay.

- **Systolic Array Operation:** The systolic array performs multiply-accumulate operations on data as it propagates across rows (Matrix A) and down columns (Matrix B), computing partial sums at each node. The computed results are passed downwards and accumulated row by row until reaching the final row, where they are collected as the final output.

- **Output Gatekeepers:** Output data from the systolic array is passed through a series of gatekeepers, synchronizing results and controlling output timing. The first output gatekeeper initiates externally, while subsequent ones cascade signals.

## Submodule Diagram

The following diagram illustrates the MM Unit’s components and data flow paths, including input FIFOs, gatekeepers, and the systolic array’s integration.

{!diagrams/mm_unit.html!}

## Related Files

| File Name                                                                                                         | Type           |
|-------------------------------------------------------------------------------------------------------------------|----------------|
| [hs_npu_mm_unit](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_mm_unit.sv)               | Top Module     |
| [hs_npu_fifo](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_fifo.sv)                     | Submodule - FIFO       |
| [hs_npu_gatekeeper](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_gatekeeper.sv)         | Submodule - Gatekeeper |
| [hs_npu_systolic](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_systolic.sv)             | Submodule - Systolic Array |
| [Emulation](https://github.com/OpenCEHardware/ScaleNPU/blob/main/emulation/npu.cpp)             | C++ model emulating this block |

