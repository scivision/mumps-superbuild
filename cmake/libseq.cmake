# this directory only takes effect if MUMPS_parallel is OFF
# it's a phony MPI library to let MUMPS use the same function calls on a single worker.

mumps_get_src(mpiseq_c_sources mpiseq c)

add_library(mpiseq_c ${mpiseq_c_sources})
target_include_directories(mpiseq_c PUBLIC
"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mumps_seq/>
)
target_compile_options(mpiseq_c PRIVATE ${mumps_cflags})
target_compile_definitions(mpiseq_c PRIVATE ${mumps_cdefs})

mumps_get_src(mpiseq_fortran_sources mpiseq fortran)

add_library(mpiseq_fortran ${mpiseq_fortran_sources} $<TARGET_OBJECTS:mpiseq_c>)
# BUILD_SHARED_LIBS=on reveals that $<TARGET_OBJECTS:mpiseq_c> is needed in the Fortran target
target_include_directories(mpiseq_fortran PUBLIC
"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mumps_seq/>
)
target_compile_options(mpiseq_fortran PRIVATE ${mumps_fflags})
target_link_libraries(mpiseq_fortran INTERFACE mpiseq_c)

# we don't use this target directly, but it's to be compatible with other build systems that make a
# libmpiseq file
add_library(mpiseq $<TARGET_OBJECTS:mpiseq_c> $<TARGET_OBJECTS:mpiseq_fortran>)
target_link_libraries(mpiseq PUBLIC mpiseq_fortran mpiseq_c)
target_link_options(mpiseq PRIVATE
	"$<$<BOOL:${MSVC}>:/LIBPATH:${CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES}>"
)

set_target_properties(mpiseq PROPERTIES
EXPORT_NAME MPISEQ
LIBRARY_OUTPUT_DIRECTORY ${MUMPS_BINARY_DIR}/lib
ARCHIVE_OUTPUT_DIRECTORY ${MUMPS_BINARY_DIR}/lib
)

if(CMAKE_VERSION VERSION_GREATER_EQUAL 4.1)
  set_target_properties(mpiseq mpiseq_c mpiseq_fortran PROPERTIES SPDX_LICENSE "CECILL-C")
endif()

install(TARGETS mpiseq mpiseq_c mpiseq_fortran EXPORT ${PROJECT_NAME}-targets)

# mpi.f doesn't have Fortran module
install(FILES elapse.h mpi.h mpif.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mumps_seq/)

# This is used in place of find_package(MPI) in MUMPS when MUMPS_parallel is OFF
add_library(MPI::MPI_C ALIAS mpiseq_c)
add_library(MPI::MPI_Fortran ALIAS mpiseq_fortran)
