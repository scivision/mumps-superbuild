###
#
# @copyright (c) 2009-2014 The University of Tennessee and The University
#                          of Tennessee Research Foundation.
#                          All rights reserved.
# @copyright (c) 2012-2014 Inria. All rights reserved.
# @copyright (c) 2012-2014 Bordeaux INP, CNRS (LaBRI UMR 5800), Inria, Univ. Bordeaux. All rights reserved.
#
###
#
# - Find Scotch include dirs and libraries
#  This does not check that intsize and realsize are compatible.
#
#  COMPONENTS:
#
#  * ESMUMPS: detect Scotch esmumps interface
#  * PTScotch: detect parallel (MPI) Scotch
#
# This module finds headers and scotch library.
# Results are reported in variables:
#  SCOTCH_FOUND           - True if headers and requested libraries were found
#  SCOTCH_INCLUDE_DIRS    - scotch include directories
#  SCOTCH_LIBRARIES       - scotch component libraries to be linked
#
# Imported Targets
# ^^^^^^^^^^^^^^^^
#
# SCOTCH::scotch
#
#=============================================================================
# Copyright 2012-2013 Inria
# Copyright 2012-2013 Emmanuel Agullo
# Copyright 2012-2013 Mathieu Faverge
# Copyright 2012      Cedric Castagnede
# Copyright 2013      Florent Pruvost
# (C) 2018-2025 SciVision
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file MORSE-Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================

set(scotch_h scotch.h)
if(PTScotch IN_LIST SCOTCH_FIND_COMPONENTS)
  string(PREPEND scotch_h pt)
endif()

find_path(SCOTCH_INCLUDE_DIR
NAMES ${scotch_h}
PATH_SUFFIXES scotch
DOC "Scotch include directory"
)
# PATH_SUFFIXES scotch
# for Ubuntu, Debian, RHEL, ...

set(SCOTCH_LIBRARIES)
# need plain scotch when using ptscotch
if(PTScotch IN_LIST SCOTCH_FIND_COMPONENTS)
  find_library(SCOTCH_ptscotch_LIBRARY
  NAMES ptscotch
  DOC "Parallel Scotch library"
  )
  list(APPEND SCOTCH_LIBRARIES ${SCOTCH_ptscotch_LIBRARY})
endif()

find_library(SCOTCH_scotch_LIBRARY
NAMES scotch
DOC "Scotch library"
)
list(APPEND SCOTCH_LIBRARIES ${SCOTCH_scotch_LIBRARY})


if(PTScotch IN_LIST SCOTCH_FIND_COMPONENTS)
  find_library(SCOTCH_ptscotcherr_LIBRARY
  NAMES ptscotcherr
  DOC "Scotch PTScotchErr library"
  )
  list(APPEND SCOTCH_LIBRARIES ${SCOTCH_ptscotcherr_LIBRARY})
endif()

find_library(SCOTCH_scotcherr_LIBRARY
NAMES scotcherr
DOC "Scotch ScotchErr library"
)
list(APPEND SCOTCH_LIBRARIES ${SCOTCH_scotcherr_LIBRARY})


if(ESMUMPS IN_LIST SCOTCH_FIND_COMPONENTS)
  if(PTScotch IN_LIST SCOTCH_FIND_COMPONENTS)
    find_library(SCOTCH_ptesmumps_LIBRARY
    NAMES ptesmumps
    DOC "Scotch PTESMUMPS library"
    )
    list(APPEND SCOTCH_LIBRARIES ${SCOTCH_ptesmumps_LIBRARY})
  endif()

  find_library(SCOTCH_esmumps_LIBRARY
  NAMES esmumps
  DOC "Scotch ESMUMPS library"
  )
  list(APPEND SCOTCH_LIBRARIES ${SCOTCH_esmumps_LIBRARY})
endif()


if(PTScotch IN_LIST SCOTCH_FIND_COMPONENTS)
  if(SCOTCH_ptesmumps_LIBRARY AND SCOTCH_ptscotch_LIBRARY)
    set(SCOTCH_ESMUMPS_FOUND true)
    set(SCOTCH_PTScotch_FOUND true)
  endif()
elseif(SCOTCH_esmumps_LIBRARY)
  set(SCOTCH_ESMUMPS_FOUND true)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCOTCH
REQUIRED_VARS SCOTCH_LIBRARIES SCOTCH_INCLUDE_DIR
HANDLE_COMPONENTS
)

if(SCOTCH_FOUND)
  set(SCOTCH_INCLUDE_DIRS ${SCOTCH_INCLUDE_DIR})

  message(DEBUG "Scotch libraries: ${SCOTCH_LIBRARIES}")
  message(DEBUG "Scotch include directories: ${SCOTCH_INCLUDE_DIRS}")

  foreach(l IN ITEMS scotcherr ptscotcherr scotch ptscotch esmumps ptesmumps)
    if(SCOTCH_${l}_LIBRARY AND NOT TARGET SCOTCH::${l})
      add_library(SCOTCH::${l} INTERFACE IMPORTED)
      set_property(TARGET SCOTCH::${l} PROPERTY INTERFACE_LINK_LIBRARIES "${SCOTCH_${l}_LIBRARY}")
      set_property(TARGET SCOTCH::${l} PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${SCOTCH_INCLUDE_DIR}")
      mark_as_advanced(${SCOTCH_${l}_LIBRARY})
    endif()
  endforeach()
endif()

mark_as_advanced(SCOTCH_INCLUDE_DIR)
