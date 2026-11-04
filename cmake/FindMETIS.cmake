# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindMETIS
-------

Finds the METIS library.

Imported Targets
^^^^^^^^^^^^^^^^

METIS::METIS - The METIS library

Result Variables
^^^^^^^^^^^^^^^^

METIS_LIBRARIES
  libraries to be linked

METIS_INCLUDE_DIRS
  dirs to be included

#]=======================================================================]


find_library(METIS_LIBRARY
NAMES metis
PATH_SUFFIXES METIS libmetis
DOC "METIS library"
)

# METIS >= 5.2 keeps GKlib as a separate library, so an installed METIS needs it too or the
# gk_* symbols stay unresolved. Some packagings bundle GKlib into libmetis -- among them the
# METIS built by this superbuild -- so it is optional and only added when found.
find_library(GKLIB_LIBRARY
NAMES GKlib gklib
PATH_SUFFIXES METIS libmetis GKlib
DOC "GKlib library, needed by METIS >= 5.2 unless bundled into the METIS library"
)

find_path(METIS_INCLUDE_DIR
NAMES metis.h
PATH_SUFFIXES METIS
DOC "METIS include directory"
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(METIS
REQUIRED_VARS METIS_LIBRARY METIS_INCLUDE_DIR
)

if(METIS_FOUND)
  set(METIS_INCLUDE_DIRS ${METIS_INCLUDE_DIR})

  set(METIS_LIBRARIES ${METIS_LIBRARY})
  if(GKLIB_LIBRARY)
    list(APPEND METIS_LIBRARIES ${GKLIB_LIBRARY})
  endif()

  message(VERBOSE "METIS libraries: ${METIS_LIBRARIES}
  METIS include directories: ${METIS_INCLUDE_DIRS}")

  if(NOT TARGET METIS::METIS)
    add_library(METIS::METIS INTERFACE IMPORTED)
    if(GKLIB_LIBRARY)
      set_property(TARGET METIS::METIS PROPERTY INTERFACE_LINK_LIBRARIES "${METIS_LIBRARY};${GKLIB_LIBRARY}")
    else()
      set_property(TARGET METIS::METIS PROPERTY INTERFACE_LINK_LIBRARIES "${METIS_LIBRARY}")
    endif()
    set_property(TARGET METIS::METIS PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${METIS_INCLUDE_DIR}")
  endif()

endif(METIS_FOUND)

mark_as_advanced(METIS_INCLUDE_DIR METIS_LIBRARY GKLIB_LIBRARY)
