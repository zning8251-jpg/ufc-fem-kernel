!===============================================================================
! MODULE:  RT_Load_Brg
! LAYER:   L5_RT
! DOMAIN:  Load
! ROLE:    Brg
! BRIEF:   Cross-layer bridge for the split Load implementation family.
!===============================================================================
MODULE RT_Load_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                        IF_STATUS_ERROR
  USE RT_Load_Impl_Def, ONLY: RT_Load_Impl_Desc, RT_Load_Impl_State, &
                              RT_Load_Impl_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Load_Brg_FromL3
  PUBLIC :: RT_Load_Brg_ToL4
  PUBLIC :: RT_Load_Brg_RouteLoadType

  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_LOAD_LOAD_CONCENTRATED = 1_i4, &
    RT_LOAD_LOAD_DISTRIBUTED  = 2_i4, &
    RT_LOAD_LOAD_PRESSURE     = 3_i4, &
    RT_LOAD_LOAD_BODY_FORCE   = 4_i4, &
    RT_LOAD_LOAD_THERMAL      = 5_i4, &
    RT_LOAD_LOAD_INERTIA      = 6_i4

CONTAINS

  SUBROUTINE RT_Load_Brg_FromL3(n_loads, l4_slot_index, desc, status)
    INTEGER(i4),            INTENT(IN)    :: n_loads, l4_slot_index
    TYPE(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    desc%n_loads = n_loads
    desc%l4_slot_index = l4_slot_index
    desc%is_active = (n_loads > 0_i4)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Load_Brg_FromL3

  SUBROUTINE RT_Load_Brg_ToL4(ctx, state, amp_factor, status)
    TYPE(RT_Load_Impl_Ctx),   INTENT(IN)  :: ctx
    TYPE(RT_Load_Impl_State), INTENT(IN)  :: state
    REAL(wp),                 INTENT(OUT) :: amp_factor
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)
    amp_factor = state%current_amp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Load_Brg_ToL4

  SUBROUTINE RT_Load_Brg_RouteLoadType(load_type, desc, state, ctx, amp_factor, &
                                       load_vector, status)
    INTEGER(i4),             INTENT(IN)    :: load_type
    TYPE(RT_Load_Impl_Desc), INTENT(IN)    :: desc
    TYPE(RT_Load_Impl_State), INTENT(IN)   :: state
    TYPE(RT_Load_Impl_Ctx),  INTENT(IN)    :: ctx
    REAL(wp),                INTENT(OUT)   :: amp_factor
    REAL(wp),                INTENT(INOUT) :: load_vector(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    amp_factor = state%current_amp
    IF (.NOT. desc%is_active) THEN
      load_vector = 0.0_wp
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    SELECT CASE (load_type)
    CASE (RT_LOAD_LOAD_CONCENTRATED, RT_LOAD_LOAD_DISTRIBUTED, &
          RT_LOAD_LOAD_PRESSURE, RT_LOAD_LOAD_BODY_FORCE, &
          RT_LOAD_LOAD_THERMAL, RT_LOAD_LOAD_INERTIA)
      load_vector = load_vector * amp_factor
      status%status_code = IF_STATUS_OK
    CASE DEFAULT
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_Load_Brg_RouteLoadType received unknown load_type'
    END SELECT
  END SUBROUTINE RT_Load_Brg_RouteLoadType

END MODULE RT_Load_Brg
