import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import random
import numpy as np



@cocotb.test()
async def test_systolic_array(dut):
    """Test the hs_npu_systolic module."""
    
    # Generate a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())

    # Resetting the inputs
    dut.enable_in.value = 0
    for i in range(8):
        dut.matrixA[i].value = 0
        dut.matrixB[i].value = 0
        dut.sum_in[i].value = 0
        dut.result[i].value = 0

    await RisingEdge(dut.clk)  # Wait for one clock cycle

    # Define test data for matrixA, matrixB, and sum_in

    # Define matrices
    matrixA_data = [  77,  -36,   54,  -72 ]

    matrixB_data = [ [ -58,  -47,   43,  -57,   -53, 94, 34, 109],
                     [ -35, -128,  -26,   53,   -20, -5, 127, -81],
                     [  98,   10,   13,  -15,   -43, 69, 68, 37],
                     [  85,   37,   -3, -115, -110, -98, 95, -14]]

    expected_result = [ 5303,  -1039,  -5199,  -1349,  -4186, -17068,   9277, -14632 ]

    # Set sum to 0
    for i in range(8):        
        dut.sum_in[i].value = 0

    # Populate weights 
    dut.enable_in.value = 1  # Enable the systolic array weights
    for i in range(4):
        for j in range(8):
            dut.matrixB[j].value = matrixB_data[i][j]
        await ClockCycles(dut.clk, 1)
    for i in range(4):
        for j in range(8):
            dut.matrixB[j].value = 0
        await ClockCycles(dut.clk, 1)
    dut.enable_in.value = 0  # Disable the systolic array weights

    # Insert data
    for i in range(8):
        if i in range(4):
            dut.matrixA[i].value = 0
        else:
            dut.matrixA[i].value = matrixA_data[i-4]
        await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 8) # Wait for computation to occur

    # AGREGAR MANUALMENTE CADA CICLO PARA LAS 8 ENTRADAS, PROBAR A DIOS CON LA MATRIZ DE PESOS Y 1 ENTRADA

    # Display the output results
    result_values = []
    for i in range(8):
        result = dut.result[i].value.signed_integer  # Get signed integer value
        result_values.append(result)
        cocotb.log.info(f"Result[{i}]: {result}")

    # Optional: Add verification logic if you have expected results
    expected_results = []
    for i in range(8):
        assert result_values[i] == expected_result[i], f"Mismatch at index {i}: Expected {expected_result}, got {result_values[i]}"
        cocotb.log.info(f"Verification Passed for Result[{i}]")

    cocotb.log.info("Test completed successfully.")
