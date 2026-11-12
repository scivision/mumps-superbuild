cmake_minimum_required(VERSION 3.25)

project(MUMPSgpuExample
LANGUAGES C Fortran
)

enable_testing()

set_property(DIRECTORY PROPERTY LABELS "mumps:gpu")

if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin)
  # need CMAKE_IGNORE_PATH for CMake < 3.23 and to ensure system env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

if(PROJECT_IS_TOP_LEVEL)
  find_package(MUMPS CONFIG REQUIRED)
endif()

if(MUMPS_DOUBLE OR MUMPS_BUILD_DOUBLE)
  add_executable(D_gpu mumps_cuda_gpu_example.f90)
  target_link_libraries(D_gpu PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  # always link MPI as we use the libmpiseq if not MUMPS_parallel

  add_test(NAME D_gpu COMMAND D_gpu)
endif()


file(GENERATE OUTPUT .gitignore CONTENT "*")
