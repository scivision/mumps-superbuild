# -- generated MUMPS_INTSIZE header
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.5)
  set(intsrc ${CMAKE_CURRENT_SOURCE_DIR}/mumps_int_def)
  if(MUMPS_intsize64)
    string(APPEND intsrc 64_h.in)
  else()
    string(APPEND intsrc 32_h.in)
  endif()
  configure_file(${intsrc} ${CMAKE_CURRENT_SOURCE_DIR}/../include/mumps_int_def.h COPYONLY)
else()
  if(MUMPS_intsize64)
    set(MUMPS_INTSIZE MUMPS_INTSIZE64)
  else()
    set(MUMPS_INTSIZE MUMPS_INTSIZE32)
  endif()
  file(CONFIGURE OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/../include/mumps_int_def.h
CONTENT "#ifndef MUMPS_INT_H
#define MUMPS_INT_H
#define ${MUMPS_INTSIZE}
#endif"
@ONLY)
endif()

# -- Mumps COMMON
mumps_get_src(COMM_SRC_Fortran comm_src_fortran base)

if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.3)
  mumps_get_src(_c comm_src_fortran ge_5_3)
  list(APPEND COMM_SRC_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.6)
  mumps_get_src(_c comm_src_fortran ge_5_6)
  list(APPEND COMM_SRC_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.7)
  mumps_get_src(_c comm_src_fortran ge_5_7)
  list(APPEND COMM_SRC_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.8)
  mumps_get_src(_c comm_src_fortran lt_5_8)
  list(APPEND COMM_SRC_Fortran ${_c})
else()
  mumps_get_src(_c comm_src_fortran ge_5_8)
  list(APPEND COMM_SRC_Fortran ${_c})
endif()

mumps_get_src(COMM_OTHER_C comm_c base)

mumps_get_src(COMM_OTHER_Fortran comm_fortran base)

if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.6)
  mumps_get_src(_c comm_c lt_5_6)
  list(APPEND COMM_OTHER_C ${_c})
else()
  mumps_get_src(_c comm_c ge_5_6)
  list(APPEND COMM_OTHER_C ${_c})
endif()

if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.3)
  mumps_get_src(_c comm_fortran ge_5_3)
  list(APPEND COMM_OTHER_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.4)
  mumps_get_src(_c comm_c ge_5_4)
  list(APPEND COMM_OTHER_C ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.7)
  mumps_get_src(_c comm_fortran lt_5_7)
  list(APPEND COMM_OTHER_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.8)
  mumps_get_src(_c comm_c ge_5_8)
  list(APPEND COMM_OTHER_C ${_c})
  if(WIN32 AND MUMPS_HAVE_AVX512VBM)
    set_property(SOURCE mumps_flytes.c APPEND
      PROPERTY COMPILE_OPTIONS "$<$<COMPILE_LANG_AND_ID:C,IntelLLVM>:-Wno-incompatible-pointer-types>")
  endif()
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.9)
  mumps_get_src(_c comm_c ge_5_9)
  list(APPEND COMM_OTHER_C ${_c})
endif()

if(MUMPS_scotch)
  mumps_get_src(_c comm_c scotch)
  list(APPEND COMM_OTHER_C ${_c})
endif()
if(MUMPS_metis OR MUMPS_parmetis)
  mumps_get_src(_c comm_c metis)
  list(APPEND COMM_OTHER_C ${_c})
endif()

add_library(mumps_common_C OBJECT ${COMM_OTHER_C})
target_link_libraries(mumps_common_C PRIVATE
MPI::MPI_C
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_C>
)
target_compile_definitions(mumps_common_C PRIVATE ${mumps_cdefs})
target_compile_options(mumps_common_C PRIVATE ${mumps_cflags})

add_library(mumps_common_Fortran OBJECT ${COMM_SRC_Fortran} ${COMM_OTHER_Fortran})
target_link_libraries(mumps_common_Fortran PRIVATE
MPI::MPI_Fortran
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
)
target_compile_definitions(mumps_common_Fortran PRIVATE ${mumps_fdefs})
target_compile_options(mumps_common_Fortran PRIVATE ${mumps_fflags})

get_property(mumps_common_Fortran_defs TARGET mumps_common_Fortran PROPERTY COMPILE_DEFINITIONS)
message(DEBUG "mumps_common_Fortran compile definitions: ${mumps_common_Fortran_defs}")
if("MPI_TO_K_OMP" IN_LIST mumps_common_Fortran_defs OR
   NOT CMAKE_GENERATOR MATCHES "MinGW|Unix Makefiles")
   # Error copying Fortran module "src/mumps_mpitoomp_m.mod" with GNU Make
   # the issue seems to be that the Fortran module is only present if MPI_TO_K_OMP is defined.
   # detect if this worked as intended - assuming MPI_TO_K_OMP not defined and building with Ninja:
   #   nm build/src/CMakeFiles/mumps_common_Fortran.dir/mumps_mpitoomp_m.F.o
   # should see like "T _mumps_mpitoomp_m_return_"
  target_sources(mumps_common_Fortran PRIVATE mumps_mpitoomp_m.F)
endif()

add_library(mumps_common $<TARGET_OBJECTS:mumps_common_Fortran> $<TARGET_OBJECTS:mumps_common_C>)
target_link_options(mumps_common PRIVATE
  "$<$<BOOL:${MSVC}>:/LIBPATH:${CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES}>"
)

# use MPI_Fortran_INCLUDE_DIRS directly to avoid MPICH Fortran -fallow flag leakage

foreach(t IN ITEMS mumps_common mumps_common_C mumps_common_Fortran)
  target_include_directories(${t} PUBLIC
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR};${CMAKE_CURRENT_SOURCE_DIR}/../include>"
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

  if(MUMPS_ptscotch)
    target_link_libraries(${t} PUBLIC SCOTCH::ptesmumps SCOTCH::ptscotch SCOTCH::ptscotcherr)
  endif()
  if(MUMPS_scotch)
    target_link_libraries(${t} PUBLIC SCOTCH::esmumps SCOTCH::scotch SCOTCH::scotcherr)
  endif()

  target_link_libraries(${t} PUBLIC
  $<$<BOOL:${MUMPS_parmetis}>:PARMETIS::PARMETIS>
  $<$<BOOL:${MUMPS_metis}>:METIS::METIS>
  pord
  $<$<AND:$<BOOL:${MUMPS_scalapack}>,$<BOOL:${MUMPS_parallel}>>:SCALAPACK::SCALAPACK>
  LAPACK::LAPACK
  "$<$<BOOL:${MUMPS_gpu}>:CUDA::cublas;CUDA::cudart>"
  $<$<BOOL:${MUMPS_xkblas}>:xkblas::xkblas>
  $<$<BOOL:${IMPI_LIB64}>:${IMPI_LIB64}>
  ${CMAKE_THREAD_LIBS_INIT}
  )

  target_compile_definitions(${t} PRIVATE ${ORDERING_DEFS})
endforeach()

target_link_libraries(mumps_common PRIVATE
MPI::MPI_Fortran MPI::MPI_C
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_C>
)
# this is needed for mpiseq, and is best for clarity and consistency

if(BUILD_SHARED_LIBS AND APPLE AND CMAKE_Fortran_COMPILER_ID STREQUAL "LLVMFlang")
  # flang linker can't handle -dynamiclib flag
  set_property(TARGET mumps_common PROPERTY LINKER_LANGUAGE C)
endif()

set_target_properties(mumps_common PROPERTIES
EXPORT_NAME COMMON
VERSION ${MUMPS_ACTUAL_VERSION}
LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
)

install(TARGETS mumps_common EXPORT ${PROJECT_NAME}-targets)

# --- MUMPS::MUMPS exported target
# MUMPS::MUMPS is the target most users will link to.
add_library(MUMPS INTERFACE)

function(precision_source a)

mumps_get_src(SRC_C arith_c base)
list(TRANSFORM SRC_C PREPEND ${a})

mumps_get_src(SRC_Fortran arith_fortran base)

if(MUMPS_Ninja_preprocess_workaround)
  # We have asked MUMPS devs to use different syntax, but they declined as this is really a Flang bug.
  # we have opened an LLVM bug report https://github.com/llvm/llvm-project/issues/202815
  # this workaround works because these 3 source files don't depend on each other for Fortran modules,
  # so we can skip Ninja module dependency discovery for these files as a workaround for
  # https://gitlab.kitware.com/cmake/cmake/-/issues/27702
  set_property(SOURCE ${a}fac_asm.F ${a}fac_asm_master_m.F ${a}fac_asm_master_ELT_m.F PROPERTY Fortran_PREPROCESS false)
endif()

if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.3)
  mumps_get_src(_c arith_fortran ge_5_3)
  list(APPEND SRC_Fortran ${_c})
endif()
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.6)
  mumps_get_src(_c arith_fortran ge_5_6)
  list(APPEND SRC_Fortran ${_c})
endif()

if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.8)
  mumps_get_src(_c arith_fortran lt_5_8)
  list(APPEND SRC_Fortran ${_c})
else()
  mumps_get_src(_c arith_fortran ge_5_8)
  list(APPEND SRC_Fortran ${_c})
endif()

if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.7)
  mumps_get_src(_c arith_fortran ge_5_7)
  list(APPEND SRC_Fortran ${_c})
endif()

list(TRANSFORM SRC_Fortran PREPEND ${a})

mumps_get_src(CINT_SRC cint base)

add_library(${a}mumps_C OBJECT ${CINT_SRC} ${SRC_C})
target_compile_definitions(${a}mumps_C PRIVATE ${ORDERING_DEFS} ${mumps_cdefs} MUMPS_ARITH=MUMPS_ARITH_${a})
target_compile_options(${a}mumps_C PRIVATE ${mumps_cflags})
target_link_libraries(${a}mumps_C PRIVATE
MPI::MPI_C
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_C>
)

add_library(${a}mumps_Fortran OBJECT ${SRC_Fortran})
target_link_libraries(${a}mumps_Fortran PRIVATE
MPI::MPI_Fortran
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
$<$<TARGET_EXISTS:mumps_dummy_openmp>:mumps_dummy_openmp>
)
target_compile_definitions(${a}mumps_Fortran PRIVATE ${ORDERING_DEFS} ${mumps_fdefs})
target_compile_options(${a}mumps_Fortran PRIVATE ${mumps_fflags})

add_library(${a}mumps $<TARGET_OBJECTS:${a}mumps_C> $<TARGET_OBJECTS:${a}mumps_Fortran>)

if(WIN32 AND BUILD_SHARED_LIBS)
  # Automatic DLL exports cannot make Fortran module data consumable without
  # dllimport annotations, so keep common data in the same DLL as its users.
  target_sources(${a}mumps PRIVATE
    $<TARGET_OBJECTS:mumps_common_Fortran>
    $<TARGET_OBJECTS:mumps_common_C>
  )
endif()

target_link_options(${a}mumps PRIVATE
  "$<$<BOOL:${MSVC}>:/LIBPATH:${CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES}>"
)

foreach(t IN ITEMS ${a}mumps ${a}mumps_C ${a}mumps_Fortran)

  target_include_directories(${t} PUBLIC
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../include>"
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )
  target_link_libraries(${t} PUBLIC mumps_common)

endforeach()

target_link_libraries(${a}mumps PRIVATE
MPI::MPI_Fortran
$<$<BOOL:${MUMPS_openmp}>:OpenMP::OpenMP_Fortran>
)
# MPI::MPI_Fortran is needed for mpiseq as well

string(TOUPPER ${a} aup)

set_target_properties(${a}mumps PROPERTIES
EXPORT_NAME ${aup}MUMPS
VERSION ${MUMPS_ACTUAL_VERSION}
LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
)

if(BUILD_SHARED_LIBS AND APPLE AND CMAKE_Fortran_COMPILER_ID STREQUAL "LLVMFlang")
  # flang linker can't handle -dynamiclib flag
  set_property(TARGET ${a}mumps PROPERTY LINKER_LANGUAGE C)
endif()

target_link_libraries(MUMPS INTERFACE ${a}mumps)

install(TARGETS ${a}mumps EXPORT ${PROJECT_NAME}-targets)

install(FILES
${CMAKE_CURRENT_SOURCE_DIR}/../include/${a}mumps_c.h
${CMAKE_CURRENT_SOURCE_DIR}/../include/${a}mumps_struc.h
${CMAKE_CURRENT_SOURCE_DIR}/../include/mumps_int_def.h
TYPE INCLUDE
)

endfunction()

if(BUILD_SINGLE)
  precision_source("s")
endif()
if(BUILD_DOUBLE)
  precision_source("d")
endif()
if(BUILD_COMPLEX)
  precision_source("c")
endif()
if(BUILD_COMPLEX16)
  precision_source("z")
endif()


install(FILES
${CMAKE_CURRENT_SOURCE_DIR}/../include/mumps_c_types.h
${CMAKE_CURRENT_SOURCE_DIR}/../include/mumps_compat.h
TYPE INCLUDE
)

install(TARGETS MUMPS EXPORT ${PROJECT_NAME}-targets)

add_library(MUMPS::MUMPS ALIAS MUMPS)
