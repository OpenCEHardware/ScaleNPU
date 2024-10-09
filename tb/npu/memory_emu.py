import struct

# Define the matrices and vectors
matrixB_data = [
    [-58, -47, 43, -57, -53, 94, 34, 109],
    [-35, -128, -26, 53, -20, -5, 127, -81],
    [98, 10, 13, -15, -43, 69, 68, 37],
    [85, 37, -3, -115, -110, -98, 95, -14]
]

# matrixB_data = [
#     [0xC6, 0xD1, 0x2B, 0xC7, 0xCB, 0x5E, 0x22, 0x6D],
#     [0xDD, 0x80, 0xE6, 0x35, 0xEC, 0xFB, 0x7F, 0xAF],
#     [0x62, 0x0A, 0x0D, 0xF1, 0xD5, 0x45, 0x44, 0x25],
#     [0x55, 0x25, 0xFD, 0x8D, 0x92, 0x9E, 0x5F, 0xF2]
# ]

matrixA_data = [
    [77, -36, 54, -72],
    [96, -26, 29, -93],
    [95, -37, 33, -78],
    [110, 32, -59, -122]
]

bias_vector = [-128, -91, 10, -89, 10, 10, 127, 10]  # 32-bit integers
sums_vector = [0, 0, 0, 0, 0, 0, 0, 0]  # 32-bit integers

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


print(memory)


# Function to retrieve 32-bit data from memory
def get_data(address):
    # Fetch 4 consecutive bytes from the memory starting at the given address
    if address + 3 >= len(memory):
        raise ValueError("Address out of bounds")
    
    # Get the 4 bytes
    bytes_data = memory[address:address + 4]

    print(bytes_data)

    # Convert each byte to its signed 8-bit binary representation
    signed_binaries = []
    for byte in bytes_data:
        # Convert byte to signed 8-bit binary
        print(byte)
        signed_binary = format(byte & 0xFF, '08b')  # Mask to ensure it's in the range of 0-255
        signed_binaries.append(signed_binary)
        print(signed_binary)

    print(type(signed_binaries[0]))

    data = signed_binaries[3] + signed_binaries[2] + signed_binaries[1] + signed_binaries[0]
    print(data) 

    # Output the signed binary representations
    return int(data,2)


# Example usage: retrieve the first 32-bit value from the bias vector
address_bias = len(matrixB_data) * len(matrixB_data[0]) + len(matrixA_data) * len(matrixA_data[0])
address_bias = 48
bias_value = get_data(address_bias)

# Extract the original 4 bytes

print(f"First bias value (32-bit) at address {address_bias}: {bias_value}")
print(f"First bias value (32-bit) at address {address_bias}: {hex(bias_value)}")

