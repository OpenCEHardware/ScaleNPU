# Systolic Array Module

## Description

The Systolic Array module (`hs_npu_systolic`) is the central computational component of the ScaleNPU, designed to perform efficient matrix multiplication using a systolic array structure. This module orchestrates the flow of data through an `SIZE x SIZE` grid of MAC units. The array processes elements from two input matrices (matrix A and matrix B). Elements of Matrix B propagate vertically through columns, while elements of Matrix A flow horizontally across rows. The systolic array enables synchronized multiplication and accumulation at each node, with the results passing to the next row.

The `SIZE` parameter defines the dimensions of the systolic array, making it scalable for various matrix sizes.

!!! note
    
    For the NPU, matrix A is the input matrix and matrix B is the weight matrix.

## I/O Table

### Input Table

| Input Name      | Direction | Type               | Description                                                   |
|-----------------|-----------|--------------------|---------------------------------------------------------------|
| `clk`           | Input     | `logic`            | Clock signal for synchronization across MAC units.            |
| `enable_in`     | Input     | `logic`            | Enable signal to activate the flow of Matrix B values.        |
| `matrixA`       | Input     | `short[SIZE]`      | Input values for Matrix A, with each element feeding one row. |
| `matrixB`       | Input     | `short[SIZE]`      | Input values for Matrix B, with each element feeding one column. |
| `sum_in`        | Input     | `word[SIZE]`       | Initial sums for the first row of MAC units.                  |

### Output Table

| Output Name     | Direction | Type               | Description                                                  |
|-----------------|-----------|--------------------|--------------------------------------------------------------|
| `result`        | Output    | `word[SIZE]`       | Final computed values from the last row of MAC units.        |

## Module Behavior and Data Flow

This subsection does not prescribe a "correct" usage, as the systolic array can be used in several ways; nevertheless, this explains the specific way it is used in the NPU:

- Matrix B values are injected into the first row of the array. These values propagate downward (one row per cycle) if `enable_in` is set. If `enable_in` is not set, the last value is stored and used by each MAC unit as the B operand.

- Matrix A values enter the first row and always propagate from right to left. The immediate value at the input is used as operand A by the MAC unit.

- Each MAC unit performs a multiply-accumulate operation using the inputs from its left (A values) and top (B values). Results are propagated downward and used as the SUM operand by the below MAC unit.

## Submodule Diagram

The following diagram illustrates the Systolic Array module, showing the flow of inputs, outputs, and internal signal paths.

{!diagrams/systolic.html!}

## Related Files

| File Name                       | Type       |
|---------------------------------|------------|
| [hs_npu_systolic](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_systolic.sv) | Top        |
| [hs_npu_mac](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_mac.sv)           | Submodule - MAC |

