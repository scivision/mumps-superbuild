function(project_build prefix bindir)

execute_process(
COMMAND ${CMAKE_COMMAND}
  -B${bindir} -S${CMAKE_CURRENT_LIST_DIR}/..
  --install-prefix=${prefix}
  -DMUMPS_parallel=${MUMPS_parallel}
  -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
  -DMUMPS_ENABLE_RPATH:BOOL=${BUILD_SHARED_LIBS}
  -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
  -DCMAKE_Fortran_COMPILER:FILEPATH=${CMAKE_Fortran_COMPILER}
  -DBUILD_SINGLE:BOOL=${BUILD_SINGLE}
  -DBUILD_DOUBLE:BOOL=${BUILD_DOUBLE}
  -DMUMPS_openmp:BOOL=${MUMPS_openmp}
  -DMUMPS_parmetis:BOOL=${MUMPS_parmetis}
  -DMUMPS_metis:BOOL=${MUMPS_metis}
  -DMUMPS_scotch:BOOL=${MUMPS_scotch}
  -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH}
COMMAND_ERROR_IS_FATAL ANY
)

execute_process(COMMAND ${CMAKE_COMMAND} --build ${bindir} --parallel
COMMAND_ERROR_IS_FATAL ANY
)

execute_process(COMMAND ${CMAKE_COMMAND} --install ${bindir}
COMMAND_ERROR_IS_FATAL ANY
)

endfunction()
