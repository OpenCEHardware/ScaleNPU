import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.regression import TestFactory
from cocotb.clock import Clock
from cocotb_bus.drivers.amba import AXI4LiteMaster
from axi import * 

# Constants
CLK_PERIOD = 10  # Clock period in ns

# Define the matrices and vectors
matrixB_data = [
    [-58, -47, 43, -57, -53, 94, 34, 109],
    [-35, -128, -26, 53, -20, -5, 127, -81],
    [98, 10, 13, -15, -43, 69, 68, 37],
    [85, 37, -3, -115, -110, -98, 95, -14]
]

matrixA_data = [
    [0, 0, 0, 0, 77, -36, 54, -72 ],
    [0, 0, 0, 0, 96, -26, 29, -93],
    [0, 0, 0, 0, 95, -37, 33, -78],
    [0, 0, 0, 0, 110, 32, -59, -122]
]

bias_vector = [-128, -91, 10, -89, 10, 10, 127, 10]  # 32-bit integers
sums_vector = [0, 0, 0, 0, 0, 0, 0, 0]  # 32-bit integers

# Define later 2

weights_417 = [
    [56, -57, -103, 82, 88, -37, 44, 62],
    [-124, 78, 19, -51, -61, -98, -79, -9],
    [66, 68, -1, -35, 96, 70, 110, -19],
    [49, -114, 32, 42, -16, -123, -128, -118],
    [88, -68, -106, -4, -16, -80, 71, -38],
    [101, -10, -75, 65, -25, -74, -53, -14],
    [78, -8, -53, -124, 127, 55, 107, 47],
    [74, -91, -82, 37, -49, 126, -57, -59]
]

biases_417 = [-128, 41, 18, -23, 127, 86, 119, 15]


weights_418 = [
    [-109, -119, -113, 0, 0, 0, 0, 0],
    [127, -103, -27, 0, 0, 0, 0, 0],
    [-128, 3, -39, 0, 0, 0, 0, 0],
    [63, -127, 33, 0, 0, 0, 0, 0],
    [-108, 47, -70, 0, 0, 0, 0, 0],
    [94, -34, -84, 0, 0, 0, 0, 0],
    [-51, -96, 94, 0, 0, 0, 0, 0],
    [16, -110, -90, 0, 0, 0, 0, 0],
]

biases_418 = [-128, -12, 127, 0, 0, 0, 0, 0]

@cocotb.test()
async def test_hs_npu(dut):
    """Test hs_npu module."""
    # Create a clock on the clk signal
    clock = Clock(dut.clk_npu, CLK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())

    # Resetting module
    dut.rst_n.value = 0
    await ClockCycles(dut.clk_npu, 5)
    dut.rst_n.value = 1

    # # Create an empty bytearray
    # memory = bytearray(b'\xc6\xd1+\xc7\xcb^"m\xdd\x80\xe65\xec\xfb\x7f\xafb\n\r\xf1\xd5ED%U%\xfd\x8d\x92\x9e_\xf2')

    memory = bytearray();

    # Flatten matrix B and matrix A as int8 values (1 byte each)
    for row in matrixB_data:
        for byte in row:
            memory.append(byte & 0xFF)  # Convert to 8-bit

    for row in matrixA_data:
        for byte in row:
            memory.append(byte & 0xFF)  # Convert to 8-bit

    # Add bias and sums vectors as int32 values (4 bytes each)
    for bias in bias_vector:
        memory.extend(bias.to_bytes(4, byteorder='little', signed=True))

    for sum_val in sums_vector:
        memory.extend(sum_val.to_bytes(4, byteorder='little', signed=True))

    # Flatten and add weights_417 as int8 values (1 byte each)
    for row in weights_417:
        for value in row:
            memory.append(value & 0xFF)  # Convert to 8-bit

    # Add biases_417 as int32 values (4 bytes each)
    for bias in biases_417:
        memory.extend(bias.to_bytes(4, byteorder='little', signed=True))

    # Flatten and add weights_418 as int8 values (1 byte each)
    for row in weights_418:
        for value in row:
            memory.append(value & 0xFF)  # Convert to 8-bit

    # Add biases_418 as int32 values (4 bytes each)
    for bias in biases_418:
        memory.extend(bias.to_bytes(4, byteorder='little', signed=True))


    print(memory)

    memory = memoryview(memory)

    # Initialize AXI4-Lite and AXI4 burst interfaces
    csr_if = AXI4LiteMaster(dut, "csr", dut.clk_npu, case_insensitive=True)
    mem_if = AXI4Agent(dut, "mem", dut.clk_npu, memory, case_insensitive=False)
    
    ARCHID_REG_ADDR            = 0x00
    IMPID_REG_ADDR             = 0x04
    NUM_ROWS_INPUT_REG_ADDR    = 0x08
    NUM_COLS_INPUT_REG_ADDR    = 0x0C
    NUM_ROWS_WEIGHT_REG_ADDR   = 0x10
    NUM_COLS_WEIGHT_REG_ADDR   = 0x14
    REINPUT_REG_ADDR           = 0x18
    REWEIGHT_REG_ADDR          = 0x1C
    SAVEOUT_REG_ADDR           = 0x20
    USE_BIAS_REG_ADDR          = 0x24
    USE_SUMM_REG_ADDR          = 0x28
    SHIFT_AMT_REG_ADDR         = 0x2C
    ACT_FN_REG_ADDR            = 0x30
    BASE_MEMADDR_REG_ADDR      = 0x34
    RESULT_MEMADDR_REG_ADDR    = 0x38
    MAINCTRL_INIT_REG_ADDR     = 0x3C
    EXIT_CODE_REG_ADDR         = 0x40

    await csr_if.write(NUM_ROWS_INPUT_REG_ADDR, 4)
    await csr_if.write(NUM_COLS_INPUT_REG_ADDR, 8)
    await csr_if.write(NUM_ROWS_WEIGHT_REG_ADDR, 4)
    await csr_if.write(NUM_COLS_WEIGHT_REG_ADDR, 8)

    await csr_if.write(REINPUT_REG_ADDR, 0)
    await csr_if.write(REWEIGHT_REG_ADDR, 0)
    await csr_if.write(SAVEOUT_REG_ADDR, 1)
    await csr_if.write(USE_BIAS_REG_ADDR, 1)
    await csr_if.write(USE_SUMM_REG_ADDR, 1)
    await csr_if.write(SHIFT_AMT_REG_ADDR, 7)
    await csr_if.write(ACT_FN_REG_ADDR, 1)

    await csr_if.write(BASE_MEMADDR_REG_ADDR, 0)
    await csr_if.write(RESULT_MEMADDR_REG_ADDR, 1000)

    await csr_if.write(MAINCTRL_INIT_REG_ADDR, 1)


    await RisingEdge(dut.irq)

    await csr_if.write(NUM_ROWS_INPUT_REG_ADDR, 4)
    await csr_if.write(NUM_COLS_INPUT_REG_ADDR, 8)
    await csr_if.write(NUM_ROWS_WEIGHT_REG_ADDR, 8)
    await csr_if.write(NUM_COLS_WEIGHT_REG_ADDR, 8)

    await csr_if.write(REINPUT_REG_ADDR, 1)
    await csr_if.write(REWEIGHT_REG_ADDR, 0)
    await csr_if.write(SAVEOUT_REG_ADDR, 1)
    await csr_if.write(USE_BIAS_REG_ADDR, 1)
    await csr_if.write(USE_SUMM_REG_ADDR, 0)
    await csr_if.write(SHIFT_AMT_REG_ADDR, 7)
    await csr_if.write(ACT_FN_REG_ADDR, 1)

    await csr_if.write(BASE_MEMADDR_REG_ADDR, 128)
    await csr_if.write(RESULT_MEMADDR_REG_ADDR, 2000)

    await csr_if.write(MAINCTRL_INIT_REG_ADDR, 1)


    await RisingEdge(dut.irq)

    await csr_if.write(NUM_ROWS_INPUT_REG_ADDR, 4)
    await csr_if.write(NUM_COLS_INPUT_REG_ADDR, 8)
    await csr_if.write(NUM_ROWS_WEIGHT_REG_ADDR, 8)
    await csr_if.write(NUM_COLS_WEIGHT_REG_ADDR, 3)

    await csr_if.write(REINPUT_REG_ADDR, 1)
    await csr_if.write(REWEIGHT_REG_ADDR, 0)
    await csr_if.write(SAVEOUT_REG_ADDR, 1)
    await csr_if.write(USE_BIAS_REG_ADDR, 1)
    await csr_if.write(USE_SUMM_REG_ADDR, 0)
    await csr_if.write(SHIFT_AMT_REG_ADDR, 0)
    await csr_if.write(ACT_FN_REG_ADDR, 0)

    await csr_if.write(BASE_MEMADDR_REG_ADDR, 224)
    await csr_if.write(RESULT_MEMADDR_REG_ADDR, 3000)

    await csr_if.write(MAINCTRL_INIT_REG_ADDR, 1)

    await RisingEdge(dut.irq)

    await ClockCycles(dut.clk_npu, 10)
