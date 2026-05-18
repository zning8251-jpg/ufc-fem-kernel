!===============================================================================
! MODULE:  RT_Load_Def
! LAYER:   L5_RT
! DOMAIN:  Load
! ROLE:    Def
! BRIEF:   TYPE definitions for load routing at L5_RT.
!===============================================================================
MODULE RT_Load_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: RT_Load_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => LD_I
    PROCEDURE :: Clean => LD_C
  END TYPE

  TYPE, PUBLIC :: RT_Load_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => LS_I
    PROCEDURE :: Clean => LS_C
  END TYPE

  TYPE, PUBLIC :: RT_Load_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => LA_I
  END TYPE

  TYPE, PUBLIC :: RT_Load_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => LC_I
    PROCEDURE :: Clean => LC_C
  END TYPE

  TYPE, PUBLIC :: RT_Load_Dispatch_Arg
    INTEGER(i4) :: load_id
    INTEGER(i4) :: ip_index
    INTEGER(i4) :: elem_id
    REAL(wp) :: force_vector(6)
    REAL(wp) :: applied_load(6)
    INTEGER(i4) :: status_code
    CHARACTER(len=256) :: message
  END TYPE

CONTAINS

  SUBROUTINE LD_I(this, mat_id, l4_slot)
    CLASS(RT_Load_Desc), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: mat_id, l4_slot
    this%mat_id = mat_id
    this%l4_slot_index = l4_slot
    this%is_active = .TRUE.
  END SUBROUTINE

  SUBROUTINE LD_C(this)
    CLASS(RT_Load_Desc), INTENT(INOUT) :: this
    this%is_active = .FALSE.
  END SUBROUTINE

  SUBROUTINE LS_I(this, num_ips)
    CLASS(RT_Load_State), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: num_ips
    this%num_ips = num_ips
    this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE LS_C(this)
    CLASS(RT_Load_State), INTENT(INOUT) :: this
    this%num_ips = 0
    this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE LA_I(this)
    CLASS(RT_Load_Algo), INTENT(OUT) :: this
    this%dispatch_strategy = 0
  END SUBROUTINE

  SUBROUTINE LC_I(this)
    CLASS(RT_Load_Ctx), INTENT(OUT) :: this
    this%current_step = 0
    this%current_incr = 0
    this%current_iter = 0
  END SUBROUTINE

  SUBROUTINE LC_C(this)
    CLASS(RT_Load_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE

END MODULE RT_Load_Def
