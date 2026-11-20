# Used by MUMPS devs to compare MUMPS source versions
#  option: -Dglob="Makefile" to only compare Makefiles or other file(GLOB) patterns
#
# Note that difftastic doesn't yet recognize Fortran fixed-form comments, but the comparison is still valid
# https://github.com/stadelmanma/tree-sitter-fortran/issues/6
# https://github.com/stadelmanma/tree-sitter-fixed-form-fortran/pull/2

cmake_minimum_required(VERSION 3.25)

if(NOT DEFINED old OR NOT DEFINED new)
  message(FATAL_ERROR "Please set 'old' and 'new' variables to the MUMPS source versions you want to compare. Example:
  cmake -Dold=\"5.7.3\" -Dnew=\"5.8.2\" -P ${CMAKE_CURRENT_LIST_DIR}/compare_mumps_version_source.cmake")
endif()

set(uhead "https://mumps-solver.org/MUMPS_")
set(utail ".tar.gz")

set(old_url "${uhead}${old}${utail}")
set(new_url "${uhead}${new}${utail}")

if(NOT glob)
  set(glob "Makefile")
endif()

# --- download MUMPS sources
include(FetchContent)

FetchContent_Populate(src_old URL ${old_url})

FetchContent_Populate(src_new URL ${new_url})

# --- diffing

find_package(Python COMPONENTS Interpreter)

if(Python_Interpreter_FOUND)

  file(GLOB_RECURSE files LIST_DIRECTORIES false RELATIVE "${src_new_SOURCE_DIR}"
    "${src_new_SOURCE_DIR}/${glob}")

  message(STATUS "Comparing source files ${files} using Python difflib")

  foreach(file IN LISTS files)
    execute_process(
        COMMAND ${Python_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/diff_print.py --ignore-comments
          ${src_old_SOURCE_DIR}/${file} ${src_new_SOURCE_DIR}/${file}
        COMMAND_ERROR_IS_FATAL ANY
    )
  endforeach()
endif()

find_program(difft NAMES difftastic difft)

if(NOT difft)
  message(STATUS "Obtain difftastic source comparison program by")
  if(WIN32)
    message(STATUS "winget install --id=Wilfred.difftastic -e")
    message(STATUS "However, to use 'less -R' it's easier to use WSL with   snap install difftastic")
  elseif(APPLE)
    message(STATUS "brew install difftastic")
  else()
    message(STATUS "snap install difftastic   (or use distro's package manager)")
  endif()
endif()

message(STATUS "To compare directories")
if(WIN32)
  set(pager "more")
else()
  set(pager "less -R")
endif()
message(STATUS "   ${difft} --ignore-comments --color=always ${src_old_SOURCE_DIR} ${src_new_SOURCE_DIR} | ${pager}")
