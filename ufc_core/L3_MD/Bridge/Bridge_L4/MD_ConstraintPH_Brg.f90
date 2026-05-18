!===============================================================================
! MODULE: MD_ConstraintPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — Constraint L3→L4 bridge
! BRIEF:  Map L3 constraint descriptors (MPC/Tie/Coupling) to L4 PH params.
! PILOT:  Use `MD_Constraint_PH_FillParams_FromMD` / `MD_Constraint_PH_Fill_*` only;
!         removed redundant `MD_*_PH_Bridge` one-line aliases (no-op forwarding).
!===============================================================================

MODULE MD_ConstraintPH_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Constr_Def, ONLY: &
      MPCConstraintDef, TieConstraintDef, CplConstraintDef, &
      CONSTRAINT_MPC, CONSTRAINT_TIE, CONSTRAINT_COUPLING, &
      MPC_TYPE_BEAM, MPC_TYPE_LINK, MPC_TYPE_PIN, MPC_TYPE_GENERAL, &
      COUPLING_TYPE_KINEMATIC, COUPLING_TYPE_DISTRIBUTING, &
      DOF_UX, DOF_UY, DOF_UZ, DOF_RX, DOF_RY, DOF_RZ, DOF_ALL

  IMPLICIT NONE
  PRIVATE

  ! Public procedures
  PUBLIC :: MD_Constraint_PH_FillParams_FromMD

  ! Constraint type enumeration for PH layer
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_MPC = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_TIE = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_COUPLING = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_RBE2 = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_RBE3 = 5_i4

  ! Penalty method enumeration
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_ELIMINATION = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_PENALTY = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTRAINT_LAGRANGE = 3_i4

  !---------------------------------------------------------------------------
  ! TYPE: MD_Constraint_PH_Params
  ! KIND: Arg
  ! DESC: PH constraint parameters bundle (output from bridge)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constraint_Cfg_Basic
    INTEGER(i4) :: constraint_id = 0_i4
    CHARACTER(LEN=64) :: constraint_name = ""
    INTEGER(i4) :: constraint_type = 0_i4  ! MPC, TIE, COUPLING
    LOGICAL :: is_active = .TRUE.
  END TYPE PH_Constraint_Cfg_Basic

  TYPE, PUBLIC :: PH_Constraint_Cfg_MPC
    INTEGER(i4), ALLOCATABLE :: dof_list(:)      ! Global DOF indices
    REAL(wp), ALLOCATABLE :: coef_list(:)       ! Coefficients c1, c2, ...
    REAL(wp) :: constant_term = 0.0_wp           ! C0 in sum(ci*ui) = C0
    INTEGER(i4) :: mpc_type = 0_i4               ! BEAM, LINK, PIN, GENERAL
  END TYPE PH_Constraint_Cfg_MPC

  TYPE, PUBLIC :: PH_Constraint_Cfg_Tie
    INTEGER(i4) :: master_surface_id = 0_i4
    INTEGER(i4) :: slave_surface_id = 0_i4
    CHARACTER(LEN=64) :: master_surface = ""
    CHARACTER(LEN=64) :: slave_surface = ""
    REAL(wp) :: position_tolerance = 0.05_wp
    LOGICAL :: adjust_slave = .TRUE.
  END TYPE PH_Constraint_Cfg_Tie

  TYPE, PUBLIC :: PH_Constraint_Cfg_Coupling
    INTEGER(i4) :: ref_node_id = 0_i4
    CHARACTER(LEN=64) :: coupled_surface = ""
    INTEGER(i4) :: coupling_type = 0_i4        ! KINEMATIC, DISTRIBUTING
    INTEGER(i4) :: dof_mask = DOF_ALL          ! DOF mask bits
    REAL(wp), ALLOCATABLE :: coef_list(:)      ! Weights for distributing
  END TYPE PH_Constraint_Cfg_Coupling

  TYPE, PUBLIC :: PH_Constraint_Cfg_Enforcement
    INTEGER(i4) :: enforcement_method = PH_CONSTRAINT_PENALTY
    REAL(wp) :: penalty_parameter = 1.0e10_wp   ! Default penalty
  END TYPE PH_Constraint_Cfg_Enforcement

  TYPE, PUBLIC :: MD_Constraint_PH_Params
    TYPE(PH_Constraint_Cfg_Basic) :: basic
    TYPE(PH_Constraint_Cfg_MPC) :: mpc
    TYPE(PH_Constraint_Cfg_Tie) :: tie
    TYPE(PH_Constraint_Cfg_Coupling) :: coupling
    TYPE(PH_Constraint_Cfg_Enforcement) :: enforcement
  END TYPE MD_Constraint_PH_Params

  !---------------------------------------------------------------------------
  ! TYPE: MD_Constraint_PH_Params_Array
  ! KIND: Arg
  ! DESC: Array wrapper for PH constraint parameters
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constraint_PH_Params_Array
    TYPE(MD_Constraint_PH_Params), ALLOCATABLE :: params(:)
    INTEGER(i4) :: n_constraints = 0_i4
  END TYPE MD_Constraint_PH_Params_Array

  INTERFACE MD_Constraint_PH_FillParams_FromMD
    MODULE PROCEDURE MD_Constraint_PH_Fill_MPC
    MODULE PROCEDURE MD_Constraint_PH_Fill_Tie
    MODULE PROCEDURE MD_Constraint_PH_Fill_Coupling
  END INTERFACE MD_Constraint_PH_FillParams_FromMD

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Constraint_PH_Fill_MPC
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge MPC definition to PH constraint parameters
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Constraint_PH_Fill_MPC(mpc_desc, params, status, global_dof_map)
    TYPE(MPCConstraintDef), INTENT(IN) :: mpc_desc
    TYPE(MD_Constraint_PH_Params), INTENT(INOUT) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: global_dof_map(:,:)

    INTEGER(i4) :: i, n_terms

    CALL init_error_status(status)

    ! Basic identification
    params%basic%constraint_id = mpc_desc%tie_id
    params%basic%constraint_name = mpc_desc%name
    params%basic%constraint_type = PH_CONSTRAINT_MPC
    params%basic%is_active = mpc_desc%is_active

    ! MPC type
    params%mpc%mpc_type = mpc_desc%mpc_type

    ! Coefficient and DOF arrays
    n_terms = mpc_desc%n_terms
    IF (n_terms > 0) THEN
      IF (ALLOCATED(params%mpc%dof_list)) DEALLOCATE(params%mpc%dof_list)
      IF (ALLOCATED(params%mpc%coef_list)) DEALLOCATE(params%mpc%coef_list)
      ALLOCATE(params%mpc%dof_list(n_terms))
      ALLOCATE(params%mpc%coef_list(n_terms))

      DO i = 1, n_terms
        params%mpc%dof_list(i) = mpc_desc%dof_list(i)
        params%mpc%coef_list(i) = mpc_desc%coef_list(i)
      END DO

      params%mpc%constant_term = mpc_desc%constant_term
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_Constraint_PH_Fill_MPC]: No terms in MPC"
      RETURN
    END IF

    ! Default enforcement method
    params%enforcement%enforcement_method = PH_CONSTRAINT_PENALTY
    params%enforcement%penalty_parameter = 1.0e10_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Constraint_PH_Fill_MPC

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Constraint_PH_Fill_Tie
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge Tie definition to PH constraint parameters
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Constraint_PH_Fill_Tie(tie_desc, params, status)
    TYPE(TieConstraintDef), INTENT(IN) :: tie_desc
    TYPE(MD_Constraint_PH_Params), INTENT(INOUT) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Basic identification
    params%basic%constraint_id = tie_desc%tie_id
    params%basic%constraint_name = tie_desc%name
    params%basic%constraint_type = PH_CONSTRAINT_TIE
    params%basic%is_active = tie_desc%is_active

    ! Surface references
    params%tie%master_surface = tie_desc%master_surface
    params%tie%slave_surface = tie_desc%slave_surface
    params%tie%master_surface_id = tie_desc%master_surface_id
    params%tie%slave_surface_id = tie_desc%slave_surface_id

    ! Parameters
    params%tie%position_tolerance = tie_desc%position_tolerance
    params%tie%adjust_slave = tie_desc%adjust

    ! Default enforcement
    params%enforcement%enforcement_method = PH_CONSTRAINT_ELIMINATION

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Constraint_PH_Fill_Tie

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Constraint_PH_Fill_Coupling
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge Coupling definition to PH constraint parameters
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Constraint_PH_Fill_Coupling(cpl_desc, params, status)
    TYPE(CplConstraintDef), INTENT(IN) :: cpl_desc
    TYPE(MD_Constraint_PH_Params), INTENT(INOUT) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Basic identification
    params%basic%constraint_id = cpl_desc%coupling_id
    params%basic%constraint_name = cpl_desc%name
    params%basic%constraint_type = PH_CONSTRAINT_COUPLING
    params%basic%is_active = cpl_desc%is_active

    ! Reference node and surface
    params%coupling%ref_node_id = cpl_desc%ref_node
    params%coupling%coupled_surface = cpl_desc%surface_name

    ! Coupling type
    params%coupling%coupling_type = cpl_desc%coupling_type

    ! DOF mask
    params%coupling%dof_mask = 0_i4
    IF (cpl_desc%constrain_dof(1)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_UX
    IF (cpl_desc%constrain_dof(2)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_UY
    IF (cpl_desc%constrain_dof(3)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_UZ
    IF (cpl_desc%constrain_dof(4)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_RX
    IF (cpl_desc%constrain_dof(5)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_RY
    IF (cpl_desc%constrain_dof(6)) params%coupling%dof_mask = params%coupling%dof_mask + DOF_RZ

    ! Weights (if distributing coupling)
    IF (ALLOCATED(cpl_desc%weights)) THEN
      IF (ALLOCATED(params%coupling%coef_list)) DEALLOCATE(params%coupling%coef_list)
      ALLOCATE(params%coupling%coef_list(SIZE(cpl_desc%weights)))
      params%coupling%coef_list = cpl_desc%weights
    END IF

    ! Enforcement method
    IF (cpl_desc%coupling_type == COUPLING_TYPE_KINEMATIC) THEN
      params%enforcement%enforcement_method = PH_CONSTRAINT_ELIMINATION
    ELSE
      params%enforcement%enforcement_method = PH_CONSTRAINT_PENALTY
      params%enforcement%penalty_parameter = 1.0e12_wp
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Constraint_PH_Fill_Coupling

END MODULE MD_ConstraintPH_Brg
