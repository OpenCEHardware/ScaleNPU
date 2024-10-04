import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import numpy as np
import random

@cocotb.test()
async def test_hs_npu_mm_unit(dut):
    """Test the hs_npu_mm_unit module with FIFO and gatekeeper logic."""
    
    # Generate a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())

    # Resetting the inputs
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Initialize the control signals
    dut.flush_input_fifos.value = 0
    # dut.flush_output_fifos.value = 0
    dut.flush_weight_fifos.value = 0
    dut.start_input_gatekeeper.value = 0
    dut.start_output_gatekeeper.value = 0
    dut.enable_weights.value = 0

    # Reset FIFO valid and ready signals
    dut.input_fifo_valid_i.value = 0
    dut.weight_fifo_valid_i.value = 0
    # dut.output_fifo_ready_i.value = 0

    # Wait for reset to propagate
    await RisingEdge(dut.clk)

    # Define test data for matrixA, matrixB, and initial sums
    matrixA_data = [
        [77, -36, 54, -72],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [-1, -1, -1, -1],
        [77, -36, 54, -72],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [-1, -1, -1, -1]
    ]
    matrixB_data = [
        [-58, -47, 43, -57, -53, 94, 34, 109],
        [-35, -128, -26, 53, -20, -5, 127, -81],
        [98, 10, 13, -15, -43, 69, 68, 37],
        [85, 37, -3, -115, -110, -98, 95, -14]
    ]
    # expected_result = [
    #     [5303, -1039, -5199, -1349, -4186, -17068, 9277, -14632]
    # ]

    input_rows = len(matrixA_data)
    weight_rows = len(matrixB_data)
    input_size = len(matrixA_data[0])
    weight_size = len(matrixB_data[0])
    systolic_size = dut.SIZE.value
    
    # Set initial sums to 0
    for i in range(systolic_size):
        dut.input_sums[i].value = 0

    # Loading weights into the weight FIFO (0 padding on unsed lanes)
    dut.weight_fifo_valid_i.value = 1
    for i in range(weight_rows):
        for j in range(systolic_size):
            dut.weight_matrix_row[j].value = matrixB_data[i][j]
        await ClockCycles(dut.clk, 1)
    for i in range(systolic_size-weight_rows):
        for j in range(systolic_size):
            dut.weight_matrix_row[j].value = 0
        await ClockCycles(dut.clk, 1)
    
    # Disable weight input after loading
    dut.weight_fifo_valid_i.value = 0

    # Load weights into the systolic array
    dut.enable_weights.value = 1
    await ClockCycles(dut.clk, 8)
    dut.enable_weights.value = 0

    # Loading weights into the weight FIFO
    dut.input_fifo_valid_i.value = 1
    for i in range(input_rows):
        for j in range(systolic_size-input_size):
            dut.input_matrix_row[j].value = 0
        for j in range(input_size):
            dut.input_matrix_row[(systolic_size-input_size) + j].value = matrixA_data[i][j]
        await ClockCycles(dut.clk, 1)
    dut.input_fifo_valid_i.value = 0

    # Starting input gatekeeper for the systolic array
    dut.enable_cycles_in.value = input_rows
    dut.start_input_gatekeeper.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start_input_gatekeeper.value = 0
    await ClockCycles(dut.clk, systolic_size - 1)

    # Start the output gatekeeper to get results
    dut.start_output_gatekeeper.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start_output_gatekeeper.value = 0

    # Collect results from output gatekeepers
    result_matrix = []
    await ClockCycles(dut.clk, 1)
    for i in range(2*systolic_size -1):
        result_values = []
        for j in range(weight_size):
            result = dut.output_data[j].value.signed_integer
            result_values.append(result)
        result_matrix.append(result_values)
        await ClockCycles(dut.clk, 1)
        
    print(result_matrix)

    #     # Iterate over the array
    # for i in range(8):

    # # Start the output gatekeeper to get results
    # dut.start_output_gatekeeper.value = 1
    # await ClockCycles(dut.clk, 1)
    # dut.start_output_gatekeeper.value = 0
    # await ClockCycles(dut.clk, systolic_size + 1)  # Wait for computation to complete

    # # Collect results from output FIFOs
    # result_matrix = []
    # result_values = []
    # dut.output_fifo_ready_i.value = 1
    # await ClockCycles(dut.clk, 1)
    # for i in range(input_rows):
    #     for j in range(weight_size):
    #         result = dut.output_data[j].value.signed_integer
    #         result_values.append(result)
    #         cocotb.log.info(f"Result[{i}]: {result}")
    #     await ClockCycles(dut.clk, 1)
    #     result_matrix.append(result_values)

    # Verification of results
    # for i in range(weight_size):
    #     assert result_values[i] == expected_result[0][i], f"Mismatch at index {i}: Expected {expected_result[i]}, got {result_values[i]}"
    #     cocotb.log.info(f"Verification Passed for Result[{i}]")

    cocotb.log.info("Test completed successfully.")
