cmake_minimum_required(VERSION 3.14)

project(PLext)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Add pybind11
include(FetchContent)
FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11.git
    GIT_TAG        v2.6.2
)
FetchContent_MakeAvailable(pybind11)

set(JL_PATH "${PROJECT_SOURCE_DIR}/jl")
set(PY_PATH "${PROJECT_SOURCE_DIR}/py")
set(ENV{JULIA_DEPOT_PATH} "${JL_PATH}/jl_depot")

set(JL_PKG "PLext.jl")
set(PY_PKG "PyPLext")

include_directories(BEFORE SYSTEM ${JL_PATH}/${JL_PKG})
add_custom_target(JLModule ALL)

add_custom_command(TARGET JLModule
    PRE_BUILD
    COMMAND julia --startup-file=no --project=${JL_PATH}/${JL_PKG} -e "using Pkg; Pkg.instantiate()" 
    COMMAND OUTDIR=${JL_PATH}/PLextCompiled PKGDIR=${JL_PATH}/${JL_PKG} julia --startup-file=no --project=${JL_PATH}/${JL_PKG}/build -e "using Pkg; Pkg.instantiate(); include(\"${JL_PATH}/${JL_PKG}/build/build.jl\")" 
    COMMENT "Build Julia shared extension library"
    VERBATIM
)

add_library (libplext SHARED IMPORTED)
set_property(TARGET libplext PROPERTY IMPORTED_LOCATION ${JL_PATH}/PLextCompiled/lib/libplext${CMAKE_SHARED_LIBRARY_SUFFIX})
add_dependencies(libplext JLModule)

include_directories(BEFORE SYSTEM ${JL_PATH}/PLextCompiled/include)
pybind11_add_module(PyPLext ${PY_PATH}/bindings/pyplext.cpp)
add_dependencies(PyPLext JLModule)

target_link_libraries(PyPLext PRIVATE libplext)
set_target_properties(PyPLext PROPERTIES CXX_VISIBILITY_PRESET hidden)