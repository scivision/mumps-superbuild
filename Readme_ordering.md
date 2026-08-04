# MUMPS ordering

MUMPS by default uses PORD for ordering.
MUMPS can optionally use ordering libraries Scotch, METIS, and/or ParMETIS, which will be automatically built if needed.

## Scotch

Build Scotch without trying to find it:

```sh
cmake -DMUMPS_scotch=yes
```

Optionally, to try to find a system Scotch library, falling back to build Scotch if it's not found.
Optionally, specify the location of Scotch with CMake option `-DSCOTCH_ROOT=/path/to/scotch"

```sh
cmake -DMUMPS_scotch=yes -DMUMPS_find_scotch=yes
```

By default, if "MUMPS_parallel=yes", then PTScotch will be used for parallel ordering by auto-setting "MUMPS_ptscotch=yes".
This can be overriden to use non-parallel scotch like:

```sh
cmake -DMUMPS_scotch=yes -DMUMPS_ptscotch=no
```

## METIS / ParMETIS

```sh
cmake -DMUMPS_metis=yes
```

```sh
cmake -DMUMPS_parmetis=yes
```

METIS is built by default. Optionally, try to find an installed METIS or ParMETIS first,
falling back to building it if none is found:

```sh
cmake -DMUMPS_metis=yes -DMUMPS_find_metis=yes
```

Specifying its location implies the search:

```sh
cmake -DMUMPS_metis=yes -DMETIS_ROOT=/path/to/metis
```

Build MUMPS

```sh
cmake --build build
cmake --install build
```

## Example

Test that MUMPS can be used with an example application.
The MUMPS installed package will know what if any external ordering libraries are needed and where to find them.

Build MUMPS example:

```sh
cmake -S example -B example/build -DMUMPS_ROOT=build/local

cmake --build example/build
```

---

If 64-bit integers are needed, use:

```sh
cmake -DMUMPS_intsize64=true
```
