# retrieve MUMPS source files from JSON
# every MUMPS source file key is an array, even if only a single element is present.

include_guard()

function(mumps_get_src out key1 key2)
  set(_files "")

  if(CMAKE_VERSION VERSION_GREATER_EQUAL "4.5")

    string(JSON _farr ARRAY_SPLIT "${source_json}" "mumps_sources" "${key1}" "${key2}")
    # output is compact JSON, this is canonical way to pop out element,
    # otherwise the element quotes mess up the CMake ;-list
    foreach(_f IN LISTS _farr)
      string(JSON _file GET "${_f}")
      list(APPEND _files ${_file})
    endforeach()

  else()

    string(JSON L LENGTH "${source_json}" "mumps_sources" "${key1}" "${key2}")

    if(L GREATER 0)
      math(EXPR L "${L} - 1")
      foreach(_idx RANGE ${L})
        string(JSON _src_file GET "${source_json}" "mumps_sources" "${key1}" "${key2}" ${_idx})
        list(APPEND _files ${_src_file})
      endforeach()
    endif()

  endif()

  message(DEBUG "${key1}/${key2} ${_files}")

  set(${out} "${_files}" PARENT_SCOPE)
endfunction()
