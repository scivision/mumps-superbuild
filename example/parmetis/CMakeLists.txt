cmake_minimum_required(VERSION 3.25)

project(MUMPSparmetisExamples
LANGUAGES C Fortran
)

enable_testing()

set_property(DIRECTORY PROPERTY LABELS "mumps:parmetis")

if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin)
  # need CMAKE_IGNORE_PATH for CMake < 3.23 and to ensure system env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

if(PROJECT_IS_TOP_LEVEL)
  find_package(MUMPS CONFIG REQUIRED)
endif()

if(NOT MUMPS_parallel OR NOT MUMPS_parmetis)
  message(FATAL_ERROR "The ParMETIS example requires a parallel MUMPS build with ParMETIS enabled.")
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/mpi_launcher.cmake)

function(precision_ex a)
  add_executable(${a}_parmetis_fortran
    ${a}_parmetis.F90
    parmetis_mpi_comm.c
  )

  target_compile_definitions(${a}_parmetis_fortran PRIVATE $<$<BOOL:${MUMPS_intsize64}>:MUMPS_INTEGER_64>)

  target_link_libraries(${a}_parmetis_fortran PRIVATE MUMPS::MUMPS
  PARMETIS::PARMETIS
  MPI::MPI_Fortran MPI::MPI_C
  "$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran;OpenMP::OpenMP_C>"
  )
  # always link MPI as we use the libmpiseq if not MUMPS_parallel

  add_test(NAME ${a}_parmetis_fortran COMMAND ${a}_parmetis_fortran)
  test_mpi_launcher(${a}_parmetis_fortran ${a}_parmetis_fortran 2)

  add_executable(${a}_parmetis_c ${a}_parmetis.c)
  target_link_libraries(${a}_parmetis_c PRIVATE MUMPS::MUMPS
  PARMETIS::PARMETIS
  MPI::MPI_C
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_C>
  )

  add_test(NAME ${a}_parmetis_c COMMAND ${a}_parmetis_c)
  test_mpi_launcher(${a}_parmetis_c ${a}_parmetis_c 2)
endfunction()

if(MUMPS_DOUBLE OR BUILD_DOUBLE)
  precision_ex("d")
endif()

file(GENERATE OUTPUT .gitignore CONTENT "*")
