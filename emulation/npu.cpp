#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip> // For std::setw
#include <sstream>
#include <limits>  // For numeric limits

// Define the input size, hidden layers size, and output size
#define INPUT_SIZE 4
#define HIDDEN_SIZE 8
#define OUTPUT_SIZE 3
#define SYS_SIZE 8

// Color prints
#define RED     "\033[31m"
#define RESET   "\033[0m"

const int number_of_inputs = 3;
int current_input_size = 8;
int result_cycles = 0;
int input_cycles = 0;


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

int total_cycles = 0;


void check_overflow(int num) {
    // Define the limits for a signed short
    const short MIN_SHORT = std::numeric_limits<short>::min();  // -32768
    const short MAX_SHORT = std::numeric_limits<short>::max();  // 32767

    // Check if the value is within the range of a signed short
    if (num < MIN_SHORT || num > MAX_SHORT) {
        std::cerr << RED << "Alert: new_sum (" << num << ") does not fit within a signed short!\n" << RESET;
    }
}

class Gatekeeper {
public:
    int input;
    int output;
    int new_enable_cycles;
    int enable_cycles;
    bool start;
    bool new_start;
    int id;
    Gatekeeper* right_keeper;

    Gatekeeper() : input(-1), output(-1), new_enable_cycles(-1), enable_cycles(-1), start(false), new_start(nullptr), right_keeper(nullptr) {}

    // Cycle method
    void cycle() {
        if (new_start) {
            enable_cycles = new_enable_cycles;
        }
        if (enable_cycles > 0) {
            output = input;
            enable_cycles--;
            std::cout << "Keeper " << id << " sent output: "<< output << std::endl;
        } else {
            output = 0;
        }
        if (right_keeper != nullptr){
            right_keeper->new_start = start;
        }
        start = new_start;
    }
};

class MAC {
public:
    int current_input;
    int sum;
    int new_sum;
    int new_weight;
    bool* enable;
    int id;
    int result;
    int previous_input;
    int weight;

    // Pointers to two other MAC instances
    MAC* mac_right;
    MAC* mac_below;
    Gatekeeper* keeper;

    // Constructor to initialize parameters
    MAC() : weight(-1), new_weight(-1), enable(nullptr), previous_input(-1), current_input(-1), sum(-1), new_sum(-1), result(-1), mac_right(nullptr), mac_below(nullptr), id(-1) {}

    // Method to perform the MAC operation
    void beat() {

        check_overflow(new_sum);
        

        // If not in last column, pass the previous input to the right MAC
        if (mac_right != nullptr) {
            mac_right->current_input = previous_input;
        }

        // Perform MAC operation
        result = (weight * current_input) + sum;

        check_overflow(result);

        // If not in last row, pass the result as the sum to the MAC below
        if (mac_below != nullptr) {
            mac_below->new_sum = result;
            mac_below->new_weight = weight;
        } 
        else {
            keeper->input = result;
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

    outFile << "Total cycles:  "<< total_cycles << "\n";
    outFile << "Total input cycles:  "<< input_cycles << "\n";
    outFile << "Total result cycles:  "<< result_cycles << "\n";
    outFile.close();
    std::cout << "Total cycles:  "<< total_cycles << std::endl;
}

void systolic_beat(int beats, std::vector<std::vector<MAC>>& mac_matrix) {
    // Repeat the systolic beat `beats` times
    for (int b = 0; b < beats; b++) {
        total_cycles++;
        // Iterate over each MAC in the matrix row by row
        for (int i = 0; i < mac_matrix.size(); ++i) {
            for (int j = 0; j < mac_matrix[i].size(); ++j) {
                mac_matrix[i][j].beat();
            }
        }
    }
}

void cycle_keepers(Gatekeeper* gatekeepers, int size) {
    // Iterate over each Gatekeeper in the array
    for (int i = 0; i < size; ++i) {
        gatekeepers[i].cycle();
    }
}

void set_up_weights(const int* row_weights, std::vector<std::vector<MAC>>& mac_matrix){

    // Set weights to a value
    for (int j = 0; j < SYS_SIZE; j++)
    {
        mac_matrix[0][j].new_weight = row_weights[j];
    }

}

void set_inputs(const int inputs[SYS_SIZE][number_of_inputs], Gatekeeper* gatekeepers, std::vector<std::vector<MAC>>& mac_matrix){

    // Set inputs to a value
    for (int i = 0; i < SYS_SIZE; i++)
    {
        if (input_cycles - i >= 0){
            gatekeepers[i].input = inputs[i][input_cycles - i];
        }
    }
}

void push_input(Gatekeeper* gatekeepers, std::vector<std::vector<MAC>>& mac_matrix){
    // Set inputs to a value
    for (int i = 0; i < SYS_SIZE; i++)
    {
        mac_matrix[i][0].current_input = gatekeepers[i].output;
    }
}


int main() {


    // Define inputs
    // const int input_matrix[SYS_SIZE][SYS_SIZE] = {
    //     { 0,    0,    0,    0,    0,    0,    0,    0},
    //     { 0,    0,    0,    0,    0,    0,    0,    0},
    //     { 0,    0,    0,    0,    0,    0,    0,    0},
    //     { 0,    0,    0,    0,    0,    0,    0,    0},
    //     { 77,  96,    0,    0,    0,    0,    0,    0},
    //     { 0,  -36,  -26,    0,    0,    0,    0,    0},
    //     { 0,    0,   54,   29,    0,    0,    0,    0},
    //     { 0,    0,    0,  -72,  -93,    0,    0,    0}
    // };

    const int input_matrix[SYS_SIZE][number_of_inputs] = {
        { 77,  96,  96},
        {-36, -26, -26},
        { 54,  29,  29},
        {-72, -93, -93},
        { 77,  96,  96},
        {-36, -26, -26},
        { 54,  29,  29},
        {-72, -93, -93}
    };

    const int weights[SYS_SIZE][SYS_SIZE] = {
        {-58, -47, 43, -57, -53, 94, 34, 109},
        {-35, -128, -26, 53, -20, -5, 127, -81},
        {98, 10, 13, -15, -43, 69, 68, 37},
        {85, 37, -3, -115, -110, -98, 95, -14},
        {-58, -47, 43, -57, -53, 94, 34, 109},
        {-35, -128, -26, 53, -20, -5, 127, -81},
        {98, 10, 13, -15, -43, 69, 68, 37},
        {85, 37, -3, -115, -110, -98, 95, -14},
    };

    const int weights1[SYS_SIZE][SYS_SIZE] = {
        { 114,  -46,  114,   27,  -37,  -19, -126,   34 },
        { 125,  -39,  -19,   63,   -7,  114,   46,    0 },
        {  82, -118,   57, -127,  -48,   34,  -45,  -74 },
        { 108, -117, -101,  -93,   56, -105,   31,  -83 },
        { -28,  -57, -127,   92,  -47,  -13,  108,  -18 },
        {  13,  -16,  -73,   39,   72,  102,   67,  121 },
        {-124,    4,  -91,   24, -123, -114,  -40,   66 },
        {  68,   -7, -122,  111,  -89,  -99,  -73,   54 }
    };

    const int weights2[SYS_SIZE][SYS_SIZE] = {
        { -100,   47,  -30,   55,   32,  125, -122,   89 },
        {-113,  -22,   74,  126,   18,  -11,  -17,   13 },
        { -72,  109,  -98,   20,   68, -106,   88,  -52 },
        {   4,  -17,  -68, -102,  111, -123,  -37,  125 },
        { -65,   -7,  -98,  -50,  -39,   39,  -57,   70 },
        { -67,   84,  -49,   95,  -99,   81,   54,  -56 },
        { -36,   44,  -75,  -79, -115,  -39, -115,  -59 },
        { 118,   92,  107,   88,  -11,  -21,  112,  -35 }
    };

    const int weights3[SYS_SIZE][SYS_SIZE] = {
        { -95,   87,  -92,   41,   46,  118,   30, -114 },
        {  31,   26,  -19,   94,  119,  -65,  -81,  -32 },
        {  79,  -25,   16,   66,  -71, -119,  -17,  -32 },
        { -98,  -93,   76,  122,   79,  -64,   13,   25 },
        {   7,   87,   37,   61,  105,  -81,  105,   59 },
        {  76,  -67,  117,  116,  -28,   79,   82,   27 },
        {  39,  115,   54,    8,   70,  -43,   39,   24 },
        {  95,   27,   63,  -46, -122,   -5,   94,  111 }
    };

    const int weights4[SYS_SIZE][SYS_SIZE] = {
        {  98,  -67,  -61,   18,  125,   48,  -88, -118 },
        { 125,   13,  -20,   -7,   66,  108,  -61,  108 },
        { 100,   59, -120, -101,   80,  -94,  -14,  -35 },
        {-124,   31,   68,   25, -101,   29,  102,  -88 },
        { -70,   92,   26,  -92,  -23,  -97, -123,   -2 },
        {-119,  -41,  -31, -112,  -97, -124,   52,  -94 },
        {  36,   82, -109, -112, -117, -115,   -9,   87 },
        { 124,   66,   -1, -117,   12,  114,  -68, -122 }
    };
    
    Gatekeeper out_gatekeepers[SYS_SIZE];

    // Connect each Gatekeeper to the next one to the right
    for (int i = 0; i < SYS_SIZE - 1; ++i) {
        out_gatekeepers[i].right_keeper = &out_gatekeepers[i + 1];
    }

    // Initialize gatekeepers
    for (int i = 0; i < SYS_SIZE ; ++i) {
        out_gatekeepers[i].id = i;
        out_gatekeepers[i].new_enable_cycles = number_of_inputs;
    }

    Gatekeeper in_gatekeepers[SYS_SIZE];

    // Connect each Gatekeeper to the next one to the right
    for (int i = 0; i < SYS_SIZE - 1; ++i) {
        in_gatekeepers[i].right_keeper = &in_gatekeepers[i + 1];
    }

    // Initialize gatekeepers
    for (int i = 0; i < SYS_SIZE ; ++i) {
        in_gatekeepers[i].id = i;
        in_gatekeepers[i].new_enable_cycles = number_of_inputs;
    }

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
            else{
                mac_matrix[i][j].keeper = &out_gatekeepers[j];
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

    // //Test enable signal
    // for (int j = 0; j < SYS_SIZE; j++)
    // {
    //     mac_matrix[0][j].new_weight = 100;
    // }


    char ch;

    std::cout << "Press the spacebar to make beat. Press 'q' to quit." << std::endl;

    while (true) {
        ch = std::cin.get();  // Waits for a key press

        
        if (ch == ' ') { // Check if the key is a spacebar
            // Initialize MAC IDs for debugging
            if (total_cycles == SYS_SIZE){
                in_gatekeepers[0].new_start = 1;
            }else{
                in_gatekeepers[0].new_start = 0;
            }
            if (total_cycles == SYS_SIZE -1 + current_input_size){
                out_gatekeepers[0].new_start = 1;
            }else{
                out_gatekeepers[0].new_start = 0;
            }
            if(total_cycles >= SYS_SIZE -1 + current_input_size && total_cycles < 3*SYS_SIZE + number_of_inputs - 2){
                result_cycles++;
            }
            set_inputs(input_matrix,in_gatekeepers,mac_matrix);
            cycle_keepers(in_gatekeepers,SYS_SIZE);
            push_input(in_gatekeepers,mac_matrix);
            systolic_beat(1, mac_matrix);
            cycle_keepers(out_gatekeepers,SYS_SIZE);
            if (total_cycles >= SYS_SIZE && total_cycles <= (SYS_SIZE) + SYS_SIZE + number_of_inputs-1){
                input_cycles++;
            }
            createMatrixFile(mac_matrix, "mac_matrix_info.txt");
        } else if (ch == 'q') { // Check if the user wants to quit
            std::cout << "Exiting..." << std::endl;
            break;
        }
    }

    return 0;
};
