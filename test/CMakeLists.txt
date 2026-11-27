set_property(DIRECTORY PROPERTY LABELS "mumps:unit")

include(${PROJECT_SOURCE_DIR}/cmake/mpi_launcher.cmake)

add_executable(print_mumps_options print_mumps_options.f90)
target_link_libraries(print_mumps_options PRIVATE MUMPS::MUMPS)
add_test(NAME print_mumps_options COMMAND print_mumps_options)

if(MUMPS_BUILD_DOUBLE)
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

if(MUMPS_BUILD_SINGLE)
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

if(MUMPS_BUILD_DOUBLE)
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

if(MUMPS_metis)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/metis build_metis_example)
endif()

if(MUMPS_parmetis)
  add_subdirectory(${PROJECT_SOURCE_DIR}/example/parmetis build_parmetis_example)
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

if(MUMPS_python)
  set(python_test_dirs)

  list(APPEND python_test_dirs
    "$<TARGET_FILE_DIR:_mumps_superbuild>"
    "$<TARGET_FILE_DIR:dmumps>")

  foreach(t IN ITEMS mumps_common mpiseq mpiseq_c mpiseq_fortran)
    if(TARGET ${t})
      list(APPEND python_test_dirs $<TARGET_FILE_DIR:${t}>)
    endif()
  endforeach()

  foreach(prefix IN LISTS CMAKE_PREFIX_PATH)
    list(APPEND python_test_dirs "${prefix}/bin")
  endforeach()
  if(WIN32 AND DEFINED ENV{CMAKE_PREFIX_PATH})
    list(APPEND python_test_dirs "$ENV{CMAKE_PREFIX_PATH}/bin")
  endif()
  if(CMAKE_Fortran_COMPILER)
    cmake_path(GET CMAKE_Fortran_COMPILER PARENT_PATH fortran_runtime_dir)
    list(APPEND python_test_dirs "${fortran_runtime_dir}")
  endif()
  list(REMOVE_DUPLICATES python_test_dirs)

  if(NOT MUMPS_parallel)
    add_test(NAME python_solve
      COMMAND Python::Interpreter
        "${CMAKE_CURRENT_SOURCE_DIR}/python_solve.py"
        --package-root "${PROJECT_BINARY_DIR}/python"
        --dll-directory ${python_test_dirs})

    set_tests_properties(python_solve PROPERTIES
      LABELS "python"
      PASS_REGULAR_EXPRESSION "residual: "
    )
  elseif(MPIEXEC_EXECUTABLE)
    add_test(NAME python_mpi_solve
      COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} 2
        ${Python_EXECUTABLE}
        "${CMAKE_CURRENT_SOURCE_DIR}/python_solve.py"
        --mpi
        --package-root "${PROJECT_BINARY_DIR}/python"
        --dll-directory ${python_test_dirs})

    set_tests_properties(python_mpi_solve PROPERTIES
      LABELS "python;mpi"
      PROCESSORS 2
      RESOURCE_LOCK cpu_mpi
      PASS_REGULAR_EXPRESSION "residual: "
    )
  endif()
endif()

get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)

if(MUMPS_parallel AND NOT MPIEXEC_EXECUTABLE)
# this is a corner case, for example Windows MSYS2 with ARM64 CPU
  foreach(t IN LISTS test_names)
    get_property(label TEST ${t} PROPERTY LABELS)
    if("mpi" IN_LIST label)
      set_property(TEST ${t} PROPERTY DISABLED true)
    endif()
  endforeach()
endif()

if(BUILD_SHARED_LIBS)
  if(WIN32)
    set_property(TEST ${test_names} PROPERTY
    ENVIRONMENT_MODIFICATION
      "PATH=path_list_prepend:$<TARGET_FILE_DIR:mumps_common>"
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
