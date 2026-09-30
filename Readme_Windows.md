# MUMPS on Windows

The Fortran library MUMPS builds on Windows just as well as other operating systems.
Methods of building MUMPS on Windows include:

* Windows Subsystem for Linux (WSL) - GCC GFortran, LLVM Flang
* [Intel oneAPI Fortran compiler](https://www.intel.com/content/www/us/en/developer/tools/oneapi/oneapi-toolkit-download.html) with oneAPI C compiler `icx` or Visual Studio C compiler `cl`
* MSYS2 - GCC GFortran, LLVM Flang

CMake and Ninja can be installed on native Windows via WinGet:

```pwsh
winget install Ninja-build.Ninja
winget install Kitware.CMake
```

Build and test MUMPS with the CMake preset workflow:

```sh
cmake --workflow default
```

If desired to use MSVC Visual Studio `cl` as the C compiler with oneAPI Fortran compiler `ifx`, use workflow:

```sh
cmake --workflow msvc
```

### Troubleshooting generator

> CMake Error: CMake was unable to find a build program corresponding to "Ninja". CMAKE_MAKE_PROGRAM is not set.

then add the Ninja filepath to Windows environment variable `CMAKE_PROGRAM_PATH`.
Alternatively, tell CMake the full path to Ninja like:

```sh
cmake -G Ninja -B build -DCMAKE_MAKE_PROGRAM=path/to/ninja.exe
```

## CMake configure output

```sh
cmake -G Ninja -B build -DBUILD_SINGLE=yes -DBUILD_DOUBLE=yes -DBUILD_COMPLEX=yes -DBUILD_COMPLEX16=yes
```

To speed up MUMPS build and reduce binary size, feel free to omit (set to `no`) unneeded precisions in the command above.

Intel oneAPI MKL LAPACK and SCALAPACK are used.

## Build

```sh
cmake --build build
```

With the default options, under the `${MUMPS_BINARY_DIR}/lib` directory this results in library binaries for Windows oneAPI / Visual Studio:

```
dmumps.lib
smumps.lib
mumps_common.lib
pord.lib
```

or with WSL / MSYS2

```
libdmumps.a
libsmumps.a
libmumps_common.a
libpord.a
```

## Self test

Optionally, run self-tests:

```sh
ctest --test-dir build
```

## MinGW patch

GCC Gfortran on Windows in general has issues with msmpi "mpif.h" as used by MUMPS in parallel builds.
We implemented a
[patch](./cmake/mumps_mingw_mpi.patch)
using code from MSYS2 msmpi package to address this issue.
We've asked the MUMPS dev team to switch MUMPS to MPI-2 `use mpi` from MPI-1 `include 'mpif.h'` since that header is deprecated by MPI-4.1 standard.
