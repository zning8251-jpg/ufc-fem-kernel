!===============================================================================
! MODULE: PH_BC_Def
! LAYER:  L4_PH
! DOMAIN: LoadBC
! ROLE:   Def — boundary condition type definitions and controller
! BRIEF:  BC enforcement types (Penalty/Lagrange/Elimination), cache, controller,
!         Dirichlet/Neumann descriptors, and P0 lifecycle procedures.
!===============================================================================
! All types use canonical PH_BC_* naming (R-09 compliant).
! No aliases — global unique names only.
!===============================================================================
MODULE PH_BC_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! BC method constants
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BC_BC_PENALTY     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BC_BC_LAGRANGE    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BC_BC_ELIMINATION = 3_i4

  ! ==========================================================================
  ! Canonical TYPE definitions (PH_BC_*)
  ! ==========================================================================

  !> @brief Enforcement method and params (α = penalty_param for Penalty)
  TYPE, PUBLIC :: PH_BC_Enforcement_Type
    INTEGER(i4) :: method = PH_BC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0e12_wp      ! penalty α (Penalty)
    LOGICAL :: use_adaptive_penalty = .FALSE.  ! adaptive scaling
    REAL(wp) :: lagrange_tol = 1.0e-10_wp      ! Lagrange convergence tol
  END TYPE PH_BC_Enforcement_Type

  !> Single BC cache (node, DOF index, prescribed u_bar, time, amp)
  TYPE, PUBLIC :: PH_BC_Cache_Type
    INTEGER(i4) :: bcId = 0_i4
    INTEGER(i4) :: nodeId = 0_i4
    INTEGER(i4) :: dof = 0_i4
    REAL(wp) :: value = 0.0_wp
    REAL(wp) :: current_time = 0.0_wp
    REAL(wp) :: amp_factor = 1.0_wp
  END TYPE PH_BC_Cache_Type

  !> BC controller: enforcement + C matrix (Lagrange)
  TYPE, PUBLIC :: PH_BC_Ctrl_Type
    TYPE(PH_BC_Enforcement_Type) :: enforcement
    INTEGER(i4) :: nConstrainedDOFs = 0_i4
    INTEGER(i4), ALLOCATABLE :: constrained_dof_ids(:)
    REAL(wp), ALLOCATABLE :: bc_values(:)
    INTEGER(i4) :: nConstraints = 0_i4
    REAL(wp), ALLOCATABLE :: constraint_matrix(:,:)
    REAL(wp), ALLOCATABLE :: constraint_rhs(:)
    INTEGER(i4) :: nTotalDOFs = 0_i4
    REAL(wp), ALLOCATABLE :: bc_vector(:)
    LOGICAL, ALLOCATABLE :: is_constrained(:)
    INTEGER(i4) :: nActiveBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: bc_cache(:)
  END TYPE PH_BC_Ctrl_Type

  !> Init param
  TYPE, PUBLIC :: PH_BC_InitPar_Type
    INTEGER(i4) :: nTotalDOFs = 0_i4
  END TYPE PH_BC_InitPar_Type

  !> SetMethod params
  TYPE, PUBLIC :: PH_BC_MethodPar_Type
    INTEGER(i4) :: method = PH_BC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0e12_wp
  END TYPE PH_BC_MethodPar_Type

  !> Penalty/Elimination system (K, R)
  TYPE, PUBLIC :: PH_BC_System_Type
    REAL(wp), ALLOCATABLE :: K(:,:)
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_BC_System_Type

  !> Lagrange augmented (K_aug, R_aug)
  TYPE, PUBLIC :: PH_BC_SystemAug_Type
    REAL(wp), ALLOCATABLE :: K_aug(:,:)
    REAL(wp), ALLOCATABLE :: R_aug(:)
  END TYPE PH_BC_SystemAug_Type

  !> ApplyBCs input (bc_cache + nBCs)
  TYPE, PUBLIC :: PH_BC_ApplyBCsIn_Type
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: bc_cache(:)
  END TYPE PH_BC_ApplyBCsIn_Type

  !> Dirichlet BC descriptor
  TYPE, PUBLIC :: PH_BC_Dirichlet_Desc
    INTEGER(i4) :: n_dofs = 0_i4
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)
    REAL(wp),    ALLOCATABLE :: prescribed_values(:)
  END TYPE PH_BC_Dirichlet_Desc

  !> Neumann BC descriptor
  TYPE, PUBLIC :: PH_BC_Neumann_Desc
    INTEGER(i4) :: n_dofs = 0_i4
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)
    REAL(wp),    ALLOCATABLE :: values(:)
  END TYPE PH_BC_Neumann_Desc

  ! ==========================================================================
  ! Public Interface (ByType)
  ! ==========================================================================
  PUBLIC :: PH_BC_Ctrl_Init
  PUBLIC :: PH_BC_Ctrl_Free
  PUBLIC :: PH_BC_Ctrl_SetMethod
  PUBLIC :: PH_BC_Ctrl_ApplyBCs

  INTERFACE PH_BC_Ctrl_Init
    MODULE PROCEDURE PH_BC_Ctrl_Init_Scalar, PH_BC_Ctrl_Init_Par
  END INTERFACE PH_BC_Ctrl_Init
  INTERFACE PH_BC_Ctrl_SetMethod
    MODULE PROCEDURE PH_BC_Ctrl_SetMethod_Scalar, PH_BC_Ctrl_SetMethod_Par
  END INTERFACE PH_BC_Ctrl_SetMethod

CONTAINS

  ! ==========================================================================
  ! PH_BC_Ctrl_Init: init BC controller
  ! ==========================================================================
  SUBROUTINE PH_BC_Ctrl_Init_Scalar(ctrl, nTotalDOFs)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    INTEGER(i4), INTENT(IN) :: nTotalDOFs
    ctrl%nTotalDOFs = nTotalDOFs
    ctrl%nConstrainedDOFs = 0
    ctrl%nConstraints = 0
    ctrl%nActiveBCs = 0
    ALLOCATE(ctrl%bc_vector(nTotalDOFs))
    ALLOCATE(ctrl%is_constrained(nTotalDOFs))
    ctrl%bc_vector = 0.0_wp
    ctrl%is_constrained = .FALSE.
    ctrl%enforcement%method = PH_BC_BC_PENALTY
    ctrl%enforcement%penalty_param = 1.0e12_wp
  END SUBROUTINE PH_BC_Ctrl_Init_Scalar

  SUBROUTINE PH_BC_Ctrl_Init_Par(ctrl, init_par)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    TYPE(PH_BC_InitPar_Type), INTENT(IN) :: init_par
    CALL PH_BC_Ctrl_Init_Scalar(ctrl, init_par%nTotalDOFs)
  END SUBROUTINE PH_BC_Ctrl_Init_Par

  ! ==========================================================================
  ! PH_BC_Ctrl_Free: free BC controller
  ! ==========================================================================
  SUBROUTINE PH_BC_Ctrl_Free(ctrl)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    IF (ALLOCATED(ctrl%constrained_dof_ids)) DEALLOCATE(ctrl%constrained_dof_ids)
    IF (ALLOCATED(ctrl%bc_values)) DEALLOCATE(ctrl%bc_values)
    IF (ALLOCATED(ctrl%constraint_matrix)) DEALLOCATE(ctrl%constraint_matrix)
    IF (ALLOCATED(ctrl%constraint_rhs)) DEALLOCATE(ctrl%constraint_rhs)
    IF (ALLOCATED(ctrl%bc_vector)) DEALLOCATE(ctrl%bc_vector)
    IF (ALLOCATED(ctrl%is_constrained)) DEALLOCATE(ctrl%is_constrained)
    IF (ALLOCATED(ctrl%bc_cache)) DEALLOCATE(ctrl%bc_cache)
    ctrl%nConstrainedDOFs = 0
    ctrl%nConstraints = 0
    ctrl%nActiveBCs = 0
    ctrl%nTotalDOFs = 0
  END SUBROUTINE PH_BC_Ctrl_Free

  ! ==========================================================================
  ! PH_BC_Ctrl_SetMethod: set BC method
  ! ==========================================================================
  SUBROUTINE PH_BC_Ctrl_SetMethod_Scalar(ctrl, method, penalty_param)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    INTEGER(i4), INTENT(IN) :: method
    REAL(wp), INTENT(IN), OPTIONAL :: penalty_param
    ctrl%enforcement%method = method
    IF (PRESENT(penalty_param)) ctrl%enforcement%penalty_param = penalty_param
  END SUBROUTINE PH_BC_Ctrl_SetMethod_Scalar

  SUBROUTINE PH_BC_Ctrl_SetMethod_Par(ctrl, method_par)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    TYPE(PH_BC_MethodPar_Type), INTENT(IN) :: method_par
    CALL PH_BC_Ctrl_SetMethod_Scalar(ctrl, method_par%method, method_par%penalty_param)
  END SUBROUTINE PH_BC_Ctrl_SetMethod_Par

  ! ==========================================================================
  ! PH_BC_Ctrl_ApplyBCs: apply BC from in_par
  ! ==========================================================================
  SUBROUTINE PH_BC_Ctrl_ApplyBCs(ctrl, in_par)
    TYPE(PH_BC_Ctrl_Type), INTENT(INOUT) :: ctrl
    TYPE(PH_BC_ApplyBCsIn_Type), INTENT(IN) :: in_par
    INTEGER(i4) :: nBCs, i, dof_id
    IF (in_par%nBCs <= 0 .OR. .NOT. ALLOCATED(in_par%bc_cache) .OR. SIZE(in_par%bc_cache) < in_par%nBCs) RETURN
    nBCs = in_par%nBCs
    ctrl%bc_vector = 0.0_wp
    ctrl%is_constrained = .FALSE.
    ctrl%nActiveBCs = nBCs
    IF (ALLOCATED(ctrl%bc_cache)) DEALLOCATE(ctrl%bc_cache)
    ALLOCATE(ctrl%bc_cache(nBCs))
    ctrl%bc_cache = in_par%bc_cache(1:nBCs)
    DO i = 1, nBCs
      dof_id = in_par%bc_cache(i)%dof
      IF (dof_id > 0 .AND. dof_id <= ctrl%nTotalDOFs) THEN
        ctrl%bc_vector(dof_id) = in_par%bc_cache(i)%value * in_par%bc_cache(i)%amp_factor
        ctrl%is_constrained(dof_id) = .TRUE.
      END IF
    END DO
    ctrl%nConstrainedDOFs = COUNT(ctrl%is_constrained)
  END SUBROUTINE PH_BC_Ctrl_ApplyBCs

END MODULE PH_BC_Def