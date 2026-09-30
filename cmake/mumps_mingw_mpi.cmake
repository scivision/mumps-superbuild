# based on https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-mumps/0004-mpi-module.patch
# I've emailed MUMPS dev team on 2026-09-30 to see if they'll switch to MPI-2 "use mpi"
# as MPI-4.1 deprecates mpif.h
#
# Goal is to remove this patch once MUMPS switches to MPI-2 "use mpi", and just alert MinGW users if they have old MUMPS

find_package(Git REQUIRED)
set(_patch "${CMAKE_CURRENT_SOURCE_DIR}/cmake/mumps_mingw_mpi.patch")
set(_mumps_source_relative "${mumps_upstream_SOURCE_DIR}")
cmake_path(RELATIVE_PATH _mumps_source_relative
BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

execute_process(
COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace --check -p1
    "--directory=${_mumps_source_relative}" "${_patch}"
WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
COMMAND_ECHO STDOUT
RESULT_VARIABLE _can_apply
ERROR_VARIABLE _apply_error
)

if(_can_apply EQUAL 0)
execute_process(
    COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace -p1
    "--directory=${_mumps_source_relative}" "${_patch}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND_ECHO STDOUT
    COMMAND_ERROR_IS_FATAL ANY
)
else()
execute_process(
    COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace --reverse --check -p1
    "--directory=${_mumps_source_relative}" "${_patch}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND_ECHO STDOUT
    RESULT_VARIABLE _already_applied
    ERROR_VARIABLE _reverse_error
)
if(NOT _already_applied EQUAL 0)
    message(FATAL_ERROR
    "MinGW MPI patch neither applies nor is already applied:\n${_apply_error}\n${_reverse_error}")
endif()
endif()
