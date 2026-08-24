# --- compiler options

set(mumps_cdefs)
set(mumps_fdefs)
set(mumps_cflags)

set(mumps_fflags -w)
# lets project consuming MUMPS not have excessive warnings from MUMPS sources

if(MSVC)
  # https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2026-1/names-001.html
  # include/mumps_compat.h has logic that corresponds to our logic for MUMPS_WIN32
  list(APPEND mumps_cdefs $<$<COMPILE_LANGUAGE:C>:UPPER>)
else()
  list(APPEND mumps_cdefs $<$<COMPILE_LANGUAGE:C>:Add_>)
endif()

if(MSVC)
  list(APPEND mumps_cdefs _CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE)
endif()

if(MUMPS_openmp)
  if(MUMPS_scotch)
    list(APPEND mumps_cdefs "MUMPS_SCOTCHIMPORTOMPTHREADS")
    list(APPEND mumps_fdefs "MUMPS_SCOTCHIMPORTOMPTHREADS")
  endif()
endif()

# catch missing function errors at compile time rather than link time
# to avoid huge error listing on link
list(APPEND mumps_cflags $<$<COMPILE_LANG_AND_ID:C,AppleClang,Clang,GNU,IntelLLVM>:-Werror-implicit-function-declaration>)

# -fno-strict-aliasing is important for memory leaks
# https://github.com/scivision/mumps-superbuild/pull/56
# IntelLLVM does not have -fno-strict-aliasing for Fortran
list(APPEND mumps_cflags
"$<$<COMPILE_LANG_AND_ID:C,AppleClang,Clang,GNU,IntelLLVM>:-fno-strict-aliasing>"
)
list(APPEND mumps_fflags "$<$<COMPILE_LANG_AND_ID:Fortran,FlangLLVM,GNU>:-fno-strict-aliasing>")

list(APPEND mumps_fflags
"$<$<COMPILE_LANG_AND_ID:Fortran,IntelLLVM>:-warn:declarations>"
"$<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-fimplicit-none>"
)

list(APPEND mumps_fflags
"$<$<AND:$<COMPILE_LANG_AND_ID:Fortran,GNU>,$<VERSION_GREATER_EQUAL:${CMAKE_Fortran_COMPILER_VERSION},10>>:-fallow-argument-mismatch;-fallow-invalid-boz>"
)

if(MUMPS_intsize64)
  # ALL libraries must be compiled with -fdefault-integer-8, including MPI,
  # or runtime fails
  # See MUMPS 5.7.0 User manual about error -69

  list(APPEND mumps_cdefs "$<$<COMPILE_LANGUAGE:C>:INTSIZE64;PORD_INTSIZE64>")
  # PORD_INTSIZE64 is used in src/mumps_pord.c and PORD/include/types.h

  if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU|LLVMFlang")

    add_compile_options("$<$<COMPILE_LANGUAGE:Fortran>:-fdefault-integer-8>")

  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    # https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2025-2/using-the-ilp64-interface-vs-lp64-interface.html
    # https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-windows/2025-2/using-the-ilp64-interface-vs-lp64-interface.html
    # https://www.intel.com/content/www/us/en/docs/mpi-library/developer-guide-linux/2021-16/ilp64-support.html

    set(_mkl_ilp64 $<IF:$<BOOL:${MUMPS_openmp}>,parallel,sequential>)

    add_compile_options("$<$<COMPILE_LANGUAGE:Fortran>:-i8>")
    if(WIN32)
      add_compile_options("$<$<COMPILE_LANGUAGE:Fortran>:/Qmkl-ilp64=${_mkl_ilp64}>")
    endif()

    add_compile_definitions("$<$<COMPILE_LANGUAGE:C>:MKL_ILP64>")

    list(APPEND mumps_fdefs "$<$<COMPILE_LANGUAGE:Fortran>:WORKAROUNDINTELILP64MPI2INTEGER>")

    add_link_options("$<$<COMPILE_LANGUAGE:Fortran>:-qmkl-ilp64=${_mkl_ilp64}>")
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
