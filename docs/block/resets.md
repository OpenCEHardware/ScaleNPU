# Reset Domains

The ScaleNPU operates on a single, shared reset signal. Upon power-up, it is essential to assert the reset signal for at least one full clock cycle to ensure proper initialization by clearing any residual values and resets the state machine of the memory ordering unit and memory interface to an idle state. 

Asserting this signal would also effectively stop any ongoing inference operations, regardless of the state. This means results can be lost or incomplete. 