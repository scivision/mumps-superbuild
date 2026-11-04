program test_parmetis
use, intrinsic :: iso_c_binding, only: c_int, c_int32_t, c_int64_t, c_float, &
  c_ptr, c_null_ptr
use mpi
implicit none

#ifdef MUMPS_INTEGER_64
integer, parameter :: idx_kind = c_int64_t
#else
integer, parameter :: idx_kind = c_int32_t
#endif

interface
  function mumps_example_comm_world() bind(C, name="mumps_example_comm_world") result(comm)
    import :: c_ptr
    type(c_ptr) :: comm
  end function

  integer(c_int) function ParMETIS_V3_PartKway( &
      vtxdist, xadj, adjncy, vwgt, adjwgt, wgtflag, numflag, ncon, nparts, &
      tpwgts, ubvec, options, edgecut, part, comm) &
      bind(C, name="ParMETIS_V3_PartKway")
    import :: c_int, idx_kind, c_float, c_ptr
    integer(idx_kind) :: vtxdist(*), xadj(*), adjncy(*)
    type(c_ptr), value :: vwgt, adjwgt
    integer(idx_kind) :: wgtflag, numflag, ncon, nparts
    real(c_float) :: tpwgts(*), ubvec(*)
    integer(idx_kind) :: options(*), edgecut, part(*)
    type(c_ptr), value :: comm
  end function
end interface

integer(idx_kind) :: vtxdist(3), xadj(3), adjncy(3), part(2)
integer(idx_kind) :: wgtflag, numflag, ncon, nparts, options(3), edgecut
real(c_float) :: tpwgts(2), ubvec(1)
type(c_ptr) :: comm
integer :: ierr, rank, nprocs, part_status
integer :: local_error, global_error, local_counts(2), global_counts(2)
integer :: i

call MPI_Init(ierr)
if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"

call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
if (ierr /= MPI_SUCCESS) then
  call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  error stop "MPI_Comm_rank failed"
endif
call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
if (ierr /= MPI_SUCCESS) then
  call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  error stop "MPI_Comm_size failed"
endif

if (nprocs /= 2) then
  if (rank == 0) write(*, '(a)') "This example requires exactly two MPI ranks."
  call MPI_Finalize(ierr)
  error stop "Invalid MPI rank count"
endif

vtxdist = [0_idx_kind, 2_idx_kind, 4_idx_kind]
part = -1_idx_kind
wgtflag = 0_idx_kind
numflag = 0_idx_kind
ncon = 1_idx_kind
nparts = 2_idx_kind
options = 0_idx_kind
edgecut = 0_idx_kind
tpwgts = [0.5_c_float, 0.5_c_float]
ubvec = [1.05_c_float]

if (rank == 0) then
  ! Local CSR rows for vertices 0 and 1 of the path graph 0-1-2-3.
  xadj = [0_idx_kind, 1_idx_kind, 3_idx_kind]
  adjncy = [1_idx_kind, 0_idx_kind, 2_idx_kind]
else
  ! Local CSR rows for vertices 2 and 3.
  xadj = [0_idx_kind, 2_idx_kind, 3_idx_kind]
  adjncy = [1_idx_kind, 3_idx_kind, 2_idx_kind]
endif

comm = mumps_example_comm_world()
part_status = ParMETIS_V3_PartKway( &
    vtxdist, xadj, adjncy, c_null_ptr, c_null_ptr, wgtflag, numflag, ncon, &
    nparts, tpwgts, ubvec, options, edgecut, part, comm)

local_error = merge(0, 1, part_status == 1)
call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, &
  MPI_COMM_WORLD, ierr)
if (ierr /= MPI_SUCCESS) then
  call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  error stop "MPI_Allreduce failed"
endif
if (global_error /= 0) then
  if (rank == 0) write(*, '(a,i0,a)') &
    "ParMETIS_V3_PartKway failed (status ", part_status, ")."
  call MPI_Finalize(ierr)
  error stop "ParMETIS_V3_PartKway failed"
endif

local_counts = 0
local_error = 0
do i = 1, 2
  if (part(i) < 0_idx_kind .or. part(i) >= nparts) then
    local_error = 1
  else
    local_counts(part(i) + 1_idx_kind) = local_counts(part(i) + 1_idx_kind) + 1
  endif
enddo

call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, &
  MPI_COMM_WORLD, ierr)
if (ierr /= MPI_SUCCESS) then
  call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  error stop "MPI_Allreduce failed"
endif
call MPI_Allreduce(local_counts, global_counts, 2, MPI_INTEGER, MPI_SUM, &
  MPI_COMM_WORLD, ierr)
if (ierr /= MPI_SUCCESS) then
  call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  error stop "MPI_Allreduce failed"
endif
if (global_error /= 0 .or. any(global_counts == 0)) then
  if (rank == 0) write(*, '(a)') "ParMETIS returned an invalid or empty partition."
  call MPI_Finalize(ierr)
  error stop "Invalid ParMETIS partition"
endif

if (rank == 0) then
  write(*, '(a,i0)') "ParMETIS_V3_PartKway: edge cut = ", edgecut
  write(*, '(a,i0,a,i0)') "Partition sizes: ", global_counts(1), ", ", global_counts(2)
endif

call MPI_Finalize(ierr)
if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program
