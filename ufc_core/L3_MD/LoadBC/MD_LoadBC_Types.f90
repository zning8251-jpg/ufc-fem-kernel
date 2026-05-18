!===============================================================================
! MODULE:  MD_LoadBC_Types
! LAYER:   L3_MD
! DOMAIN:  LoadBC
! ROLE:    _Def - aggregated Load+BC controller types for L3-L4 bridge
! BRIEF:   MD_LoadBC_Ctrl_Type consolidates MD_Load_Def + MD_BC_Def into a
!          single controller used by MD_Base_Def and the bridge layer.
!===============================================================================

MODULE MD_LoadBC_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  USE MD_Load_Def, ONLY: MD_Load_Desc, MD_Load_State, MD_Load_Domain
  USE MD_BC_Def,   ONLY: MD_BC_Desc, MD_BC_State, MD_BC_Algo, MD_BC_Domain
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: MD_LoadBC_Ctrl_Type
    TYPE(MD_Load_Desc),  ALLOCATABLE :: loads(:)
    TYPE(MD_BC_Desc),    ALLOCATABLE :: bcs(:)
    TYPE(MD_Load_State), ALLOCATABLE :: load_state(:)
    TYPE(MD_BC_State),   ALLOCATABLE :: bc_state(:)
    INTEGER(i4) :: n_loads = 0_i4
    INTEGER(i4) :: n_bcs   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  END TYPE MD_LoadBC_Ctrl_Type

  TYPE, PUBLIC :: MD_LoadBC_StepCtx_Type
    INTEGER(i4) :: step_idx   = 0_i4
    INTEGER(i4) :: incr_idx   = 0_i4
    REAL(wp)    :: time_curr  = 0.0_wp
    REAL(wp)    :: time_prev  = 0.0_wp
    REAL(wp)    :: dt         = 0.0_wp
  END TYPE MD_LoadBC_StepCtx_Type

  TYPE, PUBLIC :: MD_BC_Def_Type
    INTEGER(i4) :: bc_id    = 0_i4
    INTEGER(i4) :: bc_type  = 0_i4
    INTEGER(i4) :: node_id  = 0_i4
    INTEGER(i4) :: dof      = 0_i4
    REAL(wp)    :: value    = 0.0_wp
  END TYPE MD_BC_Def_Type

  TYPE, PUBLIC :: MD_Load_Def_Type
    INTEGER(i4) :: load_id   = 0_i4
    INTEGER(i4) :: load_type = 0_i4
    INTEGER(i4) :: node_id   = 0_i4
    REAL(wp)    :: magnitude = 0.0_wp
  END TYPE MD_Load_Def_Type

  PUBLIC :: MD_LoadBC_Ctrl_Init
  PUBLIC :: MD_LoadBC_Ctrl_Free

CONTAINS

  SUBROUTINE MD_LoadBC_Ctrl_Init(ctrl)
    TYPE(MD_LoadBC_Ctrl_Type), INTENT(INOUT) :: ctrl
    ctrl%n_loads = 0_i4
    ctrl%n_bcs = 0_i4
    ctrl%initialized = .TRUE.
  END SUBROUTINE

  SUBROUTINE MD_LoadBC_Ctrl_Free(ctrl)
    TYPE(MD_LoadBC_Ctrl_Type), INTENT(INOUT) :: ctrl
    IF (ALLOCATED(ctrl%loads)) DEALLOCATE(ctrl%loads)
    IF (ALLOCATED(ctrl%bcs)) DEALLOCATE(ctrl%bcs)
    IF (ALLOCATED(ctrl%load_state)) DEALLOCATE(ctrl%load_state)
    IF (ALLOCATED(ctrl%bc_state)) DEALLOCATE(ctrl%bc_state)
    ctrl%n_loads = 0_i4
    ctrl%n_bcs = 0_i4
    ctrl%initialized = .FALSE.
  END SUBROUTINE

END MODULE MD_LoadBC_Types
