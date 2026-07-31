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

## ScalaPACK

ScalaPACK is only used for `MUMPS_parallel=on`.
ScalaPACK can be omitted with MUMPS &ge; 5.7.0 by option:

```sh
cmake -DMUMPS_scalapack=off
```

To control whether to first look for Scalapack and only if needed automatically build ScalaPACK,
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

MUMPS can take profit from avx512 vbmi (Vector Byte Manipulation Instructions) instruction set to speed-up compression and decompression when using BLR with adaptive precision.
This option `MUMPS_avx512vbmi=true` will activate this feature (if your compiler handles it). There is no execution test, so you can enable
it on a machine that doesn't handle this instruction set (but you wont be able to run this build of mumps locally).
Default is avx512 vbmi OFF.

```sh
cmake -DMUMPS_avx512vbmi=on
```


---

[Matlab](./Readme_matlab.md) can use MUMPS library as well.
