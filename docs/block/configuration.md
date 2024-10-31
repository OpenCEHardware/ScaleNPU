# Configuration

The ScaleNPU was designed with a focus on flexibility, allowing for extensive configurability and parameterization. While the current implementation includes several configurable parameters, many have only been tested with their default values.

### Parameters

| Parameter Name            | Type  | Description                                                                              | Default Value | Range/Possible Values |
|---------------------------|-------|------------------------------------------------------------------------------------------|---------------|-----------------------|
| `SIZE`                    | `int` | Number of rows and columns in the systolic array.                                        | `8`           | Positive integer (limited by FPGA DSP blocks)|
| `INPUT_DATA_WIDTH`        | `int` | Bit width for input data values in the systolic array.                                   | `16`          | `8`, `16`, `32`, `64` |
| `WEIGHT_DATA_WIDTH`       | `int` | Bit width for weight values in the systolic array.                                       | `16`          | `8`, `16`, `32`, `64` |
| `OUTPUT_DATA_WIDTH`       | `int` | Bit width for output data from MAC operations.  It also defines bias and sum data width. | `32`          | `8`, `16`, `32`, `64` |
| `ACTIVATION_OUTPUT_WIDTH` | `int` | Bit width for output after the activation (and quantization) function.                   | `16`          | Should match `INPUT_DATA_WIDTH`|
| `BUFFER_SIZE`             | `int` | Maximum number of inferences stored in SDRAM.                                            | `16`          | Based on SDRAM capacity and application|
| `INPUT_FIFO_DEPTH`        | `int` | Depth of the input FIFO buffer.                                                          | `16`          | Should match `BUFFER_SIZE` |
| `OUTPUT_FIFO_DEPTH`       | `int` | Depth of the output FIFO buffer.                                                         | `16`          | Should match `BUFFER_SIZE` |
| `WEIGHT_FIFO_DEPTH`       | `int` | Depth of the weight FIFO buffer.                                                         | `8`           | Typically smaller than input/output buffers. Minimum is `SIZE`|
| `BURST_SIZE`              | `int` | Burst size for AXI RAM transfers (2^N bytes).                                            | `2`           | Positive integer; should align with input and weight sizes  |
| `BURST_LEN`               | `int` | Length of the burst in 32-bit word transfers.                                            | `1`           | Positive integer  |

**Remarks**:

- `BURST_SIZE` and `BURST_LEN` follow AXI protocol limitations, directly influencing memory ordering behavior.
- FIFO depths depend on SDRAM limits in the FPGA, so testing beyond default values could reveal memory constraints. Default values are close to minimum requirements.

### Typedefs

| Typedef Name | Type    | Description                                                                 |
|--------------|---------|-----------------------------------------------------------------------------|
| `word`       | `logic signed [31:0]` | A signed 32-bit data type used in operations like MAC.       |
| `short`      | `logic signed [15:0]` | A signed 16-bit data type for inputs and weights.            |
| `uword`      | `logic [31:0]`        | An unsigned 32-bit data type used in memory or control ops.  |

These typedefs ensure consistent data sizing across the architecture.

---

### Supported Parameter Variations

Due to time constraints, the ScaleNPU's parameterization has been primarily tested with default values. Most limitations arise in the memory management unit, given its rigid handling of `BURST_SIZE` and `BURST_LEN` in relation to the systolic array size, input/weight/output bit widths, and buffer capacities. Extending functionality to support all potential parameter combinations would require significantly more logic, especially in the memory ordering and interface units.

!!! warning
    
    Current configurations outside of the default values may not guarantee proper operation of the ScaleNPU.

The following table outlines some potential issues and solutions related to specific parameters:

| Parameter Name            | Likelihood of Failure                                  | Reason for Failure                                                       | Possible Solution                                                        |
|---------------------------|--------------------------------------------------------|--------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `SIZE`                    | Medium, if DSP constraints are respected.               | Memory ordering might not fill the array if `SIZE` is not divisible by `BURST_LEN`. With `SIZE=8`, four 2-beat requests fill the array's 8 rows/columns. | Add logic to handle unaligned bursts|
| `INPUT_DATA_WIDTH`, `WEIGHT_DATA_WIDTH`, `OUTPUT_DATA_WIDTH` | Low, but may require adjusting burst parameters. | Current 16-bit default guards against overflow; larger values may increase DSP needs and require burst adjustments. | Adjust burst sizes/lengths to handle larger data widths, prevent overflow |
| `ACTIVATION_OUTPUT_WIDTH` | Low, but may also require burst adjustments.           | As above, larger widths may increase DSP needs and affect burst sizes/lengths. | Same as above |
| `BUFFER_SIZE`             | Very low.                                               | NPU may exit with code `11` if buffer size is too small for CPU inputs. | Increase buffer size or perform inference on fewer inputs at a time. |
| `BURST_SIZE`              | Medium.                                                | Misalignment with input, weight, and bias widths | Ensure proper alignment, or refactor memory ordering/interface state machines |
| `BURST_LEN`               | High.                                                  | Hardcoded logic in memory ordering unit expects default values | Refactor memory ordering/interface state machines to support flexibility |

!!! note

    For DE1-SoC and DE1-Nano boards, altering these parameters is generally unnecessary, as the default implementation is sufficient for most academic projects. An appropriate driver could abstract many of these implementation details.