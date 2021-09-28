#ifdef __cplusplus
#include<complex>
#define COMPLEX_T std::complex<double> 
extern "C"{
#else
#include <stdint.h>
#include <complex.h>
#define COMPLEX_T double complex
#endif 

void applyPauliX(COMPLEX_T*, int64_t, int64_t, bool);
void applyCX(COMPLEX_T*, int64_t, int64_t, int64_t, bool);
void applyHadamard(COMPLEX_T*, int64_t, int64_t, bool);
void applyRX(COMPLEX_T*, int64_t, int64_t, bool, double);
void applyRY(COMPLEX_T*, int64_t, int64_t, bool, double);

#ifdef __cplusplus
}
#endif