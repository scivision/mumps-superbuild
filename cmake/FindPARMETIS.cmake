# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindParMETIS
-------

Finds the ParMETIS library (may be fulfilled by Scotch ParMETIS interface layer).

Imported Targets
^^^^^^^^^^^^^^^^

PARMETIS::PARMETIS - The ParMETIS library

Result Variables
^^^^^^^^^^^^^^^^

PARMETIS_LIBRARIES
  libraries to be linked

PARMETIS_INCLUDE_DIRS
  dirs to be included

#]=======================================================================]


find_library(PARMETIS_LIBRARY
NAMES parmetis
PATH_SUFFIXES METIS libmetis
HINTS ${SCOTCH_ROOT} $ENV{SCOTCH_ROOT}
DOC "ParMETIS library"
)

find_path(PARMETIS_INCLUDE_DIR
NAMES parmetis.h
PATH_SUFFIXES METIS
HINTS ${SCOTCH_ROOT} $ENV{SCOTCH_ROOT}
DOC "ParMETIS include directory"
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PARMETIS
REQUIRED_VARS PARMETIS_LIBRARY PARMETIS_INCLUDE_DIR
)

if(PARMETIS_FOUND)
  set(PARMETIS_INCLUDE_DIRS ${PARMETIS_INCLUDE_DIR})
  set(PARMETIS_LIBRARIES ${PARMETIS_LIBRARY})

  if(NOT TARGET PARMETIS::PARMETIS)
    add_library(PARMETIS::PARMETIS INTERFACE IMPORTED)
    set_property(TARGET PARMETIS::PARMETIS PROPERTY INTERFACE_LINK_LIBRARIES "${PARMETIS_LIBRARY}")
    set_property(TARGET PARMETIS::PARMETIS PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${PARMETIS_INCLUDE_DIR}")
  endif()

endif(PARMETIS_FOUND)

mark_as_advanced(PARMETIS_INCLUDE_DIR PARMETIS_LIBRARY)
