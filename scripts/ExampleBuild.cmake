function(example_build example_bin)

execute_process(
COMMAND ${CMAKE_COMMAND}
  -B${example_bin} -S${CMAKE_CURRENT_LIST_DIR}/../example
  -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH}
  -DMUMPS_ROOT:PATH=${prefix}
  -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
  -DCMAKE_Fortran_COMPILER:FILEPATH=${CMAKE_Fortran_COMPILER}
COMMAND_ERROR_IS_FATAL ANY
)

execute_process(COMMAND ${CMAKE_COMMAND} --build ${example_bin} --parallel
RESULT_VARIABLE build_result
)
set(build_result ${build_result} PARENT_SCOPE)

if(build_result EQUAL 0)
  execute_process(COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${example_bin} -V
  RESULT_VARIABLE test_result
  )
  set(test_result ${test_result} PARENT_SCOPE)
endif()

endfunction()
