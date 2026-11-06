# Generate pkg-config files, so that non-CMake consumers (Meson, Autotools, plain Makefiles) can
# find MUMPS. CMake consumers use MUMPSConfig.cmake instead and do not need these.
#
# One file per enabled arithmetic, named after the library it wraps: smumps, dmumps, cmumps,
# zmumps. Consumers looking for the conda-forge "<a>mumps_seq" names generally fall back to these.

# Convert a CMake link list (absolute paths, frameworks, bare names, flags) into pkg-config flags.
# Imported targets cannot be expressed in pkg-config and are skipped.
function(mumps_pc_flags out)

set(_flags)

foreach(item IN LISTS ARGN)
  if(NOT item)
    continue()
  endif()

  if(item MATCHES "^-")
    list(APPEND _flags "${item}")
  elseif(item MATCHES "\\.framework/?$")
    cmake_path(GET item STEM _stem)
    list(APPEND _flags "-framework ${_stem}")
  elseif(item MATCHES "::")
    # imported target, e.g. LAPACK::LAPACK -- no pkg-config equivalent
  elseif(IS_ABSOLUTE "${item}")
    cmake_path(GET item PARENT_PATH _dir)
    cmake_path(GET item STEM _stem)
    string(REGEX REPLACE "^lib" "" _stem "${_stem}")
    list(APPEND _flags "-L${_dir}" "-l${_stem}")
  else()
    list(APPEND _flags "-l${item}")
  endif()
endforeach()

list(REMOVE_DUPLICATES _flags)
list(JOIN _flags " " _joined)

set(${out} "${_joined}" PARENT_SCOPE)

endfunction()


# External dependencies are only needed on the consumer's link line for a static MUMPS, so they
# go in Libs.private, which pkg-config emits only for --static.
set(_pc_external ${LAPACK_LIBRARIES} ${PARMETIS_LIBRARIES} ${METIS_LIBRARIES} ${SCOTCH_LIBRARIES}
${OpenMP_C_LIBRARIES} ${OpenMP_Fortran_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT}
)

# MUMPS is mostly Fortran, so a C or C++ consumer linking it statically needs the Fortran runtime.
# CMake gives MUMPSConfig.cmake this for free through its own Fortran link handling, but
# pkg-config has to be told, otherwise such a consumer fails on __gfortran_* and similar.
foreach(d IN LISTS CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES)
  list(APPEND _pc_external "-L${d}")
endforeach()
list(APPEND _pc_external ${CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES})
if(MUMPS_parallel)
  list(APPEND _pc_external ${SCALAPACK_LIBRARIES} ${MPI_C_LIBRARIES} ${MPI_Fortran_LIBRARIES})
endif()

# ScaLAPACK and the ordering libraries, when built from source, are targets in this build rather
# than find_package results, so there is no path to report. They install into this same prefix, so
# name them and let the -L${libdir} already in Libs resolve them.
if(MUMPS_parallel AND NOT SCALAPACK_LIBRARIES)
  list(APPEND _pc_external scalapack)
endif()
# ParMETIS is listed before METIS, and METIS before GKlib, because each needs symbols from the
# next and a static link line is resolved in order. MUMPS_parmetis pulls in METIS whether or not
# MUMPS_metis is set, so METIS is named for either.
if(MUMPS_parmetis AND NOT PARMETIS_LIBRARIES)
  list(APPEND _pc_external parmetis)
endif()
if((MUMPS_metis OR MUMPS_parmetis) AND NOT METIS_LIBRARIES)
  list(APPEND _pc_external metis)
  if(TARGET GKlib)
    list(APPEND _pc_external GKlib)
  endif()
endif()
if(MUMPS_scotch AND NOT SCOTCH_LIBRARIES)
  if(MUMPS_ptscotch)
    list(APPEND _pc_external ptesmumps ptscotch ptscotcherr)
  endif()
  list(APPEND _pc_external esmumps scotch scotcherr)
endif()

mumps_pc_flags(_pc_libs_private ${_pc_external})

# Libraries from this same install that every arithmetic needs.
set(_pc_common mumps_common pord)
if(NOT MUMPS_parallel)
  list(APPEND _pc_common mpiseq_fortran mpiseq_c)
endif()

set(_pc_desc_s "single precision real (float32)")
set(_pc_desc_d "double precision real (float64)")
set(_pc_desc_c "single precision complex (complex64)")
set(_pc_desc_z "double precision complex (complex128)")

set(_pc_ariths)
if(BUILD_SINGLE)
  list(APPEND _pc_ariths s)
endif()
if(BUILD_DOUBLE)
  list(APPEND _pc_ariths d)
endif()
if(BUILD_COMPLEX)
  list(APPEND _pc_ariths c)
endif()
if(BUILD_COMPLEX16)
  list(APPEND _pc_ariths z)
endif()

if(MUMPS_parallel)
  set(_pc_flavor "parallel")
else()
  set(_pc_flavor "sequential")
endif()

set(_pc_files)

foreach(a IN LISTS _pc_ariths)
  set(_pc_name "${a}mumps")
  set(_pc_description
  "MUMPS sparse direct solver (${_pc_flavor}), ${_pc_desc_${a}}"
  )

  set(_pc_libs "-l${a}mumps")
  foreach(l IN LISTS _pc_common)
    string(APPEND _pc_libs " -l${l}")
  endforeach()

  configure_file(${CMAKE_CURRENT_LIST_DIR}/mumps.pc.in
  ${PROJECT_BINARY_DIR}/pkgconfig/${a}mumps.pc
  @ONLY
  )
  list(APPEND _pc_files ${PROJECT_BINARY_DIR}/pkgconfig/${a}mumps.pc)
endforeach()

install(FILES ${_pc_files} DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
