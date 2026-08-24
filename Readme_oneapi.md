# Intel oneAPI

MUMPS CMake requires
[oneMKL >= 2021.3](https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2025-2/cmake-config-for-onemkl.html).
The
[Intel oneMKL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html)
library that provides LAPACK and SCALAPACK are required.

We handle the compile and link options as
[specified by Intel MPI](https://www.intel.com/content/www/us/en/docs/mpi-library/developer-guide-linux/2021-16/ilp64-support.html).
We link "libmpi_ilp64" as a workaround to a
[long-standing issue](https://discourse.cmake.org/t/problem-enabling-64-bit-fortran-compilation-on-windows-using-intel-oneapi-with-cmake-on-windows/4541)
with Intel MPI and CMake.

## Linux

Use the oneAPI
[oneapi-vars.sh](https://www.intel.com/content/www/us/en/docs/oneapi/programming-guide/2026-1/use-the-setvars-and-oneapi-vars-scripts-with-linux.html)
to enable oneAPI.

If the oneAPI compiler is not found by CMake after running the oneapi-vars.sh, try hinting the compiler location like:

```sh
cmake -B build -DCMAKE_C_COMPILER=$CMPLR_ROOT/bin/icx -DCMAKE_Fortran_COMPILER=$CMPLR_ROOT/bin/ifx
```

## Windows

One may use Intel oneAPI on Windows via WSL.
This procedure described native oneAPI on Windows instead.

Be sure to use the oneAPI command prompt.
Under Windows Start menu look for "Intel oneAPI command prompt for Intel 64 for Visual Studio".
Alternatively, use the oneAPI
[oneapi-vars.bat](https://www.intel.com/content/www/us/en/docs/oneapi/programming-guide/2025-1/use-the-setvars-script-with-windows.html).

If the oneAPI compiler is not found by CMake, try hinting its location from oneAPI Command Prompt (do not enclose with quotes):

```sh
cmake -G Ninja -B build -DCMAKE_C_COMPILER=%CMPLR_ROOT%/bin/icx.exe -DCMAKE_Fortran_COMPILER=%CMPLR_ROOT%/bin/ifx.exe

cmake --build build
```

## Visual Studio generator

If Visual Studio generator is desired:

```sh
cmake -Bbuild -G "Visual Studio 18 2026" -T fortran=ifx
# or
cmake -Bbuild -G "Visual Studio 17 2022" -T fortran=ifx
```

In any case, build like:

```sh
cmake --build build --config Release
```

Optionally, test:

```sh
ctest --test-dir build -C Release -V
```
