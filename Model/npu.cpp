#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip> // For std::setw
#include <sstream>

// Define the input size, hidden layers size, and output size
#define INPUT_SIZE 4
#define HIDDEN_SIZE 8
#define OUTPUT_SIZE 3
#define SYS_SIZE 8


// const short ZERO [SYS_SIZE][SYS_SIZE] = {
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0},
//     { 0,    0,    0,    0,    0,    0,    0,    0}
// };

int cycle = 0;

class MAC {
public:
    // Public members: accessible from outside the class
    short current_input;
    short sum;
    short new_sum;
    short new_weight;
    bool* enable;
    int id;
    short result;
    short previous_input;
    short weight;

    // Pointers to two other MAC instances
    MAC* mac_right;
    MAC* mac_below;

    // Constructor to initialize parameters
    MAC() : weight(-1), new_weight(-1), enable(nullptr), previous_input(-1), current_input(-1), sum(-1), new_sum(-1), result(-1), mac_right(nullptr), mac_below(nullptr), id(-1) {}

    // Method to perform the MAC operation
    void beat() {

        // If not in last column, pass the previous input to the right MAC
        if (mac_right != nullptr) {
            mac_right->current_input = previous_input;
        }

        // Perform MAC operation
        result = (weight * current_input) + sum;


        // If not in last row, pass the result as the sum to the MAC below
        if (mac_below != nullptr) {
            mac_below->new_sum = result;
            mac_below->new_weight = weight;
        }

        // Change weight after calculation if enabled
        if (*enable) {
            weight = new_weight;
        }

        // Update previous input for the next cycle
        previous_input = current_input;
        sum = new_sum;
    }

};

// Function to create a text file with the matrix information
void createMatrixFile(const std::vector<std::vector<MAC>>& mac_matrix, const std::string& filename) {
    std::ofstream outFile(filename);
    if (!outFile) {
        std::cerr << "Error creating file: " << filename << std::endl;
        return;
    }

    // Iterate through the matrix
    for (size_t i = 0; i < mac_matrix.size(); ++i) {

        // Print header for the matrix
        for (const auto& mac : mac_matrix[i]) {
            outFile << "MAC " << mac.id << std::setw(15 - std::to_string(mac.id).length()) << "| ";
        }
        outFile << "\n";

        // Print previous inputs for the current row
        for (const auto& mac : mac_matrix[i]) {
            outFile << "Input  = " << mac.current_input << std::setw(10 - std::to_string(mac.current_input).length()) << "| ";
        }
        outFile << "\n";

        // Print results for the current row
        for (const auto& mac : mac_matrix[i]) {
            outFile << "Sum    = " << mac.sum << std::setw(10 - std::to_string(mac.sum).length()) << "| ";
        }
        outFile << "\n";

        // Print results for the current row
        for (const auto& mac : mac_matrix[i]) {
            outFile << "Enable = " << *mac.enable << std::setw(10 - std::to_string(*mac.enable).length()) << "| ";
        }
        outFile << "\n";

        // Print results for the current row
        for (const auto& mac : mac_matrix[i]) {
            outFile << "Weight = " << mac.weight << std::setw(10 - std::to_string(mac.weight).length()) << "| ";
        }
        outFile << "\n";

        // Print results for the current row
        for (const auto& mac : mac_matrix[i]) {
            outFile << "Result = " << mac.result << std::setw(10 - std::to_string(mac.result).length()) << "| ";
        }
        outFile << "\n";

        // Print a separator line for the current row
        outFile << std::string(20 * mac_matrix[i].size(), '-') << "\n";
    }

    outFile << "Did cycle  "<< cycle << "\n";
    outFile.close();
    std::cout << "Did cycle  "<< cycle << std::endl;
}

void systolic_beat(int beats, std::vector<std::vector<MAC>>& mac_matrix) {
    // Repeat the systolic beat `beats` times
    for (int b = 0; b < beats; b++) {
        cycle++;
        // Iterate over each MAC in the matrix row by row
        for (int i = 0; i < mac_matrix.size(); ++i) {
            for (int j = 0; j < mac_matrix[i].size(); ++j) {
                mac_matrix[i][j].beat();
            }
        }
    }
    createMatrixFile(mac_matrix, "mac_matrix_info.txt");
}

void set_up_weights(const short* row_weights, std::vector<std::vector<MAC>>& mac_matrix){

    // Set weights to a value
    for (int j = 0; j < SYS_SIZE; j++)
    {
        mac_matrix[0][j].new_weight = row_weights[j];
    }

}

void push_input(const short inputs[SYS_SIZE][SYS_SIZE], std::vector<std::vector<MAC>>& mac_matrix, int column){

    // Set inputs to a value
    for (int i = 0; i < SYS_SIZE; i++)
    {
        mac_matrix[i][0].current_input = inputs[i][column];
    }

}


int main() {


    // Define inputs
    const short input_matrix[SYS_SIZE][SYS_SIZE] = {
        { 0,    0,    0,    0,    0,    0,    0,    0},
        { 0,    0,    0,    0,    0,    0,    0,    0},
        { 0,    0,    0,    0,    0,    0,    0,    0},
        { 0,    0,    0,    0,    0,    0,    0,    0},
        { 77,   0,    0,    0,    0,    0,    0,    0},
        { 0,  -36,    0,    0,    0,    0,    0,    0},
        { 0,    0,   54,    0,    0,    0,    0,    0},
        { 0,    0,    0,  -72,    0,    0,    0,    0}
    };

    const short weights[SYS_SIZE][SYS_SIZE] = {
        {-58, -47, 43, -57, -53, 94, 34, 109},
        {-35, -128, -26, 53, -20, -5, 127, -81},
        {98, 10, 13, -15, -43, 69, 68, 37},
        {85, 37, -3, -115, -110, -98, 95, -14},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0}
    };
    
    // Create an SYS_SIZE x SYS_SIZE matrix of MAC objects
    std::vector<std::vector<MAC>> mac_matrix(SYS_SIZE, std::vector<MAC>(SYS_SIZE));

    bool global_enable = true;

    // Initialize MAC IDs for debugging
    for (int i = 0; i < SYS_SIZE; ++i) {
        for (int j = 0; j < SYS_SIZE; ++j) {
            mac_matrix[i][j].id = (i * SYS_SIZE + j); // Unique ID for each MAC
            mac_matrix[i][j].enable = &global_enable;
        }
    }

    // Connect MAC units
    for (int i = 0; i < SYS_SIZE; ++i) {
        for (int j = 0; j < SYS_SIZE; ++j) {
            // Connect to the right MAC if it exists
            if (j + 1 < SYS_SIZE) {
                mac_matrix[i][j].mac_right = &mac_matrix[i][j + 1];
            }

            // Connect to the below MAC if it exists
            if (i + 1 < SYS_SIZE) {
                mac_matrix[i][j].mac_below = &mac_matrix[i+1][j];
            }
        }
    }

    // // Print the connections for debugging
    // for (int i = 0; i < SYS_SIZE; ++i) {
    //     for (int j = 0; j < SYS_SIZE; ++j) {
    //         std::cout << "MAC " << mac_matrix[i][j].id << " is connected to: ";
    //         if (mac_matrix[i][j].mac_right) {
    //             std::cout << "Right MAC ID " << mac_matrix[i][j].mac_right->id << ", ";
    //         } else {
    //             std::cout << "No Right, ";
    //         }

    //         if (mac_matrix[i][j].mac_below) {
    //             std::cout << "Below MAC ID " << mac_matrix[i][j].mac_below->id;
    //         } else {
    //             std::cout << "No Below";
    //         }

    //         std::cout << std::endl;
    //     }
    // }

    // Set first column of input to 0
    for (int i = 0; i < SYS_SIZE; i++)
    {
        mac_matrix[i][0].current_input = 0;
    }
    // Set  first row of sum to 0
    for (int j = 0; j < SYS_SIZE; j++)
    {
        mac_matrix[0][j].sum = 0;
        mac_matrix[0][j].new_sum = 0;
    }

    // Initial systolic setup
    for (int i = 0; i < SYS_SIZE; i++)
    {
        set_up_weights(weights[i],mac_matrix);
        systolic_beat(1, mac_matrix);
    }
    // for (int i = 0; i < SYS_SIZE - INPUT_SIZE; i++)
    // {
    //     short zero[SYS_SIZE] = {0,0,0,0,0,0,0,0};
    //     set_up_weights(zero,mac_matrix);
    //     systolic_beat(1, mac_matrix);
    // }
    

    global_enable = false;

    // //Test enable
    // for (int j = 0; j < SYS_SIZE; j++)
    // {
    //     mac_matrix[0][j].new_weight = 100;
    // }
    

    char ch;

    std::cout << "Press the spacebar to make beat. Press 'q' to quit." << std::endl;

    int column = 0; 

    while (true) {
        ch = std::cin.get();  // Waits for a key press

        
        if (ch == ' ') { // Check if the key is a spacebar
            // Initialize MAC IDs for debugging
            push_input(input_matrix,mac_matrix,column);
            systolic_beat(1, mac_matrix);
            column++;
        } else if (ch == 'q') { // Check if the user wants to quit
            std::cout << "Exiting..." << std::endl;
            break;
        }
    }

    return 0;
};
