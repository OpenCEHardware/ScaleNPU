# FIFO Module

## Description

The FIFO (First-In, First-Out) module in the ScaleNPU functions as a sequence of specialized buffers that temporarily store and manage data flow between different processing stages. Instead of a centralized buffer for the entire NPU, the ScaleNPU utilizes multiple FIFO instances, each serving a specific role, this enables parallel data storage and retrieval within the NPU.

The FIFO sequentially stores incoming data (`in`) as long as the `valid_i` and `ready_o` signals are active. When data is requested (`ready_i` asserted), it outputs in the order stored, one value per cycle. The `ready_o` output indicates if more data can be written to the FIFO, while `valid_o` shows if valid data is available for reading. The `flush` signal resets the FIFO state.

A unique feature of the ScaleNPU FIFO is its custom `reread` signal. the `reread` signal resets the read pointer, allowing data to be output again, which a normal FIFO is not able to do. 

In the `hs_npu_fifo` module, `WIDTH` defines the bit width of each entry, making the FIFO adaptable to handle data sizes ranging from small values (e.g., 8-bit) to larger ones (e.g., 32-bit), while `DEPTH` specifies the number of entries the FIFO can hold, setting its capacity before it is full. The data input (`in`) and output (`out`) signals are sized according to `WIDTH`, aligning with the bit size of data being processed, and the internal array is sized `[DEPTH][WIDTH]`.

## I/O Table

### Input Table

| Input Name      | Direction | Type               | Description                                               |
|-----------------|-----------|--------------------|-----------------------------------------------------------|
| `clk_core`      | Input     | `logic`            | Clock signal for synchronization.                         |
| `rst_core_n`    | Input     | `logic`            | Active-low reset signal for initializing the FIFO state.  |
| `flush`         | Input     | `logic`            | Resets the FIFO state and clears data.                    |
| `reread`        | Input     | `logic`            | Resets the read pointer to reread all stored data.        |
| `valid_i`       | Input     | `logic`            | Indicates if the input data is valid for writing.         |
| `in`            | Input     | `logic [WIDTH-1:0]`| Data input for values to be stored in the FIFO.           |
| `ready_i`       | Input     | `logic`            | Indicates if the output can be accepted by the consumer.  |

### Output Table

| Output Name     | Direction | Type               | Description                                              |
|-----------------|-----------|--------------------|----------------------------------------------------------|
| `ready_o`       | Output    | `logic`            | Indicates if the FIFO can accept more data.              |
| `valid_o`       | Output    | `logic`            | Indicates if the FIFO has valid data available to read.  |
| `out`           | Output    | `logic [WIDTH-1:0]`| Data output line for values retrieved from the FIFO.     |

## Submodule Diagram

The following diagram illustrates the FIFO module, its inputs, outputs, and internal signal paths.

{!diagrams/fifo.html!}

## Related Files

| File Name          | Type       |
|--------------------|------------|
| [hs_npu_fifo](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_fifo.sv)      | Top        |
