import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

# Constants
WIDTH = 32
DEPTH = 4

@cocotb.test()
async def test_fifo_keeper(dut):
    """Test case for loading 4 integers into the first FIFO, enabling the gatekeeper for 2 cycles, 
       and checking that the output FIFO only stores 2 numbers."""
    
    # Generate a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())

    # Reset the DUT
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2) # Wait for computation to occur
    dut.rst_n.value = 1

    # Initialize inputs
    dut.start_in.value = 0
    dut.enable_cycles.value = 2  # Enable the gatekeeper for 2 cycles
    dut.fifo_in_valid.value = 0
    dut.fifo_out_ready.value = 1  # Assume the output FIFO is always ready

    # Wait for reset release
    await RisingEdge(dut.clk)

    # Write 4 integers to the input FIFO
    input_data = [10, 20, 30, 40]
    for i, data in enumerate(input_data):
        dut.fifo_in_data.value = data
        dut.fifo_in_valid.value = 1
        await RisingEdge(dut.clk)
        while dut.fifo_in_ready.value.integer == 0:
            await RisingEdge(dut.clk)  # Wait until FIFO is ready
        dut.fifo_in_valid.value = 0

    # Start the gatekeeper and allow data to flow for 2 cycles
    dut.start_in.value = 1
    await RisingEdge(dut.clk)
    dut.start_in.value = 0

    # Wait for the gatekeeper to finish transferring data for 2 cycles
    await ClockCycles(dut.clk, 4) # Wait for computation to occur


    # Assert that the output FIFO received only 2 values (since enable_cycles = 2)
    expected_output = input_data[:2]
    output_data = []


    # Read from the output FIFO (only 2 values should be present)
    for i in range(2):
        output_data.append(dut.output_fifo.fifo[i].value.integer)


    assert output_data == expected_output, f"Output data mismatch: expected {expected_output}, got {output_data}"

    # End the simulation
    dut._log.info(f"Test passed with output data: {output_data}")
