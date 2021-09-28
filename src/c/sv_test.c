#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "julia_init.h"
#include "plext.h"

int main(int argc, char *argv[]){
    int ret_code;
    init_julia(argc, argv);

    int num_qubits = 4;
    int num_elements = (1<<num_qubits);
    double complex* sv = (double complex*) malloc(sizeof(double complex)*(num_elements));

    sv[0] = 1;
    for(int i=0; i < num_elements; i++ ){
        printf("%f + i%f\n", creal(sv[i]), cimag(sv[i]));
    }
    printf("\n");
    applyHadamard(sv, num_elements, 1, false);
    applyHadamard(sv, num_elements, 2, false);
    applyHadamard(sv, num_elements, 3, false);
    //applyHadamard(sv, num_elements, 4, false);
    for(int i=0; i < num_elements; i++ ){
        printf("%f + i%f\n", creal(sv[i]), cimag(sv[i]));
    }
    free(sv);
    shutdown_julia(ret_code);
    return ret_code;
}