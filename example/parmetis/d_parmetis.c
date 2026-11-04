#include <stdio.h>
#include <stdlib.h>

#include <mpi.h>
#include <parmetis.h>

int main(int argc, char **argv)
{
  idx_t vtxdist[3] = {0, 2, 4};
  idx_t xadj[3];
  idx_t adjncy[3];
  idx_t part[2] = {-1, -1};
  idx_t wgtflag = 0;
  idx_t numflag = 0;
  idx_t ncon = 1;
  idx_t nparts = 2;
  idx_t options[3] = {0, 0, 0};
  idx_t edgecut = 0;
  real_t tpwgts[2] = {0.5, 0.5};
  real_t ubvec[1] = {1.05};
  idx_t *vwgt = NULL;
  idx_t *adjwgt = NULL;
  MPI_Comm comm = MPI_COMM_WORLD;
  int rank;
  int size;
  int part_status;
  int local_error;
  int global_error;
  int local_counts[2] = {0, 0};
  int global_counts[2] = {0, 0};
  int result = EXIT_SUCCESS;
  int i;

  if (MPI_Init(&argc, &argv) != MPI_SUCCESS) {
    return EXIT_FAILURE;
  }

  if (MPI_Comm_rank(comm, &rank) != MPI_SUCCESS ||
      MPI_Comm_size(comm, &size) != MPI_SUCCESS) {
    result = EXIT_FAILURE;
    goto finalize;
  }

  if (size != 2) {
    if (rank == 0) {
      fprintf(stderr, "This example requires exactly two MPI ranks.\n");
    }
    result = EXIT_FAILURE;
    goto finalize;
  }

  if (rank == 0) {
    /* Local CSR rows for vertices 0 and 1 of the path graph 0-1-2-3. */
    xadj[0] = 0;
    xadj[1] = 1;
    xadj[2] = 3;
    adjncy[0] = 1;
    adjncy[1] = 0;
    adjncy[2] = 2;
  } else {
    /* Local CSR rows for vertices 2 and 3. */
    xadj[0] = 0;
    xadj[1] = 2;
    xadj[2] = 3;
    adjncy[0] = 1;
    adjncy[1] = 3;
    adjncy[2] = 2;
  }

  part_status = ParMETIS_V3_PartKway(
      vtxdist, xadj, adjncy, vwgt, adjwgt, &wgtflag, &numflag, &ncon,
      &nparts, tpwgts, ubvec, options, &edgecut, part, &comm);

  local_error = part_status != METIS_OK;
  if (MPI_Allreduce(&local_error, &global_error, 1, MPI_INT, MPI_MAX, comm) !=
      MPI_SUCCESS) {
    result = EXIT_FAILURE;
    goto finalize;
  }
  if (global_error) {
    if (rank == 0) {
      fprintf(stderr, "ParMETIS_V3_PartKway failed (status %d).\n", part_status);
    }
    result = EXIT_FAILURE;
    goto finalize;
  }

  for (i = 0; i < 2; ++i) {
    if (part[i] < 0 || part[i] >= nparts) {
      local_error = 1;
    } else {
      ++local_counts[part[i]];
    }
  }

  if (MPI_Allreduce(&local_error, &global_error, 1, MPI_INT, MPI_MAX, comm) !=
      MPI_SUCCESS) {
    result = EXIT_FAILURE;
    goto finalize;
  }
  if (MPI_Allreduce(local_counts, global_counts, 2, MPI_INT, MPI_SUM, comm) !=
      MPI_SUCCESS) {
    result = EXIT_FAILURE;
    goto finalize;
  }
  if (global_error || global_counts[0] == 0 || global_counts[1] == 0) {
    if (rank == 0) {
      fprintf(stderr, "ParMETIS returned an invalid or empty partition.\n");
    }
    result = EXIT_FAILURE;
    goto finalize;
  }

  if (rank == 0) {
    printf("ParMETIS_V3_PartKway: edge cut = %lld\n", (long long)edgecut);
    printf("Partition sizes: %d, %d\n", global_counts[0], global_counts[1]);
  }

finalize:
  if (MPI_Finalize() != MPI_SUCCESS) {
    result = EXIT_FAILURE;
  }
  return result;
}
