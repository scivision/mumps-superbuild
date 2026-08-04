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

## Visual Studio generator

Ninja is the smoother path and is what the presets use. If Visual Studio project files are
wanted, select the Fortran toolset and let CMake pick MSVC `cl` for C:

```sh
cmake -B build -G "Visual Studio 17 2022" -A x64 -T fortran=ifx

cmake --build build --config Release
```

Three things differ from the Ninja generator:

* MSBuild does not preprocess `*.F` / `*.F90`, whereas CMake preprocesses them itself for the
  Ninja Fortran module dependency scanner. `cmake/compilers.cmake` adds `/fpp` for this
  generator; without it the build fails with misleading errors #5082, #6333, #6417 and #5508.
* Targets built only from `$<TARGET_OBJECTS:>` are linked by link.exe rather than ifx, and
  MSBuild's `LIB` does not cover the Intel Fortran runtime. `cmake/compilers.cmake` adds the
  oneAPI compiler `lib` directory to the linker search path.
* ALL_BUILD is a `.vcxproj` and cannot depend on a Fortran `.vfproj`, so a Fortran target that
  no other target links is never built. Give such targets `LINKER_LANGUAGE C`.
