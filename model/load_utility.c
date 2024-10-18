#include <stdio.h>
#include <stdlib.h>

// const short weights[4][8] = {
//     {-58, -47, 43, -57, -53, 94, 34, 109},
//     {-35, -128, -26, 53, -20, -5, 127, -81},
//     {98, 10, 13, -15, -43, 69, 68, 37},
//     {85, 37, -3, -115, -110, -98, 95, -14}
// };

// const short weights[8][8] = {
//     {56, -57, -103, 82, 88, -37, 44, 62},
//     {-124, 78, 19, -51, -61, -98, -79, -9},
//     {66, 68, -1, -35, 96, 70, 110, -19},
//     {49, -114, 32, 42, -16, -123, -128, -118},
//     {88, -68, -106, -4, -16, -80, 71, -38},
//     {101, -10, -75, 65, -25, -74, -53, -14},
//     {78, -8, -53, -124, 127, 55, 107, 47},
//     {74, -91, -82, 37, -49, 126, -57, -59}
// };

const short weights[8][8] = {
    {-109, -119, -113, 0, 0, 0, 0, 0},
    {127, -103, -27, 0, 0, 0, 0, 0},
    {-128, 3, -39, 0, 0, 0, 0, 0},
    {63, -127, 33, 0, 0, 0, 0, 0},
    {-108, 47, -70, 0, 0, 0, 0, 0},
    {94, -34, -84, 0, 0, 0, 0, 0},
    {-51, -96, 94, 0, 0, 0, 0, 0},
    {16, -110, -90, 0, 0, 0, 0, 0},
};

const short inputs[4] [8] = {
    0,0,0,0, 77, -36, 54, -72,
    0,0,0,0, 96, -26, 29, -93,
    0,0,0,0, 95, -37, 33, -78,
    0,0,0,0, 110, 32, -59, -122,
};

int main() {
    int* npu_data = malloc(sizeof(int) * 16); // allocate memory for 8 packed 4-byte integers
    if (npu_data == NULL) {
        printf("Memory allocation failed\n");
        return 1;
    }

    for (int row = 0; row < 8; ++row) {
        for (int col = 0; col < 1; ++col) {
            // Packing 4 weights into a single 32-bit int (little-endian)
            int packed_value = 0;
            for (int byte = 0; byte < 4; ++byte) {
                packed_value |= ((unsigned char)weights[row][col * 4 + byte] & 0xFF) << (byte * 8);
            }
            npu_data[row * 2 + col] = packed_value;
        }
    }

    // for (int row = 0; row < 8; ++row) {
    //     // Packing 4 weights into a single 32-bit int (little-endian)
    //     int packed_value = 0;
    //     for (int byte = 0; byte < 4; ++byte) {
    //         packed_value |= ((unsigned char)weights[row][byte] & 0xFF) << (byte * 8);
    //     }
    //     npu_data[row] = packed_value;
    // }
    

    // Printing the packed values for verification
    for (int i = 0; i < 16; ++i) {
        printf("npu_data_3[%d] = 0x%08X\n", i, npu_data[i]);
    }

    free(npu_data);
    return 0;
}
