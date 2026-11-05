# For dev testing, to ease testing of shared libraries, which
# may not show run path problems until executables are run.

cmake_minimum_required(VERSION 3.25)

include(${CMAKE_CURRENT_LIST_DIR}/GetTempdir.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/ProjectBuild.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/ExampleBuild.cmake)

get_tempdir(tempdir)

set(BUILD_SINGLE off)
set(BUILD_DOUBLE on)
set(BUILD_SHARED_LIBS on)
# set(FCs flang gfortran gfortran)
set(CCs gcc)
set(FCs gfortran)

if(APPLE)
  set(CCs clang)
  find_program(brew NAMES brew)
  if(brew)
    execute_process(COMMAND ${brew} --prefix gcc RESULT_VARIABLE ret OUTPUT_VARIABLE gcc_root OUTPUT_STRIP_TRAILING_WHITESPACE)
    file(GLOB cand LIST_DIRECTORIES false ${gcc_root}/bin/gcc-*)
    # filter out non-numeric suffixes like gcc-ar, gcc-nm, gcc-ranlib
    list(FILTER cand INCLUDE REGEX ".*gcc-[0-9]+$")
    # sort to get latest version last
    list(SORT cand COMPARE NATURAL)
    list(GET cand -1 _latest_gcc)

    list(APPEND CCs ${_latest_gcc})
    list(APPEND FCs gfortran)
  endif()
endif()

message(STATUS "CCs: ${CCs}")
message(STATUS "FCs: ${FCs}")

function(build_and_test)
cmake_path(GET CMAKE_C_COMPILER STEM cc)
cmake_path(GET CMAKE_Fortran_COMPILER STEM fc)

set(bindir ${tempdir}/mumps_shared_build_${MUMPS_parallel}_${MUMPS_openmp}_${MUMPS_parmetis}_${cc}_${fc})
set(prefix ${bindir}/install)

message(STATUS "MUMP_parallel=${MUMPS_parallel}
MUMP_openmp=${MUMPS_openmp}
MUMP_parmetis=${MUMPS_parmetis}
cc=${cc}
fc=${fc}
binary_dir: ${bindir}
temp install dir: ${prefix}"
)

project_build(${prefix} ${bindir})

execute_process(COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${bindir} -V)

example_build(${bindir}/example)
if(NOT build_result EQUAL 0)
  message(FATAL_ERROR "Build failed for configuration: MUMPS_parallel=${MUMPS_parallel} MUMPS_openmp=${MUMPS_openmp} MUMPS_parmetis=${MUMPS_parmetis} cc=${cc} fc=${fc}")
endif()
if(NOT test_result EQUAL 0)
  message(FATAL_ERROR "Tests failed for configuration: MUMPS_parallel=${MUMPS_parallel} MUMPS_openmp=${MUMPS_openmp} MUMPS_parmetis=${MUMPS_parmetis} cc=${cc} fc=${fc}")
endif()

endfunction()

foreach(CMAKE_C_COMPILER CMAKE_Fortran_COMPILER IN ZIP_LISTS CCs FCs)
  foreach(MUMPS_parallel IN ITEMS true false)
    foreach(MUMPS_openmp IN ITEMS true false)
      if(MUMPS_parallel)
        foreach(MUMPS_parmetis IN ITEMS true false)
          build_and_test()
        endforeach()
      else()
        set(MUMPS_parmetis false)
        build_and_test()
      endif()
    endforeach()
  endforeach()
endforeach()
