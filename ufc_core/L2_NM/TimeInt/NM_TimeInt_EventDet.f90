!===============================================================================
! MODULE: NM_TimeInt_EventDet
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Time-step event detection (contact/buckling/failure/BC change)
! BRIEF:  Event detection and zero-crossing for adaptive time stepping
!===============================================================================

MODULE NM_TimeInt_EventDet
!> Status: stub (not implemented yet; deferred for current release)
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_TimeInt_AdaptStep, ONLY: Dynamic_State
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief event type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_NONE = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_CONTACT = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_SEPARATION = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_BUCKLING = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_MATERIAL_FAILURE = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_BC_CHANGE = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_LOAD_CHANGE = 6
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_ZERO_CROSSING = 7
  INTEGER(i4), PARAMETER, PUBLIC :: NM_EVENT_USER_DEFINED = 99

  !> @brief event action enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACTION_NONE = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACTION_REDUCE_STEP = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACTION_RESTART = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACTION_SWITCH_ALGORITHM = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACTION_TERMINATE = 4

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief event definition
    TYPE, PUBLIC :: TimeEvent_ID
    INTEGER(i4) :: event_type = NM_EVENT_NONE
    INTEGER(i4) :: event_id = 0_i4
  END TYPE TimeEvent_ID

  TYPE, PUBLIC :: TimeEvent_Data
    REAL(wp) :: event_time = ZERO
    REAL(wp) :: event_value = ZERO
  END TYPE TimeEvent_Data

  TYPE, PUBLIC :: TimeEvent_Tol
    REAL(wp) :: event_tolerance = 1.0E-8_wp
  END TYPE TimeEvent_Tol

  TYPE, PUBLIC :: TimeEvent_Flags
    LOGICAL :: is_triggered = .FALSE.
    LOGICAL :: is_processed = .FALSE.
  END TYPE TimeEvent_Flags

  TYPE, PUBLIC :: TimeEvent_Meta
    CHARACTER(LEN=128) :: description = ""
  END TYPE TimeEvent_Meta

  TYPE, PUBLIC :: TimeEvent
    TYPE(TimeEvent_ID)    :: id
    TYPE(TimeEvent_Data)  :: data
    TYPE(TimeEvent_Tol)   :: tol
    TYPE(TimeEvent_Flags) :: flags
    TYPE(TimeEvent_Meta)  :: meta
  END TYPE TimeEvent

  !> @brief event detector config
    TYPE, PUBLIC :: EventDetector_Config_Flags
    LOGICAL :: enable_contact_detection = .TRUE.
    LOGICAL :: enable_buckling_detection = .TRUE.
    LOGICAL :: enable_failure_detection = .TRUE.
    LOGICAL :: enable_zero_crossing = .TRUE.
  END TYPE EventDetector_Config_Flags

  TYPE, PUBLIC :: EventDetector_Config_Tol
    REAL(wp) :: contact_tolerance = 1.0E-6_wp
    REAL(wp) :: buckling_tolerance = 1.0E-4_wp
    REAL(wp) :: zero_crossing_tolerance = 1.0E-10_wp
  END TYPE EventDetector_Config_Tol

  TYPE, PUBLIC :: EventDetector_Config_Ctrl
    INTEGER(i4) :: max_events_per_step = 10_i4
  END TYPE EventDetector_Config_Ctrl

  TYPE, PUBLIC :: EventDetector_Config
    TYPE(EventDetector_Config_Flags) :: flags
    TYPE(EventDetector_Config_Tol)   :: tol
    TYPE(EventDetector_Config_Ctrl)  :: ctrl
  END TYPE EventDetector_Config

  !> @brief event detector state
  TYPE, PUBLIC :: EventDetector_State
    INTEGER(i4) :: n_events_detected = 0_i4
    INTEGER(i4) :: n_events_processed = 0_i4
    TYPE(TimeEvent), ALLOCATABLE :: event_history(:)
    INTEGER(i4) :: history_size = 0_i4
    INTEGER(i4) :: history_pos = 0_i4
  END TYPE EventDetector_State

  !> @brief contact event data
  TYPE, PUBLIC :: Contact_Event_Data
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: surface_id = 0_i4
    REAL(wp) :: gap_distance = ZERO
    REAL(wp) :: contact_force = ZERO
    REAL(wp) :: penetration_depth = ZERO
  END TYPE Contact_Event_Data

  !> @brief buckling event data
  TYPE, PUBLIC :: Buckling_Event_Data
    INTEGER(i4) :: element_id = 0_i4
    REAL(wp) :: critical_load = ZERO
    REAL(wp) :: current_load = ZERO
    REAL(wp) :: eigenvalue = ZERO
    INTEGER(i4) :: buckling_mode = 0_i4
  END TYPE Buckling_Event_Data

  !> @brief zero-crossing function
  TYPE, PUBLIC :: ZeroCrossing_Function
    INTEGER(i4) :: func_id = 0_i4
    REAL(wp) :: prev_value = ZERO
    REAL(wp) :: curr_value = ZERO
    REAL(wp) :: target_value = ZERO
    LOGICAL :: is_active = .FALSE.
  END TYPE ZeroCrossing_Function

  !> @brief event detection result
  TYPE, PUBLIC :: EventDetection_Result
    LOGICAL :: event_found = .FALSE.
    INTEGER(i4) :: n_events = 0_i4
    TYPE(TimeEvent), ALLOCATABLE :: events(:)
    REAL(wp) :: suggested_dt = ZERO
    INTEGER(i4) :: recommended_action = NM_ACTION_NONE
  END TYPE EventDetection_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main detection interface
  PUBLIC :: NM_EventDetector_Init
  PUBLIC :: NM_Detect_Events
  PUBLIC :: NM_Process_Events
  
  ! contact events
  PUBLIC :: NM_Detect_Events
  PUBLIC :: NM_Detect_Separation_Events
  PUBLIC :: NM_Check_Contact_Condition
  
  ! buckling events
  PUBLIC :: NM_Detect_Buckling_Events
  PUBLIC :: NM_Check_Buckling_Condition
  
  ! zero-crossing
  PUBLIC :: NM_Detect_Zero_Crossing
  PUBLIC :: NM_Reg_Zero_Crossing
  PUBLIC :: NM_Update_Zero_Crossing
  
  ! event handling
  PUBLIC :: NM_Handle_Contact_Event
  PUBLIC :: NM_Handle_Buckling_Event
  PUBLIC :: NM_Calc_Event_Time
  
  ! utils
  PUBLIC :: NM_Add_Event_To_History
  PUBLIC :: NM_Get_Next_Event_Time
  PUBLIC :: NM_Suggest_Step_For_Event

CONTAINS

  !=============================================================================
  ! INITIALIZATION
  !=============================================================================

  !> @brief Initialize event detector
  !! @param[out] state detector state
  !! @param[in] max_history max history size
  !! @param[out] status error status
  SUBROUTINE NM_EventDetector_Init(state, max_history, status)
    TYPE(EventDetector_State), INTENT(OUT) :: state
    INTEGER(i4), INTENT(IN) :: max_history
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    state%n_events_detected = 0_i4
    state%n_events_processed = 0_i4
    state%history_size = max_history
    state%history_pos = 0_i4

    ALLOCATE(state%event_history(max_history))

  END SUBROUTINE NM_EventDetector_Init

  !=============================================================================
  ! MAIN DETECTION INTERFACE
  !=============================================================================

  !> @brief Detect all events
  !! @details Main entry: detect all event types
  !! @param[in] config detector config
  !! @param[inout] state detector state
  !! @param[in] dyn_state dynamics state
  !! @param[in] t current time
  !! @param[in] dt time step
  !! @param[out] result detection result
  !! @param[out] status error status
  SUBROUTINE NM_Detect_Events(config, state, dyn_state, t, dt, result, status)
    TYPE(EventDetector_Config), INTENT(IN) :: config
    TYPE(EventDetector_State), INTENT(INOUT) :: state
    TYPE(Dynamic_State), INTENT(IN) :: dyn_state
    REAL(wp), INTENT(IN) :: t, dt
    TYPE(EventDetection_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(TimeEvent) :: temp_events(10)
    INTEGER(i4) :: n_events, i

    CALL init_error_status(status)

    n_events = 0_i4
    result%event_found = .FALSE.
    result%n_events = 0_i4
    result%recommended_action = NM_ACTION_NONE

    ! Detect contact events
    IF (config%flags%enable_contact_detection) THEN
      CALL NM_Detect_Events(config, dyn_state, t, dt, temp_events, n_events, status)
    END IF

    ! Detect separation events
    IF (config%flags%enable_contact_detection .AND. n_events < 10) THEN
      CALL NM_Detect_Separation_Events(config, dyn_state, t, dt, temp_events, n_events, status)
    END IF

    ! Detect buckling events
    IF (config%flags%enable_buckling_detection .AND. n_events < 10) THEN
      CALL NM_Detect_Buckling_Events(config, dyn_state, t, dt, temp_events, n_events, status)
    END IF

    ! Collect results
    IF (n_events > 0_i4) THEN
      result%event_found = .TRUE.
      result%n_events = n_events
      ALLOCATE(result%events(n_events))
      DO i = 1, n_events
        result%events(i) = temp_events(i)
        CALL NM_Add_Event_To_History(state, temp_events(i))
      END DO

      ! Suggested action
      result%recommended_action = NM_ACTION_REDUCE_STEP
      result%suggested_dt = dt * 0.5_wp
    END IF

  END SUBROUTINE NM_Detect_Events

  !> @brief Process detected events
  !! @param[in] result detection result
  !! @param[inout] dt time step (may be modified)
  !! @param[out] action action to take
  !! @param[out] status error status
  SUBROUTINE NM_Process_Events(result, dt, action, status)
    TYPE(EventDetection_Result), INTENT(IN) :: result
    REAL(wp), INTENT(INOUT) :: dt
    INTEGER(i4), INTENT(OUT) :: action
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    action = NM_ACTION_NONE

    IF (.NOT. result%event_found) RETURN

    ! Determine action by event type
    DO i = 1, result%n_events
      SELECT CASE (result%events(i)%event_type)
      CASE (NM_EVENT_CONTACT, NM_EVENT_SEPARATION)
        action = MAX(action, NM_ACTION_REDUCE_STEP)
      CASE (NM_EVENT_BUCKLING)
        action = MAX(action, NM_ACTION_SWITCH_ALGORITHM)
      CASE (NM_EVENT_MATERIAL_FAILURE)
        action = MAX(action, NM_ACTION_TERMINATE)
      CASE DEFAULT
        action = MAX(action, NM_ACTION_REDUCE_STEP)
      END SELECT
    END DO

    ! Apply suggested step
    IF (result%suggested_dt > ZERO) THEN
      dt = MIN(dt, result%suggested_dt)
    END IF

  END SUBROUTINE NM_Process_Events

  !=============================================================================
  ! CONTACT EVENT DETECTION
  !=============================================================================

  !> @brief Detect contact events
  !! @details Detect contact between bodies
  !! @param[in] config config
  !! @param[in] dyn_state dynamics state
  !! @param[in] t current time
  !! @param[in] dt time step
  !! @param[inout] events event array
  !! @param[inout] n_events event count
  !! @param[out] status error status
  SUBROUTINE NM_Detect_Events(config, dyn_state, t, dt, events, n_events, status)
    TYPE(EventDetector_Config), INTENT(IN) :: config
    TYPE(Dynamic_State), INTENT(IN) :: dyn_state
    REAL(wp), INTENT(IN) :: t, dt
    TYPE(TimeEvent), INTENT(INOUT) :: events(:)
    INTEGER(i4), INTENT(INOUT) :: n_events
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    LOGICAL :: contact_detected
    REAL(wp) :: event_time

    CALL init_error_status(status)

    ! Simplified contact detection: velocity change
    ! actual
    contact_detected = .FALSE.

    ! Detect sudden velocity change (possible contact)
    IF (ALLOCATED(dyn_state%velocity)) THEN
      IF (SIZE(dyn_state%velocity) > 0) THEN
        ! Simplified: velocity near zero (rebound)
        contact_detected = (MAXVAL(ABS(dyn_state%velocity)) < config%tol%contact_tolerance)
      END IF
    END IF

    IF (contact_detected .AND. n_events < SIZE(events)) THEN
      n_events = n_events + 1_i4
      events(n_events)%id%event_type = NM_EVENT_CONTACT
      events(n_events)%data%event_time = t + dt
      events(n_events)%data%event_value = ZERO
      events(n_events)%tol%event_tolerance = config%tol%contact_tolerance
      events(n_events)%flags%is_triggered = .TRUE.
      events(n_events)%meta%description = "Contact detected"
    END IF

  END SUBROUTINE NM_Detect_Events

  !> @brief Detect separation events
  !! @details Detect separation between bodies
  SUBROUTINE NM_Detect_Separation_Events(config, dyn_state, t, dt, events, n_events, status)
    TYPE(EventDetector_Config), INTENT(IN) :: config
    TYPE(Dynamic_State), INTENT(IN) :: dyn_state
    REAL(wp), INTENT(IN) :: t, dt
    TYPE(TimeEvent), INTENT(INOUT) :: events(:)
    INTEGER(i4), INTENT(INOUT) :: n_events
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    LOGICAL :: separation_detected

    CALL init_error_status(status)

    separation_detected = .FALSE.

    ! Simplified separation detection
    IF (ALLOCATED(dyn_state%velocity)) THEN
      IF (SIZE(dyn_state%velocity) > 0) THEN
        separation_detected = (MAXVAL(ABS(dyn_state%velocity)) > 10.0_wp * config%tol%contact_tolerance)
      END IF
    END IF

    IF (separation_detected .AND. n_events < SIZE(events)) THEN
      n_events = n_events + 1_i4
      events(n_events)%id%event_type = NM_EVENT_SEPARATION
      events(n_events)%data%event_time = t + dt
      events(n_events)%data%event_value = ZERO
      events(n_events)%tol%event_tolerance = config%tol%contact_tolerance
      events(n_events)%flags%is_triggered = .TRUE.
      events(n_events)%meta%description = "Separation detected"
    END IF

  END SUBROUTINE NM_Detect_Separation_Events

  !> @brief Check contact condition
  !! @details Check if two bodies are in contact
  !! @param[in] pos1 body1 position
  !! @param[in] pos2 body2 position
  !! @param[in] radius1 body1 radius
  !! @param[in] radius2 body2 radius
  !! @param[in] tolerance tolerance
  !! @return in contact or not
  FUNCTION NM_Check_Contact_Condition(pos1, pos2, radius1, radius2, tolerance) &
                                       RESULT(is_contact)
    REAL(wp), INTENT(IN) :: pos1(:), pos2(:), radius1, radius2, tolerance
    LOGICAL :: is_contact

    REAL(wp) :: distance

    distance = SQRT(SUM((pos1 - pos2)**2))
    is_contact = (distance <= (radius1 + radius2 + tolerance))

  END FUNCTION NM_Check_Contact_Condition

  !> @brief Handle contact events
  !! @details Process detected contact events
  !! @param[in] event contact events
  !! @param[inout] dyn_state dynamics state
  !! @param[out] status error status
  SUBROUTINE NM_Handle_Contact_Event(event, dyn_state, status)
    TYPE(TimeEvent), INTENT(IN) :: event
    TYPE(Dynamic_State), INTENT(INOUT) :: dyn_state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Contact events: may adjust velocity or apply contact force
    ! Simplified: flag for small step

  END SUBROUTINE NM_Handle_Contact_Event

  !=============================================================================
  ! BUCKLING EVENT DETECTION
  !=============================================================================

  !> @brief Detect buckling events
  !! @details Detect structural buckling or instability
  !! @param[in] config config
  !! @param[in] dyn_state dynamics state
  !! @param[in] t current time
  !! @param[in] dt time step
  !! @param[inout] events event array
  !! @param[inout] n_events event count
  !! @param[out] status error status
  SUBROUTINE NM_Detect_Buckling_Events(config, dyn_state, t, dt, events, n_events, status)
    TYPE(EventDetector_Config), INTENT(IN) :: config
    TYPE(Dynamic_State), INTENT(IN) :: dyn_state
    REAL(wp), INTENT(IN) :: t, dt
    TYPE(TimeEvent), INTENT(INOUT) :: events(:)
    INTEGER(i4), INTENT(INOUT) :: n_events
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    LOGICAL :: buckling_detected
    REAL(wp) :: displacement_norm

    CALL init_error_status(status)

    buckling_detected = .FALSE.

    ! Simplified buckling detection: based on displacement magnitude
    IF (ALLOCATED(dyn_state%displacement)) THEN
      displacement_norm = SQRT(SUM(dyn_state%displacement**2))
      ! If displacement abnormally large, possible buckling
      buckling_detected = (displacement_norm > config%tol%buckling_tolerance)
    END IF

    IF (buckling_detected .AND. n_events < SIZE(events)) THEN
      n_events = n_events + 1_i4
      events(n_events)%id%event_type = NM_EVENT_BUCKLING
      events(n_events)%data%event_time = t + dt
      events(n_events)%data%event_value = displacement_norm
      events(n_events)%tol%event_tolerance = config%tol%buckling_tolerance
      events(n_events)%flags%is_triggered = .TRUE.
      events(n_events)%meta%description = "Buckling detected"
    END IF

  END SUBROUTINE NM_Detect_Buckling_Events

  !> @brief Check buckling condition
  !! @details Check if structure is buckling
  !! @param[in] stiffness stiffness matrix
  !! @param[in] geom_stiffness geometric stiffness matrix
  !! @param[in] tolerance tolerance
  !! @return whether buckling
  FUNCTION NM_Check_Buckling_Condition(stiffness, geom_stiffness, tolerance) &
                                        RESULT(is_buckling)
    REAL(wp), INTENT(IN) :: stiffness(:,:), geom_stiffness(:,:)
    REAL(wp), INTENT(IN) :: tolerance
    LOGICAL :: is_buckling

    REAL(wp), ALLOCATABLE :: combined(:,:)
    REAL(wp) :: det
    INTEGER(i4) :: n

    n = SIZE(stiffness, 1)
    ALLOCATE(combined(n, n))

    ! Combined stiffness matrix
    combined = stiffness + geom_stiffness

    ! Simplified: check if determinant near zero
    ! actual impl should use eigenvalue analysis
    det = ONE  ! placeholder
    is_buckling = (ABS(det) < tolerance)

    DEALLOCATE(combined)

  END FUNCTION NM_Check_Buckling_Condition

  !> @brief Handle buckling events
  !! @details Process detected buckling events
  !! @param[in] event buckling events
  !! @param[inout] dyn_state dynamics state
  !! @param[out] status error status
  SUBROUTINE NM_Handle_Buckling_Event(event, dyn_state, status)
    TYPE(TimeEvent), INTENT(IN) :: event
    TYPE(Dynamic_State), INTENT(INOUT) :: dyn_state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Buckling events: may switch solver or terminate analysis

  END SUBROUTINE NM_Handle_Buckling_Event

  !=============================================================================
  ! ZERO CROSSING DETECTION
  !=============================================================================

  !> @brief Detect zero crossing
  !! @details Detect function value crossing zero
  !! @param[in] func zero-crossing function
  !! @param[in] prev_value previous value
  !! @param[in] curr_value current value
  !! @param[in] tolerance tolerance
  !! @return whether zero crossing occurred
  FUNCTION NM_Detect_Zero_Crossing(func, prev_value, curr_value, tolerance) &
                                    RESULT(crossing_detected)
    TYPE(ZeroCrossing_Function), INTENT(IN) :: func
    REAL(wp), INTENT(IN) :: prev_value, curr_value, tolerance
    LOGICAL :: crossing_detected

    crossing_detected = (prev_value * curr_value < ZERO) .OR. &
                        (ABS(curr_value) < tolerance)

  END FUNCTION NM_Detect_Zero_Crossing

  !> @brief Register zero-crossing function
  !! @details Register function to monitor zero crossing
  !! @param[inout] func zero-crossing function
  !! @param[in] func_id function ID
  !! @param[in] target_value target value (usually
  SUBROUTINE NM_Reg_Zero_Crossing(func, func_id, target_value)
    TYPE(ZeroCrossing_Function), INTENT(INOUT) :: func
    INTEGER(i4), INTENT(IN) :: func_id
    REAL(wp), INTENT(IN) :: target_value

    func%func_id = func_id
    func%target_value = target_value
    func%prev_value = ZERO
    func%curr_value = ZERO
    func%is_active = .TRUE.

  END SUBROUTINE NM_Reg_Zero_Crossing

  !> @brief Update zero-crossing function
  !! @details Update function value and check zero crossing
  !! @param[inout] func zero-crossing function
  !! @param[in] new_value new value
  !! @param[out] crossing_detected whether zero crossing detected
  SUBROUTINE NM_Update_Zero_Crossing(func, new_value, crossing_detected)
    TYPE(ZeroCrossing_Function), INTENT(INOUT) :: func
    REAL(wp), INTENT(IN) :: new_value
    LOGICAL, INTENT(OUT) :: crossing_detected

    func%prev_value = func%curr_value
    func%curr_value = new_value - func%target_value

    crossing_detected = (func%prev_value * func%curr_value < ZERO)

  END SUBROUTINE NM_Update_Zero_Crossing

  !=============================================================================
  ! EVENT TIME COMPUTATION
  !=============================================================================

  !> @brief Compute event time
  !! @details Use linear interpolation for exact event time
  !! @param[in] t_prev previous time
  !! @param[in] t_curr current time
  !! @param[in] val_prev previous value
  !! @param[in] val_curr current value
  !! @param[in] target target value
  !! @return event time
  FUNCTION NM_Calc_Event_Time(t_prev, t_curr, val_prev, val_curr, target) &
                                  RESULT(event_time)
    REAL(wp), INTENT(IN) :: t_prev, t_curr, val_prev, val_curr, target
    REAL(wp) :: event_time

    REAL(wp) :: frac, denom

    denom = val_curr - val_prev
    IF (ABS(denom) < 1.0E-14_wp) THEN
      event_time = t_curr
    ELSE
      frac = (target - val_prev) / denom
      event_time = t_prev + frac * (t_curr - t_prev)
    END IF

  END FUNCTION NM_Calc_Event_Time

  !> @brief Get next event time
  !! @details Get next event time from history
  !! @param[in] state detector state
  !! @param[in] current_time current time
  !! @return next event time
  FUNCTION NM_Get_Next_Event_Time(state, current_time) RESULT(next_event_time)
    TYPE(EventDetector_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: current_time
    REAL(wp) :: next_event_time

    INTEGER(i4) :: i
    REAL(wp) :: min_time

    min_time = HUGE(ONE)

    DO i = 1, state%history_size
      IF (state%event_history(i)%is_triggered .AND. &
          .NOT. state%event_history(i)%is_processed) THEN
        IF (state%event_history(i)%event_time > current_time) THEN
          min_time = MIN(min_time, state%event_history(i)%event_time)
        END IF
      END IF
    END DO

    IF (min_time < HUGE(ONE)) THEN
      next_event_time = min_time
    ELSE
      next_event_time = -ONE  ! no event
    END IF

  END FUNCTION NM_Get_Next_Event_Time

  !> @brief Suggest step for event
  !! @details Suggest step based on upcoming event
  !! @param[in] next_event_time next event time
  !! @param[in] current_time current time
  !! @param[in] current_dt current step size
  !! @param[in] safety_factor safety factor
  !! @return suggested step size
  FUNCTION NM_Suggest_Step_For_Event(next_event_time, current_time, &
                                      current_dt, safety_factor) RESULT(suggested_dt)
    REAL(wp), INTENT(IN) :: next_event_time, current_time, current_dt, safety_factor
    REAL(wp) :: suggested_dt

    REAL(wp) :: time_to_event

    IF (next_event_time < ZERO) THEN
      ! no event
      suggested_dt = current_dt
    ELSE
      time_to_event = next_event_time - current_time
      IF (time_to_event > current_dt * 1.1_wp) THEN
        ! event far, use current step
        suggested_dt = current_dt
      ELSE IF (time_to_event > 1.0E-10_wp) THEN
        ! event near, reduce step
        suggested_dt = time_to_event * safety_factor
      ELSE
        ! event occurred or very close
        suggested_dt = current_dt * 0.1_wp
      END IF
    END IF

  END FUNCTION NM_Suggest_Step_For_Event

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief Add event to history
  !! @details Add event to history
  !! @param[inout] state detector state
  !! @param[in] event event
  SUBROUTINE NM_Add_Event_To_History(state, event)
    TYPE(EventDetector_State), INTENT(INOUT) :: state
    TYPE(TimeEvent), INTENT(IN) :: event

    state%history_pos = state%history_pos + 1_i4
    IF (state%history_pos > state%history_size) THEN
      state%history_pos = 1_i4
    END IF

    state%event_history(state%history_pos) = event
    state%n_events_detected = state%n_events_detected + 1_i4

  END SUBROUTINE NM_Add_Event_To_History

END MODULE NM_TimeInt_EventDet