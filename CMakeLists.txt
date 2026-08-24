# CMake >= 3.28 strongly recommended for build graph reliability
cmake_minimum_required(VERSION 3.25...4.5)
# CMake >= 3.24 for FetchContent FIND_PACKAGE_ARGS
# CMAKE >= 3.25 for block(), VALIDATOR on find_*()

set(MUMPS_PROJECT_VERSION 5.9.1.0)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "Please use out of source build:
  cmake -B build")
endif()

set(_json_fn ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libraries.json)
file(READ ${_json_fn} json)

set(_source_json_fn ${CMAKE_CURRENT_SOURCE_DIR}/cmake/source.json)
file(READ ${_source_json_fn} source_json)

get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT is_multi_config AND NOT (CMAKE_BUILD_TYPE OR DEFINED ENV{CMAKE_BUILD_TYPE}))
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default" FORCE)
endif()

include(FetchContent)

if(NOT DEFINED MUMPS_url)
  if(NOT DEFINED MUMPS_UPSTREAM_VERSION)
    string(REGEX MATCH "^([0-9]+\\.[0-9]+\\.[0-9]+)" MUMPS_UPSTREAM_VERSION ${MUMPS_PROJECT_VERSION})
    if(MUMPS_UPSTREAM_VERSION STREQUAL "")
      message(FATAL_ERROR "Please define 'cmake -DMUMPS_url=...' or 'cmake -DMUMPS_UPSTREAM_VERSION=...")
    endif()
  endif()

  set(MUMPS_url "https://mumps-solver.org/MUMPS_${MUMPS_UPSTREAM_VERSION}.tar.gz")
endif()

if(DEFINED MUMPS_UPSTREAM_VERSION AND NOT DEFINED MUMPS_sha256)
  string(JSON MUMPS_sha256 ERROR_VARIABLE _jerr GET ${source_json} "mumps_sha256" "${MUMPS_UPSTREAM_VERSION}")
  if(NOT _jerr AND MUMPS_sha256)
    set(MUMPS_hash URL_HASH SHA256=${MUMPS_sha256})
  else()
    set(MUMPS_hash)
    message(STATUS "No sha256 for MUMPS ${MUMPS_UPSTREAM_VERSION} found in ${_json_fn}")
  endif()
endif()

if(DEFINED FETCHCONTENT_SOURCE_DIR_MUMPS_UPSTREAM)
  message(STATUS "MUMPS ${MUMPS_UPSTREAM_VERSION}: using source dir ${FETCHCONTENT_SOURCE_DIR_MUMPS_UPSTREAM}")
else()
  message(STATUS "MUMPS ${MUMPS_UPSTREAM_VERSION}: ${MUMPS_url} ${MUMPS_sha256}")
endif()

option(MUMPS_UPDATE_DISCONNECTED "don't check for updates of subprojects" ON)
set(FETCHCONTENT_UPDATES_DISCONNECTED ${MUMPS_UPDATE_DISCONNECTED})

FetchContent_Declare(mumps_upstream URL ${MUMPS_url} ${MUMPS_hash})
FetchContent_MakeAvailable(mumps_upstream)

# Read MUMPS/VERSION file to get the actual version
# the first line is like "MUMPS 5.7.3"
file(STRINGS "${mumps_upstream_SOURCE_DIR}/VERSION" _version_line LIMIT_COUNT 1 REGEX "^MUMPS [0-9]+\\.[0-9]+\\.[0-9]+")
message(DEBUG "MUMPS version line: ${_version_line}")
string(REGEX REPLACE "MUMPS ([0-9]+\\.[0-9]+\\.[0-9]+)" "\\1" MUMPS_ACTUAL_VERSION "${_version_line}")
if(MUMPS_UPSTREAM_VERSION AND NOT MUMPS_ACTUAL_VERSION VERSION_EQUAL MUMPS_UPSTREAM_VERSION)
  message(FATAL_ERROR "Failed to read MUMPS version ${MUMPS_UPSTREAM_VERSION} from ${mumps_upstream_SOURCE_DIR}/VERSION, got ${MUMPS_ACTUAL_VERSION} instead.")
endif()

# minimum MUMPS version
if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.2)
  message(FATAL_ERROR "MUMPS version ${MUMPS_ACTUAL_VERSION} is too old, please use MUMPS >= 5.2")
endif()

project(MUMPS
LANGUAGES C Fortran
VERSION ${MUMPS_PROJECT_VERSION}
DESCRIPTION "Sparse direct parallel solver"
HOMEPAGE_URL "https://mumps-solver.org/"
)
if(CMAKE_VERSION VERSION_LESS 3.28)
  message(WARNING "CMake >= 3.28 is strongly recommended for reliable build graph and minimal rebuilds, but you are using ${CMAKE_VERSION}.
  Consider upgrading CMake if you experience build failures.")
endif()

if(CMAKE_VERSION VERSION_GREATER 3.30.0 AND CMAKE_VERSION VERSION_LESS 3.30.4)
cmake_policy(SET CMP0168 OLD)
# workaround to stop repeat FetchContent download on each configure for CMake 3.30.0..3.30.3
endif()

enable_testing()

include(GNUInstallDirs)

# --- Checks and workarounds

if(CMAKE_Fortran_COMPILER_ID STREQUAL "LLVMFlang")
  if(CMAKE_GENERATOR MATCHES "Ninja")
    if(WIN32)
      set(_g "MinGW Makefiles")
    else()
      set(_g "Unix Makefiles")
    endif()
    message(WARNING "MUMPS: LLVM Flang with Ninja generator may fail to build. https://gitlab.kitware.com/cmake/cmake/-/issues/27702
    Recommend using Makefiles generator instead:   cmake -G \"${_g}\" -B build --fresh")
  endif()

  if(MUMPS_UPSTREAM_VERSION VERSION_LESS 5.9.1 AND NOT MUMPS_openmp)
    message(STATUS "Implementing dummy OpenMP to workaround MUMPS source files that use omp_lib but don't guard it with !$ sentinel")
    # OBJECT builds omp_lib.mod, but INTERFACE does not.
    add_library(mumps_dummy_openmp OBJECT src/dummy_openmp.f90)
    target_include_directories(mumps_dummy_openmp INTERFACE ${CMAKE_CURRENT_BINARY_DIR})  #Fortran_MODULE_DIRECTORY is empty by default
  endif()
endif()


if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin $ENV{CONDA_PREFIX}/lib $ENV{CONDA_PREFIX}/include)
  # need CMAKE_IGNORE_PATH to ensure env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

# --- user options
include(options.cmake)

if(WIN32 AND BUILD_SHARED_LIBS)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

# --- RPATH handling for transitive dependencies
if(MUMPS_ENABLE_RPATH AND NOT WIN32)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
  set(CMAKE_BUILD_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
endif()

include(cmake/compilers.cmake)

message(STATUS "MUMPS ${PROJECT_VERSION} upstream ${MUMPS_UPSTREAM_VERSION} install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CMake ${CMAKE_VERSION}  Toolchain ${CMAKE_TOOLCHAIN_FILE}")

include(cmake/MumpsGetSource.cmake)

# --- dependencies
find_package(Threads)

if(MUMPS_openmp)
  find_package(OpenMP COMPONENTS C Fortran REQUIRED)
endif()

if(MUMPS_gpu)
# see User Manual section 5.27
  find_package(CUDAToolkit REQUIRED)

  list(APPEND mumps_cdefs "USE_GPU")
  list(APPEND mumps_fdefs "USE_GPU")

# https://cmake.org/cmake/help/latest/module/FindCUDAToolkit.html
  if(MUMPS_xkblas)
    # Check if 'xkblas_url' hasn't been defined by the user (with -D)
    if(NOT DEFINED xkblas_url)
      string(JSON xkblas_url GET "${json}" "xkblas")
    endif()

    # FIXME: in the future as users contribute, we could adapt to NVHPC, etc.
    set(KAAPI_USE_CUDA_RT true)
    set(KAAPI_USE_OPENBLAS true)

    FetchContent_Declare(mumps_xkblas URL ${xkblas_url})
    FetchContent_MakeAvailable(mumps_xkblas)

    list(APPEND mumps_cdefs "USE_XKBLAS")
    list(APPEND mumps_fdefs "USE_XKBLAS")

    add_library(xkblas::xkblas ALIAS xkblas)
  endif()
endif()

# -- Scalapack / MPI
if(MUMPS_parallel)
  find_package(MPI COMPONENTS C Fortran REQUIRED)
  if(NOT DEFINED ENV{MKLROOT} AND NOT LAPACK_VENDOR MATCHES "^MKL" OR NOT MUMPS_scalapack)
    # oneMKL MKLConfig.cmake must be invoked only once
    include(cmake/lapack.cmake)
  endif()

  if(MUMPS_scalapack)
    include(cmake/scalapack.cmake) # this will also create the LAPACK::LAPACK target
  elseif(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.6)
    list(APPEND mumps_fdefs NOSCALAPACK)
  endif()

  # this is needed for Intel MPI ILP64 support
  # It's a long-known FindMPI CMake issue
  # https://discourse.cmake.org/t/problem-enabling-64-bit-fortran-compilation-on-windows-using-intel-oneapi-with-cmake-on-windows/4541
  # https://github.com/scivision/mumps-superbuild/issues/114
  if(MUMPS_intsize64 AND DEFINED ENV{I_MPI_ROOT})
    find_path(IMPI_INC64
      NAMES mpi.mod
      HINTS $ENV{I_MPI_ROOT}
      NO_DEFAULT_PATH
      PATH_SUFFIXES include/mpi/ilp64
      REQUIRED
    )
    message(STATUS "Found IMPI ILP64 include: ${IMPI_INC64}")
    list(PREPEND MPI_Fortran_INCLUDE_DIRS ${IMPI_INC64})

    find_library(IMPI_LIB64
      NAMES mpi_ilp64 libmpi_ilp64
      HINTS $ENV{I_MPI_ROOT}
      NO_DEFAULT_PATH
      PATH_SUFFIXES lib
      REQUIRED
    )
    message(STATUS "Found IMPI ILP64 library: ${IMPI_LIB64}")
  endif()

else()

  include(cmake/lapack.cmake)
  set(MPI_C_INCLUDE_DIRS       ${mumps_upstream_SOURCE_DIR}/libseq)
  set(MPI_Fortran_INCLUDE_DIRS ${mumps_upstream_SOURCE_DIR}/libseq)

  configure_file(cmake/libseq.cmake
  ${mumps_upstream_SOURCE_DIR}/libseq/CMakeLists.txt
  COPYONLY
  )
  add_subdirectory(${mumps_upstream_SOURCE_DIR}/libseq libseq)

endif()

# GEMMT is recommended in MUMPS User Manual if available
if(MUMPS_gemmt)
  include(cmake/gemmt.cmake)
  if(BLAS_HAVE_GEMMT)
    list(APPEND mumps_fdefs GEMMT_AVAILABLE)
  endif()
endif()

# AVX512 VBMI instruction set accelerates adaptive precision with BLR (starting with mumps 5.9.0)
if(MUMPS_ACTUAL_VERSION VERSION_GREATER_EQUAL 5.9.0 AND MUMPS_avx512)
  include(cmake/avx512vbmi.cmake)
  if(MUMPS_HAVE_AVX512VBMI)
    list(APPEND mumps_fdefs USE_AVX512_VBMI)
    list(APPEND mumps_cdefs USE_AVX512_VBMI)
    add_compile_options("$<$<COMPILE_LANGUAGE:C>:${MUMPS_AVX512VBMI_CFLAGS}>")
  else()
    message(WARNING "MUMPS_avx512=on, but AVX512 VBMI instruction set not detected on this system. Please check compiler and CPU support.")
  endif()
endif()

# --- ordering libs

set(ORDERING_DEFS pord)

if(MUMPS_scotch)
  include(cmake/scotch.cmake)

  list(APPEND ORDERING_DEFS scotch $<$<BOOL:${MUMPS_parallel}>:ptscotch>)
endif()



if(MUMPS_metis OR MUMPS_parmetis)
  set(IDXTYPEWIDTH 32)
  if(MUMPS_intsize64)
    set(IDXTYPEWIDTH 64)
  endif()

  if(MUMPS_parmetis)
    set(_metis_components COMPONENTS ParMETIS)
  else()
    set(_metis_components)
  endif()

  # Check if 'metis_url' hasn't been defined by the user (with -D)
  if(NOT DEFINED metis_url)
    if(MUMPS_parmetis)
      string(JSON metis_url GET "${json}" "parmetis")
    else()
      string(JSON metis_url GET "${json}" "metis")
    endif()
  endif()

  # FetchContent derives the find_package() name from the content name, so the FIND_PACKAGE_ARGS
  # below looks for a package called "mumps_metis" and cmake/FindMETIS.cmake is never reached.
  # The content cannot simply be renamed to METIS: scivision/parmetis declares its own METIS
  # content and the first declaration wins, which would leave ParMETIS without a real METIS.
  # Look METIS up explicitly instead, opt-in so that building it stays the default.
  if(MUMPS_find_metis OR DEFINED METIS_ROOT OR DEFINED ENV{METIS_ROOT})
    find_package(METIS ${_metis_components})
  endif()

  if(NOT METIS_FOUND)
    FetchContent_Declare(mumps_metis
    URL ${metis_url}
    FIND_PACKAGE_ARGS ${_metis_components}
    )

    FetchContent_MakeAvailable(mumps_metis)
  endif()

  list(APPEND ORDERING_DEFS REALTYPEWIDTH=32 IDXTYPEWIDTH=${IDXTYPEWIDTH} metis)

endif()

install(FILES
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindLAPACK.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindSCALAPACK.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindMETIS.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindSCOTCH.cmake
DESTINATION cmake
)

message(STATUS "MUMPS ORDERING_DEFS: ${ORDERING_DEFS}")
message(STATUS "MUMPS C definitions: ${mumps_cdefs}")
message(STATUS "MUMPS Fortran definitions: ${mumps_fdefs}")
message(STATUS "MUMPS LAPACK_VENDOR: ${LAPACK_VENDOR}")
message(STATUS "MUMPS SCALAPACK_VENDOR: ${SCALAPACK_VENDOR}")

# --- MUMPS build

# --- PORD (always used)
configure_file(cmake/pord.cmake
${mumps_upstream_SOURCE_DIR}/PORD/lib/CMakeLists.txt
COPYONLY)
add_subdirectory(${mumps_upstream_SOURCE_DIR}/PORD/lib PORD/lib)

# --- MUMPS itself
configure_file(cmake/mumps.cmake
${mumps_upstream_SOURCE_DIR}/src/CMakeLists.txt
COPYONLY)
add_subdirectory(${mumps_upstream_SOURCE_DIR}/src src)

# Several MUMPS Fortran/C sources call pthread APIs directly (e.g. for
# I/O locking / OpenMP-adjacent synchronization), but none of the MUMPS
# targets explicitly link Threads::Threads, only relying on it being
# pulled in transitively by whichever BLAS/LAPACK/SCALAPACK/MPI backend
# happens to depend on pthread. Some backends (e.g. a shared OpenBLAS, or
# certain MPI implementations) don't expose that dependency transitively,
# leaving these symbols unresolved at link time on those configurations.
# Link Threads::Threads directly on the MUMPS targets so the pthread
# symbols they use are always resolved regardless of backend.
if(Threads_FOUND)
  foreach(tgt IN ITEMS MUMPS::COMMON MUMPS::SMUMPS MUMPS::DMUMPS MUMPS::CMUMPS MUMPS::ZMUMPS MUMPS::PORD)
    if(TARGET ${tgt})
      target_link_libraries(${tgt} INTERFACE Threads::Threads)
    endif()
  endforeach()
endif()

if(MUMPS_matlab)
  configure_file(cmake/matlab.cmake
  ${mumps_upstream_SOURCE_DIR}/MATLAB/CMakeLists.txt
  COPYONLY
  )
  add_subdirectory(${mumps_upstream_SOURCE_DIR}/MATLAB MATLAB)
endif()


if(${PROJECT_NAME}_BUILD_TESTING)
  add_subdirectory(test)
endif()


# --- feature summary

message(STATUS "Configured MUMPS ${MUMPS_ACTUAL_VERSION} source in ${mumps_upstream_SOURCE_DIR}")

if(MUMPS_IS_TOP_LEVEL)

find_program(GRAPHVIZ_DOT NAMES dot)
if(GRAPHVIZ_DOT)
    set(_graph_name ${PROJECT_BINARY_DIR}/graphviz/${PROJECT_NAME})
    add_custom_target(graphviz
      COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/graphviz
      COMMAND ${CMAKE_COMMAND} --graphviz=${_graph_name}.dot -B${PROJECT_BINARY_DIR} -S${PROJECT_SOURCE_DIR}
      COMMAND ${GRAPHVIZ_DOT} -Tsvg ${_graph_name}.dot -o ${_graph_name}.svg
      COMMAND ${CMAKE_COMMAND} -E echo "CMake ${PROJECT_NAME} targets graph: ${_graph_name}.svg"
    )
endif()

endif()

if(MUMPS_IS_TOP_LEVEL)
  include(cmake/summary.cmake)
endif()

include(cmake/install.cmake)

file(GENERATE OUTPUT .gitignore CONTENT "*")
