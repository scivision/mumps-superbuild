include(CheckCompilerFlag)
include(CheckSourceCompiles)
include(CheckSourceRuns)

set(MUMPS_AVX512VBMI_CFLAGS "")

if(CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  if(WIN32)
    set(MUMPS_AVX512VBMI_CFLAGS /QxHost)
  else()
    set(MUMPS_AVX512VBMI_CFLAGS -xHost)
  endif()
elseif(MSVC)
  set(MUMPS_AVX512VBMI_CFLAGS /arch:AVX512)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  set(MUMPS_AVX512VBMI_CFLAGS -mavx512vbmi -mavx512f -mavx512bw -mavx512vl)
  # we have examined and these are the flags actually needed - each of them
  # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-mavx512f

  # ;-list of flags must be in quotes or check_compiler_flag will falsely fail
  check_compiler_flag(C "${MUMPS_AVX512VBMI_CFLAGS}" MUMPS_COMPILER_SUPPORTS_AVX512)
  if(NOT MUMPS_COMPILER_SUPPORTS_AVX512)
    set(MUMPS_AVX512VBMI_CFLAGS "")
  endif()
endif()

if(DEFINED MUMPS_HAVE_AVX512VBMI)
  return()
endif()

block()
# MSVC doesn't have __AVX512VBMI__ macro like other compilers

if(WIN32 AND CMAKE_C_COMPILER_ID STREQUAL "MSVC")

  try_run(_mumps_avx512vbmi_run _mumps_avx512vbmi_build
  SOURCES ${CMAKE_CURRENT_LIST_DIR}/avx512vbmi.c
  CMAKE_FLAGS -DCOMPILE_DEFINITIONS="${MUMPS_AVX512VBMI_CFLAGS}"
  )
  # quirk of try_{compile,run} that "flags" are passed as compile definitions.

  if(NOT _mumps_avx512vbmi_build)
    set(MUMPS_HAVE_AVX512VBMI FALSE CACHE INTERNAL "AVX512VBMI support not detected (due to build error)")
  elseif(_mumps_avx512vbmi_run EQUAL 0)
    set(MUMPS_HAVE_AVX512VBMI TRUE CACHE INTERNAL "AVX512VBMI support detected")
  elseif(_mumps_avx512vbmi_run EQUAL 1)
    set(MUMPS_HAVE_AVX512VBMI TRUE CACHE INTERNAL "AVX512VBMI support detected - need define __AVX512VBMI__")
    list(APPEND mumps_cdefs $<$<COMPILE_LANGUAGE:C>:__AVX512VBMI__>)
  else()
    set(MUMPS_HAVE_AVX512VBMI FALSE CACHE INTERNAL "AVX512VBMI support not detected")
  endif()

else()
  file(READ ${CMAKE_CURRENT_LIST_DIR}/avx512vbmi.c avx_src)
  string(REPLACE ";" " " CMAKE_REQUIRED_FLAGS "${MUMPS_AVX512VBMI_CFLAGS}")

  check_source_compiles(C "${avx_src}" MUMPS_HAVE_AVX512VBMI)
endif()

endblock()
