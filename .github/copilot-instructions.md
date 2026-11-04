---
description: when building the project code, use CMake presets
applyTo: '**/*.cmake, **/CMakeLists.txt, **/CMakePresets.json, **/*.cpp, **/*.h, **/*.c, **/*.f, **/*.f90'
---

* build and test project code: `cmake --workflow default`
* only build the project code: `cmake --workflow build`

* On Windows, suggest using WSL (Windows subsystem for Linux) to test the project code, especially with options like MUMPS_parmetis=on.
