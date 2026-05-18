!===============================================================================
! MODULE: AP_Config_Core
! LAYER:  L6_AP
! DOMAIN: Config
! ROLE:   Core — key-value configuration store
! BRIEF:  Set/get typed values, command-line parsing, printing.
!===============================================================================
! Signature: (desc, state, status) or (state, key, value, status)
! P0: Init, Finalize, Parse_CommandLine
! P1: Set_Int, Set_Real, Set_String, Get_Int, Get_Real, Get_String
! P3: Print
!===============================================================================
MODULE AP_Config_Core
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Config_Def,  ONLY: AP_Config_Desc, AP_Config_State, &
                            AP_ConfigEntry, AP_CFG_MAX, AP_CFG_KEY_LEN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Config_Core_Init
  PUBLIC :: AP_Config_Core_Finalize
  PUBLIC :: AP_Config_Set_Int
  PUBLIC :: AP_Config_Set_Real
  PUBLIC :: AP_Config_Set_String
  PUBLIC :: AP_Config_Get_Int
  PUBLIC :: AP_Config_Get_Real
  PUBLIC :: AP_Config_Get_String
  PUBLIC :: AP_Config_Parse_CommandLine
  PUBLIC :: AP_Config_Print

CONTAINS

  SUBROUTINE AP_Config_Core_Init(desc, state, status)
    TYPE(AP_Config_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Config_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    state%n_entries = 0
    DO i = 1, AP_CFG_MAX
      state%entries(i)%key      = ""
      state%entries(i)%int_val  = 0
      state%entries(i)%real_val = 0.0_wp
      state%entries(i)%str_val  = ""
      state%entries(i)%valid    = .FALSE.
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Core_Init

  SUBROUTINE AP_Config_Core_Finalize(desc, state, status)
    TYPE(AP_Config_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Config_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%n_entries = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Core_Finalize

  !---------------------------------------------------------------------------
  ! Find existing entry index by key, or return 0 if not found
  !---------------------------------------------------------------------------
  FUNCTION find_entry(state, key) RESULT(idx)
    TYPE(AP_Config_State), INTENT(IN) :: state
    CHARACTER(LEN=*),      INTENT(IN) :: key
    INTEGER(i4) :: idx
    INTEGER(i4) :: i

    idx = 0
    DO i = 1, state%n_entries
      IF (TRIM(state%entries(i)%key) == TRIM(key) .AND. &
          state%entries(i)%valid) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION find_entry

  !---------------------------------------------------------------------------
  ! Set integer config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Set_Int(state, key, value, status)
    TYPE(AP_Config_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),      INTENT(IN)    :: key
    INTEGER(i4),           INTENT(IN)    :: value
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      IF (state%n_entries >= AP_CFG_MAX) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[AP_Config_Set_Int]: config store full"
        RETURN
      END IF
      state%n_entries = state%n_entries + 1
      idx = state%n_entries
      state%entries(idx)%key   = key
      state%entries(idx)%valid = .TRUE.
    END IF
    state%entries(idx)%int_val = value
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Set_Int

  !---------------------------------------------------------------------------
  ! Set real config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Set_Real(state, key, value, status)
    TYPE(AP_Config_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),      INTENT(IN)    :: key
    REAL(wp),              INTENT(IN)    :: value
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      IF (state%n_entries >= AP_CFG_MAX) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[AP_Config_Set_Real]: config store full"
        RETURN
      END IF
      state%n_entries = state%n_entries + 1
      idx = state%n_entries
      state%entries(idx)%key   = key
      state%entries(idx)%valid = .TRUE.
    END IF
    state%entries(idx)%real_val = value
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Set_Real

  !---------------------------------------------------------------------------
  ! Set string config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Set_String(state, key, value, status)
    TYPE(AP_Config_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),      INTENT(IN)    :: key
    CHARACTER(LEN=*),      INTENT(IN)    :: value
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      IF (state%n_entries >= AP_CFG_MAX) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[AP_Config_Set_String]: config store full"
        RETURN
      END IF
      state%n_entries = state%n_entries + 1
      idx = state%n_entries
      state%entries(idx)%key   = key
      state%entries(idx)%valid = .TRUE.
    END IF
    state%entries(idx)%str_val = value
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Set_String

  !---------------------------------------------------------------------------
  ! Get integer config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Get_Int(state, key, value, status)
    TYPE(AP_Config_State), INTENT(IN)  :: state
    CHARACTER(LEN=*),      INTENT(IN)  :: key
    INTEGER(i4),           INTENT(OUT) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      value = 0
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Config_Get_Int]: key not found"
      RETURN
    END IF
    value = state%entries(idx)%int_val
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Get_Int

  !---------------------------------------------------------------------------
  ! Get real config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Get_Real(state, key, value, status)
    TYPE(AP_Config_State), INTENT(IN)  :: state
    CHARACTER(LEN=*),      INTENT(IN)  :: key
    REAL(wp),              INTENT(OUT) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      value = 0.0_wp
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Config_Get_Real]: key not found"
      RETURN
    END IF
    value = state%entries(idx)%real_val
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Get_Real

  !---------------------------------------------------------------------------
  ! Get string config value
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Get_String(state, key, value, status)
    TYPE(AP_Config_State), INTENT(IN)  :: state
    CHARACTER(LEN=*),      INTENT(IN)  :: key
    CHARACTER(LEN=*),      INTENT(OUT) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = find_entry(state, key)
    IF (idx == 0) THEN
      value = ""
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Config_Get_String]: key not found"
      RETURN
    END IF
    value = state%entries(idx)%str_val
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Get_String

  !---------------------------------------------------------------------------
  ! Parse command-line arguments (placeholder)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Parse_CommandLine(state, status)
    TYPE(AP_Config_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Parse_CommandLine

  !---------------------------------------------------------------------------
  ! Print all config entries
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Config_Print(desc, state, unit_num, status)
    TYPE(AP_Config_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Config_State), INTENT(IN)  :: state
    INTEGER(i4),           INTENT(IN)  :: unit_num
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    WRITE(unit_num, '(A,I0,A)') "===== CONFIG (", state%n_entries, " entries) ====="
    DO i = 1, state%n_entries
      IF (state%entries(i)%valid) THEN
        WRITE(unit_num, '(A,A,A,I0,A,ES12.4,A,A)') &
          "  ", TRIM(state%entries(i)%key), &
          " | int=", state%entries(i)%int_val, &
          " | real=", state%entries(i)%real_val, &
          " | str=", TRIM(state%entries(i)%str_val)
      END IF
    END DO
    WRITE(unit_num, '(A)') "================================="
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Print

END MODULE AP_Config_Core
