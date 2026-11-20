# Matlab

Matlab MEX interface may be built:

```sh
cmake -DMUMPS_matlab=on
```

Matlab require `-DMUMPS_parallel=off`.
These Matlab scripts seems to have been developed ~ 2006 and may not fully work anymore.
Ask the MUMPS Users List if you need such scripts.
We present them mainly as an example of compiling MEX libraries for Matlab with CMake.
