# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindMETIS
-------

Finds the METIS library.

Imported Targets
^^^^^^^^^^^^^^^^

METIS::METIS - The METIS library

COMPONENTS
----------

``INT64``
  Use 64-bit integers for indices in METIS functions (default 32-bit)

Result Variables
^^^^^^^^^^^^^^^^

METIS_LIBRARIES
  libraries to be linked

METIS_INCLUDE_DIRS
  dirs to be included

#]=======================================================================]

include(CheckSourceCompiles)

function(metis_check _result path)

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_LINK_OPTIONS)
set(CMAKE_REQUIRED_INCLUDES ${METIS_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${path})
if(GKLIB_LIBRARY)
  list(APPEND CMAKE_REQUIRED_LIBRARIES ${GKLIB_LIBRARY})
endif()

string(MAKE_C_IDENTIFIER "${path}" _id)

check_source_compiles(C
[=[
#include <metis.h>
#include <stddef.h> // for NULL

int main(void) {
  idx_t nvtxs = 1, ncon = 1, nparts = 1, objval = 0;
  idx_t xadj[2] = {0, 0};
  idx_t adjncy[1] = {0};
  idx_t part[1] = {0};
  int r = METIS_PartGraphKway(&nvtxs, &ncon, xadj, adjncy,
                              NULL, NULL, NULL, &nparts,
                              NULL, NULL, NULL, &objval, part);
  return 0;
}
]=]
METIS_WORKS_${_id})

if(NOT METIS_WORKS_${_id})
  set(${_result} FALSE PARENT_SCOPE)
endif()

endfunction()


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

set(_metis_names metis)
if(INT64 IN_LIST METIS_FIND_COMPONENTS)
  list(PREPEND _metis_names metis64)
endif()

find_library(METIS_LIBRARY
NAMES ${_metis_names}
PATH_SUFFIXES METIS libmetis
DOC "METIS library"
VALIDATOR metis_check
)

if(METIS_LIBRARY AND INT64 IN_LIST METIS_FIND_COMPONENTS)
  set(METIS_INT64_FOUND true)
endif()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(METIS
REQUIRED_VARS METIS_LIBRARY METIS_INCLUDE_DIR
HANDLE_COMPONENTS
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
