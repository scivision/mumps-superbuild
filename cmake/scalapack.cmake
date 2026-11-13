# Make SCALAPACK_VENDOR match LAPACK_VENDOR

if(NOT DEFINED SCALAPACK_VENDOR)
  if(LAPACK_VENDOR STREQUAL "MKL")
    set(SCALAPACK_VENDOR MKL)
  elseif(NOT DEFINED LAPACK_VENDOR AND MUMPS_USE_MKL)
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

if(MUMPS_intsize64 AND NOT INT64 IN_LIST SCALAPACK_VENDOR)
  list(APPEND SCALAPACK_VENDOR INT64)
endif()

if(MUMPS_find_static)
  list(APPEND SCALAPACK_VENDOR STATIC)
endif()


# Scalapack options
set(BUILD_TESTING off)
foreach(_p IN ITEMS SINGLE DOUBLE COMPLEX COMPLEX16)
  set(SCALAPACK_BUILD_${_p} ${MUMPS_BUILD_${_p}})
endforeach()


# Check if 'scalapack_url' hasn't been defined by the user (with -D)
if(NOT DEFINED scalapack_url)
  string(JSON scalapack_url GET "${json}" "scalapack")
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM" OR CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  # oneAPI must use MKL, it will fail to build Netlib SCALAPACK
  set(FETCHCONTENT_TRY_FIND_PACKAGE_MODE OPT_IN)
endif()

set(_mumps_precs SINGLE DOUBLE COMPLEX COMPLEX16)
set(_scalapack_comps REAL32 REAL64 COMPLEX64 COMPLEX128)
set(_scalapack_fpa)
foreach(_prec _comp IN ZIP_LISTS _mumps_precs _scalapack_comps)
  if(MUMPS_BUILD_${_prec})
    list(APPEND _scalapack_fpa ${_comp})
  endif()
endforeach()

FetchContent_Declare(SCALAPACK
URL ${scalapack_url}
FIND_PACKAGE_ARGS COMPONENTS ${SCALAPACK_VENDOR} ${_scalapack_fpa}
)

FetchContent_MakeAvailable(SCALAPACK)

if(NOT TARGET SCALAPACK::SCALAPACK)
  add_library(SCALAPACK::SCALAPACK ALIAS scalapack)
endif()
