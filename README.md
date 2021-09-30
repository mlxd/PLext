# PLext:
## or How I Learned to Stop Worrying and Just use Julia

As many of us know, (or at least those of us writing code with performance/efficiency as a necessity), Python can often by problematic when one needs blazing-fast code. An often used way to achieve this is to build a Python extension module using C, Cython, or (my favourite) Pybind11, amongst others. 

Pybind11 enables a user to develop a shared (dynamic) library in C++, with built in supports for Numpy conversion, and expose it as a loadable module in Python This is currently how we build [PennyLane Lightning ("lightning.qubit")](https://github.com/PennyLaneAI/pennylane-lightning/). This allows us to expose highly performant implementations of datastructures, algorithms, and even make use of multithreading via OpenMP --- again, all callable from Python.

Though, while the strengths of C++ enable us to overcome some of the weaknesses of Python (performant implementations and multithreading), C++ itself can often be challenging to work with, especially for new developers. Given Python supports a C API for extensions, we can also consider other languages that allow building libraries with a C calling interface.

Enter [Julia](). Julia is a JIT (just-in-time) compiled language, which means that functions are compiled on their first run, enabling great optimzation potential that cannot be gained in AOT (ahead-of-time) compiled languages. Julia has an extensive package ecosystem, many of which heavily target scientific computing problems. While JIT compilation has advantages in many cases, sometimes we wish to have access to an AOT compiled binary/library, as well as the many packages available in the ecosystem. This is one of those situations.

This project uses the Julia [PackageCompiler]() package to build a shared library, which is then bound and wrapped for import into Python. As we aim to build the package AOT, a Julia REPL will not be required to use the library, which can be installed as one would any other wheel. Though, it should be stated that a Julia runtime including libraries and tools will also be linked in here, as they are essential to use the required libraries.

## Structure

To keep things simple (or as simple as I can make them), we aim to replicate some of the behaviour of Lightning's `StateVector` class: taking a pointer from a Python managed Numpy array representing the state-vector, operating upon it using Julia defined functions, and veriyfing the operations manipulate the Numpy data directly. Simple, really!

To avoid playing with the C-API in both Numpy and Python I have opted to make use of Pybind11 to enable the wrapping of the generated library. By wrapping the Julia initialization and finalization methods in a C++ class we can make use of an RAII-like means to start and stop the Julia runtime. As the build-system for a multi-language project can become a challenge, I have opted to use CMake coupled with Python setuptools to generated the Julia library, thinly wrap the exposed methods in a Pybind11 interface, link everything nicely, and generate a wheel.

Since building wheels on my local machine will make it tough to share, I opted for the `manylinux2014_x86_64` image, and targetting `manylinux2_24_x86_64` as the wheel version (ie GLIBC v2.24 minimum). We manually install Julia onto the image (see the attached `Dockerfile`), and audit the generated wheel using `auditwheel` to include any required dependent shared libraries required to make use of the built extension.

## Issues

While a built of the Python module directly using CMake works (is importable and runnable with correct outputs), getting the binary to work from a wheel is a little more challenging. [Many packages](https://uwekorn.com/2019/09/15/how-we-build-apache-arrows-manylinux-wheels.html) have moved away from `pip` installing wheels due to the inherent difficulty in dealing with externally compiled libraries, and instead focus on `conda`, which more easily allows installing additional binaries, libraries and tools needed for a given package.

## Performance

No new package escapes the runtime performance checks. As this is a proof of concept, the runtime performance isn't expected to be on par with Lightning, though it should surpass bare Python/Numpy performance.