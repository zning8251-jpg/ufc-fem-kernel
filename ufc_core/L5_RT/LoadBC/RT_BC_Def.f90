!===============================================================================
! MODULE:  RT_BC_Def
! LAYER:   L5_RT
! DOMAIN:  BC
! ROLE:    Def
! BRIEF:   TYPE definitions for BC routing at L5_RT.
!===============================================================================
MODULE RT_BC_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: RT_BC_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BD_I
    PROCEDURE :: Clean => BD_C
  END TYPE

  TYPE, PUBLIC :: RT_BC_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BS_I
    PROCEDURE :: Clean => BS_C
  END TYPE

  TYPE, PUBLIC :: RT_BC_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => BA_I
  END TYPE

  TYPE, PUBLIC :: RT_BC_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => BC_I
    PROCEDURE :: Clean => BC_C
  END TYPE

  TYPE, PUBLIC :: RT_BC_Dispatch_Arg
    INTEGER(i4) :: bc_id = 0_i4
    INTEGER(i4) :: dof_index = 0_i4
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp) :: prescribed_val = 0.0_wp
    REAL(wp) :: reaction_force = 0.0_wp
    INTEGER(i4) :: status_code
    CHARACTER(len=256) :: message
  END TYPE

CONTAINS

  SUBROUTINE BD_I(this, mat_id, l4_slot)
    CLASS(RT_BC_Desc), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: mat_id, l4_slot
    this%mat_id = mat_id
    this%l4_slot_index = l4_slot
    this%is_active = .TRUE.
  END SUBROUTINE

  SUBROUTINE BD_C(this)
    CLASS(RT_BC_Desc), INTENT(INOUT) :: this
    this%is_active = .FALSE.
  END SUBROUTINE

  SUBROUTINE BS_I(this, num_ips)
    CLASS(RT_BC_State), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: num_ips
    this%num_ips = num_ips
    this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE BS_C(this)
    CLASS(RT_BC_State), INTENT(INOUT) :: this
    this%num_ips = 0
    this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE BA_I(this)
    CLASS(RT_BC_Algo), INTENT(OUT) :: this
    this%dispatch_strategy = 0
  END SUBROUTINE

  SUBROUTINE BC_I(this)
    CLASS(RT_BC_Ctx), INTENT(OUT) :: this
    this%current_step = 0
    this%current_incr = 0
    this%current_iter = 0
  END SUBROUTINE

  SUBROUTINE BC_C(this)
    CLASS(RT_BC_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE

END MODULE RT_BC_Def
