# MUMPS sparse solver

[![ci](https://github.com/scivision/mumps-superbuild/actions/workflows/ci.yml/badge.svg)](https://github.com/scivision/mumps-superbuild/actions/workflows/ci.yml)
[![ci_windows](https://github.com/scivision/mumps-superbuild/actions/workflows/ci_windows.yml/badge.svg)](https://github.com/scivision/mumps-superbuild/actions/workflows/ci_windows.yml)
[![ci_build](https://github.com/scivision/mumps-superbuild/actions/workflows/ci_build.yml/badge.svg)](https://github.com/scivision/mumps-superbuild/actions/workflows/ci_build.yml)
[![oneapi-linux](https://github.com/scivision/mumps-superbuild/actions/workflows/oneapi-linux.yml/badge.svg)](https://github.com/scivision/mumps-superbuild/actions/workflows/oneapi-linux.yml)

MUMPS is a Fortran library by the
MUMPS Technologies team co-founded by Jean-Yves L'Excellent from Graal / ROMA
with optional C interfaces for MPI and/or OpenMP parallel
(or serial `cmake --workflow nompi`) solving of sparse linear systems of equations.
This repository provides a CMake superbuild project using CMake's built-in
[FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)
module for MUMPS and optional MUMPS dependencies including ScaLAPACK, ParMETIS, and Scotch.
This CMake superbuild downloads the unmodified source tarfile from mumps-solver.org and builds.

Optional support for CUDA GPA and xKBLAS GPU-accelerated BLAS is
[available](./Readme_options.md).

CMake builds MUMPS quickly and more conveniently than the original Makefiles. CMake allows easy reuse of MUMPS in external projects via any of:

* CMake [FetchContent](https://gist.github.com/scivision/2ad002ed26589783f1522160da4d27d1)
* build MUMPS, `cmake --install`, then [find_package(MUMPS CONFIG REQUIRED)](https://gist.github.com/scivision/1ea2d19011c165b39b15ccb95d54f451)
* CMake ExternalProject_Add (similar to FetchContent example)

[MUMPS CeCILL-C license](https://mumps-solver.org/index.php?page=dwnld#license)
is distinct from this CMake superbuild license.
The MUMPS Team typically make new
[releases](https://mumps-solver.org/index.php?page=dwnld#cl)
each year.

Many compilers and systems are supported by CMake build system on Windows, MacOS and Linux.
Static (default) or Shared `cmake -DBUILD_SHARED_LIBS=on` MUMPS builds are supported.

Virtually all contemporary compilers work, including GCC, Clang/Flang, oneAPI, NVHPC, AOCC, Cray, CUDA, etc.

By default PORD ordering is used.
[Scotch, METIS, and parMETIS ordering](./Readme_ordering.md)
can be used and will be automatically built if needed.

Several [LAPACK vendors](./Readme_LAPACK.md) are supported.

The MUMPS discrete solver project is distinct from this CMake superbuild.
See the
[MUMPS Users email list](https://listes.ens-lyon.fr/sympa/subscribe/mumps-users)
and
[MUMPS User Guide](https://mumps-solver.org/index.php?page=doc)
for any questions about MUMPS itself.

## Shared Libraries and Runtime Dependency Resolution

When building shared libraries with `-DBUILD_SHARED_LIBS=on`, the installed MUMPS libraries include relative RPATH entries (`$ORIGIN`, `$ORIGIN/..`) that allow runtime dependencies to be resolved relative to the installation location.
This ensures correct resolution of MUMPS dependencies (BLAS, MPI, Scotch, etc.) without requiring environment setup through modules or `LD_LIBRARY_PATH`, especially when MUMPS is used as a transitive dependency of another library.

## MUMPS build library files

One-step configure and build with CMake workflow using default options:

```sh
cmake --workflow --preset build
```

The `${MUMPS_BINARY_DIR}/lib` directory contains library binaries.


* libdmumps.a (real64)
* libsmumps.a (real32)
* libmumps_common.a (common MUMPS routines)
* libpord.a  (PORD library)

If using Intel oneAPI on
[Windows](./Readme_Windows.md),
correspondingly:

* dmumps.lib
* smumps.lib
* mumps_common.lib
* pord.lib

### MUMPS build options

Numerous MUMPS [build options are available](./Readme_options.md).

The default precision is float64 and float32.
To build all precisions including complex64, complex128 do:

```sh
cmake -Bbuild -DBUILD_SINGLE=on -DBUILD_DOUBLE=on -DBUILD_COMPLEX=on -DBUILD_COMPLEX16=on

cmake --build build
```

The headers and library are optionally installed to an install prefix:

```sh
cmake -Bbuild --install-prefix /path/to/install/mumps

cmake --install build
```

If `-DMUMPS_parallel=no` was set, additional helper libraries are built in place of linking MPI libraries:

* libmpiseq_fortran.a
* libmpiseq_c.a

The libmpiseq.a file isn't used directly by this project, but it for compatibility with other build systems that may expect a libmpiseq file.

These libraries can be linked into C, C++, Fortran, etc. programs, or even be used with appropriate interfaces from [Matlab](./Readme_matlab.md) and Python
[PyMUMPS](https://pypi.org/project/PyMUMPS/)
and
[python-mumps](https://pypi.org/project/python-mumps/).

## Offline sources for MUMPS, Scalapack, and/or other prerequisites

For offline / cached MUMPS source usage, the user can download & specify a local MUMPS source archive like:

```sh
cmake -Dversion="5.9.0" -Dcache=./cache -P scripts/DownloadMUMPSsource.cmake

cmake -Bbuild -DMUMPS_url=./cache/MUMPS_5.9.0.tar.gz
```

The MUMPS version can be omitted to download a recent version, default location "./cache".

```sh
cmake -P scripts/DownloadMUMPSsource.cmake
```

In general, the
[FETCHCONTENT_SOURCE_DIR_<uppercaseName>](https://cmake.org/cmake/help/latest/module/FetchContent.html#variable:FETCHCONTENT_SOURCE_DIR_%3CuppercaseName%3E)
variable can be used to specify a local source directory for MUMPS and MUMPS prerequisites (ScaLAPACK, ParMETIS, METIS, Scotch, xKBLAS, win_flex_bison).
It's only designed for DIRECTORY usage, not for compressed archives, so the user must extract the source archive to a directory first.

### MUMPS offline source examples

Example for MUMPS source that's extracted to a directory (say to workaround a bug in a specific version of MUMPS):

```sh
curl -o ./mumps-5.9.0.tar.gz -L https://mumps-solver.org/MUMPS_5.9.0.tar.gz

tar -xf ./mumps-5.9.0.tar.gz

cmake -DFETCHCONTENT_SOURCE_DIR_MUMPS_UPSTREAM="./MUMPS_5.9.0" -Bbuild
```

Example for MUMPS source that's downloaded as a compressed archive:

```sh
curl -o ./mumps-5.9.0.tar.gz -L https://mumps-solver.org/MUMPS_5.9.0.tar.gz

cmake -DMUMPS_url="./mumps-5.9.0.tar.gz" -Bbuild
```

### MUMPS prerequisite offline source examples

Example for library that's extracted to a directory (say to workaround a bug in a specific version of ScaLAPACK):

```sh
curl -o ./scalapack.tar.gz -L https://github.com/Reference-ScaLAPACK/scalapack/archive/8ea5880a448cd24622dff95fd1b7394c31e61bda.tar.gz

tar -xf ./scalapack.tar.gz

cmake -DFETCHCONTENT_SOURCE_DIR_SCALAPACK="./scalapack-8ea5880a448cd24622dff95fd1b7394c31e61bda" -Bbuild
```

MUMPS prerequisites can also be specified with offline source archives.

Example for library that's downloaded as a compressed archive:

```sh
curl -o ./scalapack.tar.gz -L https://github.com/Reference-ScaLAPACK/scalapack/archive/8ea5880a448cd24622dff95fd1b7394c31e61bda.tar.gz

cmake -Dscalapack_url="./scalapack.tar.gz" -Bbuild
```

Archive URLs can be specified for any of the MUMPS prerequisites, for example:

```
scalapack_url
parmetis_url
metis_url
scotch_url
xkblas_url
win_flex_bison_url
```

## Target dependency graph

To see the CMake target dependency graph do:

```sh
cmake -B build

cmake --build build -t graphviz
```

and view the SVG file build/graphviz/MUMPS.svg via a web browser or SVG viewer.

## Self test and examples

Optionally, run self-tests:

```sh
ctest --test-dir build
```

To build the example, first "install" the MUMPS package-the default install location is under the MUMPS build/local directory:

```sh
cmake --workflow default
cmake --install build

cd ./example
cmake --workflow default
```

## Using binary libraries

### From CMake

The install ships a CMake package. Point `CMAKE_PREFIX_PATH` at the install prefix and link the
arithmetic targets you need:

```cmake
find_package(MUMPS CONFIG REQUIRED)
target_link_libraries(myapp PRIVATE MUMPS::DMUMPS)   # or MUMPS::MUMPS for every arithmetic built
```

```sh
cmake -B build -DCMAKE_PREFIX_PATH=~/.local
```

Consumers that enable only C are supported; the package does not require the consumer to have a
Fortran compiler or OpenMP.

Linking the MUMPS binaries into a user-program is project-dependent.
An example using the examples in this project with GNU GCC, using the "mpicxx" MPI compiler wrapper:

```sh
mpicxx ./example/d_example.cpp -I./build/local/include -L./build/local/lib -ldmumps -lmumps_common -lpord -lscalapack -llapack -lblas -lgfortran
```

If `-DMUMPS_parallel=no` was used to build MUMPS, instead do:

```sh
g++ ./example/d_example.cpp -I./build/local/include -L./build/local/lib -ldmumps -lmumps_common -lpord -llapack -lblas -lmpiseq_fortran -lmpiseq_c -lgfortran
```
