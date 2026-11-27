"""Small Python interface to MUMPS."""

import numpy as np

from ._mumps_superbuild import __version__, mumps_int_bits, solve_double

__all__ = ["spsolve", "__version__"]


def spsolve(matrix, rhs, *, verbose=False):
    """Solve a square sparse linear system in double precision."""
    if len(matrix.shape) != 2 or matrix.shape[0] != matrix.shape[1]:
        raise ValueError("matrix must be square")
    if np.iscomplexobj(matrix.data) or np.iscomplexobj(rhs):
        raise TypeError("mumps_superbuild currently supports real data only")

    matrix = matrix.tocoo(copy=False)
    index_dtype = np.dtype(f"i{mumps_int_bits() // 8}")
    row = np.ascontiguousarray(matrix.row + 1, dtype=index_dtype)
    column = np.ascontiguousarray(matrix.col + 1, dtype=index_dtype)
    values = np.ascontiguousarray(matrix.data, dtype=np.float64)
    solution = np.array(rhs, dtype=np.float64, copy=True, order="C")

    if solution.ndim != 1 or solution.size != matrix.shape[0]:
        raise ValueError("rhs must be a one-dimensional array matching matrix")

    solve_double(
        n=matrix.shape[0],
        nz=len(values),
        row_address=row.ctypes.data,
        column_address=column.ctypes.data,
        values_address=values.ctypes.data,
        rhs_address=solution.ctypes.data,
        verbose=verbose,
    )
    return solution
