# Activation Module

## Description

The **Activation Module** (`hs_npu_activation`) processes data by applying an activation function (currently ReLU) and performs quantization through a configurable right shift operation. This module allows for flexible activation functions, with ReLU being implemented as a basic function. Quantization is achieved by truncating the shifted output data to the desired width, specified by the `OUTPUT_WIDTH` parameter. 


!!! note 
    
    Future support for additional activation functions can be easily integrated using look-up tables, which allow efficient management and implementation of multiple activation methods.

## I/O Table

### Input Table

| Input Name      | Direction | Type                              | Description                                                                 |
|-----------------|-----------|-----------------------------------|-----------------------------------------------------------------------------|
| `input_data`    | Input     | `logic[DATA_WIDTH-1:0]`          | Data to be processed by the activation function.                           |
| `valid_i`       | Input     | `logic`                           | Signal indicating the input data is valid.                                  |
| `relu_en`       | Input     | `logic`                           | Enable signal for applying ReLU activation; if low, data passes unmodified. |
| `shift_amount`  | Input     | `logic[DATA_WIDTH-1:0]`           | Shift value to control the level of quantization in the output.             |

### Output Table

| Output Name     | Direction | Type                              | Description                                                                 |
|-----------------|-----------|-----------------------------------|-----------------------------------------------------------------------------|
| `result`        | Output    | `logic[OUTPUT_WIDTH-1:0]`        | Quantized output after activation and shift, truncated to `OUTPUT_WIDTH` bits. |
| `valid_o`       | Output    | `logic`                           | Valid signal indicating the output is ready.                                |

## Module Behavior and Data Flow

1. **ReLU Activation**: When `relu_en` is high, the ReLU function is applied to `input_data`. The module outputs the maximum of `input_data` and 0, effectively setting negative values to zero. If `relu_en` is low, the module bypasses ReLU and passes `input_data` directly to the next step.

2. **Quantization via Right Shift**: The processed data then undergoes an arithmetic right shift by the value specified in `shift_amount`. This step performs quantization, reducing the precision of the data to fit within `OUTPUT_WIDTH` bits.

3. **Truncation to Output Width**: After shifting, the result is truncated to `OUTPUT_WIDTH` bits, producing the quantized output in `result`. The `valid_o` signal indicates that the result is ready.

### Example: ReLU and Shift Logic

If `valid_i` is asserted:

- When `relu_en` is high:
    - `relu_result` = max(`input_data`, 0)
  
- If `relu_en` is low:
    - `relu_result` = `input_data`

- **Shift**: The `relu_result` is then right-shifted by `shift_amount`.
- **Output**: The shifted data is truncated to `OUTPUT_WIDTH` bits and assigned to `result`, with `valid_o` set high.


## Diagram 

The diagram is trivial.

## Related Files

| File Name                                                                                                        | Type       |
|------------------------------------------------------------------------------------------------------------------|------------|
| [hs_npu_activation](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_activation.sv)        | Top Module |