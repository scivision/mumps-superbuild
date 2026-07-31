option(MUMPS_BUILD_TESTING "Build tests" ${MUMPS_IS_TOP_LEVEL})

option(MUMPS_find_static "Find static libraries for Lapack and Scalapack (default shared then static search)")

option(MUMPS_gemmt "GEMMT is recommended in MUMPS User Manual if available" ON)

option(MUMPS_avx512 "AVX512 VBMI instruction set accelerates adaptive precision with BLR" OFF)

option(MUMPS_parallel "parallel (use MPI)" ON)
option(MUMPS_scalapack "Use ScalaPACK to speed up the solution of linear systems" ON)

option(MUMPS_intsize64 "use 64-bit integers in C and Fortran")

option(MUMPS_gpu "MUMPS CUDA CPU support (see User Manual section 5.27)" OFF)
option(MUMPS_xkblas "use xKBLAS for GPU-accelerated BLAS" OFF)
if(MUMPS_xkblas AND NOT MUMPS_gpu)
  message(FATAL_ERROR "xKBLAS requires MUMPS_gpu=on")
endif()

option(MUMPS_scotch "use Scotch orderings")
if(MUMPS_scotch AND MUMPS_parallel)
  set(_ptscotch_default ON)
endif()
option(MUMPS_ptscotch "use PTScotch orderings" ${_ptscotch_default})
if(MUMPS_ptscotch AND NOT MUMPS_parallel)
  message(FATAL_ERROR "PTScotch requires MUMPS_parallel=on")
endif()

option(MUMPS_parmetis "use parallel METIS ordering")
option(MUMPS_metis "use sequential METIS ordering")
if(MUMPS_parmetis AND NOT MUMPS_parallel)
  message(FATAL_ERROR "parmetis requires MUMPS_parallel=on")
endif()

option(MUMPS_openmp "use OpenMP")

option(MUMPS_matlab "Matlab interface" OFF)
if(MUMPS_matlab AND MUMPS_parallel)
  message(FATAL_ERROR "Matlab requires -DMUMPS_parallel=off")
endif()


option(BUILD_SHARED_LIBS "Build shared libraries")

# fPIC flags are specified by MUMPS INSTALL file, so we do the same in CMake
include(CheckPIESupported)
check_pie_supported()
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(BUILD_SINGLE "Build single precision float32 real" ON)
option(BUILD_DOUBLE "Build double precision float64 real" ON)
option(BUILD_COMPLEX "Build single precision complex")
option(BUILD_COMPLEX16 "Build double precision complex")

option(MUMPS_ENABLE_RPATH "Enable RPATH in installed MUMPS libraries" OFF)


# --- other options

# this is for convenience of those needing scalapack, lapack, scotch, etc. built
if(MUMPS_IS_TOP_LEVEL AND CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set_property(CACHE CMAKE_INSTALL_PREFIX PROPERTY VALUE "${PROJECT_BINARY_DIR}/local")
endif()
