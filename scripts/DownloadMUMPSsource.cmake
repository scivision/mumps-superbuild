# download MUMPS source to a local cache.
#
#   cmake -Dversion="5.9.0" -Dcache=/path/to/cache -P scripts/DownloadMUMPSsource.cmake
#
# Specify cache to main MUMPs superbuild like:
#
#   cmake -B build -DFETCHCONTENT_SOURCE_DIR_MUMPS_UPSTREAM=/path/to/cache

cmake_minimum_required(VERSION 3.25)

include(FetchContent)

set(topdir ${CMAKE_CURRENT_LIST_DIR}/..)
file(REAL_PATH "${topdir}" topdir)

if(NOT DEFINED cache OR cache STREQUAL "")
  set(cache ${topdir}/cache)
endif()
file(REAL_PATH "${cache}" cache)

set(json_fn ${topdir}/cmake/source.json)

file(READ ${json_fn} _json)

if(NOT DEFINED version OR version STREQUAL "")
  string(JSON _num_versions LENGTH ${_json} "mumps_sha256")
  math(EXPR _last_version_idx "${_num_versions} - 1")

  set(mumps_versions)
  foreach(i RANGE ${_last_version_idx})
    string(JSON _v MEMBER ${_json} "mumps_sha256" ${i})
    list(APPEND mumps_versions "${_v}")
  endforeach()

  list(SORT mumps_versions COMPARE NATURAL ORDER ASCENDING)
  list(GET mumps_versions ${_last_version_idx} newest_mumps_version)

  set(version "${newest_mumps_version}")
endif()

string(JSON upstream_hash ERROR_VARIABLE _jerr GET ${_json} "mumps_sha256" "${version}")
if(NOT _jerr AND upstream_hash)
  set(hash EXPECTED_HASH SHA256=${upstream_hash})
else()
  set(hash)
  message(STATUS "No sha256 for MUMPS ${version} found in ${json_fn}")
endif()

set(archive MUMPS_${version}.tar.gz)

set(url "https://mumps-solver.org/${archive}")

file(DOWNLOAD ${url} ${cache}/${archive}
     ${hash}
     SHOW_PROGRESS
     STATUS _status
     LOG _log)

list(GET _status 0 _code)
if(NOT _code EQUAL 0)
  list(GET _status 1 _msg)
  message(FATAL_ERROR "Failed to download MUMPS source from ${url}: ${_msg}
  ${_log}")
else()
  message(STATUS "${url} => ${cache}/${archive}")
endif()

message(STATUS "Use this cached archive for CMake builds like

  cmake -S ${topdir} -B build -DMUMPS_url=${cache}/${archive}")
