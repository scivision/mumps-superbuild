"""Small Python interface to MUMPS."""

import numpy as np

from ._mumps_superbuild import __version__, mumps_int_bits, solve_double

__all__ = ["spsolve", "__version__"]


def spsolve(matrix, rhs, *, comm=None, verbose=False):
    """Solve a centralized square sparse system in double precision."""
    rank = 0 if comm is None else comm.rank
    comm_fortran = 0 if comm is None else comm.py2f()

    prepared = None
    validation_error = None
    if rank == 0:
        try:
            prepared = _prepare_system(matrix, rhs)
        except (AttributeError, TypeError, ValueError) as error:
            validation_error = f"{type(error).__name__}: {error}"

    if comm is not None:
        validation_error = comm.bcast(validation_error, root=0)
    if validation_error is not None:
        raise ValueError(validation_error)

    if prepared is None:
        solution = np.empty(0, dtype=np.float64)
        solve_double(
            n=0,
            nz=0,
            row_address=0,
            column_address=0,
            values_address=0,
            rhs_address=0,
            comm_fortran=comm_fortran,
            verbose=verbose,
        )
        return None

    n, row, column, values, solution = prepared
    solve_double(
        n=n,
        nz=len(values),
        row_address=row.ctypes.data,
        column_address=column.ctypes.data,
        values_address=values.ctypes.data,
        rhs_address=solution.ctypes.data,
        comm_fortran=comm_fortran,
        verbose=verbose,
    )
    return solution


def _prepare_system(matrix, rhs):
    if len(matrix.shape) != 2 or matrix.shape[0] != matrix.shape[1]:
        raise ValueError("matrix must be square")

    matrix = matrix.tocoo(copy=False)
    if np.iscomplexobj(matrix.data) or np.iscomplexobj(rhs):
        raise TypeError("mumps_superbuild currently supports real data only")

    index_dtype = np.dtype(f"i{mumps_int_bits() // 8}")
    row = np.ascontiguousarray(matrix.row + 1, dtype=index_dtype)
    column = np.ascontiguousarray(matrix.col + 1, dtype=index_dtype)
    values = np.ascontiguousarray(matrix.data, dtype=np.float64)
    solution = np.array(rhs, dtype=np.float64, copy=True, order="C")

    if solution.ndim != 1 or solution.size != matrix.shape[0]:
        raise ValueError("rhs must be a one-dimensional array matching matrix")

    return matrix.shape[0], row, column, values, solution
