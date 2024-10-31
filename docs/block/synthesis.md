# Synthesis

This section presents the synthesis results of the ScaleNPU across two FPGAs: DE1-SoC and DE10-Nano. The table below summarizes the usage of resources, including ALMs, registers, memory blocks, and DSPs, along with their respective utilization percentages.

## Synthesis Results Table

| FPGA       | ALMs (Usage / Total) | Registers | Memory Bits (Usage / Total) | DSPs (Usage / Total) | Comments                                       |
|------------|-----------------------|-----------|-----------------------------|-----------------------|------------------------------------------------|
| DE1-SoC    | 3,744 / 32,070 (11.7%) | 5,682     | 5,120 / 4,065,280 (0.1%)    | 40 / 87 (46%)         | Efficient usage within the board's capacity.   |
| DE10-Nano  | 3,754.8 / 41,910 (8.9%) | 5,695     | 5,120 / 5,662,720 (0.09%)   | 40 / 112 (36%)        | Lower utilization than DE1-SoC, with more capacity. |

## Additional Comments

- **Performance and Area**: Both boards demonstrate efficient resource use, with relatively low utilization of memory bits (not accounting for external memory needed to store weights, inputs, biases, and sum values) and ALMs. DSP utilization is notable, especially on the DE1-SoC, where nearly half of the DSP resources are consumed, limiting the maximum size of the systolic array.

- **Scalability**: Resource usage is intentionally kept low to accommodate additional system components, including a CPU, interconnect, and memory, which are necessary for full system integration to effectively use the ScaleNPU as an accelerator.

