# Accumulator Module

## Description

The Accumulator module (`hs_npu_accumulator`) performs an accumulation operation, adding a bias to each input data value and outputting the result. It accepts a bias value and enables accumulation based on a valid input signal. The accumulated result is output along with a signal indicating validity.

The `OUTPUT_DATA_WIDTH` parameter defines the width of the input and output data, allowing flexibility for various data formats.

## I/O Table

### Input Table

| Input Name     | Direction | Type                              | Description                                         |
|----------------|-----------|-----------------------------------|-----------------------------------------------------|
| `clk`          | Input     | `logic`                           | Clock signal for synchronization.                   |
| `rst_n`        | Input     | `logic`                           | Reset signal (active low) to initialize the module. |
| `input_data`   | Input     | `logic[OUTPUT_DATA_WIDTH-1:0]`    | Data to be accumulated with the bias value.         |
| `valid_i`      | Input     | `logic`                           | Valid signal indicating `input_data` is ready.      |
| `bias_in`      | Input     | `logic[OUTPUT_DATA_WIDTH-1:0]`    | Bias value to add to `input_data`.                  |
| `bias_en`      | Input     | `logic`                           | Enable signal for updating the stored bias.         |

### Output Table

| Output Name    | Direction | Type                              | Description                                         |
|----------------|-----------|-----------------------------------|-----------------------------------------------------|
| `result`       | Output    | `logic[OUTPUT_DATA_WIDTH-1:0]`    | Accumulated result after adding `input_data` and the stored bias. |
| `valid_o`      | Output    | `logic`                           | Signal indicating the result is valid.              |

## Module Behavior and Data Flow

- **Bias Handling**: The accumulator holds a bias value, which can be updated whenever the `bias_en` signal is asserted. When `bias_en` is active, the bias is set to the value on `bias_in`; otherwise, it retains its previous value.
  
- **Accumulation Process**: When `valid_i` is asserted, the module adds the stored bias to the incoming `input_data` and outputs the result through `result`, with `valid_o` set high to indicate a valid output. If `valid_i` is deasserted, `result` outputs zero and `valid_o` is low, indicating no valid accumulation result.

## Diagram

The diagram is trivial.

The bias value is floped, only registered when `bias_en` is set.


When `valid_i` is set: 

```systemverilog
    result  = input_data + bias;
    valid_o = 1;
```

Else:


```systemverilog
    result  = 0;
    valid_o = 0;
```

## Related Files

| File Name                                                                                                         | Type           |
|-------------------------------------------------------------------------------------------------------------------|----------------|
| [hs_npu_accumulator](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_accumulator.sv)       | Top Module     |