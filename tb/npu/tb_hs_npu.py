import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
import random
import struct


# Set parameters for the test
SIZE = 8
INPUT_DATA_WIDTH = 16
OUTPUT_DATA_WIDTH = 32
CLOCK_PERIOD = 10  # in ns

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

# Function to retrieve 32-bit data from memory
def get_data(address):

    memory = []

    # Flatten matrix B and matrix A as int8 values (1 byte each)
    memory = [byte for row in matrixB_data for byte in row] + \
            [byte for row in matrixA_data for byte in row]

    # Add bias and sums vectors as int32 values (4 bytes each)
    # Pack each 32-bit integer as 4 bytes and extend the memory
    for bias in bias_vector:
        memory.append(bias)
        for _ in range(3):
            if bias < 0:
                memory.append(-1)
            else:
                memory.append(0)

    for sum_val in sums_vector:
        memory.append(sum_val)
        for _ in range(3):
            if sum_val < 0:
                memory.append(-1)
            else:
                memory.append(0)

    # -----------

    # Fetch 4 consecutive bytes from the memory starting at the given address
    if address >= len(memory):
        print(f"Address {hex(address)} out of bounds")
        print(f"Address {address} out of bounds")
        return(-1)
    
    # Get the 4 bytes
    bytes_data = memory[address:address + 4]

    # Convert each byte to its signed 8-bit binary representation
    signed_binaries = []
    for byte in bytes_data:
        # Convert byte to signed 8-bit binary
        signed_binary = format(byte & 0xFF, '08b')  # Mask to ensure it's in the range of 0-255
        signed_binaries.append(signed_binary)

    data = signed_binaries[3] + signed_binaries[2] + signed_binaries[1] + signed_binaries[0]


    # Output the signed binary representations
    return int(data,2)

@cocotb.coroutine
async def memory_read_dummy(dut):
    while True:
        await RisingEdge(dut.clk)
        dut.mem_valid_i.value = 0
        if (dut.mem_read_ready_o.value):
            value1 = get_data(dut.request_address.value.signed_integer)
            value2 = get_data(dut.request_address.value.signed_integer + 4)
            dut.memory_data_in[0].value = value1
            dut.memory_data_in[1].value = value2
            print(f"Addresses {hex(dut.request_address.value)} to {hex(dut.request_address.value + 3) }, have been read. Returned {value1}")
            print(f"Addresses {hex(dut.request_address.value + 4)} to {hex(dut.request_address.value + 4 + 3)}, have been read. Returned {value2}")
            await ClockCycles(dut.clk, random.randint(5,10)) # IMPORTANT, memory should take at least 1 cycle to answer
            dut.mem_valid_i.value = 1

@cocotb.coroutine
async def memory_write_dummy(dut):
    while True:
        await RisingEdge(dut.clk)
        if (dut.mem_write_valid_o.value and dut.mem_ready_i.value):
            dut.mem_ready_i.value = 0
            print(f"{dut.memory_data_out[0].value.signed_integer} has been written to address {hex(dut.request_address.value)}")
            print(f"{dut.memory_data_out[1].value.signed_integer} has been written to address {hex(dut.request_address.value + 4)}")
            await ClockCycles(dut.clk, random.randint(5,10)) # IMPORTANT, memory should take at least 1 cycle to answer
            dut.mem_ready_i.value = 1


@cocotb.test()
async def hs_npu_test(dut):
    """Test the hs_npu module"""

    # Generate a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_read_dummy(dut))
    cocotb.start_soon(memory_write_dummy(dut))

    # Resetting module
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    dut.mem_ready_i.value = 1

    dut.num_input_rows_in.value = 4;
    dut.num_input_columns_in.value = 4;
    dut.num_weight_rows_in.value = 4;
    dut.num_weight_columns_in.value = 8;

    dut.reuse_inputs_in.value = 0;
    dut.reuse_weights_in.value = 0;
    dut.save_outputs_in.value = 1;
    dut.use_bias_in.value = 1;
    dut.use_sum_in.value = 1;
    dut.shift_amount_in.value = 7;
    #dut.shift_amount_in.value = 0;
    dut.activation_select_in.value = 1;
    dut.base_address_in.value = 0;
    dut.result_address_in.value = 100;

    dut.exec_valid_i.value = 1;
    await ClockCycles(dut.clk, 1)
    dut.exec_valid_i.value = 0;


    await ClockCycles(dut.clk, 500)