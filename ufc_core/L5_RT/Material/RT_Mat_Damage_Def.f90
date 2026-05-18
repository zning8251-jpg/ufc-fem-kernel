!===============================================================================
! MODULE: RT_Mat_Damage_Def
! LAYER:  L5_RT
! DOMAIN: Material / Damage
! ROLE:   Def
! BRIEF:  TYPE definitions for damage material routing at L5_RT layer.
!===============================================================================
MODULE RT_Mat_Damage_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  ! TYPE :: RT_Mat_Damage_Desc
  TYPE, PUBLIC :: RT_Mat_Damage_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => Desc_Init
    PROCEDURE :: Clean => Desc_Clean
  END TYPE

  ! TYPE :: RT_Mat_Damage_State
  TYPE, PUBLIC :: RT_Mat_Damage_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Clean => State_Clean
  END TYPE

  ! TYPE :: RT_Mat_Damage_Algo
  TYPE, PUBLIC :: RT_Mat_Damage_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE

  ! TYPE :: RT_Mat_Damage_Ctx
  TYPE, PUBLIC :: RT_Mat_Damage_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE

  ! TYPE :: RT_Mat_Damage_Dispatch_Arg
  TYPE, PUBLIC :: RT_Mat_Damage_Dispatch_Arg
    ! [IN] fields
    INTEGER(i4) :: mat_id      ! [IN]  material ID
    INTEGER(i4) :: ip_index    ! [IN]  integration point index
    INTEGER(i4) :: elem_id     ! [IN]  element ID
    REAL(wp)    :: strain(6)   ! [IN]  total strain
    REAL(wp)    :: dstrain(6)  ! [IN]  strain increment
    REAL(wp)    :: temperature ! [IN]  temperature
    REAL(wp)    :: dtemp      ! [IN]  temperature increment
    REAL(wp)    :: F(3,3)     ! [IN]  deformation gradient (for Hyper)

    ! [OUT] fields
    REAL(wp)    :: stress(6)   ! [OUT] updated stress
    REAL(wp)    :: ddsdde(6,6) ! [OUT] tangent stiffness

    ! [OUT] status
    INTEGER(i4)        :: status_code  ! [OUT] exit status
    CHARACTER(len=256) :: message      ! [OUT] status message
  END TYPE

  ! All types declared PUBLIC on TYPE line

CONTAINS
  SUBROUTINE Desc_Init(this, mat_id, l4_slot)
    CLASS(RT_Mat_Damage_Desc), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: mat_id, l4_slot
    this%mat_id = mat_id; this%l4_slot_index = l4_slot; this%is_active = .TRUE.
  END SUBROUTINE

  SUBROUTINE Desc_Clean(this)
    CLASS(RT_Mat_Damage_Desc), INTENT(INOUT) :: this
    this%is_active = .FALSE.
  END SUBROUTINE

  SUBROUTINE State_Init(this, num_ips)
    CLASS(RT_Mat_Damage_State), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: num_ips
    this%num_ips = num_ips; this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE State_Clean(this)
    CLASS(RT_Mat_Damage_State), INTENT(INOUT) :: this
    this%num_ips = 0; this%state_committed = .FALSE.
  END SUBROUTINE

  SUBROUTINE Algo_Init(this)
    CLASS(RT_Mat_Damage_Algo), INTENT(OUT) :: this
    this%dispatch_strategy = 0
  END SUBROUTINE

  SUBROUTINE Ctx_Init(this)
    CLASS(RT_Mat_Damage_Ctx), INTENT(OUT) :: this
    this%current_step = 0; this%current_incr = 0; this%current_iter = 0
  END SUBROUTINE

  SUBROUTINE Ctx_Clean(this)
    CLASS(RT_Mat_Damage_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE

END MODULE RT_Mat_Damage_Def
