!=======================================================================
! Module: RT_Parallel_Types                               [Template v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Parallel execution configuration and state
!
! Purpose:
!   Types for thread-level (OpenMP) and process-level (MPI) parallelism,
!   domain decomposition and load balancing.
!=======================================================================
MODULE RT_Parallel_Types
  USE IF_Prec_Core
  USE IF_Err_Brg,  ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Parallelism mode flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PAR_MODE_PAR_MODE_SERIAL     = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PAR_MODE_PAR_MODE_OPENMP     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PAR_MODE_PAR_MODE_MPI        = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PAR_MODE_PAR_MODE_HYBRID     = 3_i4  ! OMP+MPI  ! migrated

  !=====================================================================
  ! RT_Thread_Ctx — OpenMP thread-local context (call-scoped)
  !   One instance per thread; set up at the beginning of a parallel region.
  !=====================================================================
  TYPE, PUBLIC :: RT_Thread_Ctx
    INTEGER(i4) :: thread_id   = 0_i4   ! OMP_GET_THREAD_NUM()
    INTEGER(i4) :: n_threads   = 1_i4   ! OMP_GET_NUM_THREADS()
    INTEGER(i4) :: elem_start  = 0_i4   ! first element index for this thread
    INTEGER(i4) :: elem_end    = 0_i4   ! last element index for this thread
    INTEGER(i4) :: mat_start   = 0_i4   ! first material point for this thread
    INTEGER(i4) :: mat_end     = 0_i4
    LOGICAL     :: is_master   = .FALSE.  ! thread 0 flag
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Thread_Ctx

  !=====================================================================
  ! RT_MPI_Ctx — MPI process context (call-scoped per distributed increment)
  !=====================================================================
  TYPE, PUBLIC :: RT_MPI_Ctx
    INTEGER(i4) :: rank          = 0_i4    ! MPI_Comm_rank
    INTEGER(i4) :: n_ranks       = 1_i4    ! MPI_Comm_size
    INTEGER(i4) :: n_local_elems = 0_i4    ! elements owned by this rank
    INTEGER(i4) :: n_ghost_elems = 0_i4    ! ghost/halo elements
    INTEGER(i4) :: n_local_nodes = 0_i4
    INTEGER(i4) :: n_ghost_nodes = 0_i4
    LOGICAL     :: is_root       = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_MPI_Ctx

  !=====================================================================
  ! RT_Domain_Decomp_Desc — domain decomposition configuration (Desc = immutable)
  !=====================================================================
  TYPE, PUBLIC :: RT_Domain_Decomp_Desc
    INTEGER(i4) :: n_partitions      = 1_i4    ! number of MPI partitions
    INTEGER(i4) :: partition_method  = 0_i4    ! 0=RCB, 1=graph, 2=spectral
    LOGICAL     :: rebalance         = .FALSE.  ! dynamic rebalancing
    INTEGER(i4) :: rebal_every_n     = 50_i4   ! rebalance every N increments
    REAL(wp)    :: imbalance_tol     = 0.1_wp  ! acceptable imbalance fraction
    LOGICAL     :: is_active         = .FALSE.
  END TYPE RT_Domain_Decomp_Desc

  !=====================================================================
  ! RT_Load_Balance_Algo — runtime load-balancing algorithm parameters
  !=====================================================================
  TYPE, PUBLIC :: RT_Load_Balance_Algo
    INTEGER(i4) :: method          = 0_i4   ! 0=work-stealing, 1=static, 2=guided
    INTEGER(i4) :: chunk_size      = 16_i4  ! chunk size for guided scheduling
    REAL(wp)    :: oversubscribe   = 1.2_wp ! allow up to 20% oversubscription
    LOGICAL     :: migrate_mat_state = .FALSE.  ! migrate material state on rebalance
  END TYPE RT_Load_Balance_Algo

END MODULE RT_Parallel_Types
