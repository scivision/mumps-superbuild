cmake_minimum_required(VERSION 3.25)

project(MUMPSExamples
LANGUAGES C CXX Fortran
)

enable_testing()

if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin)
  # need CMAKE_IGNORE_PATH for CMake < 3.23 and to ensure system env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU|Intel")
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror-implicit-function-declaration>)
elseif(CMAKE_C_COMPILER_ID MATCHES "MSVC")
  add_link_options($<$<COMPILE_LANGUAGE:C>:/NODEFAULTLIB:MSVCRT>)
endif()

find_package(MUMPS CONFIG REQUIRED)
message(STATUS "MUMPS_DIR: ${MUMPS_DIR}
parallel: ${MUMPS_parallel}
Scotch: ${MUMPS_scotch}
METIS: ${MUMPS_metis}
ParMETIS: ${MUMPS_parmetis}
OpenMP: ${MUMPS_openmp}
GPU: ${MUMPS_gpu}
XKBlas: ${MUMPS_xkblas}
")

message(STATUS "MUMPS_intsize64: ${MUMPS_intsize64}
LAPACK vendor: ${MUMPS_LAPACK_VENDOR}
Scalapack vendor: ${MUMPS_SCALAPACK_VENDOR}
real32: ${MUMPS_SINGLE}
real64: ${MUMPS_DOUBLE}
complex64: ${MUMPS_COMPLEX}
complex128: ${MUMPS_COMPLEX16}
")

if(MUMPS_parallel)
  find_package(MPI COMPONENTS CXX)
endif()

if(MUMPS_openmp)
  find_package(OpenMP COMPONENTS CXX)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/mpi_launcher.cmake)

function(precision_ex a lang)

  add_executable(${a}_example_${lang} ${a}_example.${lang})
  target_link_libraries(${a}_example_${lang} PRIVATE MUMPS::MUMPS MPI::MPI_Fortran)
  if(lang STREQUAL "cpp")
    target_link_libraries(${a}_example_${lang} PRIVATE
      $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_CXX>
      $<$<BOOL:${MUMPS_parallel}>:MPI::MPI_CXX>
    )
  elseif(lang STREQUAL "c")
    target_link_libraries(${a}_example_${lang} PRIVATE
      $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_C>
      $<$<BOOL:${MUMPS_parallel}>:MPI::MPI_C>
    )
  endif()
  # always link MPI (MPI::MPI_Fortran and MPI::MPI_C) as we use the libmpiseq if not MUMPS_parallel

  add_test(NAME ${a}_example_${lang} COMMAND ${a}_example_${lang})

  if(MUMPS_parallel)
    test_mpi_launcher(${a}_example_${lang} ${a}_example_${lang} 2)
  endif()

endfunction()

if(MUMPS_DOUBLE)
  precision_ex("d" c)
  if(MPI_CXX_FOUND)
    precision_ex("d" cpp)
  endif()
endif()

if(MUMPS_COMPLEX_16)
  precision_ex("z" c)
endif()


# test properties
get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)

if(MUMPS_parallel)
  set_property(TEST ${test_names} PROPERTY RESOURCE_LOCK cpu_mpi)
endif()

if(WIN32)
  get_property(imp_mumps TARGET MUMPS::COMMON PROPERTY IMPORTED_LOCATION_RELEASE)
  if(imp_mumps)
    cmake_path(GET imp_mumps PARENT_PATH imp_mumps_dir)
  endif()
  set_property(TEST ${test_names} PROPERTY
  ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:${imp_mumps_dir};PATH=path_list_prepend:${CMAKE_PREFIX_PATH}/bin"
  )
endif()

file(GENERATE OUTPUT .gitignore CONTENT "*")
