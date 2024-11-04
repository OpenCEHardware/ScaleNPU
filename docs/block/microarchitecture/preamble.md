### Microarchitecture Overview

The following sections detail each of the NPU modules, explaining their functionality and the flow of data through the architecture. If this is your first time reading the document, we recommend following the sections in order, as they build upon each other in terms of concepts and implementation, making it easier to grasp the next module after understanding the previous one.

---

## Basics and Core Concepts

This section provides foundational knowledge for understanding the NPU design. If you are already familiar with NPUs, feel free to skip ahead.

The NPU’s primary goal is to accelerate inference for pretrained neural networks, focusing on fast and efficient matrix multiplication. Matrix multiplication, as you might know, involves multiplying and summing the elements of two matrices. In hardware, this is achieved through a systolic array of interconnected Multiply-Accumulate units (MACs). In machine learning, the result is then combined with a bias value and passed through an activation function, which forms the core of the NPU's computation. To manage memory limitations and ensure efficient computation, we also use symmetric power-of-2 quantization, which discards bits by shifting them left.

Beyond computation, the NPU manages **storage** and **control**:

- **Storage** handles the retrieval and internal storage of inputs, weights, and biases, as well as how results are sent back to memory.
- **Control** coordinates data movement within the NPU and manages communication and instructions from the CPU.

### NPU Operation Flow

The NPU generally follows these steps:

1. **Configuration**: The CPU fills Control Status Registers with configuration data, including an "init" register that starts the process. Before this the CPU must have loaded inputs, weights, biases, and sums into memory.

2. **Verification**: The NPU checks the provided data. If everything is valid, it proceeds to the next stage.

3. **Loading Data**:
   - **Weights, Inputs, Biases, and Sums**: First, weights are loaded into the NPU’s internal storage. Then process repeats for inputs, biases, and sums. Control Status Registers can be configured to skip one or more of these steps. Inputs are often not loaded from memory but instead come from the results of previous run, allowing internal transfer between memory modules.

4. **Computation**:
   - **Weight Loading**: Weights are loaded into the systolic array.
   - **Input Flow**: Once the systolic array is full, weights are locked, and inputs flow through the array in a specific order, which matches the order in which results are produced.

5. **Result Generation**: After a certain number of cycles, the NPU begins producing results while still processing some inputs, as detailed in the systolic array section. Results are stored and ordered as they are generated.

6. **Result Storage**: Depending on the CSR configuration, results may be stored back into memory. If storing is disabled, the process simply concludes. Intermediate results may be skipped to avoid the slow access to memory, which is typically useful only for debugging.

7. **Completion**: When the process is completed the NPU sends a IRQ signal to the CPU. This includes the singal itself and a exit code value is set to a specific CSR, so that the CPU knows if the execution concluded successfully.

It’s important to note that the NPU itself is agnostic to the larger inference process—it simply performs matrix multiplication and applies functions. Software manages the higher-level logic. A single NPU operation represents just one layer of the neural network, so for a multilayer perceptron, the process must be repeated for each layer. CSRs can also disable activation functions, quantization, and biases, effectively turning the NPU into a standard matrix multiplier.

!!! note

    You might wonder how the NPU handles matrix multiplications that exceed the size of the systolic array. The short answer is, it doesn’t; software needs to divide large matrices into smaller chunks. Fortunately, matrix multiplication can be split into multiple smaller multiplications. The NPU includes "sum" values specifically for this purpose. While technically these sums could be managed by adjusting the bias values, they are provided separately for simplicity.

