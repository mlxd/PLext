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

set(JL_PKG "PLext.jl")
set(PY_PKG "PyPLext")

include_directories(BEFORE SYSTEM ${JL_PATH}/${JL_PKG})
add_custom_target(JLModule ALL)
add_custom_command(TARGET JLModule
    PRE_BUILD
    COMMAND OUTDIR=${CMAKE_CURRENT_BINARY_DIR}/${JL_PATH} julia --startup-file=no --project=. -e "using Pkg; Pkg.instantiate()"
    COMMAND OUTDIR=${CMAKE_CURRENT_BINARY_DIR}/${JL_PATH} julia --startup-file=no --project=build -e "using Pkg; Pkg.instantiate(); include(\"build/build.jl\")"
    COMMENT "Build Julia shared extension library"
    VERBATIM
)

add_library (libplext SHARED IMPORTED)
set_property(TARGET libplext PROPERTY IMPORTED_LOCATION ${JL_PATH}/build/lib/libplext${CMAKE_SHARED_LIBRARY_SUFFIX})
add_dependencies(libplext JLModule)

include_directories(BEFORE SYSTEM ${CMAKE_CURRENT_BINARY_DIR}/Build/include)
pybind11_add_module(PyPLext ${PROJECT_SOURCE_DIR}/${PY_PATH}/bindings/pyplext.cpp)
add_dependencies(PyPLext JLModule)

target_link_libraries(PyPLext PRIVATE libplext)
set_target_properties(PyPLext PROPERTIES CXX_VISIBILITY_PRESET hidden)