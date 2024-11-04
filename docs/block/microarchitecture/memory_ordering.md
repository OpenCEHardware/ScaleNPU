# Memory Ordering Unit

## Description

The `hs_npu_memory_ordering` module is a control unit responsible for orchestrating data flow between memory and the inference unit in the NPU. It uses a state machine to manage loading of input matrices, weights, biases, and sums, as well as saving output data back to memory. Key functionalities include handling memory requests, controlling data read and write operations, and setting up FIFOs for input, weight, and output buffers. This module also supports reusing weights and inputs, applying biases, and shifting values for activation functions. Its execution can be configured through control signals, with outputs aligned for the systolic array dimensions, ensuring data preparation for matrix multiplication and inference tasks.

### Overview and Responsibilities

1. **State Machine**: 
    - The module transitions between states like `IDLE`, `LOADING_WEIGHTS`, `LOADING_INPUTS`, `LOADING_BIAS`, `LOADING_SUMS`, `READY_TO_COMPUTE`, and `SAVING`. Each state has specific responsibilities, and transitions occur based on conditions such as memory validity signals and reuse flags.
   
2. **Data Loading and Memory Requests**: 
    - During the loading phases, this module issues memory requests and loads data (weights, inputs, bias, sums) from memory or previous inference results based on the configuration. It uses `BURST_SIZE` to control the amount of data per transfer.

    !!! danger

        As discussed earlier, changing the default value of `BURST_SIZE` might cause errors.
   
3. **Computation Control**: 
    - In the `READY_TO_COMPUTE` state, the module controls gates (`start_input_gatekeeper` and `start_output_gatekeeper`) and enables the computation within the inference unit, coordinating the input and output flow through the gatekeepers.

    !!! info

        This is absolutely central to the NPU, as this timing is very sentitive, one cycle too early or too late will produce incomplete or incorrect results. 
   
4. **Saving Results**: 
    - After computation, in the `SAVING` state, it can write results back to memory if `save_outputs_in` is asserted. It uses memory write signals (`mem_write_valid_o` and `memory_data_out`) to save computed outputs sequentially.

5. **FIFO Control**:
    - The module manages FIFO flushing and readiness signals to synchronize data flow within the NPU, particularly for input, weight, and output FIFOs.

### State Descriptions

- **IDLE**: Initializes parameters and waits for a valid execution signal (`exec_valid_i`). When received, captures layer parameters, resets relevant counters, and transitions to `LOADING_WEIGHTS`.
  
- **LOADING_WEIGHTS**: Loads weights from memory into `output_weights` until the required rows are loaded or `reuse_weights` is set. When done, it transitions to `LOADING_INPUTS`.

- **LOADING_INPUTS**: Loads input data from memory (or reuses prior inputs if `reuse_inputs` is set). After loading, it transitions to `LOADING_BIAS`.

- **LOADING_BIAS**: If `use_bias` is asserted, loads bias values into `bias`. When completed, moves to `LOADING_SUMS`.

- **LOADING_SUMS**: Similar to the bias load, but for sums if `use_sum` is asserted. After loading, transitions to `READY_TO_COMPUTE`.

- **READY_TO_COMPUTE**: Activates input and output gatekeepers for controlled data flow into the inference unit. Sets up the module for computation based on `computation_cycles` and then transitions to `SAVING` to store results.

- **SAVING**: Saves the output data to memory if `save_outputs_in` is asserted. Once all data is saved, resets for the next cycle and goes back to `IDLE`.

    !!! info

        Note that the unit assumes that all the data is concurrently stored in memory, in a specific order!

### Control Signal Assignments

- **exec_ready_o**: Indicates readiness for a new operation when in `IDLE`.
- **mem_read_ready_o** and **mem_write_valid_o**: Control memory read/write based on the state and internal flags.
- **flush_input_fifos**, **flush_weight_fifos**, and **flush_output_fifos**: Manage FIFO flushing in relevant states.
  
### Output Data and Gatekeeper Configuration

- `output_weights`, `output_inputs`, `output_bias`, and `output_sums` hold data that will be transferred to inference and accumulation units.
- `start_input_gatekeeper`, `start_output_gatekeeper`, and `enable_cycles_gatekeeper` configure gatekeepers, allowing smooth data flow within the processing unit.

## I/O Table

### Input Signals

| Input Name             | Direction | Type                      | Description                                                                 |
|------------------------|-----------|---------------------------|-----------------------------------------------------------------------------|
| `clk`                  | Input     | `logic`                   | Clock signal for synchronization.                                           |
| `rst_n`                | Input     | `logic`                   | Active-low reset signal.                                                    |
| `exec_valid_i`         | Input     | `logic`                   | Indicates that an execution request is valid.                               |
| `mem_valid_i`          | Input     | `logic`                   | Indicates that a memory read or write request is valid.                     |
| `mem_ready_i`          | Input     | `logic`                   | Memory interface ready signal for data transfers.                           |
| `memory_data_in`       | Input     | `uword [BURST_SIZE]`      | Data matrix values read from memory.                                        |
| `num_input_rows_in`    | Input     | `uword`                   | Number of rows in the input matrix.                                         |
| `num_input_columns_in` | Input     | `uword`                   | Number of columns in the input matrix.                                      |
| `num_weight_rows_in`   | Input     | `uword`                   | Number of rows in the weight matrix.                                        |
| `num_weight_columns_in`| Input     | `uword`                   | Number of columns in the weight matrix.                                     |
| `reuse_inputs_in`      | Input     | `logic`                   | Control signal to reuse inputs across computations.                         |
| `reuse_weights_in`     | Input     | `logic`                   | Control signal to reuse weights across computations.                        |
| `save_outputs_in`      | Input     | `logic`                   | Control signal to save outputs after computation.                           |
| `use_bias_in`          | Input     | `logic`                   | Enables bias addition in the computation.                                   |
| `use_sum_in`           | Input     | `logic`                   | Enables sum accumulation in the computation.                                |
| `shift_amount_in`      | Input     | `uword`                   | Specifies the amount to shift results after computation.                    |
| `activation_select_in` | Input     | `logic`                   | Selects the activation function to apply to results.                        |
| `base_address_in`      | Input     | `uword`                   | Base address for memory accesses.                                           |
| `result_address_in`    | Input     | `uword`                   | Address to store the computation results.                                   |
| `inference_result`     | Input     | `logic [INPUT_DATA_WIDTH-1:0] [SIZE]` | Final output from inference.                                    |

### Output Signals

| Output Name              | Direction | Type                      | Description                                                                |
|--------------------------|-----------|---------------------------|----------------------------------------------------------------------------|
| `exec_ready_o`           | Output    | `logic`                   | Indicates readiness to accept a new execution command.                     |
| `finished`               | Output    | `logic`                   | Indicates that the current operation has completed.                        |
| `mem_read_ready_o`       | Output    | `logic`                   | Indicates readiness for memory read operations.                            |
| `mem_write_valid_o`      | Output    | `logic`                   | Indicates that a memory write operation is valid.                          |
| `mem_invalidate`         | Output    | `logic`                   | Signals to invalidate read data.                                           |
| `memory_data_out`        | Output    | `uword [BURST_SIZE]`      | Data matrix values written to memory.                                      |
| `request_address`        | Output    | `uword`                   | Address for requesting data from memory.                                   |
| `flush_input_fifos`      | Output    | `logic`                   | Signal to flush the input FIFOs.                                           |
| `input_fifo_valid_o`     | Output    | `logic`                   | Indicates that data in input FIFO is valid.                                |
| `flush_weight_fifos`     | Output    | `logic`                   | Signal to flush the weight FIFOs.                                          |
| `weight_fifo_valid_o`    | Output    | `logic`                   | Indicates that data in weight FIFO is valid.                               |
| `flush_output_fifos`     | Output    | `logic`                   | Signal to flush the output FIFOs.                                          |
| `output_fifo_ready_o`    | Output    | `logic`                   | Indicates that the output FIFO is ready.                                   |
| `output_fifo_reread`     | Output    | `logic`                   | Signal to reread data from the output FIFO.                                |
| `bias_enable`            | Output    | `logic`                   | Enable signal for bias in computation.                                     |
| `weight_enable`          | Output    | `logic`                   | Enable signal for weight data in computation.                              |
| `start_input_gatekeeper` | Output    | `logic`                   | Signal to start the input gatekeeper.                                      |
| `start_output_gatekeeper`| Output    | `logic`                   | Signal to start the output gatekeeper.                                     |
| `enable_cycles_gatekeeper`| Output   | `uword`                   | Number of cycles for enabling the gatekeeper.                              |
| `activation_select_out`  | Output    | `logic`                   | Output activation function selection.                                      |
| `shift_amount_out`       | Output    | `uword`                   | Output shift amount for the computation result.                            |
| `output_weights`         | Output    | `logic [INPUT_DATA_WIDTH-1:0] [SIZE]` | Output weight matrix values.                          |
| `output_inputs`          | Output    | `logic [INPUT_DATA_WIDTH-1:0] [SIZE]` | Output input matrix values.                           |
| `output_bias`            | Output    | `logic [OUTPUT_DATA_WIDTH-1:0] [SIZE]`| Output bias values.                                     |
| `output_sums`            | Output    | `logic [OUTPUT_DATA_WIDTH-1:0] [SIZE]`| Output sums balues.                         |

## State Machine Diagram

This diagram presents a basic overview of the state machine and its transitions.

{!diagrams/memory_ordering.html!}


## Related Files

| File Name                                                                                                           | Type           |
|---------------------------------------------------------------------------------------------------------------------|----------------|
| [hs_npu_memory_ordering](https://github.com/OpenCEHardware/ScaleNPU/blob/main/rtl/hs_npu/hs_npu_memory_ordering.sv) | Top            |


## Additional Comments

As discussed earlier, refactoring this module would resolve most of the current inflexibilities of the ScaleNPU in terms of sizes and parameters. Up until now, following the uarch section order, this is the only module that hardcodes specific sizes and parameters into the logic.

It should also be noted that this module is quite complex, having to manage both the AXI sizes, bursts, and synchronization, along with the MM unit requirements and special timing. While this flexibility would provide a nice boost in performance, using the default values (whose correct functionality has been validated) is still significantly faster than using the ScaleCore-V for inference. The current pain point is the software interface, as the programmer must directly interact with the CSRs. A software driver would be the most beneficial addition to the ScaleNPU at this time.

