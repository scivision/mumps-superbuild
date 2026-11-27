include(FeatureSummary)

add_feature_info(Python MUMPS_python "Python interface for MUMPS")
add_feature_info(Parallel MUMPS_parallel "parallel MUMPS (using MPI and Scalapack)")
add_feature_info(64-bit-integer MUMPS_intsize64 "use 64-bit integers in C and Fortran")
add_feature_info(GEMMT BLAS_HAVE_GEMMT "use GEMMT for symmetric matrix-matrix multiplication")

add_feature_info(ScalaPACK MUMPS_scalapack "Scalapack linear algebra library https://www.netlib.org/scalapack/")
add_feature_info(METIS MUMPS_metis "METIS graph partitioning https://github.com/KarypisLab/METIS")
add_feature_info(parMETIS MUMPS_parmetis "parMETIS parallel graph partitioning")

add_feature_info(Scotch MUMPS_scotch "Scotch graph partitioning https://www.labri.fr/perso/pelegrin/scotch/")

add_feature_info(GPU MUMPS_gpu "MUMPS CUDA GPU support (see User Manual section 5.27)")
add_feature_info(xKBLAS MUMPS_xkblas "xKBLAS GPU-accelerated BLAS")

add_feature_info(Openmp MUMPS_openmp "OpenMP API https://www.openmp.org/")
add_feature_info(AVX512 MUMPS_avx512 "AVX-512 instruction set accelerates adaptive precision with BLR")

add_feature_info(real32 MUMPS_BUILD_SINGLE "Build with single precision")
add_feature_info(real64 MUMPS_BUILD_DOUBLE "Build with double precision")
add_feature_info(complex32 MUMPS_BUILD_COMPLEX "Build with complex precision")
add_feature_info(complex64 MUMPS_BUILD_COMPLEX16 "Build with complex16 precision")
add_feature_info(shared BUILD_SHARED_LIBS "Build shared libraries")

feature_summary(WHAT ENABLED_FEATURES DISABLED_FEATURES)
