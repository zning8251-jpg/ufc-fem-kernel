!===============================================================================
! MODULE: RT_Solv_Brg
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Brg
! BRIEF:  Bridge to L2_NM numerical solver layer (PARDISO/MUMPS/LAPACK)
!===============================================================================
!
! Process族:
!   P0: Init (preconditioner create, CSR conversion)  [COLD_PATH]
!   P2: Solve (dispatch to NM_LinearSolver)            [HOT_PATH]
!   P1: Bind (CSR conversion, status mapping)          [HOT_PATH]
!   P0: Finalize (preconditioner destroy, CSR free)    [COLD_PATH]
!
! Status: SIO-REFACTORED | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_Brg
  !! Solver bridge to L2_NM: CSR conversion, preconditioner management,
  !! linear/nonlinear solve dispatch to NM_Solv_Linear / NM_Solv_Nonlin.

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  ! Phase3 S5.2.1: UF_CSR_Optimizer (bandwidth/profile, optional RCM)
  ! Phase3 S1.1/S1.2: NM_LinearSolver unified interface (direct/iterative/AGMG/SparsePak)
  USE IF_Prec_Core, only: wp, i4
  USE RT_Solv_Def
  USE NM_Mtx, ONLY: csr_analyze_bandwidth, csr_destroy
  USE NM_Solv_IterSolver
  USE NM_Solv_Linear, ONLY: UF_LinSolParams, UF_LinSolResult, &
    lin_solve, lin_solve_direct, lin_solve_cg, lin_solve_iccg, lin_solve_agmg, &
    lin_solve_sparsepak, lin_solve_sparsepak_reuse, UF_SparsePakHandle, &
    SOLVER_AUTO, SOLVER_DIRECT, SOLVER_CG, SOLVER_ICCG, SOLVER_AGMG, SOLVER_SPARSEPAK
  USE NM_Solv_Preconditioner
  ! Phase3 S2.1/S2.4/S7.1: nonlinear params/result mapping (NM_NonlinSolv)
  ! GPU modules excluded (Parallel/GPU )
  use NM_Solv_Nonlin, only: UF_NLParams, UF_NLResult, &
    NL_TYPE_NEWTON, NL_TYPE_LBFGS, NL_TYPE_MODIFIED_NR, &
    CONV_FORCE, CONV_DISP, CONV_ENERGY, CONV_MIXED
  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  ! Phase3 S7.2: Linear/nonlinear solve callbacks (eq_residual_Intf_state,
  !   eq_tangent_Intf_state, eq_Lin_Solv_Intf_state) are implemented
  !   in RT_Solver_Core; callers (RT_SolvNonlin/Lin) invoke them. The linear
  !   solve callback may call RT_LinearSolver_* here, which use NM_LinearSolver.
  !=============================================================================
  public :: RT_ConvertCSR_FromNumCore
  public :: RT_ConvertCSR_ToNumCore
  ! Phase3 S5.1: explicit free of UF_CSRMatrix (wraps ufc_numcore csr_destroy)
  public :: RT_UF_CSR_Free
  ! Phase3 S5.4.1 Brg duties: UF_Precond via RT_Precond_Create/FromCfg; RT_DestroyPreconditioner frees.
  !   UF_CSRMatrix via RT_ConvertCSR_ToNumCore; RT_UF_CSR_Free frees (Brg auto-frees on return).
  ! Phase3 S5.2.1: CSR optimizer (bandwidth/profile via UF_CSR_Optimizer)
  public :: RT_CSR_AnalyzeBandwidth_FromNumCore
  public :: RT_Precond_Create
  public :: RT_Precond_Create_FromCfg
  public :: RT_DestroyPreconditioner
  public :: RT_LinearSolver_Iterative
  ! Phase3 S1.1/S1.2/S7.1: direct & unified linear solver via ufc_numcore
  public :: RT_Cfg_To_UF_LinSolParams
  public :: RT_UF_LinSolResult_To_State
  public :: RT_LinearSolver_Direct
  public :: RT_LinearSolver_Unified
  public :: RT_LinearSolver_AGMG
  public :: RT_LinearSolver_SparsePak
  public :: RT_LinearSolver_SparsePak_Reuse
  public :: UF_SparsePakHandle
  ! Phase3 S2.1/S2.4/S7.1: nonlinear bridge (params/result mapping)
  public :: UF_NLParams
  public :: UF_NLResult
  public :: RT_Cfg_To_UF_NLParams
  public :: RT_UF_NLResult_To_State
  ! RT_MPI_* removed (Parallel )
  public :: UF_CSRMatrix
  ! Extended API ( 11400-11499)
  public :: RT_Solv_Bridge_Unified
  public :: RT_Solv_Bridge_Opt

contains

! From RT_Solver_NumCore_Bridge.f90
! ===================================================================
  ! Convert RT_CSRMatrix to UF_CSRMatrix (ufc_numcore format)
  ! ===================================================================
  
  subroutine RT_ConvertCSR_ToNumCore(rt_csr, uf_csr, status)
    type(RT_CSRMatrix), intent(in) :: rt_csr
    type(UF_CSRMatrix), intent(out) :: uf_csr
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: nrows, ncols, nnz, i
    
    call init_error_status(status)
    
    nrows = rt_csr%nrows
    ncols = rt_csr%ncols
    nnz = rt_csr%nnz
    
    ! Allocate UF_CSRMatrix (using proper field names)
    allocate(uf_csr%val(nnz))
    allocate(uf_csr%col_ind(nnz))
    allocate(uf_csr%row_ptr(nrows + 1))
    
    ! Copy data
    uf_csr%nrows = nrows
    uf_csr%ncols = ncols
    uf_csr%nnz = nnz
    uf_csr%val(1:nnz) = rt_csr%values(1:nnz)
    uf_csr%col_ind(1:nnz) = rt_csr%colInd(1:nnz)
    uf_csr%row_ptr(1:nrows+1) = rt_csr%rowPtr(1:nrows+1)
    uf_csr%is_initialized = .true.
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_ConvertCSR_ToNumCore
  
  ! ===================================================================
  ! Convert UF_CSRMatrix to RT_CSRMatrix (ufc_core format)
  ! ===================================================================
  
  subroutine RT_ConvertCSR_FromNumCore(uf_csr, rt_csr, status)
    type(UF_CSRMatrix), intent(in) :: uf_csr
    type(RT_CSRMatrix), intent(out) :: rt_csr
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: nrows, ncols, nnz
    
    call init_error_status(status)
    
    nrows = uf_csr%nrows
    ncols = uf_csr%ncols
    nnz = uf_csr%nnz
    
    ! Allocate RT_CSRMatrix (using proper field names)
    allocate(rt_csr%values(nnz))
    allocate(rt_csr%colInd(nnz))
    allocate(rt_csr%rowPtr(nrows + 1))
    
    ! Copy data
    rt_csr%nRows = nrows
    rt_csr%nCols = ncols
    rt_csr%nnz = nnz
    rt_csr%values(1:nnz) = uf_csr%val(1:nnz)
    rt_csr%colInd(1:nnz) = uf_csr%col_ind(1:nnz)
    rt_csr%rowPtr(1:nrows+1) = uf_csr%row_ptr(1:nrows+1)
    rt_csr%init = .true.
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_ConvertCSR_FromNumCore

  ! ===================================================================
  ! Phase3 S5.1: Free UF_CSRMatrix (release NumCore CSR; call after use if not local)
  ! ===================================================================
  subroutine RT_UF_CSR_Free(uf_csr, status)
    type(UF_CSRMatrix), intent(inout) :: uf_csr
    type(ErrorStatusType), intent(out), optional :: status
    if (present(status)) call init_error_status(status)
    if (uf_csr%is_initialized) call csr_destroy(uf_csr)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_UF_CSR_Free

  ! ===================================================================
  ! Phase3 S5.2.1: Analyze bandwidth/profile via UF_CSR_Optimizer
  ! ===================================================================
  subroutine RT_CSR_An_FromNumCore(K_csr, bandwidth, profile, avg_row_width, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    integer(i4), intent(out) :: bandwidth
    integer(i4), intent(out) :: profile
    real(wp), intent(out) :: avg_row_width
    type(ErrorStatusType), intent(out), optional :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(ErrorStatusType) :: st
    
    if (present(status)) call init_error_status(status)
    if (.not. K_csr%init) then
      if (present(status)) status%status_code = IF_STATUS_INVALID
      if (present(status)) status%message = 'RT_CSR_AnalyzeBandwidth: CSR not initialized'
      bandwidth = 0_i4
      profile = 0_i4
      avg_row_width = 0.0_wp
      return
    end if
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, st)
    if (st%status_code /= IF_STATUS_OK) then
      if (present(status)) status = st
      bandwidth = 0_i4
      profile = 0_i4
      avg_row_width = 0.0_wp
      return
    end if
    call csr_analyze_bandwidth(K_uf, bandwidth, profile, avg_row_width)
    call RT_UF_CSR_Free(K_uf, st)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_CSR_AnalyzeBandwidth_FromNumCore
  
  ! ===================================================================
  ! Create Preconditioner
  ! ===================================================================
  
  subroutine RT_Precond_Create(K_csr, precond_type, precond, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    integer(i4), intent(in) :: precond_type
    type(UF_Precond), intent(out) :: precond
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    integer(i4) :: pc_type
    
    call init_error_status(status)
    
    ! Convert to UF_CSRMatrix
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Map precond type (ufc_core -> ufc_numcore)
    select case (precond_type)
    case (1)  ! RT_PRECOND_JACOBI
      pc_type = PRECOND_DIAG
    case (3)  ! RT_PRECOND_ILU
      pc_type = PRECOND_ILU0
    case (4)  ! RT_PRECOND_ICC
      pc_type = PRECOND_IC0
    case default
      pc_type = PRECOND_NONE
    end select
    
    ! Create preconditioner
    call precond_create(precond, K_uf, pc_type, status%status_code)
    if (status%status_code /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'Failed to create preconditioner'
      return
    end if
    
    ! Setup preconditioner
    call precond_setup(precond, K_uf, status%status_code)
    if (status%status_code /= 0) then
      call precond_destroy(precond)
      status%status_code = IF_STATUS_INVALID
      status%message = 'Failed to setup preconditioner'
      return
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_Precond_Create

  ! ===================================================================
  ! Phase3 S4.1: Create Preconditioner from RT_Sol_Cfg (precondType, lfil, droptol)
  ! ===================================================================
  subroutine RT_Precond_Create_FromCfg(K_csr, cfg, precond, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(UF_Precond), intent(out) :: precond
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: pt
    if (cfg%precondType <= 0_i4) then
      if (cfg%symmetric) then
        pt = 4
      else
        pt = 3
      end if
    else
      select case (cfg%precondType)
      case (1)
      pt = 1
      case (2)
      pt = 3
      case (3)
      pt = 4
      case default
      pt = 3
      end select
    end if
    call RT_Precond_Create(K_csr, pt, precond, status)
  end subroutine RT_Precond_Create_FromCfg
  
  ! ===================================================================
  ! Destroy Preconditioner
  ! ===================================================================
  
  subroutine RT_DestroyPreconditioner(precond, status)
    type(UF_Precond), intent(inout) :: precond
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    call precond_destroy(precond)
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_DestroyPreconditioner
  
  ! ===================================================================
  ! Iterative Linear Solver (Bridge to ufc_numcore)
  ! ===================================================================
  
  ! Phase3: Build precond from cfg via RT_Precond_Create_FromCfg(cfg); options precondType/lfil/droptol; convert K to UF format.
  subroutine RT_LinearSolver_Iterative(K_csr, b, x, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_Precond) :: precond
    type(UF_IterParams) :: iter_params
    integer(i4) :: solver_type
    integer(i4) :: iter_status
    
    call init_error_status(status)
    
    ! Convert CSR matrix format
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Determine solver type from cfg
    solver_type = cfg%linearsolvertyp
    
    ! Phase3: Create precond from K_csr and cfg (precondType, precondLfil, precondDroptol).
    call RT_Precond_Create_FromCfg(K_csr, cfg, precond, status)
    if (status%status_code /= IF_STATUS_OK) then
      call RT_UF_CSR_Free(K_uf, status)
      return
    end if
    
    ! Setup iteration parameters
    iter_params%max_iter = cfg%maxLinearIter
    iter_params%tol_rel = cfg%linearTol
    iter_params%tol_abs = cfg%linearTol * 1.0e-6_wp
    iter_params%print_level = 0  ! Silent by default
    
    ! Call appropriate iterative solver from ufc_numcore
    select case (solver_type)
    case (RT_SOL_LINSOL_I)
      ! Use PCG for symmetric, BiCGSTAB for non-symmetric
      if (cfg%symmetric) then
        call iter_pcg(K_uf, b, x, precond, iter_params, iter_status)
      else
        call iter_bicgstab(K_uf, b, x, precond, iter_params, iter_status)
      end if
      
    case default
      status%status_code = IF_STATUS_INVALID
      status%message = 'Unsupported iterative solver type'
      call RT_DestroyPreconditioner(precond, status)
      call RT_UF_CSR_Free(K_uf, status)
      return
    end select
    
    ! Phase3 S7.1.2: Map numcore iter_status to IF_Err_Brg status.
    select case (iter_status)
    case (ITER_SUCCESS)
      status%status_code = IF_STATUS_OK
      state%nLinearIter = iter_params%iter_count
      state%linearResidual = iter_params%res_final
    case (ITER_MAX_ITER)
      status%status_code = IF_STATUS_INVALID
      status%message = 'Iterative solver reached maximum iterations'
    case (ITER_BREAKDOWN, ITER_DIVERGE, ITER_STAGNATE)
      status%status_code = IF_STATUS_INVALID
      status%message = 'Iterative solver failed to converge'
    end select
    
    ! Cleanup
    call RT_DestroyPreconditioner(precond, status)
    call RT_UF_CSR_Free(K_uf, status)
    
  end subroutine RT_LinearSolver_Iterative

  ! ===================================================================
  ! Phase3 S1.2.2: RT_Sol_Cfg ->UF_LinSolParams
  ! ===================================================================
  subroutine RT_Cfg_To_UF_LinSolParams(cfg, params_uf)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(UF_LinSolParams), intent(out) :: params_uf
    
    params_uf%max_iter = cfg%maxLinearIter
    params_uf%tol = cfg%linearTol
    params_uf%is_symmetric = cfg%symmetric
    select case (cfg%linearsolvertyp)
    case (RT_SOL_LINSOL_A)
      params_uf%solver_type = SOLVER_AUTO
    case (RT_SOL_LINSOL_D)
      params_uf%solver_type = SOLVER_DIRECT
    case (RT_SOL_LINSOL_AGMG)
      params_uf%solver_type = SOLVER_AGMG
    case (RT_SOL_LINSOL_S)
      params_uf%solver_type = SOLVER_SPARSEPAK
    case default
      if (cfg%symmetric) then
        params_uf%solver_type = SOLVER_ICCG
      else
        params_uf%solver_type = SOLVER_AGMG
      end if
    end select
    params_uf%size_threshold = 5000
    ! Phase3 S4.1: precond from cfg (0=auto: ILU0/IC0 by symmetric)
    if (cfg%precondType <= 0_i4) then
      if (cfg%symmetric) then
        params_uf%precond_type = PRECOND_IC0
      else
        params_uf%precond_type = PRECOND_ILU0
      end if
    else
      select case (cfg%precondType)
      case (1)
        params_uf%precond_type = PRECOND_DIAG
      case (2)
        params_uf%precond_type = PRECOND_ILU0
      case (3)
        params_uf%precond_type = PRECOND_IC0
      case default
        params_uf%precond_type = PRECOND_ILU0
      end select
    end if
    if (cfg%precondLfil >= 0_i4) params_uf%lfil = cfg%precondLfil
    if (cfg%precondDroptol >= 0.0_wp) params_uf%droptol = cfg%precondDroptol
  end subroutine RT_Cfg_To_UF_LinSolParams

  ! ===================================================================
  ! Phase3 S1.2.3: UF_LinSolResult ->RT_Sol_State
  ! ===================================================================
  subroutine RT_UF_LinSolResult_To_State(result_uf, state)
    type(UF_LinSolResult), intent(in) :: result_uf
    type(RT_Sol_State), intent(inout) :: state
    
    state%nLinearIter = result_uf%iterations
    state%linearResidual = result_uf%residual
    state%linearSolveTime = result_uf%solve_time
  end subroutine RT_UF_LinSolResult_To_State

  ! ===================================================================
  ! Phase3 S2.1/S2.4/S7.1: RT_Sol_Cfg ->UF_NLParams (nonlinear)
  ! ===================================================================
  subroutine RT_Cfg_To_UF_NLParams(cfg, params_uf)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(UF_NLParams), intent(out) :: params_uf
    
    params_uf%solver_type = NL_TYPE_NEWTON
    params_uf%max_iter = cfg%maxNewtonIter
    params_uf%tol_force = cfg%residualTol
    params_uf%tol_disp = cfg%correctionTol
    params_uf%tol_energy = cfg%energyTol
    if (cfg%energyTol <= 0.0_wp) params_uf%tol_energy = 1.0e-10_wp
    params_uf%use_line_search = cfg%use_line_search
    params_uf%ls_min = cfg%ls_min
    params_uf%ls_max = cfg%ls_max
    params_uf%lbfgs_m = cfg%lbfgs_m
    params_uf%adaptive = .true.
    params_uf%target_iter = 5
    ! Phase3 S2.3: arc-length (Crisfield/Riks)
    params_uf%arc_length = cfg%arc_length_init
    params_uf%arc_min = cfg%arc_min
    params_uf%arc_max = cfg%arc_max
    params_uf%psi = cfg%psi
    ! Phase3 S6.1: convergence type (1=force, 2=disp, 3=energy, 4=mixed)
    select case (cfg%conv_type)
    case (1)
    params_uf%conv_type = CONV_FORCE
    case (2)
    params_uf%conv_type = CONV_DISP
    case (3)
    params_uf%conv_type = CONV_ENERGY
    case default
    params_uf%conv_type = CONV_MIXED
    end select
  end subroutine RT_Cfg_To_UF_NLParams

  ! ===================================================================
  ! Phase3 S2.4.2: UF_NLResult ->RT_Sol_State (nonlinear)
  ! ===================================================================
  subroutine RT_UF_NLResult_To_State(result_uf, state)
    type(UF_NLResult), intent(in) :: result_uf
    type(RT_Sol_State), intent(inout) :: state
    
    state%nNewtonIter = result_uf%iterations
    state%nlConverged = result_uf%converged
    state%nlResidualNorm = result_uf%residual_norm
    state%nlDispNorm = result_uf%disp_norm
    state%nlEnergyNorm = result_uf%energy_norm
    state%nlLoadFactor = result_uf%load_factor
    state%nlArcLength = result_uf%arc_length
  end subroutine RT_UF_NLResult_To_State

  ! ===================================================================
  ! Phase3 S1.1.2: Direct solver via NM_LinearSolver (RT_CSRMatrix ->UF ->lin_solve_direct)
  ! ===================================================================
  subroutine RT_LinearSolver_Direct(K_csr, b, x, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolResult) :: result_uf
    integer(i4) :: ierr
    
    call init_error_status(status)
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call lin_solve_direct(K_uf, b, x, result_uf, ierr)
    call RT_UF_LinSolResult_To_State(result_uf, state)
    
    if (ierr /= 0) then
      status%status_code = IF_STATUS_INVALID
      if (ierr == -1) status%message = 'Direct solver: matrix too large for dense'
      if (ierr == -2) status%message = 'Direct solver: singular matrix'
      return
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_LinearSolver_Direct

  ! ===================================================================
  ! Phase3 S1.2.1: Unified linear solve via lin_solve (auto or cfg-driven)
  ! ===================================================================
  subroutine RT_LinearSolver_Unified(K_csr, b, x, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolParams) :: params_uf
    type(UF_LinSolResult) :: result_uf
    integer(i4) :: ierr
    ! Phase2 N6.2.1/N6.3.2: Optional condition/diagnostics; fill state.
    integer(i4) :: n, i, k
    real(wp), allocatable :: diag(:)
    real(wp) :: cond_est, sol_norm
    
    call init_error_status(status)
    
    ! CPU path only (GPU )
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call RT_Cfg_To_UF_LinSolParams(cfg, params_uf)
    call lin_solve(K_uf, b, x, params_uf, result_uf, ierr)
    call RT_UF_LinSolResult_To_State(result_uf, state)
    
    if (ierr /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'Unified linear solver failed'
      return
    end if
    
100 continue  ! Diagnostics section
    ! Phase2 N6.2/N6.3: Optional condition estimate and residual; update state.
    if (cfg%enable_condition .and. K_csr%nRows > 0_i4 .and. allocated(K_csr%rowPtr) .and. allocated(K_csr%colInd) .and. allocated(K_csr%values)) then
      n = K_csr%nRows
      allocate(diag(n))
      diag = 0.0_wp
      do i = 1, n
        do k = K_csr%rowPtr(i), K_csr%rowPtr(i+1) - 1
          if (K_csr%colInd(k) == i) then
            diag(i) = K_csr%values(k)
            exit
          end if
        end do
      end do
      call CondNum_Estimate_Sparse(diag, cond_est)
      state%last_condition = cond_est
      deallocate(diag)
    end if
    if (cfg%enable_error_es) then
      sol_norm = norm2(x)
      call ErrorEst_Estimate_FromNorms(state%linearResidual, sol_norm, state%last_error_esti)
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_LinearSolver_Unified

  ! ===================================================================
  ! Phase3 S1.3.1: AGMG entry via lin_solve_agmg
  ! ===================================================================
  subroutine RT_LinearSolver_AGMG(K_csr, b, x, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolParams) :: params_uf
    type(UF_LinSolResult) :: result_uf
    integer(i4) :: ierr
    
    call init_error_status(status)
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call RT_Cfg_To_UF_LinSolParams(cfg, params_uf)
    params_uf%solver_type = SOLVER_AGMG
    call lin_solve_agmg(K_uf, b, x, params_uf, result_uf, ierr)
    call RT_UF_LinSolResult_To_State(result_uf, state)
    
    if (ierr /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'AGMG solver failed'
      return
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_LinearSolver_AGMG

  ! ===================================================================
  ! Phase3 S1.1.3/S1.3.3: SparsePak direct (no reuse)
  ! ===================================================================
  subroutine RT_LinearSolver_SparsePak(K_csr, b, x, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolParams) :: params_uf
    type(UF_LinSolResult) :: result_uf
    integer(i4) :: ierr
    
    call init_error_status(status)
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call RT_Cfg_To_UF_LinSolParams(cfg, params_uf)
    params_uf%solver_type = SOLVER_SPARSEPAK
    call lin_solve_sparsepak(K_uf, b, x, params_uf, result_uf, ierr)
    call RT_UF_LinSolResult_To_State(result_uf, state)
    
    if (ierr /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'SparsePak solver failed'
      return
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_LinearSolver_SparsePak

  ! ===================================================================
  ! Phase3 S1.1.3/S1.3.3: SparsePak with factorization reuse (Newton: factor once, solve many)
  ! ===================================================================
  subroutine RT_Li_Sp_Reuse(K_csr, b, x, handle, is_first, cfg, state, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: b(:)
    real(wp), intent(inout) :: x(:)
    type(UF_SparsePakHandle), intent(inout) :: handle
    logical, intent(in) :: is_first
    type(RT_Sol_Cfg), intent(in) :: cfg
    type(RT_Sol_State), intent(inout) :: state
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolParams) :: params_uf
    type(UF_LinSolResult) :: result_uf
    integer(i4) :: ierr
    
    call init_error_status(status)
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call RT_Cfg_To_UF_LinSolParams(cfg, params_uf)
    params_uf%solver_type = SOLVER_SPARSEPAK
    call lin_solve_sparsepak_reuse(K_uf, b, x, handle, is_first, params_uf, result_uf, ierr)
    call RT_UF_LinSolResult_To_State(result_uf, state)
    
    if (ierr /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'SparsePak reuse solver failed'
      return
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_LinearSolver_SparsePak_Reuse

contains

  ! RT_MPI_* removed (Parallel )

  !=============================================================================
  ! Extended Solver Bridge API ( 11400-11499)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! 11400-11449 Bridgeʵ
  !-----------------------------------------------------------------------------
  subroutine RT_Solv_Bridge_Unified(K_csr, R, U, solver_type, solver_params, &
                                        U_result, status)
    !! Unified solver bridge implementation
    !! ͳһ Bridgeʵ
    !!
    !! This subroutine provides a unified bridge interface between RT (ufc_core)
    !! and NumCore (ufc_numcore) solvers, automatically handling format conversion
    !! and solver selection.
    !!
    !! Input:
    !!   K_csr        - Stiffness matrix in RT_CSRMatrix format
    !!   R            - Right-hand side vector
    !!   U            - Initial guess (optional)
    !!   solver_type  - Solver type (SOLVER_DIRECT, SOLVER_CG, etc.)
    !!   solver_params - Solver parameters (UF_LinSolParams)
    !!
    !! Output:
    !!   U_result     - Solution vector
    !!   status       - Error status
    !!
    !! Task: 11400-11449
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(in) :: R(:)
    real(wp), intent(in), optional :: U(:)
    integer(i4), intent(in) :: solver_type
    type(UF_LinSolParams), intent(in), optional :: solver_params
    real(wp), intent(out) :: U_result(:)
    type(ErrorStatusType), intent(out) :: status

    type(UF_CSRMatrix) :: K_uf
    type(UF_LinSolParams) :: params
    type(UF_LinSolResult) :: result
    integer(i4) :: n

    call init_error_status(status)

    ! Valid inputs
    n = K_csr%nRows
    if (size(R) /= n .or. size(U_result) /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Solv_Bridge_Unified: Size mismatch'
      return
    end if

    if (.not. K_csr%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Solv_Bridge_Unified: CSR matrix not initialized'
      return
    end if

    ! Convert RT_CSRMatrix to UF_CSRMatrix
    call RT_ConvertCSR_ToNumCore(K_csr, K_uf, status)
    if (status%status_code /= IF_STATUS_OK) then
      status%message = 'RT_Solv_Bridge_Unified: CSR conversion failed - ' // &
                       trim(status%message)
      return
    end if

    ! Set solver parameters
    if (present(solver_params)) then
      params = solver_params
    else
      ! Default parameters
      params = UF_LinSolParams()
      params%solver_type = solver_type
      params%max_iterations = 1000_i4
      params%tolerance = 1.0e-6_wp
    end if

    ! Init solution vector
    if (present(U)) then
      U_result = U
    else
      U_result = 0.0_wp
    end if

    ! Call unified linear solver via NumCore bridge
    select case (solver_type)
    case (SOLVER_DIRECT)
      call RT_LinearSolver_Direct(K_uf, R, U_result, params, result, status)

    case (SOLVER_CG)
      call RT_LinearSolver_Iterative(K_uf, R, U_result, params, result, status)

    case (SOLVER_ICCG)
      call RT_LinearSolver_Iterative(K_uf, R, U_result, params, result, status)

    case (SOLVER_AGMG)
      call RT_LinearSolver_AGMG(K_uf, R, U_result, params, result, status)

    case (SOLVER_SPARSEPAK)
      call RT_LinearSolver_SparsePak(K_uf, R, U_result, params, result, status)

    case (SOLVER_AUTO)
      ! Auto-select solver based on problem characteristics
      call RT_LinearSolver_Unified(K_uf, R, U_result, params, result, status)

    case default
      ! Default to unified solver
      call RT_LinearSolver_Unified(K_uf, R, U_result, params, result, status)
    end select

    ! Free UF_CSRMatrix
    call RT_UF_CSR_Free(K_uf, status)

    if (status%status_code /= IF_STATUS_OK) then
      status%message = 'RT_Solv_Bridge_Unified: Solver failed - ' // &
                       trim(status%message)
    end if

  end subroutine RT_Solv_Bridge_Unified

  !-----------------------------------------------------------------------------
  ! 11450-11499 Bridge Ż
  !-----------------------------------------------------------------------------
  subroutine RT_Solv_Bridge_Opt(K_csr, solver_type, optimization_flags, &
                                        optimized_params, status)
    !! Solver bridge performance optimization
    !! Bridge Ż
    !!
    !! This subroutine analyzes the problem characteristics and optimizes solver
    !! parameters for better performance, including preconditioner selection,
    !! iteration limits, and tolerance settings.
    !!
    !! Input:
    !!   K_csr            - Stiffness matrix in RT_CSRMatrix format
    !!   solver_type      - Solver type
    !!   optimization_flags - Optimization flags (bandwidth analysis, etc.)
    !!
    !! Output:
    !!   optimized_params - Optimized solver parameters
    !!   status           - Error status
    !!
    !! Task: 11450-11499
    type(RT_CSRMatrix), intent(in) :: K_csr
    integer(i4), intent(in) :: solver_type
    integer(i4), intent(in), optional :: optimization_flags
    type(UF_LinSolParams), intent(out) :: optimized_params
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, nnz, bandwidth, profile
    real(wp) :: avg_row_width, sparsity_ratio
    integer(i4) :: flags
    type(UF_CSRMatrix) :: K_uf

    call init_error_status(status)

    ! Init optimized parameters with defaults
    optimized_params = UF_LinSolParams()
    optimized_params%solver_type = solver_type

    ! Analyze matrix characteristics
    n = K_csr%nRows
    nnz = K_csr%nnz
    sparsity_ratio = real(nnz, wp) / real(n * n, wp)

    ! Set optimization flags
    flags = 0
    if (present(optimization_flags)) then
      flags = optimization_flags
    end if

    ! Analyze bandwidth if requested
    if (iand(flags, 1) /= 0) then  ! Flag bit 0: bandwidth analysis
      call RT_CSR_AnalyzeBandwidth_FromNumCore(K_csr, bandwidth, profile, &
                                                avg_row_width, status)
      if (status%status_code == IF_STATUS_OK) then
        ! Use bandwidth information for optimization
        ! For example, if bandwidth is small, direct solver may be efficient
        if (bandwidth < n / 10 .and. n < 10000) then
          optimized_params%solver_type = SOLVER_DIRECT
        end if
      end if
    end if

    ! Optimize parameters based on problem size and sparsity
    if (n < 1000) then
      ! Small problems: direct solver or CG with tight tolerance
      if (solver_type == SOLVER_AUTO .or. solver_type == SOLVER_DIRECT) then
        optimized_params%solver_type = SOLVER_DIRECT
        optimized_params%tolerance = 1.0e-10_wp
      else
        optimized_params%max_iterations = 100_i4
        optimized_params%tolerance = 1.0e-8_wp
      end if

    else if (n < 100000) then
      ! Medium problems: iterative solver with preconditioner
      if (sparsity_ratio < 0.01_wp) then
        ! Very sparse: use CG or PCG
        if (solver_type == SOLVER_AUTO) then
          optimized_params%solver_type = SOLVER_CG
        end if
        optimized_params%max_iterations = 500_i4
        optimized_params%tolerance = 1.0e-6_wp
        ! Set preconditioner
        optimized_params%precond_type = RT_PRECOND_ILU
      else
        ! Denser: use GMRES or BiCGSTAB
        optimized_params%max_iterations = 1000_i4
        optimized_params%tolerance = 1.0e-6_wp
        optimized_params%precond_type = RT_PRECOND_ILU
      end if

    else
      ! Large problems: sparse iterative solver
      if (solver_type == SOLVER_AUTO) then
        optimized_params%solver_type = SOLVER_CG
      end if
      optimized_params%max_iterations = 2000_i4
      optimized_params%tolerance = 1.0e-5_wp
      optimized_params%precond_type = RT_PRECOND_ILU
    end if

    ! Optimize based on solver type
    select case (optimized_params%solver_type)
    case (SOLVER_DIRECT)
      ! Direct solver: no iteration parameters needed
      optimized_params%max_iterations = 1_i4

    case (SOLVER_CG, SOLVER_ICCG)
      ! CG methods: typically converge faster for well-conditioned problems
      if (optimized_params%max_iterations > 1000_i4) then
        optimized_params%max_iterations = 1000_i4
      end if

    case (SOLVER_GMRES)
      ! GMRES: may need more iterations for ill-conditioned problems
      if (optimized_params%max_iterations < 500_i4) then
        optimized_params%max_iterations = 500_i4
      end if

    case (SOLVER_AGMG)
      ! AGMG: algebraic multigrid, typically very efficient
      optimized_params%max_iterations = 100_i4
      optimized_params%tolerance = 1.0e-8_wp

    case (SOLVER_SPARSEPAK)
      ! SparsePak: direct sparse solver
      optimized_params%max_iterations = 1_i4
    end select

    status%status_code = IF_STATUS_OK
    status%message = 'Solver bridge optimization completed'

  end subroutine RT_Solv_Bridge_Opt

end module RT_Solv_Brg