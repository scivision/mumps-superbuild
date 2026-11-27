# builds the minimal Python interface

find_package(Python 3.12 COMPONENTS Interpreter Development.Module REQUIRED)

if(NOT TARGET dmumps)
  message(FATAL_ERROR "MUMPS_python requires double-precision MUMPS")
endif()

set(pbd ${CMAKE_CURRENT_BINARY_DIR}/python)
set(python_package_dir "${pbd}/mumps_superbuild")
file(MAKE_DIRECTORY "${python_package_dir}")
set(python_install_dir "mumps_superbuild")

if(DEFINED SKBUILD_PROJECT_NAME)
  if(APPLE)
    set(python_origin "@loader_path")
  else()
    set(python_origin "$ORIGIN")
  endif()
else()
  set(python_install_dir "${CMAKE_INSTALL_LIBDIR}/mumps_superbuild")
endif()

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

if(DEFINED SKBUILD_PROJECT_NAME)
  set_target_properties(_mumps_superbuild PROPERTIES
    INSTALL_RPATH "${python_origin}")
  if(UNIX)
    set_target_properties(dmumps mumps_common PROPERTIES
      INSTALL_RPATH "${python_origin}")
  endif()
endif()

install(FILES
  "${MUMPS_SOURCE_DIR}/python/mumps_superbuild/__init__.py"
  DESTINATION "${python_install_dir}"
  COMPONENT python)

if(DEFINED SKBUILD_PROJECT_NAME)
  install(TARGETS _mumps_superbuild
    RUNTIME DESTINATION "${python_install_dir}"
      COMPONENT python
    LIBRARY DESTINATION "${python_install_dir}"
      COMPONENT python
    ARCHIVE DESTINATION "${python_install_dir}"
      COMPONENT python)

  set(python_runtime_targets dmumps mumps_common)
  if(TARGET pord)
    list(APPEND python_runtime_targets pord)
  endif()
  if(NOT MUMPS_parallel)
    list(APPEND python_runtime_targets mpiseq mpiseq_c mpiseq_fortran)
  endif()
  install(TARGETS ${python_runtime_targets}
    RUNTIME DESTINATION "${python_install_dir}"
      COMPONENT python
    LIBRARY DESTINATION "${python_install_dir}"
      COMPONENT python
    ARCHIVE DESTINATION "${python_install_dir}"
      COMPONENT python)
else()
  install(TARGETS _mumps_superbuild EXPORT ${PROJECT_NAME}-targets
    RUNTIME DESTINATION "${python_install_dir}"
      COMPONENT python
    LIBRARY DESTINATION "${python_install_dir}"
      COMPONENT python
    ARCHIVE DESTINATION "${python_install_dir}"
      COMPONENT python)
endif()
