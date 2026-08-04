# --- compiler options

set(mumps_cdefs)
set(mumps_fdefs)
set(mumps_cflags)

set(mumps_fflags -w)
# lets project consuming MUMPS not have excessive warnings from MUMPS sources

list(APPEND mumps_cdefs "$<$<COMPILE_LANGUAGE:C>:Add_>")
# "Add_" works for all modern compilers we tried.

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

if(WIN32 AND CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM" AND CMAKE_GENERATOR MATCHES "Visual Studio")
  # MSBuild does not run the preprocessor on *.F / *.F90. The Ninja generator does not need this,
  # as CMake preprocesses Fortran itself there to scan module dependencies. Without /fpp the
  # #if / #else in the MUMPS sources are compiled as ordinary source lines, and the build fails
  # with misleading errors: #5082, #6333, #6417, #5508.
  string(APPEND CMAKE_Fortran_FLAGS " /fpp")

  # mumps_common, mpiseq and the arithmetic libraries have no sources of their own, only
  # $<TARGET_OBJECTS:>, so CMake links them with link.exe rather than ifx. Under MSBuild the LIB
  # environment variable only covers the Visual Studio toolset, so the Intel Fortran runtime
  # (ifconsol.lib, ifmodintr.lib, ...) is not found. A Ninja build started from an oneAPI command
  # prompt already has that directory in LIB.
  # Keep forward slashes: the Visual Studio generator turns /LIBPATH: into
  # <AdditionalLibraryDirectories> and drops backslashes on the way.
  cmake_path(GET CMAKE_Fortran_COMPILER PARENT_PATH _ifx_dir)
  cmake_path(GET _ifx_dir PARENT_PATH _ifx_root)
  if(IS_DIRECTORY "${_ifx_root}/lib")
    foreach(t IN ITEMS EXE SHARED MODULE)
      string(APPEND CMAKE_${t}_LINKER_FLAGS " \"/LIBPATH:${_ifx_root}/lib\"")
    endforeach()
  else()
    message(WARNING "MUMPS: Intel Fortran runtime libraries not found under ${_ifx_root}/lib, linking may fail")
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

# Necessary for shared library with Visual Studio / Windows oneAPI
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS true)
