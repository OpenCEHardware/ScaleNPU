#include <stdio.h>
#include <math.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


// Define the input size, hidden layers size, and output size
#define INPUT_SIZE 4
#define HIDDEN_SIZE 8
#define OUTPUT_SIZE 3

// Activation function: ReLU
uint8_t relu(short x) {
    short result = (x > 0) ? x : 0; 
    result = result >> 7;
    return result;
}

// Softmax function
void softmax(short* input, float* output, int length) {
    float max = input[0];
    float sum = 0.0;

    // Find the max value to avoid overflow during exponentiation
    for (int i = 1; i < length; i++) {
        if (input[i] > max) max = input[i];
    }

    // Exponentiate and sum the values
    for (int i = 0; i < length; i++) {
        output[i] = exp((input[i] - max));
        sum += output[i];
    }

    // Normalize the output
    for (int i = 0; i < length; i++) {
        output[i] /= sum;
    }
}

// Function to perform matrix multiplication and add biases
void dense_layer1(const int8_t *inputs, const int8_t *weights, const int8_t *biases, short *output, int hidden_size , int input_size) {
    for (int j = 0; j < hidden_size; j++) {
        output[j] = biases[j]; // Start with the bias
        for (int i = 0; i < input_size; i++) {
            // Perform the dot product and add it to the bias
            output[j] += inputs[i] * weights[i * hidden_size + j];
        }
    }
}

void dense_layer2(const short *inputs, const int8_t *weights, const int8_t *biases, short *output, int hidden_size , int input_size) {
    for (int j = 0; j < hidden_size; j++) {
        output[j] = biases[j]; // Start with the bias
        for (int i = 0; i < input_size; i++) {
            // Perform the dot product and add it to the bias
            output[j] += inputs[i] * weights[i * hidden_size + j];
        }
    }
}

void dense_out(const short *inputs, const int8_t *weights, const int8_t *biases, short *output, int hidden_size , int input_size) {
    for (int j = 0; j < hidden_size; j++) {
        output[j] = biases[j]; // Start with the bias
        for (int i = 0; i < input_size; i++) {
            // Perform the dot product and add it to the bias
            output[j] += inputs[i] * weights[i * hidden_size + j];
        }
    }
}

int main() {

    // Define inputs (scaled to 16-bit short)
    const int8_t input_matrix[4 * INPUT_SIZE] = {
        77, -36, 54, -72,
        96, -26, 29, -93,
        95, -37, 33, -78,
        110, 32, -59, -122,
    };
        
    const int8_t dense1_weights[INPUT_SIZE * HIDDEN_SIZE]= {
        85, 37, -3, -115, -110, -98, 95, -14,
        98, 10, 13, -15, -43, 69, 68, 37,
        -35, -128, -26, 53, -20, -5, 127, -81,
        -58, -47, 43, -57, -53, 94, 34, 109
    };

    const int8_t dense1_biases[HIDDEN_SIZE] = {
    -128, -91, 10, -89, 10, 10, 127, 10
    };

    const int8_t dense2_weights[HIDDEN_SIZE * HIDDEN_SIZE]= {
        74, -91, -82, 37, -49, 126, -57, -59,
        78, -8, -53, -124, 127, 55, 107, 47,
        101, -10, -75, 65, -25, -74, -53, -14,
        88, -68, -106, -4, -16, -80, 71, -38,
        49, -114, 32, 42, -16, -123, -128, -118,
        66, 68, -1, -35, 96, 70, 110, -19,
        -124, 78, 19, -51, -61, -98, -79, -9,
        56, -57, -103, 82, 88, -37, 44, 62
    };

    const int8_t dense2_biases[HIDDEN_SIZE] = {
    -128, 41, 18, -23, 127, 86, 119, 15
    };

    const int8_t output_weights[HIDDEN_SIZE * OUTPUT_SIZE]  = {
        16, -110, -90,
        -51, -96, 94,
        94, -34, -84,
        -108, 47, -70,
        63, -127, 33,
        -128, 3, -39,
        127, -103, -27,
        -109, -119, -113
    };

    const int8_t output_biases[OUTPUT_SIZE] = {
    -128, -12, 127
    };

    for (int i = 0; i < 4; i++)
    {
        
        int8_t input[INPUT_SIZE];
        for (int j = 0; j < INPUT_SIZE; j++) {
            input[j] = input_matrix[i*INPUT_SIZE + j];
        }

        printf("Input %d: ",i);
        for (int k = 0; k < INPUT_SIZE; k++) {
            printf("%d, ", input[k]);
        }
        printf("\n");

        // Define arrays to hold intermediate results
        short hidden1[HIDDEN_SIZE];
        short hidden2[HIDDEN_SIZE];
        short output[OUTPUT_SIZE];
        int32_t probabilities[OUTPUT_SIZE];

        // Forward pass through the network
        dense_layer1(input, dense1_weights, dense1_biases, hidden1,HIDDEN_SIZE,INPUT_SIZE);

        printf("Dense1 %d: ",i);
        for (int k = 0; k < HIDDEN_SIZE; k++) {
            printf("%d, ", hidden1[k]);
        }
        printf("\n");
    
        // Apply ReLU activation on hidden1
        for (int i = 0; i < HIDDEN_SIZE; i++) {
            hidden1[i] = relu(hidden1[i]);
        }

        printf("Activation1 %d: ",i);
        for (int k = 0; k < HIDDEN_SIZE; k++) {
            printf("%d, ", hidden1[k]);
        }
        printf("\n");

        
        dense_layer2(hidden1, dense2_weights, dense2_biases, hidden2, HIDDEN_SIZE, HIDDEN_SIZE);

        printf("Dense2 %d: ",i);
        for (int k = 0; k < HIDDEN_SIZE; k++) {
            printf("%d, ", hidden2[k]);
        }
        printf("\n");

        // Apply ReLU activation on hidden2
        for (int i = 0; i < HIDDEN_SIZE; i++) {
            hidden2[i] = relu(hidden2[i]);
        }

        printf("Activation2 %d: ",i);
        for (int k = 0; k < HIDDEN_SIZE; k++) {
            printf("%d, ", hidden2[k]);
        }
        printf("\n");

        // Output layer (dense)
        dense_layer2(hidden2, output_weights, output_biases, output, OUTPUT_SIZE, HIDDEN_SIZE);
        printf("Output %d: ",i);
        for (int k = 0; k < OUTPUT_SIZE; k++) {
            printf("%d, ", output[k]);
        }
        printf("\n\n\n");

    //     // Apply softmax activation to the output
    //     //softmax(output, probabilities, OUTPUT_SIZE);

    //     // Print the output probabilities
    //     // printf("Output probabilities: \n");
    //     // for (int i = 0; i < OUTPUT_SIZE; i++) {
    //     //     printf("Class %d: %f\n", i, output[i]);
    //     // }

    }

    return 0;
}