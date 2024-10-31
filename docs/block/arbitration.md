# Arbitration, Fairness, QoS, and Forward Progress Guarantees

The ScaleNPU operates as a single slave module within a system, meaning it doesn’t manage multiple traffic classes or arbitration directly. Instead, it relies on the AXI protocol for memory access, where arbitration and resource sharing are handled by the AXI interconnect. This interconnect manages how memory requests from the ScaleNPU are prioritized and ensures fair access among all system modules.

## Arbitration and Fairness

The ScaleNPU delegates arbitration to the AXI interconnect, which could use round-robin or priority-based policies based on system configuration. This setup ensures that the ScaleNPU's memory requests are fairly managed alongside other AXI-connected masters, with no need for the ScaleNPU itself to enforce fairness.

- **Arbitration and Fairness**: Managed by the AXI interconnect, not the ScaleNPU.  
- **Configurability**: AXI settings determine arbitration behavior.

## Quality-of-Service (QoS)

Any QoS or priority configurations are also managed by the AXI interconnect. This allows the system to prioritize the ScaleNPU’s memory transactions if needed but is configured at the system level rather than within the ScaleNPU.

- **QoS Control**: Assigned via AXI, influencing transaction prioritization among connected modules.

## Forward Progress

The AXI protocol ensures forward progress by preventing deadlock and livelock, guaranteeing that all requests are eventually serviced as long as the interconnect adheres to AXI standards.

- **Guarantees**: Deadlock prevention and transaction progress are enforced by AXI protocol compliance, not by the ScaleNPU.