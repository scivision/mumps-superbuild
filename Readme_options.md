# MUMPS options

By default PORD ordering is used.
For large matrix systems,
[Scotch, METIS, parMETIS ordering](./Readme_ordering.md)
can be used for possible performance enhancements.

## Precision

The default precision is float64 and float32.

```cmake
option(BUILD_SINGLE "Build single precision real" ON)
option(BUILD_DOUBLE "Build double precision real" ON)
option(BUILD_COMPLEX "Build single precision complex")
option(BUILD_COMPLEX16 "Build double precision complex")
```

## GPU

Optionally CUDA GPU acceleration can be enabled with:

```cmake
cmake -DMUMPS_gpu=on
```

XKBlas GPU-accelerated BLAS can be enabled with:

```cmake
cmake -DMUMPS_xkblas=on -DMUMPS_gpu=on
```

## Integer size

The default integer size is 32-bit.
64-bit integers can be enabled with:

```cmake
cmake -DMUMPS_intsize64=on
```

HOWEVER, this requires all libraries INCLUDING MPI to be compiled with 64-bit integers.
Otherwise, the program will crash at runtime with MPI errors.
For example, oneAPI / oneMPI work, but default system installs of OpenMPI / MPICH will generally fail--the user will need to specially compile an MPI library with 64-bit integers.

## ScaLAPACK

ScaLAPACK is only used for `MUMPS_parallel=on`.
ScaLAPACK can be omitted with MUMPS &ge; 5.7.0 by option:

```sh
cmake -DMUMPS_scalapack=off
```

To control whether to first look for Scalapack and only if needed automatically build ScaLAPACK,
Optionally, specify the location of Scalapack with CMake option `-DSCALAPACK_ROOT=/path/to/scalapack"

```sh
cmake -DSCALAPACK_ROOT=/path/to/scalapack
```

To instead force build of Scalapack, do:

```sh
cmake -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER
```

## MPI

For systems where MPI, BLACS and SCALAPACK are not available, or where non-parallel execution is suitable, the default `MUMPS_parallel=true` can be disabled at CMake configure time by option:

```sh
cmake -DMUMPS_parallel=false
```

## MUMPS version selection

The MUMPS version defaults to a recent release.
For reproducibility, benchmarking and other purposes, one may select the version of MUMPS to build like:

```sh
cmake -B build -DMUMPS_UPSTREAM_VERSION=5.8.0
```

The source URL may be directly specified, which may be a local file or remote URL:

```sh
cmake -B build -DMUMPS_url=/path/to/mumps.zip
```

## OpenMP

OpenMP can make MUMPS slower in certain situations.
Try with and without OpenMP to see which is faster for your situation.
Default is OpenMP OFF.

```sh
cmake -DMUMPS_openmp=on
```

## AVX512

MUMPS 5.9.0 and newer can take profit from AVX-512-VBMI
[Vector Byte Manipulation Instructions](https://www.singlestore.com/blog/a-programmers-perspective/)
instruction set to speed-up compression and decompression when using BLR with adaptive precision.
The CMake configure option `DMUMPS_avx512vbmi=true` will activate this feature if the compiler and CPU are capable.
The CMake configuration will fail if the compiler or CPU doesn't support the requested AVX-512-VBMI instruction set.

```sh
cmake -DMUMPS_avx512vbmi=on
```

Compilers known to work with MUMPS AVX-512-VBMI with Intel AVX-512-VBMI capable CPUs include:

* [GCC &ge; 5](https://gcc.gnu.org/gcc-5/changes.html#x86)
* Clang
* Intel oneAPI
* NVIDIA HPC SDK (NVHPC)

The "Ice Lake" (2019) and later Intel workstations and server CPUs generally support AVX-512-VBMI.
Mobile (laptop) CPUs may not support the AVX-512-VBMI features, one has to try it to see if it works.
It is reported that some AMD CPUs support AVX-512-VBMI, but we have not tested this yet with MUMPS or the AMD AOCL compiler.
ARM CPUs at the time of writing don't support AVX-512 in general.

---

[Matlab](./Readme_matlab.md) can use MUMPS library as well.
