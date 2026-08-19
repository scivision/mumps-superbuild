# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindLapack
----------

Finds LAPACK libraries for C / C++ / Fortran.
Works with Netlib Lapack / LapackE, AOCL, and Intel MKL.
Intel MKL relies on having environment variable MKLROOT set, typically by sourcing
mklvars.sh beforehand.

We use this FindLapack.cmake instead of the one built into CMake, which has old code for
infrequently used Lapack libraries.

Tested on Linux, MacOS and Windows with:
* GCC / Gfortran
* Clang / Flang
* Intel (icc, ifort)
* Cray


COMPONENTS
^^^^^^^^^^

``INT64``
  64-bit integers (default 32-bit integers is what most users want and what most libraries have)

``MKL``
  Intel MKL -- sequential by default, or add TBB or MPI as well
``TBB``
  Intel MKL only: use threaded building blocks TBB
``OpenMP``
  Intel MKL only: use OpenMP (default is sequential)


``AOCL``
  AMD LAPACK fork of Netlib LAPACK.
  Requires LAPACK AOCL
  https://www.amd.com/en/developer/aocl/dense.html#lapack

``LAPACKE``
  LapackE C / C++ interface

``Netlib``
  Netlib Lapack for Fortran
``OpenBLAS``
  OpenBLAS Lapack for Fortran

``LAPACK95``
  get Lapack95 interfaces for MKL or Netlib (must also specify one of MKL, Netlib)

``STATIC``
  Library search default on non-Windows is shared then static. On Windows default search is static only.
  Specifying STATIC component searches for static libraries only.


Result Variables
^^^^^^^^^^^^^^^^

``LAPACK_FOUND``
  Lapack libraries were found
``LAPACK_<component>_FOUND``
  LAPACK <component> specified was found
``LAPACK_LIBRARIES``
  Lapack library files (including BLAS
``LAPACK_INCLUDE_DIRS``
  Lapack include directories (for C/C++)


References
^^^^^^^^^^

* Pkg-Config and MKL:  https://software.intel.com/en-us/articles/intel-math-kernel-library-intel-mkl-and-pkg-config-tool
* MKL for Windows: https://software.intel.com/en-us/mkl-windows-developer-guide-static-libraries-in-the-lib-intel64-win-directory
* MKL Windows directories: https://software.intel.com/en-us/mkl-windows-developer-guide-high-level-directory-structure
* MKL LAPACKE (C, C++): https://software.intel.com/en-us/mkl-linux-developer-guide-calling-lapack-blas-and-cblas-routines-from-c-c-language-environments
#]=======================================================================]

include(CheckSourceCompiles)

set(LAPACK_LIBRARIES)
set(LAPACK_INCLUDE_DIRS)

# ===== functions ==========

function(lapack_check _result path)

get_property(enabled_langs GLOBAL PROPERTY ENABLED_LANGUAGES)
if(NOT Fortran IN_LIST enabled_langs)
  return()
endif()

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_LINK_OPTIONS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES ${path})

check_source_compiles(Fortran
"program test
use, intrinsic :: iso_fortran_env, only : rk => real32
implicit none
real(rk), external :: snrm2
print *, snrm2(1, [0._rk], 1)
end program"
LAPACK_s_FOUND
)
if(LAPACK_s_FOUND)
  return()
endif()

check_source_compiles(Fortran
"program test
use, intrinsic :: iso_fortran_env, only : rk => real64
implicit none
real(rk), external :: dnrm2
print *, dnrm2(1, [0._rk], 1)
end program"
LAPACK_d_FOUND
)
if(LAPACK_d_FOUND)
  return()
endif()

check_source_compiles(Fortran
"program test
use, intrinsic :: iso_fortran_env, only : rk => real32
implicit none
real(rk), external :: scnrm2
print *, scnrm2(1, [(0._rk, 0._rk)], 1)
end program"
LAPACK_c_FOUND
)
if(LAPACK_c_FOUND)
  return()
endif()

check_source_compiles(Fortran
"program test
use, intrinsic :: iso_fortran_env, only : rk => real64
implicit none
real(rk), external :: dznrm2
print *, dznrm2(1, [(0._rk, 0._rk)], 1)
end program"
LAPACK_z_FOUND
)
if(LAPACK_z_FOUND)
  return()
endif()

set(${_result} false PARENT_SCOPE)

endfunction()

#=======================

function(lapack_netlib)

if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
  find_path(LAPACK95_INCLUDE_DIR
  NAMES f95_lapack.mod
  HINTS ${LAPACK95_ROOT} $ENV{LAPACK95_ROOT}
  PATH_SUFFIXES include
  DOC "LAPACK95 Fortran module"
  )

  find_library(LAPACK95_LIBRARY
  NAMES lapack95
  HINTS ${LAPACK95_ROOT} $ENV{LAPACK95_ROOT}
  DOC "LAPACK95 library"
  )

  if(NOT (LAPACK95_LIBRARY AND LAPACK95_INCLUDE_DIR))
    return()
  endif()

  set(LAPACK95_LIBRARY ${LAPACK95_LIBRARY} PARENT_SCOPE)
  set(LAPACK_LAPACK95_FOUND true PARENT_SCOPE)
  mark_as_advanced(LAPACK95_LIBRARY LAPACK95_INCLUDE_DIR)
endif()

# https://centos.pkgs.org/9-stream/centos-crb-x86_64/lapack-devel-3.9.0-8.el9.x86_64.rpm.html
set(_lapack_names lapack)
if(INT64 IN_LIST LAPACK_FIND_COMPONENTS)
  list(PREPEND _lapack_names lapack64)
endif()

find_library(LAPACK_LIBRARY
NAMES ${_lapack_names}
PATH_SUFFIXES lapack lapack/lib
DOC "LAPACK library"
)
if(NOT LAPACK_LIBRARY)
  return()
endif()

cmake_path(GET LAPACK_LIBRARY PARENT_PATH _lapack_root)
cmake_path(GET _lapack_root PARENT_PATH _lapack_root)

if(LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)
  find_library(LAPACKE_LIBRARY
  NAMES lapacke
  PATH_SUFFIXES lapack lapack/lib
  HINTS ${_lapack_root}
  DOC "LAPACKE library"
  )

  # lapack/include for Homebrew
  find_path(LAPACKE_INCLUDE_DIR
  NAMES lapacke.h
  PATH_SUFFIXES lapack lapack/include
  HINTS ${_lapack_root}
  DOC "LAPACKE include directory"
  )

  if(LAPACKE_LIBRARY AND LAPACKE_INCLUDE_DIR)
    set(LAPACK_LAPACKE_FOUND true PARENT_SCOPE)
    list(APPEND LAPACK_INCLUDE_DIRS ${LAPACKE_INCLUDE_DIR})
    list(APPEND LAPACK_LIBRARIES ${LAPACKE_LIBRARY})
  endif()

  mark_as_advanced(LAPACKE_LIBRARY LAPACKE_INCLUDE_DIR)
endif()

# Netlib on Cygwin and others

# https://centos.pkgs.org/9-stream/centos-crb-x86_64/blas-devel-3.9.0-8.el9.x86_64.rpm.html

set(_blas_names blas)
if(INT64 IN_LIST LAPACK_FIND_COMPONENTS)
  list(PREPEND _blas_names blas64)
endif()

find_library(BLAS_LIBRARY
NAMES ${_blas_names}
PATH_SUFFIXES lapack lapack/lib blas
DOC "BLAS library"
HINTS ${_lapack_root} ${BLAS_ROOT} $ENV{BLAS_ROOT}
VALIDATOR lapack_check
)

list(APPEND LAPACK_LIBRARIES ${LAPACK_LIBRARY} ${BLAS_LIBRARY})

if(LAPACK_LIBRARY AND BLAS_LIBRARY)
  set(LAPACK_Netlib_FOUND true PARENT_SCOPE)
endif()

return(PROPAGATE LAPACK_LIBRARIES LAPACK_INCLUDE_DIRS)

endfunction()

#===============================
function(lapack_openblas)

find_library(LAPACK_LIBRARY
NAMES openblas
PATH_SUFFIXES openblas
DOC "OpenBLAS library"
VALIDATOR lapack_check
)

cmake_path(GET LAPACK_LIBRARY PARENT_PATH _openblas_root)
cmake_path(GET _openblas_root PARENT_PATH _openblas_root)

find_path(LAPACK_INCLUDE_DIR
NAMES openblas_config.h cblas-openblas.h
HINTS ${_openblas_root}
DOC "OpenBLAS include directory"
)

if(LAPACK_LIBRARY AND LAPACK_INCLUDE_DIR)
  set(LAPACK_OpenBLAS_FOUND true PARENT_SCOPE)
endif()

set(LAPACK_LIBRARIES ${LAPACK_LIBRARY})
set(LAPACK_INCLUDE_DIRS ${LAPACK_INCLUDE_DIR})

return(PROPAGATE LAPACK_LIBRARIES LAPACK_INCLUDE_DIRS)

endfunction()


function(lapack_aocl)

set(_names flame)
if(WIN32)
  if(BUILD_SHARED_LIBS)
    list(APPEND _names AOCL-LibFlame-Win-MT-dll AOCL-LibFlame-Win-dll)
  else()
    list(APPEND _names AOCL-LibFlame-Win-MT AOCL-LibFlame-Win)
  endif()
endif()

set(_s "LP64")
if(INT64 IN_LIST LAPACK_FIND_COMPONENTS)
  string(PREPEND _s "I")
endif()

find_library(LAPACK_LIBRARY
NAMES ${_names}
NAMES_PER_DIR
PATH_SUFFIXES lib/${_s}
DOC "AOCL Flame library"
)

cmake_path(GET LAPACK_LIBRARY PARENT_PATH _lapack_root)
cmake_path(GET _lapack_root PARENT_PATH _lapack_root)
cmake_path(GET _lapack_root PARENT_PATH _lapack_root)
cmake_path(GET _lapack_root PARENT_PATH _aocl_root)

find_path(LAPACK_INCLUDE_DIR
NAMES FLAME.h
PATH_SUFFIXES include/${_s}
HINTS ${_lapack_root}
DOC "AOCL Flame header"
)

# --- BLIS

set(_names blis-mt blis)
if(WIN32)
  if(BUILD_SHARED_LIBS)
    list(APPEND _names AOCL-LibBlis-Win-MT-dll AOCL-LibBlis-Win-dll)
  else()
    list(APPEND _names AOCL-LibBlis-Win-MT AOCL-LibBlis-Win)
  endif()
endif()

message(STATUS "_lapack_root: ${_lapack_root} _aocl_root: ${_aocl_root}")

find_library(BLAS_LIBRARY
NAMES ${_names}
NAMES_PER_DIR
PATH_SUFFIXES lib/${_s}
HINTS ${_aocl_root}/amd-blis ${BLAS_ROOT} $ENV{BLAS_ROOT}
VALIDATOR lapack_check
DOC "AOCL Blis library"
)

find_path(BLAS_INCLUDE_DIR
NAMES blis.h
PATH_SUFFIXES include/${_s}
HINTS ${_aocl_root}/amd-blis ${BLAS_ROOT} $ENV{BLAS_ROOT}
DOC "Blis header"
)

if(LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)

  find_library(LAPACKE_LIBRARY
  NAMES lapacke
  PATH_SUFFIXES lib/${_s}
  HINTS ${_lapack_root} ${_aocl_root}/amd-libflame
  DOC "AOCL LAPACKE library"
  )

  # lapack/include for Homebrew
  find_path(LAPACKE_INCLUDE_DIR
  NAMES lapacke.h
  PATH_SUFFIXES include/${_s}
  HINTS ${_lapack_root} ${_aocl_root}/amd-libflame
  DOC "AOCL LAPACKE include directory"
  )

  if(LAPACKE_LIBRARY AND LAPACKE_INCLUDE_DIR)
    set(LAPACK_LAPACKE_FOUND true PARENT_SCOPE)
    list(APPEND LAPACK_INCLUDE_DIRS ${LAPACKE_INCLUDE_DIR})
    list(APPEND LAPACK_LIBRARIES ${LAPACKE_LIBRARY})
  endif()

  mark_as_advanced(LAPACKE_LIBRARY LAPACKE_INCLUDE_DIR)
endif()

if(LAPACK_LIBRARY AND LAPACK_INCLUDE_DIR AND BLAS_LIBRARY AND BLAS_INCLUDE_DIR)
  set(LAPACK_AOCL_FOUND true PARENT_SCOPE)
endif()

list(APPEND LAPACK_LIBRARIES ${LAPACK_LIBRARY} ${BLAS_LIBRARY})
list(APPEND LAPACK_INCLUDE_DIRS ${LAPACK_INCLUDE_DIR} ${BLAS_INCLUDE_DIR})

return(PROPAGATE LAPACK_LIBRARIES LAPACK_INCLUDE_DIRS)

endfunction()

#===============================

macro(lapack_mkl)
# https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2025-0/cmake-config-for-onemkl.html

set(MKL_INTERFACE "lp64")
if(INT64 IN_LIST LAPACK_FIND_COMPONENTS)
  string(PREPEND MKL_INTERFACE "i")
endif()

if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
  set(ENABLE_BLAS95 true)
  set(ENABLE_LAPACK95 true)
endif()

# MKL_THREADING default: "intel_thread" which is Intel OpenMP
# some systems have messed up OpenMP, so sequential unless requested
if(NOT DEFINED MKL_THREADING)
  if(TBB IN_LIST LAPACK_FIND_COMPONENTS)
    set(MKL_THREADING "tbb_thread")
  elseif(OpenMP IN_LIST LAPACK_FIND_COMPONENTS)
    set(MKL_THREADING "intel_thread")
  else()
    set(MKL_THREADING "sequential")
  endif()
endif()

# default: dynamic
if(STATIC IN_LIST LAPACK_FIND_COMPONENTS)
  set(MKL_LINK "static")
endif()

find_package(MKL CONFIG)

if(MKL_FOUND)
  set(LAPACK_COMPILE_OPTIONS $<TARGET_PROPERTY:MKL::MKL,INTERFACE_COMPILE_OPTIONS>)
  set(LAPACK_INCLUDE_DIR $<TARGET_PROPERTY:MKL::MKL,INTERFACE_INCLUDE_DIRECTORIES>)
  set(LAPACK_LIBRARY $<LINK_ONLY:MKL::MKL>)
  set(LAPACK_MKL_FOUND true)

  foreach(c IN ITEMS TBB LAPACK95 INT64 OpenMP)
    if(${c} IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_${c}_FOUND true)
    endif()
  endforeach()

  set(LAPACK_LIBRARIES ${LAPACK_LIBRARY})
  set(LAPACK_INCLUDE_DIRS ${LAPACK_INCLUDE_DIR})

endif()

endmacro()

# ========== main program

if(NOT DEFINED LAPACK_CRAY AND DEFINED ENV{CRAYPE_VERSION})
  set(LAPACK_CRAY true)
endif()

if(STATIC IN_LIST LAPACK_FIND_COMPONENTS)
  set(_orig_suff ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

if(MKL IN_LIST LAPACK_FIND_COMPONENTS)
  lapack_mkl()
elseif(Netlib IN_LIST LAPACK_FIND_COMPONENTS)
  lapack_netlib()
elseif(OpenBLAS IN_LIST LAPACK_FIND_COMPONENTS)
  lapack_openblas()
elseif(AOCL IN_LIST LAPACK_FIND_COMPONENTS)
  lapack_aocl()
elseif(LAPACK_CRAY)
  # LAPACK is implicitly part of Cray PE LibSci, use Cray compiler wrapper.
elseif(DEFINED ENV{MKLROOT} AND IS_DIRECTORY "$ENV{MKLROOT}")
  lapack_mkl()
else()
  lapack_netlib()
endif()

if(STATIC IN_LIST LAPACK_FIND_COMPONENTS)
  if(LAPACK_LIBRARY)
    set(LAPACK_STATIC_FOUND true)
  endif()
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_orig_suff})
endif()



include(FindPackageHandleStandardArgs)

if(LAPACK_CRAY)
  set(LAPACK_links true)
  find_package_handle_standard_args(LAPACK REQUIRED_VARS LAPACK_links)
else()
  find_package_handle_standard_args(LAPACK HANDLE_COMPONENTS REQUIRED_VARS LAPACK_LIBRARIES)
endif()

if(LAPACK_FOUND)
# need if _FOUND guard as can't overwrite imported target even if bad

message(VERBOSE "Lapack libraries: ${LAPACK_LIBRARIES}
Lapack include directories: ${LAPACK_INCLUDE_DIRS}")

if(NOT TARGET LAPACK::LAPACK)
  add_library(LAPACK::LAPACK INTERFACE IMPORTED)
  set_property(TARGET LAPACK::LAPACK PROPERTY INTERFACE_COMPILE_OPTIONS "${LAPACK_COMPILE_OPTIONS}")
  set_property(TARGET LAPACK::LAPACK PROPERTY INTERFACE_LINK_LIBRARIES "${LAPACK_LIBRARIES}")
  set_property(TARGET LAPACK::LAPACK PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${LAPACK_INCLUDE_DIRS}")
endif()

if(LAPACK_LAPACK95_FOUND)
  set(LAPACK95_LIBRARIES ${LAPACK95_LIBRARY})
  set(LAPACK95_INCLUDE_DIRS ${LAPACK95_INCLUDE_DIR})

  if(NOT TARGET LAPACK::LAPACK95)
    add_library(LAPACK::LAPACK95 INTERFACE IMPORTED)
    set_property(TARGET LAPACK::LAPACK95 PROPERTY INTERFACE_LINK_LIBRARIES "${LAPACK95_LIBRARY}")
    set_property(TARGET LAPACK::LAPACK95 PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${LAPACK95_INCLUDE_DIR}")
  endif()
endif()

endif(LAPACK_FOUND)

mark_as_advanced(BLAS_LIBRARY LAPACK_LIBRARY LAPACK_INCLUDE_DIR)
