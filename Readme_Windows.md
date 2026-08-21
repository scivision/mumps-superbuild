# MUMPS on Windows

The Fortran library MUMPS builds on Windows just as well as other operating systems.
Methods of building MUMPS on Windows include:

* Windows Subsystem for Linux (WSL) -- recommended in general for scientific computing on Windows
* [Intel oneAPI Fortran compiler](https://www.intel.com/content/www/us/en/developer/tools/oneapi/oneapi-toolkit-download.html) with oneAPI C compiler `icx` or Visual Studio C compiler `cl`
* MSYS2 (GCC / GFortran)

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
cmake -G Ninja -B build -DCMAKE_MAKE_PROGRAM=C:/path/to/ninja.exe
```

## Compiler

Windows compilers known to work:

* Windows Subsystem for Linux (recommended in general for scientific computing on Windows)
* Intel [oneAPI](./Readme_oneapi.md)  -- requires oneAPI Toolkit for LAPACK, ScaLAPACK, and Intel MPI
* MSYS2

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

## Shared library

`BUILD_SHARED_LIBS=on` builds one DLL per library, which does not link with the Windows oneAPI
compilers. ifx emits Fortran module variables as COMMON symbols:
`CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS` cannot export those, and Fortran cannot import them without
an explicit `DLLIMPORT` attribute in the MUMPS sources. `dmumps` then fails to resolve the
`MUMPS_BUF_COMMON` and `MUMPS_LR_COMMON` module data that lives in `mumps_common`.

Build the component libraries static and bundle every object into a single `mumps.dll` instead:

```sh
cmake -B build -DBUILD_SHARED_LIBS=off -DMUMPS_dll=on

cmake --build build
```

Those references then stay inside the DLL. Only the C API -- `smumps_c`, `dmumps_c`,
`cmumps_c`, `zmumps_c` -- and the Fortran entry points are exported; PORD, METIS and the module
data remain internal. Link against `mumps.lib` as usual.
