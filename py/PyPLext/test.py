import numpy as np
import PyPLext as plext

#Ensure Julia is initialised
jl = plext.JL()

# Create |000> state
num_qubits=25
data = np.ascontiguousarray([0]*(2**num_qubits), dtype=np.complex128)
data[0] = 1

#Apply Julia defined gates to Numpy data
num_passes = 10
params = np.random.rand(num_passes)

for j in range(num_passes):
    print(f"Pass {j}")
    for i in range(num_qubits):
        print(f"Applying Hadamard({i})")
        plext.applyHadamard(data, i, False)
        print(f"Applying RX({i}, {params[j]})")
        plext.applyRX(data, i, False, params[j])
        print(f"Applying CX({i}, {(i+1)%num_qubits})")
        plext.applyCX(data, i, (i+1)%num_qubits, False)
        print(f"Applying RY({i}, {params[j]})")
        plext.applyRY(data, i, False, params[j])
        print(f"Applying CX({(i+1)%num_qubits}, {(i+2)%num_qubits})")
        plext.applyCX(data, (i+1)%num_qubits, (i+2)%num_qubits, False)

#print(data)