#include <mpi.h>

MPI_Comm *mumps_example_comm_world(void)
{
  static MPI_Comm comm;

  comm = MPI_COMM_WORLD;
  return &comm;
}
