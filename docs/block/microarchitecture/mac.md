# MAC Module

## Description

The `hs_npu_mac` (Multiply-Accumulate) module in the ScaleNPU serves as the fundamental computational block for performing multiply-accumulate (MAC) operations, crucial for a wide variety of neural processing tasks. The module is designed to take in two values, perform element-wise multiplication, and accumulate the result into a running sum, providing the basis for complex computations, such as matrix multiplications. 

Each instance of `hs_npu_mac` operates independently, supporting parallel processing and enabling high-throughput computation across multiple elements. For applications like matrix multiplication, the inputs `a_in` and `b_in` can represent values from two matrices. The module multiplies these inputs, adds the result to an incoming `sum`, and outputs the result while forwarding the input values for further processing.

## I/O Table

### Input Table

| Input Name | Direction | Type          | Description                                                        |
|------------|-----------|---------------|--------------------------------------------------------------------|
| `clk`      | Input     | `logic`       | Clock signal for synchronization.                                  |
| `enable_in`| Input     | `logic`       | Enable signal that controls when `b_in` is registered.             |
| `a_in`     | Input     | `short`       | First input value for the MAC operation.                           |
| `b_in`     | Input     | `short`       | Second input value for the MAC operation.                          |
| `sum`      | Input     | `word`        | Running sum to which the product of `a_in` and `b_in` is added.    |

### Output Table

| Output Name | Direction | Type          | Description                                                       |
|-------------|-----------|---------------|-------------------------------------------------------------------|
| `a_out`     | Output    | `short`       | Forwarded output of `a_in` for use in subsequent operations.      |
| `b_out`     | Output    | `short`       | Forwarded output of `b_in` for use in subsequent operations.      |
| `result`    | Output    | `word`        | Output result of the multiply-accumulate operation \( a \times b + c \). |

## Operation

The `hs_npu_mac` module performs the multiply-accumulate operation as follows:

1. Receives `a_in` and `b_in` as inputs for multiplication. These inputs may represent values from two matrices in a matrix multiplication scenario.

2. When `enable_in` is active, registers the `b_in` input value, allowing selective updates to the second operand in the multiplication. In our case this is for "fixed weight" inference.

3. Performs the multiply-accumulate operation by calculating \( (a\_in \times b\_ff) + sum \), where `b_ff` stores the last registered `b_in` value.

4. Outputs the result of the operation in `result`.

5. Forwards `a_ff` and `b_ff` as `a_out` and `b_out` to propagate values to the next MAC unit.

## Internal Signals

- `a_ff`: Flip-flop register that stores the current value of `a_in`.
- `b_ff`: Flip-flop register that stores the persistent value of `b_in` when `enable_in` is active.


## Submodule Diagram

{!diagrams/mac.html!}

## Related Files

| File Name          | Type       |
|--------------------|------------|
| [hs_npu_mac](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_mac.sv)      | Top        |
