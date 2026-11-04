function(test_mpi_launcher target test Nworker)

if(NOT DEFINED MPIEXEC_EXECUTABLE OR NOT DEFINED MPIEXEC_NUMPROC_FLAG)
  message(FATAL_ERROR "MPIEXEC_EXECUTABLE and MPIEXEC_NUMPROC_FLAG must be defined to use test_mpi_launcher")
endif()

if(NOT Nworker)
  message(FATAL_ERROR "Nworker must be defined to use test_mpi_launcher")
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.29)
  set_property(TARGET ${target} PROPERTY TEST_LAUNCHER ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${Nworker})
else()
  set_property(TARGET ${target} PROPERTY CROSSCOMPILING_EMULATOR ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${Nworker})
endif()

set_property(TEST ${test} PROPERTY PROCESSORS ${Nworker})

if(DEFINED mpi_tmpdir)
  set_property(TEST ${test} PROPERTY ENVIRONMENT "TMPDIR=${mpi_tmpdir}")
endif()

endfunction()
