# --- Single Windows DLL
#
# ifx emits Fortran module variables as COMMON symbols. Those cannot be exported from a DLL
# by CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS, and Fortran has no way to import them short of an
# explicit !DIR$ ATTRIBUTES DLLIMPORT in the MUMPS sources. Splitting MUMPS over one DLL per
# library therefore fails to link: dmumps references MUMPS_BUF_COMMON / MUMPS_LR_COMMON module
# data that lives in mumps_common.
#
# Bundling every object into one shared library keeps those references inside the DLL, so only
# the C API (dmumps_c, smumps_c, ...) and the Fortran entry points need to be exported.
# Build the component libraries static (BUILD_SHARED_LIBS=off) and turn this on instead.

set(_mumps_dll_objs
$<TARGET_OBJECTS:mumps_common_C>
$<TARGET_OBJECTS:mumps_common_Fortran>
$<TARGET_OBJECTS:pord>
)

if(NOT MUMPS_parallel)
  list(APPEND _mumps_dll_objs $<TARGET_OBJECTS:mpiseq_c> $<TARGET_OBJECTS:mpiseq_fortran>)
endif()

foreach(a IN ITEMS s d c z)
  if(TARGET ${a}mumps)
    list(APPEND _mumps_dll_objs $<TARGET_OBJECTS:${a}mumps_C> $<TARGET_OBJECTS:${a}mumps_Fortran>)
  endif()
endforeach()

add_library(mumps_dll SHARED ${_mumps_dll_objs})

target_include_directories(mumps_dll PUBLIC
"$<BUILD_INTERFACE:${mumps_upstream_SOURCE_DIR}/include>"
$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# mpiseq / pord / the arithmetic objects are already inside the DLL, so only the external
# dependencies are linked here.
target_link_libraries(mumps_dll PRIVATE
LAPACK::LAPACK
$<$<AND:$<BOOL:${MUMPS_scalapack}>,$<BOOL:${MUMPS_parallel}>>:SCALAPACK::SCALAPACK>
"$<$<BOOL:${MUMPS_parallel}>:MPI::MPI_Fortran;MPI::MPI_C>"
$<$<BOOL:${MUMPS_parmetis}>:PARMETIS::PARMETIS>
$<$<BOOL:${MUMPS_metis}>:METIS::METIS>
"$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran;OpenMP::OpenMP_C>"
"$<$<BOOL:${MUMPS_gpu}>:CUDA::cublas;CUDA::cudart>"
$<$<BOOL:${MUMPS_xkblas}>:xkblas::xkblas>
$<$<BOOL:${IMPI_LIB64}>:${IMPI_LIB64}>
${CMAKE_THREAD_LIBS_INIT}
)

set_target_properties(mumps_dll PROPERTIES
OUTPUT_NAME mumps
EXPORT_NAME DLL
# C rather than Fortran so this becomes a .vcxproj: the Visual Studio generator cannot make
# ALL_BUILD (a .vcxproj) depend on a Fortran .vfproj, so a leaf .vfproj target is never built.
# link.exe picks up the Intel Fortran runtime from the /DEFAULTLIB directives in the objects,
# helped by the /LIBPATH added in cmake/compilers.cmake.
LINKER_LANGUAGE C
WINDOWS_EXPORT_ALL_SYMBOLS ON
VERSION ${MUMPS_ACTUAL_VERSION}
RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
)

add_library(MUMPS::DLL ALIAS mumps_dll)

install(TARGETS mumps_dll EXPORT ${PROJECT_NAME}-targets)
