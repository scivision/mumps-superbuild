# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindSCALAPACK
-------------

authored by SciVision: www.scivision.dev

Finds SCALAPACK libraries for MKL, OpenMPI and MPICH.
Intel MKL relies on having environment variable MKLROOT set, typically by sourcing
mklvars.sh beforehand.

This module does NOT find LAPACK or MPI, therefore if not using MKL, the user project must first do

.. code-block:: cmake

  find_package(LAPACK REQUIRED)
  find_package(MPI REQUIRED COMPONENTS Fortran)


COMPONENTS
^^^^^^^^^^

``INT64``
  64-bit integers for indexing. Note the default 32-bit integers is what most users want and what
  most libraries have.
  Note: due to the non-interface design of Scalapack, the integer bitness isn't verified in this
  FindSCALAPACK module.

``MKL``
  Intel MKL for MSVC, oneAPI, GCC.
  Working with IntelMPI (default Window, Linux), MPICH (default Mac) or OpenMPI (Linux only).
``TBB``
  MKL only: Intel MPI + TBB (default is sequential)
``OpenMP``
  MKL only: use OpenMP (default is sequential)

``AOCL``
  AMD ScaLAPACK fork of Netlib ScaLAPACK.
  Requires LAPACK AOCL
  https://www.amd.com/en/developer/aocl/scalapack.html

``STATIC``
  Library search default on non-Windows is shared then static. On Windows default search is static first.
  Specifying STATIC component searches for static libraries only.


Precision components: default REAL64, can be any combination of these.

``REAL32``
  32-bit real precision (single precision)

``REAL64``
  64-bit real precision (double precision)

``COMPLEX64``
  64-bit complex precision (single precision)

``COMPLEX128``
  128-bit complex precision (double precision)

Result Variables
^^^^^^^^^^^^^^^^

``SCALAPACK_FOUND``
  SCALapack libraries were found
``SCALAPACK_<component>_FOUND``
  SCALAPACK <component> specified was found
``SCALAPACK_LIBRARIES``
  SCALapack library files
``SCALAPACK_INCLUDE_DIRS``
  SCALapack include directories


References
^^^^^^^^^^

* MKL link-line advisor: https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-link-line-advisor.html
#]=======================================================================]

include(CheckSourceCompiles)

#===== functions

function(scalapack_check _result path)

# some OpenMPI builds need -pthread
find_package(Threads)

set(CMAKE_TRY_COMPILE_TARGET_TYPE "EXECUTABLE")

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_LINK_OPTIONS)
set(CMAKE_REQUIRED_INCLUDES ${SCALAPACK_INCLUDE_DIR} ${LAPACK_INCLUDE_DIRS})

set(CMAKE_REQUIRED_LIBRARIES ${path}
LAPACK::LAPACK MPI::MPI_Fortran ${CMAKE_THREAD_LIBS_INIT}
)
# we need LAPACK::LAPACK for SCALAPACK to link for these checks


string(MAKE_C_IDENTIFIER "${path}" _id)

# determine precisions to check; if none requested, default to real64 so that at least one compile check runs
set(_check_precisions)
foreach(_c IN ITEMS REAL32 REAL64 COMPLEX64 COMPLEX128)
  if(${_c} IN_LIST SCALAPACK_FIND_COMPONENTS)
    list(APPEND _check_precisions ${_c})
  endif()
endforeach()
if(NOT _check_precisions)
  set(_check_precisions REAL64)
endif()

set(precs s d)
set(bits 32 64)

foreach(_prec _bit IN ZIP_LISTS precs bits)
  if(NOT REAL${_bit} IN_LIST _check_precisions)
    continue()
  endif()

  check_source_compiles(Fortran
    "program test
    use, intrinsic :: iso_fortran_env
    implicit none
    real(kind=real${_bit}), external :: p${_prec}lamch
    integer :: i
    real(kind=real${_bit}) :: r
    r = p${_prec}lamch(i, 'E')
    end program"
    SCALAPACK_REAL${_bit}_FOUND_${_id}
  )

  if(SCALAPACK_REAL${_bit}_FOUND_${_id})
    set(SCALAPACK_REAL${_bit}_FOUND true CACHE BOOL "Found SCALAPACK real${_bit}")
  endif()
endforeach()


set(precs c z)
set(bits 64 128)
set(kinds real32 real64)

foreach(_prec _bit _rk IN ZIP_LISTS precs bits kinds)
  if(NOT COMPLEX${_bit} IN_LIST _check_precisions)
    continue()
  endif()

  check_source_compiles(Fortran
    "program test
    use, intrinsic :: iso_fortran_env, only : rk => ${_rk}
    implicit none
    external :: p${_prec}gemm
    integer :: desca(9), descb(9), descc(9)
    complex(kind=rk) :: alpha, beta, a(1), b(1), c(1)
    alpha = (1.0_rk, 0.0_rk)
    beta = (0.0_rk, 0.0_rk)
    call p${_prec}gemm('N', 'N', 0, 0, 0, alpha, a, 1, 1, desca, b, 1, 1, descb, beta, c, 1, 1, descc)
    end program"
    SCALAPACK_COMPLEX${_bit}_FOUND_${_id}
  )

  if(SCALAPACK_COMPLEX${_bit}_FOUND_${_id})
    set(SCALAPACK_COMPLEX${_bit}_FOUND true CACHE BOOL "Found SCALAPACK complex${_bit}")
  endif()

endforeach()

if(NOT (SCALAPACK_REAL32_FOUND OR SCALAPACK_REAL64_FOUND OR SCALAPACK_COMPLEX64_FOUND OR SCALAPACK_COMPLEX128_FOUND))
  set(${_result} false PARENT_SCOPE)
endif()

endfunction()


macro(scalapack_mkl)
# https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2025-2/cmake-config-for-onemkl.html

set(ENABLE_SCALAPACK true)
set(ENABLE_BLAS true)

set(MKL_INTERFACE "lp64")
if(INT64 IN_LIST SCALAPACK_FIND_COMPONENTS)
  string(PREPEND MKL_INTERFACE "i")
endif()

# MKL_THREADING default: "intel_thread" which is Intel OpenMP
# some systems have messed up OpenMP, so sequential unless requested
if(NOT DEFINED MKL_THREADING)
  if(TBB IN_LIST SCALAPACK_FIND_COMPONENTS)
    set(MKL_THREADING "tbb_thread")
  elseif(OpenMP IN_LIST SCALAPACK_FIND_COMPONENTS)
    set(MKL_THREADING "intel_thread")
  else()
    set(MKL_THREADING "sequential")
  endif()
endif()

set(MKL_SYCL_MPI false)
set(MKL_SYCL_LINK false)
set(ENABLE_SYCL_COMPILER false)
# for Intel oneAPI 2025.2+, we don't want SYCL

# default: dynamic
if(STATIC IN_LIST SCALAPACK_FIND_COMPONENTS)
  set(MKL_LINK "static")
endif()

find_package(MKL CONFIG)

if(NOT MKL_FOUND)
  return()
endif()

set(SCALAPACK_COMPILE_OPTIONS $<TARGET_PROPERTY:MKL::MKL,INTERFACE_COMPILE_OPTIONS>)
set(SCALAPACK_INCLUDE_DIR $<TARGET_PROPERTY:MKL::MKL,INTERFACE_INCLUDE_DIRECTORIES>)
set(SCALAPACK_LIBRARY $<LINK_ONLY:MKL::MKL>)

set(SCALAPACK_MKL_FOUND true)

foreach(c IN ITEMS TBB INT64 OpenMP REAL32 REAL64 COMPLEX64 COMPLEX128)
  if(${c} IN_LIST SCALAPACK_FIND_COMPONENTS)
    set(SCALAPACK_${c}_FOUND true)
  endif()
endforeach()

endmacro()

#==========================

function(scalapack_aocl)

set(_nodef_scalapack)
if(DEFINED SCALAPACK_ROOT)
  set(_nodef_scalapack NO_DEFAULT_PATH)
endif()

set(_ps "LP64")
if(INT64 IN_LIST SCALAPACK_FIND_COMPONENTS)
  string(PREPEND _ps "I")
endif()

if(WIN32)
  set(_path_suffix lib/${_ps}/static)
  if(NOT STATIC IN_LIST SCALAPACK_FIND_COMPONENTS)
    list(APPEND _path_suffix lib/${_ps}/shared)
  endif()
else()
  set(_path_suffix lib/${_ps})
endif()

find_library(SCALAPACK_LIBRARY
NAMES scalapack
PATH_SUFFIXES ${_path_suffix}
HINTS ${SCALAPACK_ROOT} $ENV{SCALAPACK_ROOT}
${_nodef_scalapack}
DOC "AOCL SCALAPACK library"
VALIDATOR scalapack_check
)

if(SCALAPACK_LIBRARY)
  set(SCALAPACK_AOCL_FOUND true PARENT_SCOPE)
  if(INT64 IN_LIST SCALAPACK_FIND_COMPONENTS)
    set(SCALAPACK_INT64_FOUND true PARENT_SCOPE)
  endif()
endif()

endfunction()

#===========================

function(scalapack_netlib)

if(INT64 IN_LIST SCALAPACK_FIND_COMPONENTS)
  set(_names scalapack64 scalapack64-openmpi scalapack64-mpich scalapack)
else()
  set(_names scalapack scalapack-openmpi scalapack-mpich)
endif()

# Names to search for:
# scalapack-{openmpi,mpich}: Ubuntu and similar
# "scalapack":               RHEL-like distros, Netlib, etc.
find_library(SCALAPACK_LIBRARY
NAMES ${_names}
PATH_SUFFIXES openmpi/lib mpich/lib
DOC "SCALAPACK library"
VALIDATOR scalapack_check
)

if(SCALAPACK_LIBRARY)
  set(SCALAPACK_Netlib_FOUND true PARENT_SCOPE)
  if(INT64 IN_LIST SCALAPACK_FIND_COMPONENTS)
    set(SCALAPACK_INT64_FOUND true PARENT_SCOPE)
  endif()
endif()

endfunction()

# === main

if(NOT DEFINED SCALAPACK_CRAY AND DEFINED ENV{CRAYPE_VERSION})
  set(SCALAPACK_CRAY true)
endif()

if(STATIC IN_LIST SCALAPACK_FIND_COMPONENTS)
  set(_orig_suff ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

if(MKL IN_LIST SCALAPACK_FIND_COMPONENTS)
  scalapack_mkl()
elseif(Netlib IN_LIST SCALAPACK_FIND_COMPONENTS)
  scalapack_netlib()
elseif(SCALAPACK_CRAY)
  # Cray PE has Scalapack build into LibSci. Use Cray compiler wrapper.
elseif(AOCL IN_LIST LAPACK_FIND_COMPONENTS)
  scalapack_aocl()
elseif(DEFINED ENV{MKLROOT} AND IS_DIRECTORY "$ENV{MKLROOT}")
  scalapack_mkl()
else()
  scalapack_netlib()
endif()

if(STATIC IN_LIST SCALAPACK_FIND_COMPONENTS)
  if(SCALAPACK_LIBRARY)
    set(SCALAPACK_STATIC_FOUND true)
  endif()
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_orig_suff})
endif()

# --- Finalize

include(FindPackageHandleStandardArgs)

if(SCALAPACK_CRAY)
  set(SCALAPACK_links true)
  # Cray PE has ScaLAPACK built into libsci, linked automatically by the compiler wrapper
  find_package_handle_standard_args(SCALAPACK REQUIRED_VARS SCALAPACK_links)
else()
  find_package_handle_standard_args(SCALAPACK REQUIRED_VARS SCALAPACK_LIBRARY HANDLE_COMPONENTS)
endif()

if(SCALAPACK_FOUND)
  # need if _FOUND guard as can't overwrite imported target even if bad
  set(SCALAPACK_LIBRARIES ${SCALAPACK_LIBRARY})
  set(SCALAPACK_INCLUDE_DIRS ${SCALAPACK_INCLUDE_DIR})

  message(VERBOSE "Scalapack libraries: ${SCALAPACK_LIBRARIES}
Scalapack include directories: ${SCALAPACK_INCLUDE_DIRS}")

  if(NOT TARGET SCALAPACK::SCALAPACK)
    add_library(SCALAPACK::SCALAPACK INTERFACE IMPORTED)
    set_property(TARGET SCALAPACK::SCALAPACK PROPERTY INTERFACE_LINK_LIBRARIES "${SCALAPACK_LIBRARIES}")
    set_property(TARGET SCALAPACK::SCALAPACK PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${SCALAPACK_INCLUDE_DIR}")

    # For MKL, we don't use FindLapack, so define LAPACK::LAPACK as alias
    if(MKL_FOUND AND NOT TARGET LAPACK::LAPACK)
      add_library(LAPACK::LAPACK ALIAS SCALAPACK::SCALAPACK)
    endif()
  endif()
endif()

mark_as_advanced(SCALAPACK_LIBRARY SCALAPACK_INCLUDE_DIR)
