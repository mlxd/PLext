#include "pybind11/complex.h"
#include "pybind11/numpy.h"
#include "pybind11/stl.h"
#include <pybind11/pybind11.h>

#include "plext.h"
#include "jl_init.h"

namespace py = pybind11;

struct JL_Lifetime{
    JL_Lifetime() {
        init_julia(0, nullptr);
    };
    ~JL_Lifetime() {
        int ret_code = 0;
        shutdown_julia(ret_code);
    };
};

PYBIND11_MODULE(_PyPLext, m) {
    py::class_<JL_Lifetime>(m, "JL")
        .def(py::init<>());

    m.doc() = "PLext extension from Julia PackageCompiler";

    m.def("applyPauliX", &applyPauliX, "Apply PauliX gate");
    m.def("applyCX", &applyCX, "Apply CX gate");
    m.def("applyHadamard", &applyHadamard, "Apply Hadamard gate");
    m.def("applyRX", &applyRX, "Apply RX gate");
    m.def("applyRY", &applyRY, "Apply RY gate");

    m.def("applyPauliX", 
        [](py::array_t<std::complex<double>>& sv, int wire, bool inverse) {
            py::buffer_info numpyArrayInfo = sv.request();
            std::complex<double> *data_ptr = static_cast<std::complex<double> *>(numpyArrayInfo.ptr);
            applyPauliX(data_ptr, numpyArrayInfo.shape[0], wire, inverse);
    });
    m.def("applyHadamard", 
        [](py::array_t<std::complex<double>>& sv, int wire, bool inverse) {
            py::buffer_info numpyArrayInfo = sv.request();
            std::complex<double> *data_ptr = static_cast<std::complex<double> *>(numpyArrayInfo.ptr);
            applyHadamard(data_ptr, numpyArrayInfo.shape[0], wire, inverse);
    });
    m.def("applyCX", 
        [](py::array_t<std::complex<double>>& sv, int ctrl, int tgt, bool inverse) {
            py::buffer_info numpyArrayInfo = sv.request();
            std::complex<double> *data_ptr = static_cast<std::complex<double> *>(numpyArrayInfo.ptr);
            applyCX(data_ptr, numpyArrayInfo.shape[0], ctrl, tgt, inverse);
    });
    m.def("applyRX", 
        [](py::array_t<std::complex<double>>& sv, int wire, bool inverse, double param) {
            py::buffer_info numpyArrayInfo = sv.request();
            std::complex<double> *data_ptr = static_cast<std::complex<double> *>(numpyArrayInfo.ptr);
            applyRX(data_ptr, numpyArrayInfo.shape[0], wire, inverse, param);
    });
    m.def("applyRY", 
        [](py::array_t<std::complex<double>>& sv, int wire, bool inverse, double param) {
            py::buffer_info numpyArrayInfo = sv.request();
            std::complex<double> *data_ptr = static_cast<std::complex<double> *>(numpyArrayInfo.ptr);
            applyRX(data_ptr, numpyArrayInfo.shape[0], wire, inverse, param);
    });
}