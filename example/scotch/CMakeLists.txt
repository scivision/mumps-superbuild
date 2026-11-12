cmake_minimum_required(VERSION 3.25)

project(MUMPSscotchExamples
LANGUAGES C Fortran
)

enable_testing()

if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin)
  # need CMAKE_IGNORE_PATH for CMake < 3.23 and to ensure system env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

if(PROJECT_IS_TOP_LEVEL)
  find_package(MUMPS CONFIG REQUIRED)
endif()

function(precision_ex a)
  add_executable(${a}_scotch ${a}_scotch.f90)
  target_link_libraries(${a}_scotch PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  # always link MPI as we use the libmpiseq if not MUMPS_parallel

  add_test(NAME ${a}_scotch COMMAND ${a}_scotch)
  set_tests_properties(${a}_scotch PROPERTIES LABELS "mumps:scotch")
endfunction()

if(MUMPS_d_FOUND OR MUMPS_BUILD_DOUBLE)
  precision_ex("d")
endif()

file(GENERATE OUTPUT .gitignore CONTENT "*")
