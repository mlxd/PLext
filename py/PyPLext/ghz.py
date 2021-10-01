import numpy as np
import PyPLext as plext

#Ensure Julia is initialised
jl = plext.JL()

# Create 12 qubit |0> state
num_qubits=4
data = np.ascontiguousarray([0]*(2**num_qubits), dtype=np.complex128)
data[0] = 1

print(f"Initial SV:={data}")

plext.applyHadamard(data, 0, False)
for i in range(1, num_qubits):
        plext.applyCX(data, i-1, (i), False)

print(f"Final SV:={data}")
