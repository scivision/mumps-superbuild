# builds the minimal serial, double-precision Python interface

find_package(Python 3.12 COMPONENTS Interpreter Development.Module REQUIRED)

if(NOT TARGET dmumps OR MUMPS_parallel)
  message(FATAL_ERROR "MUMPS_python currently requires serial double-precision MUMPS")
endif()

set(pbd ${CMAKE_CURRENT_BINARY_DIR}/python)
set(python_package_dir "${pbd}/mumps_superbuild")
file(MAKE_DIRECTORY "${python_package_dir}")

configure_file(
  "${MUMPS_SOURCE_DIR}/python/mumps_superbuild/__init__.py"
  "${python_package_dir}/__init__.py"
  COPYONLY)

add_custom_command(
  OUTPUT "${pbd}/_mumps_superbuild.c"
  COMMAND Python::Interpreter -m cython
          "${MUMPS_SOURCE_DIR}/python/_mumps_superbuild.pyx"
          --output-file "${pbd}/_mumps_superbuild.c"
  DEPENDS "${MUMPS_SOURCE_DIR}/python/_mumps_superbuild.pyx"
  VERBATIM)

python_add_library(_mumps_superbuild MODULE "${pbd}/_mumps_superbuild.c" WITH_SOABI)
target_link_libraries(_mumps_superbuild PRIVATE dmumps)
set_target_properties(_mumps_superbuild PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "${python_package_dir}"
  RUNTIME_OUTPUT_DIRECTORY "${python_package_dir}")

install(FILES
  "${MUMPS_SOURCE_DIR}/python/mumps_superbuild/__init__.py"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/mumps_superbuild")
install(TARGETS _mumps_superbuild EXPORT ${PROJECT_NAME}-targets
  RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/mumps_superbuild"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/mumps_superbuild"
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}/mumps_superbuild")
