include(CheckSourceCompiles)

block(PROPAGATE BLAS_HAVE_GEMMT)

if(TARGET MKL::MKL)
  set(CMAKE_REQUIRED_LIBRARIES MKL::MKL)
  if(MUMPS_parallel)
    list(APPEND CMAKE_REQUIRED_LIBRARIES MPI::MPI_Fortran)
  endif()
else()
  set(CMAKE_REQUIRED_LIBRARIES LAPACK::LAPACK)
endif()

set(CMAKE_TRY_COMPILE_TARGET_TYPE "EXECUTABLE")

if(MUMPS_BUILD_DOUBLE)
check_source_compiles(Fortran
"program check
use, intrinsic :: iso_fortran_env, only : real64
implicit none
external :: dgemmt
real(real64), dimension(2,2) :: A, B, C
CALL DGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real64 , A , 2 , B , 2 , 1._real64 , C , 2 )
end program"
BLAS_HAVE_dGEMMT
)
if(BLAS_HAVE_dGEMMT)
  set(BLAS_HAVE_GEMMT TRUE)
  return()
endif()
endif()

if(MUMPS_BUILD_SINGLE)
check_source_compiles(Fortran
"program check
use, intrinsic :: iso_fortran_env, only : real32
implicit none
external :: sgemmt
real(real32), dimension(2,2) :: A, B, C
CALL SGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real32 , A , 2 , B , 2 , 1._real32 , C , 2 )
end program"
BLAS_HAVE_sGEMMT
)
if(BLAS_HAVE_sGEMMT)
  set(BLAS_HAVE_GEMMT TRUE)
  return()
endif()
endif()

if(MUMPS_BUILD_COMPLEX)
check_source_compiles(Fortran
"program check
use, intrinsic :: iso_fortran_env, only : real32
implicit none
external :: cgemmt
complex(real32), dimension(2,2) :: A, B, C
CALL CGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real32 , A , 2 , B , 2 , 1._real32 , C , 2 )
end program"
BLAS_HAVE_cGEMMT
)
if(BLAS_HAVE_cGEMMT)
  set(BLAS_HAVE_GEMMT TRUE)
  return()
endif()
endif()

if(MUMPS_BUILD_COMPLEX16)
check_source_compiles(Fortran
"program check
use, intrinsic :: iso_fortran_env, only : real64
implicit none
external :: zgemmt
complex(real64), dimension(2,2) :: A, B, C
CALL ZGEMMT( 'U', 'N', 'T',  2 , 1 , 1._real64 , A , 2 , B , 2 , 1._real64 , C , 2 )
end program"
BLAS_HAVE_zGEMMT
)
if(BLAS_HAVE_zGEMMT)
  set(BLAS_HAVE_GEMMT TRUE)
  return()
endif()
endif()

set(BLAS_HAVE_GEMMT FALSE)

endblock()
