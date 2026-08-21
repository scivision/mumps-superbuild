# test this project used as an archive in other projects
# if broken, the CMake configure step fails

cmake_minimum_required(VERSION 3.25)

project(otherProject LANGUAGES C Fortran)

include(FetchContent)

set(MUMPS_metis on)
# tests that MUMPS/cmake/GitSubmodule.cmake can retrieve multi-level Git Submodule

FetchContent_Declare(mumps
  URL https://github.com/scivision/mumps-superbuild/archive/refs/heads/main.zip
)

FetchContent_MakeAvailable(mumps)
