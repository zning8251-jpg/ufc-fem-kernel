!===============================================================================
! MODULE: RT_Mat_Elas_Def
! LAYER:  L5_RT
! DOMAIN: Material / Elas
! ROLE:   Def
! BRIEF:  TYPE definitions for elastic material routing at L5_RT layer.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + dispatch types.
!         Lightweight: L5 is the routing/dispatch layer, state management.
!
!         Cross-layer:
!         L5 dispatch table --[dispatch]--> L4 PH_Mat_Elas_IP_Incr_Eval
!===============================================================================
MODULE RT_Mat_Elas_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  !=======================================================================
  ! PRIMARY TYPE: Desc -- L5 material routing descriptor
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Desc
    INTEGER(i4) :: mat_id          = 0_i4   ! Material ID (from L3)
    INTEGER(i4) :: sub_type        = 0_i4   ! Elastic sub-type (ISO/ORTHO/etc.)
    INTEGER(i4) :: l4_slot_index   = 0_i4   ! Index into L4 slot pool
    LOGICAL     :: is_active       = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => Desc_Init
    PROCEDURE :: Clean  => Desc_Clean
  END TYPE RT_Mat_Elas_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- L5 state tracking
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_State
    INTEGER(i4) :: num_ips         = 0_i4   ! Number of integration points
    LOGICAL     :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Clean  => State_Clean
  END TYPE RT_Mat_Elas_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- L5 dispatch algorithm control
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4  ! 0=standard, 1=vectorized
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE RT_Mat_Elas_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- L5 dispatch context
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Ctx
    INTEGER(i4) :: current_step    = 0_i4
    INTEGER(i4) :: current_incr    = 0_i4
    INTEGER(i4) :: current_iter    = 0_i4
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE RT_Mat_Elas_Ctx

  !=======================================================================
  ! Route entry for dispatch table
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Route_Entry
    INTEGER(i4) :: mat_id        = 0_i4
    INTEGER(i4) :: sub_type      = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
  END TYPE RT_Mat_Elas_Route_Entry

  !=======================================================================
  ! Dispatch table
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Dispatch_Table
    TYPE(RT_Mat_Elas_Route_Entry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: num_entries = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init  => Dispatch_Table_Init
    PROCEDURE :: Clean => Dispatch_Table_Clean
  END TYPE RT_Mat_Elas_Dispatch_Table

  !=======================================================================
  ! SIO ARGS: RT_Mat_Elas_Dispatch_Arg -- Dispatch argument bundle
  !=======================================================================
  TYPE, PUBLIC :: RT_Mat_Elas_Dispatch_Arg
    ! [IN] fields
    INTEGER(i4) :: mat_id           ! [IN]  material ID to dispatch
    INTEGER(i4) :: ip_index         ! [IN]  integration point index
    INTEGER(i4) :: elem_id          ! [IN]  element ID
    REAL(wp)    :: strain(6)        ! [IN]  total strain
    REAL(wp)    :: dstrain(6)       ! [IN]  strain increment
    REAL(wp)    :: temperature      ! [IN]  temperature
    REAL(wp)    :: dtemp            ! [IN]  temperature increment

    ! [OUT] fields
    REAL(wp)    :: stress(6)        ! [OUT] updated stress
    REAL(wp)    :: ddsdde(6,6)      ! [OUT] tangent stiffness

    ! [OUT] status
    INTEGER(i4)           :: status_code ! [OUT] exit status
    CHARACTER(len=256)    :: message     ! [OUT] status message
  END TYPE RT_Mat_Elas_Dispatch_Arg

  !=======================================================================
  ! Public exports
  !=======================================================================
  PUBLIC :: RT_Mat_Elas_Desc, RT_Mat_Elas_State
  PUBLIC :: RT_Mat_Elas_Algo, RT_Mat_Elas_Ctx
  PUBLIC :: RT_Mat_Elas_Route_Entry, RT_Mat_Elas_Dispatch_Table
  PUBLIC :: RT_Mat_Elas_Dispatch_Arg

CONTAINS

  SUBROUTINE Desc_Init(this, mat_id, sub_type, l4_slot)
    CLASS(RT_Mat_Elas_Desc), INTENT(OUT) :: this
    INTEGER(i4),             INTENT(IN)  :: mat_id
    INTEGER(i4),             INTENT(IN)  :: sub_type
    INTEGER(i4),             INTENT(IN)  :: l4_slot
    this%mat_id        = mat_id
    this%sub_type      = sub_type
    this%l4_slot_index = l4_slot
    this%is_active     = .TRUE.
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Clean(this)
    CLASS(RT_Mat_Elas_Desc), INTENT(INOUT) :: this
    this%is_active = .FALSE.
  END SUBROUTINE Desc_Clean

  SUBROUTINE State_Init(this, num_ips)
    CLASS(RT_Mat_Elas_State), INTENT(OUT) :: this
    INTEGER(i4),              INTENT(IN)  :: num_ips
    this%num_ips         = num_ips
    this%state_committed = .FALSE.
  END SUBROUTINE State_Init

  SUBROUTINE State_Clean(this)
    CLASS(RT_Mat_Elas_State), INTENT(INOUT) :: this
    this%num_ips         = 0_i4
    this%state_committed = .FALSE.
  END SUBROUTINE State_Clean

  SUBROUTINE Algo_Init(this)
    CLASS(RT_Mat_Elas_Algo), INTENT(OUT) :: this
    this%dispatch_strategy = 0_i4
  END SUBROUTINE Algo_Init

  SUBROUTINE Ctx_Init(this)
    CLASS(RT_Mat_Elas_Ctx), INTENT(OUT) :: this
    this%current_step = 0_i4
    this%current_incr = 0_i4
    this%current_iter = 0_i4
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(RT_Mat_Elas_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  SUBROUTINE Dispatch_Table_Init(this, max_entries, status)
    CLASS(RT_Mat_Elas_Dispatch_Table), INTENT(INOUT) :: this
    INTEGER(i4),                       INTENT(IN)    :: max_entries
    TYPE(ErrorStatusType),             INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(this%entries)) DEALLOCATE(this%entries)
    ALLOCATE(this%entries(max_entries))
    this%num_entries = 0_i4
    this%initialized = .TRUE.
    status%status_code = 0
  END SUBROUTINE Dispatch_Table_Init

  SUBROUTINE Dispatch_Table_Clean(this)
    CLASS(RT_Mat_Elas_Dispatch_Table), INTENT(INOUT) :: this
    IF (ALLOCATED(this%entries)) DEALLOCATE(this%entries)
    this%num_entries = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Dispatch_Table_Clean

END MODULE RT_Mat_Elas_Def