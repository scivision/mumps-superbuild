# Handle options for finding LAPACK

if(NOT DEFINED LAPACK_VENDOR AND MUMPS_USE_MKL)
  set(LAPACK_VENDOR MKL)
endif()

if(MUMPS_intsize64 AND NOT INT64 IN_LIST LAPACK_VENDOR)
  list(APPEND LAPACK_VENDOR INT64)
endif()

if(MUMPS_find_static)
  list(APPEND LAPACK_VENDOR STATIC)
endif()

if(Accelerate IN_LIST LAPACK_VENDOR AND INT64 IN_LIST LAPACK_VENDOR)
  # Accelerate's ILP64 symbols need linker aliases to be reachable from Fortran
  include(${CMAKE_CURRENT_LIST_DIR}/accelerate_ilp64.cmake)
else()
  find_package(LAPACK REQUIRED COMPONENTS ${LAPACK_VENDOR})
endif()
