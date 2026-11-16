include(FetchContent)


function(bison_homebrew)


find_program(BISON_EXECUTABLE
NAMES bison
HINTS $ENV{HOMEBREW_PREFIX}
PATH_SUFFIXES opt/bison/bin
NO_DEFAULT_PATH
)
if(NOT BISON_EXECUTABLE)
  return()
endif()

cmake_path(GET BISON_EXECUTABLE PARENT_PATH BISON_ROOT)
message(STATUS "BISON_EXECUTABLE ${BISON_EXECUTABLE}  BISON_ROOT ${BISON_ROOT}")

if(NOT DEFINED FLEX_ROOT)
  find_program(FLEX_EXECUTABLE
  NAMES flex
  HINTS $ENV{HOMEBREW_PREFIX}
  PATH_SUFFIXES opt/flex/bin
  )
  if(FLEX_EXECUTABLE)
    cmake_path(GET FLEX_EXECUTABLE PARENT_PATH FLEX_ROOT)
    message(STATUS "FLEX_EXECUTABLE ${FLEX_EXECUTABLE}  FLEX_ROOT ${FLEX_ROOT}")
  endif()

  set(FLEX_ROOT ${FLEX_ROOT} PARENT_SCOPE)
endif()

return(PROPAGATE BISON_ROOT)

endfunction()


set(SCOTCH_COMPONENTS ESMUMPS)
if(MUMPS_ptscotch)
  list(APPEND SCOTCH_COMPONENTS PTScotch)
endif()

# Probe for an existing SCOTCH first, so that build tools (Bison, Flex) are only
# obtained when SCOTCH actually needs to be built from source.
# FetchContent_MakeAvailable(SCOTCH) repeats this find_package() via FIND_PACKAGE_ARGS,
# which is cheap since results are cached.
if(NOT FETCHCONTENT_TRY_FIND_PACKAGE_MODE STREQUAL "NEVER")
  find_package(SCOTCH COMPONENTS ${SCOTCH_COMPONENTS})
endif()

if(APPLE AND NOT SCOTCH_FOUND)
  find_package(BISON 2.7)
  if(NOT BISON_FOUND)
    unset(BISON_EXECUTABLE CACHE)
    bison_homebrew()
  endif()
endif()


# https://gitlab.inria.fr/scotch/scotch/-/blob/master/CMakeLists.txt
# options were checked with Scotch 7.0.7
set(ENABLE_TESTS false)
set(INSTALL_METIS_HEADERS false)
set(BUILD_LIBSCOTCHMETIS false)
set(BUILD_LIBESMUMPS true)
set(BUILD_PTSCOTCH ${MUMPS_parallel})
if(MUMPS_intsize64)
  set(INTSIZE 64)
else()
  set(INTSIZE 32)
endif()
set(CMAKE_POSITION_INDEPENDENT_CODE true)

#https://gitlab.inria.fr/scotch/scotch/-/blob/master/src/CMakeLists.txt#L84
# CMAKE_POSITION_INDEPENDENT_CODE=ON necessary on HPC with shared libs like MPI

if(WIN32 AND NOT SCOTCH_FOUND AND (NOT BISON_ROOT OR NOT FLEX_ROOT))

  # Check if 'win_flex_bison_url' hasn't been defined by the user (with -D)
  if(NOT DEFINED win_flex_bison_url)
    string(JSON win_flex_bison_url GET "${json}" win_flex_bison)
  endif()

  FetchContent_Declare(win_flex_bison URL ${win_flex_bison_url})
  FetchContent_MakeAvailable(win_flex_bison)

  message(DEBUG "Hint Bison,Flex path ${win_flex_bison_SOURCE_DIR}")
  find_program(_bison_exe
  NAMES bison win_bison
  HINTS ${win_flex_bison_SOURCE_DIR}
  )
  if(_bison_exe)
    cmake_path(GET _bison_exe PARENT_PATH BISON_ROOT)
  endif()

  find_program(_flex_exe
  NAMES flex win_flex
  HINTS ${win_flex_bison_SOURCE_DIR}
  )
  if(_flex_exe)
    cmake_path(GET _flex_exe PARENT_PATH FLEX_ROOT)
  endif()
endif()


# Check if 'scotch_url' hasn't been defined by the user (with -D)
if(NOT DEFINED scotch_url)
  string(JSON scotch_url GET "${json}" "scotch")
endif()

message(DEBUG "Hints to Scotch: BISON_ROOT ${BISON_ROOT}  FLEX_ROOT ${FLEX_ROOT}")

# need this here to set expected policies like CMP0077 in Scotch
if(NOT DEFINED CMAKE_POLICY_VERSION_MINIMUM)
  set(CMAKE_POLICY_VERSION_MINIMUM ${CMAKE_MINIMUM_REQUIRED_VERSION})
endif()
# CMAKE_POLICY_VERSION_MINIMUM only exists from CMake 4.0. Before that Scotch's option() calls
# clear the variables set above (BUILD_PTSCOTCH among them), so a sequential build would still
# go looking for MPI.
set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

FetchContent_Declare(SCOTCH
URL ${scotch_url}
FIND_PACKAGE_ARGS COMPONENTS ${SCOTCH_COMPONENTS}
)

FetchContent_MakeAvailable(SCOTCH)
