# Interrupts

The ScaleNPU implements a single interrupt to signal the CPU upon completion of a processing task. 
This interrupt mechanism informs the CPU only when the NPU has finished a previous query.
The interrupt must be handled and cleared by the CPU before initiating any new query, ensuring proper synchronization between the CPU and the NPU.