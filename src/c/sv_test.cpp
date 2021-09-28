#include <cmath>
#include <complex>
#include <cstdlib>
#include <iostream>
#include <vector>

extern "C"{
#include "julia_init.h"
}

#include "plext.h"

int main(int argc, char *argv[]){
    int ret_code;
    init_julia(argc, argv);

    int num_qubits = 4;
    int num_elements = (1<<num_qubits);
    std::vector<std::complex<double>> sv(num_elements);

    sv[0] = 1;
    for(int i=0; i < num_elements; i++ ){
        std::cout << sv[i] << std::endl;
    }
    std::cout << std::endl;

    for(int i = 1; i < 10000; i ++){
        applyHadamard(sv.data(), num_elements, (i%(num_qubits)), false);
        applyCX(sv.data(), num_elements, (i%(num_qubits)), ((i-1)%(num_qubits)), false);
        applyPauliX(sv.data(), num_elements, (i%(num_qubits)), false);
        applyRY(sv.data(), num_elements, (i%(num_qubits)), false, static_cast<double>(i/M_PI));
        applyRX(sv.data(), num_elements, (i%(num_qubits)), false, static_cast<double>(i/M_PI));
    }

    for(int i=0; i < num_elements; i++ ){
        std::cout << sv[i] << std::endl;
    }
    std::cout << std::endl;

    shutdown_julia(ret_code);
    return ret_code;
}