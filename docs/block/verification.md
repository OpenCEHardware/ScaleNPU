# Verification

This section details the types of tests applied to the block, as well as the verification methodologies used in the development process.

## Test and test environment

The test environment employed various tools, simulators, and testbeds to verify the functionality and integration of the ScaleNPU. Initial functionality of the systolic array was prototyped in C++. Module-level testing was conducted using **cocotb**, and a complete system simulation (CPU + NPU + memory + JTAG) was carried out with **Verilator**. Final signal validation on FPGA hardware was achieved using **Signal Tap** and the Nios terminal over JTAG.

### Tests Table

| Tool          | Testing                                           | Directory/Repository                  |
|---------------|---------------------------------------------------|----------------------------|
| C++ Prototype | Initial concept verification of systolic array functionality | [Emulation](https://github.com/OpenCEHardware/ScaleNPU/tree/main/emulation)                       |
| cocotb        | Module-level tests for gatekeeper, systolic array, matrix multiplication, and inference | [Testbech](https://github.com/OpenCEHardware/ScaleNPU/tree/main/tb)             |
| Verilator     | Full-system simulation (CPU, NPU, memory, JTAG)   | [Full system simulation](https://github.com/OpenCEHardware/ScaleCore-Software)          |
| Signal Tap    | Signal validation on FPGA                         | N/A                        |
| Nios Terminal | Final system validation via JTAG                  | N/A                        |


### Test Results

 Primary verification of AXI protocol compliance and module functionality was successfully achieved across simulated and hardware environments.

## Benchmarks

Benchmarks were not run for this system.

## Issues and Resolutions

The primary issues encountered during verification were related to AXI protocol compliance, particularly in subtle variations between simulated environments and FPGA hardware. 

!!!note 
    
    While these issues were resolved, a more thorough verification of AXI protocol interactions with memory is advisable, as slight behavioral differences were noted between simulation and FPGA operation.

### Issues and Resolutions Table

| Issue                | Description                             | Resolution                                  |
|----------------------|-----------------------------------------|---------------------------------------------|
| Simulation Error     | Results were inconsistent with expected behavior in AXI transactions. | Adjusted RTL AXI timing parameters. |

!!!warning 

    This means that cocotb and verilator's models of AXI are unreliable. They can be used to verify basic functionality but they can't
    assure your module is AXI compliant.


## Verification Summary

In summary, the ScaleNPU block successfully met functional specifications and demonstrated compatibility within the AXI protocol framework. Module functionality and integration were verified at multiple stages from C++ concept prototyping to hardware-based validation on the FPGA. Additional AXI protocol testing with memory could further reinforce the design's reliability.
