import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import numpy as np
import random

@cocotb.test()
async def test_hs_npu_inference(dut):
    """Test the hs_npu_inference module with a simple matrix multiplication and accumulation."""

    # Generate a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())

    # Resetting the inputs
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Initialize the control signals
    dut.flush_input_fifos.value = 0
    dut.flush_weight_fifos.value = 0
    dut.flush_output_fifos.value = 0
    dut.start_input_gatekeeper.value = 0
    dut.start_output_gatekeeper.value = 0
    dut.enable_weights.value = 0

    # Reset FIFO valid and ready signals
    dut.input_fifo_valid_i.value = 0
    dut.weight_fifo_valid_i.value = 0
    dut.output_fifo_ready_i.value = 0

    # Wait for reset to propagate
    await RisingEdge(dut.clk)

    # Define test data for matrixA and matrixB
    matrixA_data = [
        [77, -36, 54, -72],
        [96, -26, 29, -93],
        [95, -37, 33, -78],
        [110, 32, -59, -122],
    ]

    matrixA_data = [
        [40, 0, 0, 0, 0, 0, 73, 0], 
        [77, 30, 0, 0, 0, 0, 62, 0], 
        [60, 19, 0, 0, 0, 0, 63, 0], 
        [167, 137, 0, 0, 0, 0, 8, 0]
    ]

    matrixA_data =[
        [0, 16, 0, 0, 0, 0, 0, 0], 
        [1, 0, 0, 0, 0, 41, 0, 0], 
        [0, 0, 0, 0, 0, 19, 0, 0], 
        [171, 0, 0, 0, 69, 217, 36, 0]
    ]

    matrixB_data = [    
        [  85,   37,   -3, -115, -110, -98, 95, -14],
        [  98,   10,   13,  -15,   -43, 69, 68, 37],
        [ -35, -128,  -26,   53,   -20, -5, 127, -81],
        [ -58,  -47,   43,  -57,   -53, 94, 34, 109]
    ]

    matrixB_data = [
        [74, -91, -82, 37, -49, 126, -57, -59],
        [78, -8, -53, -124, 127, 55, 107, 47],
        [101, -10, -75, 65, -25, -74, -53, -14],
        [88, -68, -106, -4, -16, -80, 71, -38],
        [49, -114, 32, 42, -16, -123, -128, -118],
        [66, 68, -1, -35, 96, 70, 110, -19],
        [-124, 78, 19, -51, -61, -98, -79, -9],
        [56, -57, -103, 82, 88, -37, 44, 62]
    ]

    matrixB_data = [
        [16, -110, -90],
        [-51, -96, 94],
        [94, -34, -84],
        [-108, 47, -70],
        [63, -127, 33],
        [-128, 3, -39],
        [127, -103, -27],
        [-109, -119, -113]
    ]

    bias_vector = [-128,-91,10,-89,10,10,127,10]
    bias_vector = [-128, 41, 18, -23, 127, 86, 119, 15]
    bias_vector = [-128, -12, 127]
    #bias_vector = [0,0,0,0,0,0,0,0]
    sums_vector = [0,0,0,0,0,0,0,0]
    sums_vector = [0,0,0]

    # Control
    do_relu = 0
    number_of_shifts = 0

    #Mat mul
    expected_result = np.dot(np.array(matrixA_data),np.array(matrixB_data))
    matrixB_data = matrixB_data[::-1]

    # Activation and quantization
    expected_result = expected_result + np.array(sums_vector)
    expected_result = expected_result + np.array(bias_vector)
    if(do_relu):
        expected_result = np.maximum(expected_result,0)
    expected_result = np.right_shift(expected_result,number_of_shifts)

    bias_vector = [-128, -12, 127, 0, 0, 0, 0, 0]
    sums_vector = [0,0,0,0,0,0,0,0]

    input_rows = len(matrixA_data)
    weight_rows = len(matrixB_data)
    input_size = len(matrixA_data[0])
    weight_size = len(matrixB_data[0])
    systolic_size = dut.SIZE.value

    # Set initial sums to 0
    for i in range(systolic_size):
        dut.input_sums[i].value = 0

    # Set biases
    dut.bias_en.value = 1
    for i in range(systolic_size):
        dut.bias_values[i].value = bias_vector[i]
    await ClockCycles(dut.clk, 1)
    dut.bias_en.value = 0
    await ClockCycles(dut.clk, 1)

    # Disable ReLU and set shift amount to 0 (no shift)
    dut.relu_enable.value = do_relu
    dut.shift_amount.value = number_of_shifts

    # Loading weights into the weight FIFO (0 padding on unused lanes)
    dut.weight_fifo_valid_i.value = 1
    for i in range(weight_rows):
        for j in range(systolic_size):
            try:
                dut.weight_matrix_row[j].value = matrixB_data[i][j]
            except:
                dut.weight_matrix_row[j].value = 0
        await ClockCycles(dut.clk, 1)
    # for i in range(systolic_size - weight_rows):
    #     await ClockCycles(dut.clk, 1)

    # Disable weight input after loading
    dut.weight_fifo_valid_i.value = 0

    # Load weights into the systolic array
    dut.enable_weights.value = 1
    await ClockCycles(dut.clk, 8)
    dut.enable_weights.value = 0

    # Loading inputs into the input FIFO
    dut.input_fifo_valid_i.value = 1
    for i in range(input_rows):
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

    await ClockCycles(dut.clk, systolic_size + input_rows) # Await for computation

    # Collect results from output FIFOs
    result_matrix = []
    dut.output_fifo_ready_i.value = 1
    await ClockCycles(dut.clk, 1)
    for i in range(input_rows):
        result_values = []
        for j in range(weight_size):
            result = dut.inference_result[j].value.signed_integer
            result_values.append(result)
        await ClockCycles(dut.clk, 1)
        result_matrix.append(result_values)

    print("Result matrix is:")
    print(result_matrix)

    # Perform verification
    assert len(result_matrix) == input_rows, "Result rows mismatch"
    assert len(result_matrix[0]) == weight_size, "Result columns mismatch"
    assert result_matrix == expected_result.tolist(), "Result mismatch"

    cocotb.log.info("Test completed successfully.")