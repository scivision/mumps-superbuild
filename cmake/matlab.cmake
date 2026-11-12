set_property(DIRECTORY PROPERTY LABELS "mumps:matlab")

if(NOT MUMPS_BUILD_DOUBLE AND NOT MUMPS_BUILD_COMPLEX16)
  message(FATAL_ERROR "Matlab requires real64 and/or complex64: `cmake -DMUMPS_BUILD_DOUBLE=true`")
endif()

if(MUMPS_parallel)
  message(FATAL_ERROR "MUMPS MEX assumes no MPI (cmake -DMUMPS_parallel=no)")
endif()

find_package(Matlab REQUIRED COMPONENTS MEX_COMPILER MAIN_PROGRAM)

mumps_get_src(matlab_c_sources matlab c)


if(MUMPS_BUILD_COMPLEX16)
  # at least through MUMPS 5.9.0, the mxGetPi (possibly others too) use interface removed in R2018a.
  matlab_add_mex(NAME zmumpsmex
  SHARED
  SRC ${matlab_c_sources}
  LINK_TO MUMPS::MUMPS
  R2017b
  )
  target_compile_definitions(zmumpsmex PRIVATE MUMPS_ARITH=MUMPS_ARITH_z)
endif()
if(MUMPS_BUILD_DOUBLE)
  matlab_add_mex(NAME dmumpsmex
  SHARED
  SRC ${matlab_c_sources}
  LINK_TO MUMPS::MUMPS
  R2018a
  )
  target_compile_definitions(dmumpsmex PRIVATE MUMPS_ARITH=MUMPS_ARITH_d)
endif()

if(MUMPS_BUILD_DOUBLE)
add_test(NAME matlabSparseRHS
COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:dmumpsmex>'), sparserhs_example"
)
set_tests_properties(matlabSparseRHS PROPERTIES PASS_REGULAR_EXPRESSION "SOLUTION OK")
# sometimes the example succeeds but hangs on cleanup

add_test(NAME matlabDiaggonal COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:dmumpsmex>'), diagainv_example"
)

add_test(NAME matlabMultipleRHS COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:dmumpsmex>'), multiplerhs_example"
)

add_test(NAME matlabSchur COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:dmumpsmex>'), schur_example"
)

add_test(NAME matlabSimpleDouble COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:dmumpsmex>'), simple_example"
)
endif()

if(MUMPS_BUILD_COMPLEX16)
add_test(NAME matlabSimpleComplex COMMAND ${Matlab_MAIN_PROGRAM} -sd ${CMAKE_CURRENT_SOURCE_DIR}
  -batch "addpath('$<TARGET_FILE_DIR:zmumpsmex>'), zsimple_example"
)
endif()
