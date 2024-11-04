# Inference Module

## Description

The **Inference Module** (`hs_npu_inference`) is the computational core of the ScaleNPU, integrating all primary submodules (matrix multiplication, accumulation, activation, and output buffering) to perform matrix-based neural network inference. This module manages data flow between subunits to achieve matrix multiplication, bias addition, activation, quantization, and buffering of results. Only control and interface modules are external to this computation section.

## Features

- **Modular Subunits**: Combines matrix multiplication, accumulation, activation (with quantization), and output FIFOs.
- **Activation Flexibility**: Support for multiple activation functions, with ReLU currently implemented.
- **Configurable Data Precision**: Supports distinct data widths and customizable quantization through a shift operation.
  
## I/O Table

### Input Table

| Input Name             | Direction | Type                                | Description                                                                                       |
|------------------------|-----------|-------------------------------------|---------------------------------------------------------------------------------------------------|
| `clk`                  | Input     | `logic`                             | Clock signal for synchronization.                                                                 |
| `rst_n`                | Input     | `logic`                             | Active-low reset signal.                                                                          |
| `flush_input_fifos`    | Input     | `logic`                             | Signal to flush the input FIFOs.                                                                  |
| `flush_weight_fifos`   | Input     | `logic`                             | Signal to flush the weight FIFOs.                                                                 |
| `flush_output_fifos`   | Input     | `logic`                             | Signal to flush the output FIFOs.                                                                 |
| `input_matrix_row`     | Input     | `logic[INPUT_DATA_WIDTH-1:0][SIZE]` | Row of input data matrix for each row in the systolic array.                                      |
| `input_fifo_valid_i`   | Input     | `logic`                             | Signal indicating valid data is present in `input_matrix_row`.                                    |
| `input_sums`           | Input     | `logic[OUTPUT_DATA_WIDTH-1:0][SIZE]`| Initial sums for each row in the matrix multiplication unit.                                      |
| `weight_matrix_row`    | Input     | `logic[WEIGHT_DATA_WIDTH-1:0][SIZE]`| Row of weight data matrix for each row in the systolic array.                                     |
| `weight_fifo_valid_i`  | Input     | `logic`                             | Signal indicating valid data is present in `weight_matrix_row`.                                   |
| `enable_weights`       | Input     | `logic`                             | Enable signal to load weights in the matrix multiplication unit.                                  |
| `start_input_gatekeeper` | Input  | `logic`                             | Start signal for the input gatekeeper.                                                            |
| `start_output_gatekeeper` | Input | `logic`                             | Start signal for the output gatekeeper.                                                           |
| `enable_cycles_in`     | Input     | `uword`                             | Cycles for enabling the matrix multiplication unit gatekeepers.                                               |
| `bias_values`          | Input     | `logic[OUTPUT_DATA_WIDTH-1:0][SIZE]`| Bias values for each accumulator in the array.                                                    |
| `bias_en`              | Input     | `logic`                             | Enable signal for loading bias values in accumulators.                                            |
| `shift_amount`         | Input     | `uword`                             | Shift amount for quantization in activation.                                                      |
| `relu_enable`          | Input     | `logic`                             | Enable signal for applying ReLU activation.                                                       |
| `output_fifo_ready_i`  | Input     | `logic`                             | Ready signal from the output FIFO gatekeeper.                                                     |
| `output_fifo_reread`   | Input     | `logic`                             | Signal to reread from output FIFOs.                                                               |

### Output Table

| Output Name           | Direction | Type                                   | Description                                                              |
|-----------------------|-----------|----------------------------------------|--------------------------------------------------------------------------|
| `input_fifo_ready_o`  | Output    | `logic[SIZE]`                          | Ready signal for each input FIFO row.                                    |
| `weight_fifo_ready_o` | Output    | `logic[SIZE]`                          | Ready signal for each weight FIFO row.                                   |
| `inference_result`    | Output    | `logic[ACTIVATION_OUTPUT_WIDTH-1:0][SIZE]` | Final inference results after activation and quantization for each row.   |
| `output_fifo_valid_o` | Output    | `logic[SIZE]`                          | Valid signal for each output FIFO row.                                   |

## Module Behavior and Data Flow

The inference module performs inference by coordinating data flow between its subunits, from input processing to final output generation:

1. **Matrix Multiplication**: Input and weight data are fed to the matrix multiplication unit (MMU), which computes the partial sums and forwards the results to each accumulator.

2. **Accumulation**: Each accumulator adds a bias value to the output from the MMU, enabling fine-tuning of the final result.

3. **Activation & Quantization**: The activation unit applies the ReLU function and performs quantization by shifting the accumulated results. The final data is truncated to `ACTIVATION_OUTPUT_WIDTH` bits, yielding the processed inference results.

4. **Output Buffering**: The processed data is stored in output FIFOs, which manage the data flow to external modules based on the `output_fifo_ready_i` signal.


## Diagram

The following diagram illustrates the inference module, its inputs, outputs, and internal signal paths.

{!diagrams/inference.html!}

## Related Files

| File Name                                                                                                         | Type           |
|-------------------------------------------------------------------------------------------------------------------|----------------|
| [hs_npu_inference](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_inference.sv)           | Top Module     |
| [hs_npu_mm_unit](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_mm_unit.sv)               | Submodule - Matrix Multiplication Unit |
| [hs_npu_accumulator](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_accumulator.sv)       | Submodule - Accumulator    |
| [hs_npu_activation](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_activation.sv)         | Submodule - Activation and Quantization |