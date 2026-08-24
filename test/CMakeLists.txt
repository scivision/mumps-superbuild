set_property(DIRECTORY PROPERTY LABELS "mumps:unit")

include(${PROJECT_SOURCE_DIR}/cmake/mpi_launcher.cmake)

add_executable(print_mumps_options print_mumps_options.f90)
target_link_libraries(print_mumps_options PRIVATE MUMPS::MUMPS)
add_test(NAME print_mumps_options COMMAND print_mumps_options)

if(BUILD_DOUBLE)
  add_executable(test_mumps_config test_mumps.f90)
  target_link_libraries(test_mumps_config PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  add_test(NAME test_mumps_config COMMAND test_mumps_config)

  if(MUMPS_parallel)
    test_mpi_launcher(test_mumps_config test_mumps_config 2)
  endif()
endif()

if(BUILD_SINGLE)
  add_executable(test_mumps_simple32 s_simple.f90)
  target_link_libraries(test_mumps_simple32 PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  add_test(NAME test_mumps_simple32 COMMAND test_mumps_simple32)

  if(MUMPS_parallel)
    test_mpi_launcher(test_mumps_simple32 test_mumps_simple32 2)
  endif()
endif()

if(BUILD_DOUBLE)
  add_executable(test_mumps_simple64 d_simple.f90)
  target_link_libraries(test_mumps_simple64 PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  add_test(NAME test_mumps_simple64 COMMAND test_mumps_simple64)

  if(MUMPS_parallel)
    test_mpi_launcher(test_mumps_simple64 test_mumps_simple64 2)
  endif()

  add_executable(test_mumps_complex128 simple.c)
  target_link_libraries(test_mumps_complex128 PRIVATE MUMPS::MUMPS
  MPI::MPI_Fortran
  $<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
  )
  add_test(NAME test_mumps_complex128 COMMAND test_mumps_complex128)
  if(CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM" AND "$ENV{GITHUB_ACTIONS}")
    # Please verify that both the operating system and the processor support Intel(R) X87, CMOV, MMX, SSE, SSE2, SSE3, SSSE3, SSE4_1, SSE4_2, MOVBE, POPCNT, AVX, F16C, FMA, BMI, LZCNT, AVX2, ADX and SHSTK instructions.
    set_tests_properties(test_mumps_complex128 PROPERTIES DISABLED true)
  endif()

  if(MUMPS_parallel)
    test_mpi_launcher(test_mumps_complex128 test_mumps_complex128 2)
  endif()
endif()

if(MUMPS_metis OR MUMPS_parmetis)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/metis build_metis_example)
endif()

if(MUMPS_scotch)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/scotch build_scotch_example)
endif()

if(MUMPS_openmp)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/openmp build_openmp_example)
endif()

if(MUMPS_gpu)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/gpu build_gpu_example)
endif()

get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)

set_property(TEST ${test_names} PROPERTY RESOURCE_LOCK cpu_mpi)

if(BUILD_SHARED_LIBS)
  if(WIN32)
    set_property(TEST ${test_names} PROPERTY
    ENVIRONMENT_MODIFICATION
      "PATH=path_list_prepend:$<TARGET_FILE_DIR:mumps_common>"
      "PATH=path_list_prepend:$<TARGET_FILE_DIR:pord>"
      "PATH=path_list_prepend:$<TARGET_FILE_DIR:mpiseq_fortran>"
      "PATH=path_list_prepend:${CMAKE_INSTALL_FULL_BINDIR}"
      "PATH=path_list_prepend:${CMAKE_PREFIX_PATH}/bin"
    )
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set_property(TEST ${test_names} PROPERTY
    ENVIRONMENT_MODIFICATION "LIBRARY_PATH=path_list_prepend:${CMAKE_INSTALL_FULL_LIBDIR};LIBRARY_PATH=path_list_prepend:${PROJECT_BINARY_DIR}"
    )
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set_property(TEST ${test_names} PROPERTY
    ENVIRONMENT_MODIFICATION "LD_LIBRARY_PATH=path_list_prepend:${CMAKE_INSTALL_FULL_LIBDIR};LD_LIBRARY_PATH=path_list_prepend:${PROJECT_BINARY_DIR}"
    )
  endif()
endif()
