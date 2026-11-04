program test_metis
implicit none
external :: mumps_metis_idxsize
integer :: idxsize
call mumps_metis_idxsize(idxsize)
print '(a,i0)', "MUMPS METIS idx size: ", idxsize
end program
