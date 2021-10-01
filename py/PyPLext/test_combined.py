import numpy as np
import pennylane_lightning as pl
import PyPLext as plext
from timeit import default_timer as timer

#Ensure Julia is initialised
jl = plext.JL()

# Create params array and defined number of iterations
num_passes = 10
params = np.random.rand(num_passes)

header = "qubits,sim," + ",".join(["t"+str(i) for i in range(num_passes)]) + ",t_total"

for num_qubits in range(6, 27, 2):
    # Create initial |000> state
    data_l = np.ascontiguousarray([0]*(2**num_qubits), dtype=np.complex128)
    data_p = np.ascontiguousarray([0]*(2**num_qubits), dtype=np.complex128)
    data_l[0] = 1
    data_p[0] = 1

    sv = pl.lightning_qubit_ops.StateVectorC128(data_l)
    print(f"{num_qubits},Lightning,", end="")
    start_l_total = timer()
    for j in range(num_passes):
        start_l_it = timer()
        for i in range(num_qubits):
            sv.Hadamard([i], False, [])
            sv.RX([i], False, [params[j]])
            sv.CNOT([i, (i+1)%num_qubits], False, [])
            sv.RY([i], False, [params[j]])
            sv.CNOT([(i+1)%num_qubits, (i+2)%num_qubits], False, [])
        end_l_it = timer()
        print(f"{end_l_it - start_l_it},", end="")
    end_l_total = timer()
    print(f"{end_l_total - start_l_total}")
    print(f"{num_qubits},PLext,", end="")
    start_p_total = timer()
    for j in range(num_passes):
        start_p_it = timer()
        for i in range(num_qubits):
            plext.applyHadamard(data_p, i, False)
            plext.applyRX(data_p, i, False, params[j])
            plext.applyCX(data_p, i, (i+1)%num_qubits, False)
            plext.applyRY(data_p, i, False, params[j])
            plext.applyCX(data_p, (i+1)%num_qubits, (i+2)%num_qubits, False)
        end_p_it = timer()
        print(f"{end_p_it - start_p_it},", end="")
    end_p_total = timer()
    print(f"{end_p_total - start_p_total}")
