"""Smoke-test the built mumps_superbuild Python interface."""

import argparse
import os
import sys

import numpy as np
from scipy.sparse import coo_matrix


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package-root", required=True)
    parser.add_argument("--dll-directory", nargs="+", default=[])
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    dll_handles = []
    if os.name == "nt":
        for directory in args.dll_directory:
            if os.path.isdir(directory):
                dll_handles.append(os.add_dll_directory(directory))

    sys.path.insert(0, args.package_root)
    from mumps_superbuild import spsolve

    matrix = coo_matrix(np.array([[4.0, 1.0], [1.0, 3.0]]))
    rhs = np.array([1.0, 2.0])
    solution = spsolve(matrix, rhs)
    residual = np.linalg.norm(matrix @ solution - rhs)

    print(f"solution: {solution}")
    print(f"residual: {residual}")
    if residual >= 1e-12:
        raise AssertionError(f"MUMPS solve residual is too large: {residual}")


if __name__ == "__main__":
    main()
