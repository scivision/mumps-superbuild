# Apple Accelerate with 64-bit integers (ILP64) for Fortran.
#
# Accelerate exports its 64-bit-integer entry points only as "<name>$NEWLAPACK$ILP64" symbols,
# which a Fortran compiler cannot name. accelerate-lapack generates Apple linker alias lists
# mapping those onto the usual "<name>_" symbols and attaches them to LAPACK::LAPACK, which is
# what the MUMPS targets link.
# https://github.com/lepus2589/accelerate-lapack

# The alias lists are generated from the Accelerate stubs of a MacOS SDK, so that SDK has to be
# the one the linker actually uses: a mismatch fails the link on symbols declared in one but
# absent from the other. Homebrew GCC has its sysroot baked in and is never told about
# CMAKE_OSX_SYSROOT, so take the SDK from the compiler rather than from xcrun, which can report a
# newer SDK than the Accelerate binary installed on this system.
if(NOT CMAKE_OSX_SYSROOT)
  execute_process(COMMAND ${CMAKE_Fortran_COMPILER} -v
  OUTPUT_QUIET
  ERROR_VARIABLE _fc_verbose
  ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(_fc_verbose MATCHES "--with-sysroot=([^ \t\r\n]+)")
    set(CMAKE_OSX_SYSROOT ${CMAKE_MATCH_1})
    message(STATUS "Accelerate ILP64: using ${CMAKE_Fortran_COMPILER_ID} Fortran sysroot ${CMAKE_OSX_SYSROOT}")
  else()
    execute_process(COMMAND xcrun --show-sdk-path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    message(STATUS "Accelerate ILP64: ${CMAKE_Fortran_COMPILER_ID} Fortran has no baked-in sysroot, using ${CMAKE_OSX_SYSROOT}.
  If the link fails on undefined \$NEWLAPACK\$ILP64 symbols, set -DCMAKE_OSX_SYSROOT to the SDK matching this MacOS version.")
  endif()
endif()

set(BLA_SIZEOF_INTEGER 8)

# Check if 'accelerate_lapack_url' hasn't been defined by the user (with -D)
if(NOT DEFINED accelerate_lapack_url)
  string(JSON accelerate_lapack_url GET "${json}" "accelerate_lapack")
endif()

FetchContent_Declare(AccelerateLAPACK
URL ${accelerate_lapack_url}
FIND_PACKAGE_ARGS 2.0.0 CONFIG NAMES AccelerateLAPACK
)

# accelerate-lapack sanity checks the SDK with "xcrun --show-sdk-version", and xcrun can only
# read SDKs under the active developer directory. A Homebrew GCC sysroot is a CommandLineTools
# SDK, which xcrun cannot see while Xcode is selected, so point DEVELOPER_DIR at it meanwhile.
cmake_path(GET CMAKE_OSX_SYSROOT PARENT_PATH _sdk_dir)
cmake_path(GET _sdk_dir PARENT_PATH _developer_dir)

set(_dev_dir_override false)
if(_developer_dir MATCHES "CommandLineTools$")
  set(_saved_developer_dir "$ENV{DEVELOPER_DIR}")
  set(ENV{DEVELOPER_DIR} ${_developer_dir})
  set(_dev_dir_override true)
  message(STATUS "Accelerate ILP64: DEVELOPER_DIR=${_developer_dir} so xcrun can read this SDK")
endif()

# accelerate-lapack keys off CMake's own FindBLAS / FindLAPACK (BLA_VENDOR=Apple and the
# LAPACK_Accelerate_LIBRARY it sets). Our FindLAPACK.cmake would shadow them, so drop this
# directory from the module path while it configures.
block(PROPAGATE LAPACK_FOUND LAPACK_LIBRARIES ACCELERATE_LAPACK_ILAVER_VERSION)
  list(REMOVE_ITEM CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
  FetchContent_MakeAvailable(AccelerateLAPACK)
endblock()

if(_dev_dir_override)
  if(_saved_developer_dir STREQUAL "")
    unset(ENV{DEVELOPER_DIR})
  else()
    set(ENV{DEVELOPER_DIR} ${_saved_developer_dir})
  endif()
endif()
