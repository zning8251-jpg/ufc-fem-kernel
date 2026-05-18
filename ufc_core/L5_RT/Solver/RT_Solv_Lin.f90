!===============================================================================
! MODULE: RT_Solv_Lin
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Solv (Linear)
! BRIEF:  Linear equation system solver dispatcher (direct/iterative)
!===============================================================================
!
! Process族:
!   P0: Init                                          [COLD_PATH]
!   P2: Solve (dispatch to PARDISO/CG/GMRES/BiCGSTAB) [HOT_PATH]
!   P0: Clean / Finalize                              [COLD_PATH]
!
! Status: SIO-REFACTORED | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_Lin
  !! Linear solver dispatcher: direct (LU/Cholesky), iterative (CG/GMRES).
  !! Delegates to L2_NM numerical core via RT_Solv_Brg.

  use IF_Base_DP
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Mem_Mgr, only: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, MEM_DOMAIN_SOLV
  USE IF_Prec_Core, only: wp, i4
  use MD_TypeSystem
  use RT_Base_Core, only: ThreadWS
  use RT_Base_Sys, only: ThreadWS_PreheatBlockSolver, ThreadWS_GetBlockSolverWorkspace
  USE RT_Solv_Brg
  USE RT_Solv_Sparse, only: RT_BlockCSRMatrix, RT_LUHandle, RT_CSR_SpMV, RT_LU_Setup_FromCSR, &
                                    RT_LU_Solv, RT_LU_Destroy, RT_LinearSolve_Direct, &
                                    RT_TripletList, RT_Triplet_Init, RT_Triplet_Free
  USE RT_Solv_Def
  use RT_Workspace_API, only: UF_WS_GetCurrentThreadWorkspacePtr
  use RT_Solv_CoreMemPool, only: g_core_mem_pool, CoreMemPool_AllocDP1D, CoreMemPool_Dealloc
  use UF_MemorySystem_Core
  use UF_Performance_Core

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: Clean         => RT_LinearSolver_Clean
  public :: DisablePrefetching => RT_LinearSolver_DisablePrefetching
  public :: EnablePrefetching => RT_LinearSolver_EnablePrefetching
  public :: GetDescriptor   => RT_LinearSolver_GetDescriptor
  public :: GetStatus       => RT_LinearSolver_GetStatus
  public :: Init      => RT_LinearSolver_Init
  public :: RT_LINSOL_AMG      = 5_i4
  public :: RT_LINSOL_BICGSTAB     = 7_i4
  public :: RT_LINSOL_CG           = 6_i4
  public :: RT_LINSOL_DIRECT       = 1_i4
  public :: RT_LINSOL_GMRES        = 8_i4
  public :: RT_LINSOL_ITER     = 2_i4
  public :: RT_LINSOL_MUMPS        = 3_i4
  public :: RT_LINSOL_PARDISO      = 4_i4
  public :: RT_LINSOL_PCG      = 9_i4
  public :: RT_LINSOL_SUPERLU      = 10_i4
  public :: RT_LinearSolver
  public :: RT_LinSolStatus
  public :: RT_LinearSolver_Clean
  public :: RT_LinearSolver_Create
  public :: RT_LinearSolver_DisablePrefetching
  public :: RT_LinearSolver_EnablePrefetching
  public :: RT_LinearSolver_GetStatus
  public :: RT_LinearSolver_Init
  public :: RT_LinearSolver_SetMemoryMode
  public :: RT_LinearSolver_Solv
  ! RT_LinearSolver_Solv_GPU removed (GPU stub)
  public :: RT_MEM_ASYNC         = 4_i4
  public :: RT_MEM_CPU       = 1_i4
  public :: RT_MEM_GPU       = 2_i4
  public :: RT_MEM_HYBRID        = 3_i4
  public :: RT_PCG_Solv_Block2
  public :: RT_PCG_Solv_Block3
  public :: RT_PRECOND_GAUSS = 2_i4
  public :: RT_PRECOND_ICC          = 4_i4
  public :: RT_PRECOND_ILU          = 3_i4
  public :: RT_PRECOND_JACOBI      = 1_i4
  public :: RT_PRECOND_NONE         = 0_i4
  public :: RT_Precond_ILU0
  public :: RT_Precond_ILUK
  public :: RT_Precond_ICC0
  public :: RT_Precond_SSOR
  public :: RT_Precond_Apply
  public :: RT_ILUPreconditioner
  public :: RT_ICCPreconditioner
  public :: RT_SSORPreconditioner
  ! RT_MPI_* removed (Parallel)

  !=============================================================================
  ! Extended Linear Solver API (task11000-11099)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! task11000-11049?
  !-----------------------------------------------------------------------------
  subroutine RT_LinearSolver_Solv_Unified(solver, K, R, U, status)
    !! Unified linear solver call interface
    !!  
    !! 
    !! This subroutine provides a unified interface for calling linear solvers,
    !! automatically handling different matrix formats (dense, sparse CSR) and
    !! solver types (direct, iterative).
    !!
    !! Input:
    !!   solver - Linear solver instance (initialized)
    !!   K      - Stiffness matrix (dense or CSR format)
    !!   R      - Right-hand side vector
    !!
    !! Output:
    !!   U      - Solution vector
    !!   status - Error status
    !!
    !! Task: 11000-11049
    type(RT_LinearSolver), intent(inout) :: solver
    real(wp), intent(in) :: K(:,:)
    real(wp), intent(in) :: R(:)
    real(wp), intent(out) :: U(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    ! Valid inputs
    if (.not. solver%isInitialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_LinearSolver_Solv_Unified: Solver not initialized'
      return
    end if

    if (size(R) /= size(U)) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_LinearSolver_Solv_Unified: Size mismatch between R and U'
      return
    end if

    if (size(K, 1) /= size(R) .or. size(K, 2) /= size(R)) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_LinearSolver_Solv_Unified: Matrix size mismatch'
      return
    end if

    ! Call the solver's Solve method
    call solver%Solve(K, R, U, status)

    if (status%status_code /= IF_STATUS_OK) then
      status%message = 'RT_LinearSolver_Solv_Unified: ' // trim(status%message)
    end if

  end subroutine RT_LinearSolver_Solv_Unified

  !-----------------------------------------------------------------------------
  ! task11050-11099?
  !-----------------------------------------------------------------------------
  subroutine RT_Li_SelectStrategy(nDOFs, nNonZeros, matrix_condition, &
                                             available_solvers, recommended_solver, status)
    !! Solver selection strategy based on problem characteristics
    !!  
    !!
    !! This subroutine analyzes problem characteristics (size, sparsity, condition)
    !! and recommends the most appropriate solver type.
    !!
    !! Input:
    !!   nDOFs            - Number of degrees of freedom
    !!   nNonZeros        - Number of non-zero entries (for sparse matrices)
    !!   matrix_condition - Estimated condition number (optional, use 0.0 if unknown)
    !!   available_solvers - Array of available solver types (RT_LINSOL_* constants)
    !!
    !! Output:
    !!   recommended_solver - Recommended solver type (RT_LINSOL_* constant)
    !!   status            - Error status
    !!
    !! Selection Strategy:
    !!   - Small systems (nDOFs < 1000): Direct solver
    !!   - Medium systems (1000 <= nDOFs < 100000): Iterative solver with preconditioner
    !!   - Large systems (nDOFs >= 100000): Sparse iterative solver
    !!   - Well-conditioned: CG or PCG
    !!   - Ill-conditioned: GMRES or BiCGSTAB with ILU preconditioner
    !!
    !! Task: 11050-11099
    integer(i4), intent(in) :: nDOFs
    integer(i4), intent(in) :: nNonZeros
    real(wp), intent(in) :: matrix_condition
    integer(i4), intent(in) :: available_solvers(:)
    integer(i4), intent(out) :: recommended_solver
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i
    real(wp) :: sparsity_ratio
    logical :: has_direct, has_iterative, has_cg, has_gmres, has_bicgstab, has_pcg

    call init_error_status(status)

    ! Check available solvers
    has_direct = .false.
    has_iterative = .false.
    has_cg = .false.
    has_gmres = .false.
    has_bicgstab = .false.
    has_pcg = .false.

    do i = 1, size(available_solvers)
      select case (available_solvers(i))
      case (RT_LINSOL_DIRECT, RT_LINSOL_MUMPS, RT_LINSOL_PARDISO, RT_LINSOL_SUPERLU)
        has_direct = .true.
      case (RT_LINSOL_ITER, RT_LINSOL_AMG)
        has_iterative = .true.
      case (RT_LINSOL_CG)
        has_cg = .true.
      case (RT_LINSOL_GMRES)
        has_gmres = .true.
      case (RT_LINSOL_BICGSTAB)
        has_bicgstab = .true.
      case (RT_LINSOL_PCG)
        has_pcg = .true.
      end select
    end do

    ! Compute sparsity ratio
    if (nDOFs > 0) then
      sparsity_ratio = real(nNonZeros, wp) / real(nDOFs * nDOFs, wp)
    else
      sparsity_ratio = 1.0_wp
    end if

    ! Selection strategy based on problem size
    if (nDOFs < 1000) then
      ! Small systems: prefer direct solver
      if (has_direct) then
        recommended_solver = RT_LINSOL_DIRECT
      else if (has_iterative) then
        recommended_solver = RT_LINSOL_ITER
      else if (has_cg) then
        recommended_solver = RT_LINSOL_CG
      else
        recommended_solver = RT_LINSOL_ITER
      end if

    else if (nDOFs < 100000) then
      ! Medium systems: iterative solver with preconditioner
      if (sparsity_ratio < 0.1_wp) then
        ! Sparse matrix: use CG or PCG
        if (has_pcg) then
          recommended_solver = RT_LINSOL_PCG
        else if (has_cg) then
          recommended_solver = RT_LINSOL_CG
        else if (has_iterative) then
          recommended_solver = RT_LINSOL_ITER
        else
          recommended_solver = RT_LINSOL_CG
        end if
      else
        ! Dense matrix: use direct or GMRES
        if (has_direct .and. nDOFs < 10000) then
          recommended_solver = RT_LINSOL_DIRECT
        else if (has_gmres) then
          recommended_solver = RT_LINSOL_GMRES
        else if (has_bicgstab) then
          recommended_solver = RT_LINSOL_BICGSTAB
        else
          recommended_solver = RT_LINSOL_ITER
        end if
      end if

    else
      ! Large systems: sparse iterative solver
      if (has_pcg) then
        recommended_solver = RT_LINSOL_PCG
      else if (has_cg) then
        recommended_solver = RT_LINSOL_CG
      else if (has_gmres) then
        recommended_solver = RT_LINSOL_GMRES
      else if (has_bicgstab) then
        recommended_solver = RT_LINSOL_BICGSTAB
      else
        recommended_solver = RT_LINSOL_ITER
      end if
    end if

    ! Adjust based on condition number if available
    if (matrix_condition > 0.0_wp) then
      if (matrix_condition > 1.0e10_wp) then
        ! Ill-conditioned: prefer GMRES or BiCGSTAB
        if (has_gmres .and. recommended_solver == RT_LINSOL_CG) then
          recommended_solver = RT_LINSOL_GMRES
        else if (has_bicgstab .and. recommended_solver == RT_LINSOL_CG) then
          recommended_solver = RT_LINSOL_BICGSTAB
        end if
      end if
    end if

    status%status_code = IF_STATUS_OK
    status%message = 'Solver selection completed'

  end subroutine RT_LinearSolver_SelectStrategy

  !=============================================================================
  ! Re-export from RT_Solv_Linear_Unified (merged)
  !=============================================================================
  ! RT_LinearSolver is already public above, no additional re-export needed

end module RT_Solv_Lin