# Make SCALAPACK_VENDOR match LAPACK_VENDOR

if(NOT DEFINED SCALAPACK_VENDOR)
  if(LAPACK_VENDOR STREQUAL "MKL")
    set(SCALAPACK_VENDOR MKL)
  elseif(NOT DEFINED LAPACK_VENDOR AND
    (DEFINED ENV{MKLROOT} AND IS_DIRECTORY "$ENV{MKLROOT}"))
    set(SCALAPACK_VENDOR MKL)
    set(LAPACK_VENDOR MKL)
  endif()

  if(LAPACK_VENDOR STREQUAL "AOCL")
    set(SCALAPACK_VENDOR AOCL)
  endif()
endif()

if(MKL IN_LIST SCALAPACK_VENDOR)
  if(MUMPS_openmp)
    list(APPEND SCALAPACK_VENDOR OpenMP)
  endif()
endif()

if(MKL IN_LIST SCALAPACK_VENDOR)
  if(MUMPS_intsize64 AND NOT INT64 IN_LIST SCALAPACK_VENDOR)
    list(APPEND SCALAPACK_VENDOR INT64)
  endif()
endif()

if(MUMPS_find_static)
  list(APPEND SCALAPACK_VENDOR STATIC)
endif()


# build scalapack
set(SCALAPACK_BUILD_TESTING off)
set(SCALAPACK_BUILD_TESTS off)

# Check if 'scalapack_url' hasn't been defined by the user (with -D)
if(NOT DEFINED scalapack_url)
  string(JSON scalapack_url GET "${json}" "scalapack")
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM" OR CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  # oneAPI must use MKL, it will fail to build Netlib SCALAPACK
  set(FETCHCONTENT_TRY_FIND_PACKAGE_MODE OPT_IN)
endif()

FetchContent_Declare(SCALAPACK
URL ${scalapack_url}
FIND_PACKAGE_ARGS COMPONENTS ${SCALAPACK_VENDOR}
)

FetchContent_MakeAvailable(SCALAPACK)

if(NOT TARGET SCALAPACK::SCALAPACK)
  add_library(SCALAPACK::SCALAPACK ALIAS scalapack)
endif()
