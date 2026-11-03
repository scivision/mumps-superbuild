# LAPACK / ScaLAPACK options

The underlying "LAPACK" and ScaLAPACK linear algebra interfacs are available from several vendors.
By default, the generic LAPACK library "lapack" is searched for.

To specify a particular LAPACK library, use CMake configure variable "LAPACK_VENDOR" and "SCALAPACK_VENDOR" using one of the following vendors:

* AOCL  [AMD Optimizing CPU Libraries](https://www.amd.com/en/developer/aocl.html)
* Atlas [Automatically Tuned Linear Algebra Software](https://math-atlas.sourceforge.net/)
* MKL  [Intel oneMKL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html): requires [oneMKL >= 2021.3](https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2023-2/cmake-config-for-onemkl.html)
* Accelerate [Apple Accelerate](https://developer.apple.com/accelerate/) (macOS only)
* Netlib [Netlib LAPACK](https://www.netlib.org/lapack/)  (default)
* OpenBLAS [OpenBLAS](https://www.openblas.net/)

For example, to use OpenBLAS:

```sh
cmake -DLAPACK_VENDOR=OpenBLAS
```

To use AMD AOCL:

```sh
cmake -DLAPACK_VENDOR=AOCL
```

To use Apple Accelerate:

```sh
cmake -DLAPACK_VENDOR=Accelerate
```

Accelerate provides BLAS and the legacy LAPACK 3.2.1 Fortran interface, which covers everything
MUMPS calls. Two caveats:

* Accelerate has no GEMMT extension, so leave `MUMPS_gemmt=off` (the default off MKL).
* `MUMPS_intsize64=on` is not supported with Accelerate. Accelerate's ILP64 entry points are
  exported only as `<name>$NEWLAPACK$ILP64` symbols, which a Fortran compiler cannot name. They
  can be reached by aliasing them onto the usual `<name>_` symbols with the Apple linker's
  `-alias_list` option, e.g. via
  [accelerate-lapack](https://github.com/lepus2589/accelerate-lapack). If you do that, the alias
  list must be generated from the *same* macOS SDK that the Fortran compiler links against, or the
  link fails on symbols present in one but not the other. Homebrew gfortran has its SDK baked in;
  check it with `gfortran -v 2>&1 | tr ' ' '\n' | grep sysroot`.

### Accelerate threading

Accelerate's BLAS/LAPACK threading is not selected by an environment variable, and
`VECLIB_MAXIMUM_THREADS` does not change how many threads it uses. The actual control is a C API,
declared in the vecLib header `thread_api.h` (macOS >= 15.0):

```c
enum BLAS_THREADING : unsigned int {
    BLAS_THREADING_MULTI_THREADED  = 0,  // Accelerate decides how many threads to use
    BLAS_THREADING_SINGLE_THREADED,      // single threaded only
};
int BLASSetThreading(const enum BLAS_THREADING threading);
enum BLAS_THREADING BLASGetThreading(void);
```

`BLAS_THREADING_MULTI_THREADED` is already the default, so nothing needs enabling. On Apple silicon
"Accelerate decides" currently means one thread: measured on an Apple M5 Pro (macOS 26.6,
Accelerate LAPACK 3.12.0) a DGEMM stays at 1.0 cores and ~410-440 GFLOP/s from m=1000 through
m=12000, and switching to `BLAS_THREADING_SINGLE_THREADED` only costs ~7%. The matrix coprocessor
is shared per core cluster, so one thread already saturates it.

Consequence for MUMPS: there is no Accelerate BLAS threading to turn on, and all shared-memory
parallelism comes from `MUMPS_openmp=on`, i.e. MUMPS's own OpenMP regions. Those help the solve
phase substantially and the factorization very little.

If a future Accelerate does multithread, note that `BLASSetThreading` sets a **thread-local**
variable. Calling it once from the main thread would not affect BLAS calls issued from MUMPS's
OpenMP worker threads; it would have to be called inside each worker (from within an
`!$omp parallel` region) to take effect.

Optionally, hint the location the LAPACK library like:

```sh
cmake -DLAPACK_ROOT=/path/to/lapack
```

CMake searches for Intel oneMKL if environment variable `MKLROOT` is set.

## GEMMT symmetric matrix-matrix multiplication

For MUMPS &ge; 5.2.0, GEMMT symmetric matrix-matrix multiplication is recommended by the MUMPS User Guide if available.
By default GEMMT is ON if with Intel MKL and may be enabled / disabled like:

```sh
cmake -DMUMPS_gemmt=off
```

## Build LAPACK

If the compiler doesn't have LAPACK and SCALAPACK, first build and install them:

```sh
cmake -S scripts -B scripts/build -DCMAKE_INSTALL_PREFIX=~/mylibs
cmake --build scripts/build -t scalapack

# mumps
cmake -B build -DCMAKE_PREFIX_PATH=~/mylibs
cmake --build build
```

Since oneAPI comes with LAPACK and ScaLAPACK with oneAPI in oneMKL, there is no need to build them with oneAPI + oneMKL.
