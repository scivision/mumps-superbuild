# convenience for testing MUMPS on physical machines, especially for Windows
# as GitHub Actions takes a couple hours to setup Windows oneAPI.
# So a dev might test MUMPS with Windows oneAPI on a laptop.
cmake_minimum_required(VERSION 3.25)

include(${CMAKE_CURRENT_LIST_DIR}/GetTempdir.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/ProjectBuild.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/ExampleBuild.cmake)

get_tempdir(tempdir)

include(${CMAKE_CURRENT_LIST_DIR}/oneapi_check.cmake)

find_package(MKL CONFIG REQUIRED)

# save build time
set(MUMPS_BUILD_SINGLE off)
set(MUMPS_BUILD_DOUBLE on)
option(BUILD_SHARED_LIBS "Build shared libraries")

foreach(MUMPS_parallel IN ITEMS true false)

set(bindir ${tempdir}/mumps_oneapi_${MUMPS_parallel})

set(prefix ${bindir}/install)

message(STATUS "MUMP_parallel=${MUMPS_parallel}
binary_dir: ${bindir}
temp install dir: ${prefix}"
)

find_library(mpiseq NAMES mpiseq
PATHS ${bindir}
NO_DEFAULT_PATH
)

if(MUMPS_parallel)
  if(mpiseq)
    message(FATAL_ERROR "mpiseq found in ${mpiseq}, but should not exist for MUMPS_parallel=true build")
  else()
   message(STATUS "mpiseq not found, as expected")
  endif()
else()
  if(mpiseq)
    message(STATUS "mpiseq found in ${mpiseq}, as expected")
  else()
    message(FATAL_ERROR "mpiseq not found, but should exist for serial build")
  endif()
endif()

execute_process(COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${bindir} -V
COMMAND_ERROR_IS_FATAL ANY
)

example_build(${bindir}/example)

endforeach()
