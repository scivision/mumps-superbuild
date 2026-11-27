"""Minimal Cython interface for serial double-precision MUMPS solves."""

from libc.stdint cimport uintptr_t
from libc.string cimport memset


cdef extern from "dmumps_c.h":
    ctypedef int MUMPS_INT
    char* MUMPS_VERSION

    ctypedef struct DMUMPS_STRUC_C:
        MUMPS_INT sym
        MUMPS_INT par
        MUMPS_INT job
        MUMPS_INT comm_fortran
        MUMPS_INT icntl[40]
        double cntl[15]
        MUMPS_INT n
        MUMPS_INT nz
        MUMPS_INT* irn
        MUMPS_INT* jcn
        double* a
        double* rhs
        MUMPS_INT info[40]
        MUMPS_INT infog[40]

    void dmumps_c(DMUMPS_STRUC_C*) nogil


cdef void check_error(DMUMPS_STRUC_C* instance) except *:
    cdef int code = instance.infog[0]
    cdef int detail = instance.infog[1]
    if code < 0:
        raise RuntimeError(
            f"MUMPS error {code}, supplementary information {detail}"
        )


def mumps_int_bits():
    return sizeof(MUMPS_INT) * 8


def solve_double(
    MUMPS_INT n,
    MUMPS_INT nz,
    uintptr_t row_address,
    uintptr_t column_address,
    uintptr_t values_address,
    uintptr_t rhs_address,
    MUMPS_INT comm_fortran=0,
    bint verbose=False,
):
    cdef DMUMPS_STRUC_C instance
    cdef bint initialized = False
    memset(&instance, 0, sizeof(instance))

    instance.par = 1
    instance.sym = 0
    instance.comm_fortran = comm_fortran

    try:
        instance.job = -1
        with nogil:
            dmumps_c(&instance)
        check_error(&instance)
        initialized = True

        instance.n = n
        instance.nz = nz
        instance.irn = <MUMPS_INT*>row_address
        instance.jcn = <MUMPS_INT*>column_address
        instance.a = <double*>values_address
        instance.rhs = <double*>rhs_address

        if not verbose:
            instance.icntl[0] = -1
            instance.icntl[1] = -1
            instance.icntl[2] = -1
            instance.icntl[3] = 0

        instance.job = 6
        with nogil:
            dmumps_c(&instance)
        check_error(&instance)
    finally:
        if initialized:
            instance.job = -2
            with nogil:
                dmumps_c(&instance)


__version__ = (<bytes>MUMPS_VERSION).decode("ascii")
