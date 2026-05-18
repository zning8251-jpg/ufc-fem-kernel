!===============================================================================
! MODULE: AP_Reg_Core
! LAYER:  L6_AP
! DOMAIN: Registry
! ROLE:   Core — registration and lookup
! BRIEF:  Element and material type registration, lookup, and listing.
!===============================================================================
! Signature: (desc, state, ..., status)
! P0: Init, Finalize, Register_Element, Register_Material
! P1: Lookup_Element, Lookup_Material
! P3: Print
!===============================================================================
MODULE AP_Reg_Core
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Reg_Def,  ONLY: AP_Registry_Desc, AP_Registry_State, &
                              AP_RegEntry, AP_REG_MAX_ENTRIES
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: CAT_ELEMENT  = 1
  INTEGER(i4), PARAMETER :: CAT_MATERIAL = 2

  PUBLIC :: AP_Registry_Core_Init
  PUBLIC :: AP_Registry_Core_Finalize
  PUBLIC :: AP_Registry_Register_Element
  PUBLIC :: AP_Registry_Register_Material
  PUBLIC :: AP_Registry_Lookup_Element
  PUBLIC :: AP_Registry_Lookup_Material
  PUBLIC :: AP_Registry_Get_Count
  PUBLIC :: AP_Registry_Print

CONTAINS

  SUBROUTINE AP_Registry_Core_Init(desc, state, status)
    TYPE(AP_Registry_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Registry_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    state%n_entries = 0
    DO i = 1, AP_REG_MAX_ENTRIES
      state%entries(i)%name     = ""
      state%entries(i)%type_id  = 0
      state%entries(i)%category = 0
      state%entries(i)%valid    = .FALSE.
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Registry_Core_Init

  SUBROUTINE AP_Registry_Core_Finalize(desc, state, status)
    TYPE(AP_Registry_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Registry_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%n_entries = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Registry_Core_Finalize

  !---------------------------------------------------------------------------
  ! Register element type
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Registry_Register_Element(desc, state, name, type_id, status)
    TYPE(AP_Registry_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Registry_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),        INTENT(IN)    :: name
    INTEGER(i4),             INTENT(IN)    :: type_id
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    CALL register_entry(state, name, type_id, CAT_ELEMENT, status)
  END SUBROUTINE AP_Registry_Register_Element

  !---------------------------------------------------------------------------
  ! Register material type
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Registry_Register_Material(desc, state, name, type_id, status)
    TYPE(AP_Registry_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Registry_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),        INTENT(IN)    :: name
    INTEGER(i4),             INTENT(IN)    :: type_id
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    CALL register_entry(state, name, type_id, CAT_MATERIAL, status)
  END SUBROUTINE AP_Registry_Register_Material

  !---------------------------------------------------------------------------
  ! Lookup element by name
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Registry_Lookup_Element(state, name, type_id, status)
    TYPE(AP_Registry_State), INTENT(IN)  :: state
    CHARACTER(LEN=*),        INTENT(IN)  :: name
    INTEGER(i4),             INTENT(OUT) :: type_id
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL lookup_entry(state, name, CAT_ELEMENT, type_id, status)
  END SUBROUTINE AP_Registry_Lookup_Element

  !---------------------------------------------------------------------------
  ! Lookup material by name
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Registry_Lookup_Material(state, name, type_id, status)
    TYPE(AP_Registry_State), INTENT(IN)  :: state
    CHARACTER(LEN=*),        INTENT(IN)  :: name
    INTEGER(i4),             INTENT(OUT) :: type_id
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL lookup_entry(state, name, CAT_MATERIAL, type_id, status)
  END SUBROUTINE AP_Registry_Lookup_Material

  FUNCTION AP_Registry_Get_Count(state) RESULT(n)
    TYPE(AP_Registry_State), INTENT(IN) :: state
    INTEGER(i4) :: n
    n = state%n_entries
  END FUNCTION AP_Registry_Get_Count

  !---------------------------------------------------------------------------
  ! Print all registry entries
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Registry_Print(desc, state, unit_num, status)
    TYPE(AP_Registry_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Registry_State), INTENT(IN)  :: state
    INTEGER(i4),             INTENT(IN)  :: unit_num
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    INTEGER(i4) :: i
    CHARACTER(LEN=16) :: cat_str

    CALL init_error_status(status)
    WRITE(unit_num, '(A,I0,A)') "===== REGISTRY (", state%n_entries, " entries) ====="
    DO i = 1, state%n_entries
      IF (state%entries(i)%valid) THEN
        SELECT CASE (state%entries(i)%category)
          CASE (CAT_ELEMENT);  cat_str = "ELEMENT"
          CASE (CAT_MATERIAL); cat_str = "MATERIAL"
          CASE DEFAULT;        cat_str = "UNKNOWN"
        END SELECT
        WRITE(unit_num, '(A,I4,A,A,A,I0)') &
          "  [", i, "] ", TRIM(cat_str), &
          " : " // TRIM(state%entries(i)%name) // " id=", &
          state%entries(i)%type_id
      END IF
    END DO
    WRITE(unit_num, '(A)') "================================="
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Registry_Print

  !===========================================================================
  ! PRIVATE helpers
  !===========================================================================

  SUBROUTINE register_entry(state, name, type_id, category, status)
    TYPE(AP_Registry_State), INTENT(INOUT) :: state
    CHARACTER(LEN=*),        INTENT(IN)    :: name
    INTEGER(i4),             INTENT(IN)    :: type_id
    INTEGER(i4),             INTENT(IN)    :: category
    TYPE(ErrorStatusType),   INTENT(INOUT) :: status

    INTEGER(i4) :: idx

    IF (state%n_entries >= AP_REG_MAX_ENTRIES) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Registry]: registry full"
      RETURN
    END IF

    idx = state%n_entries + 1
    state%entries(idx)%name     = name
    state%entries(idx)%type_id  = type_id
    state%entries(idx)%category = category
    state%entries(idx)%valid    = .TRUE.
    state%n_entries = idx
    status%status_code = IF_STATUS_OK
  END SUBROUTINE register_entry

  SUBROUTINE lookup_entry(state, name, category, type_id, status)
    TYPE(AP_Registry_State), INTENT(IN)    :: state
    CHARACTER(LEN=*),        INTENT(IN)    :: name
    INTEGER(i4),             INTENT(IN)    :: category
    INTEGER(i4),             INTENT(OUT)   :: type_id
    TYPE(ErrorStatusType),   INTENT(INOUT) :: status

    INTEGER(i4) :: i

    type_id = 0
    DO i = 1, state%n_entries
      IF (state%entries(i)%valid .AND. &
          state%entries(i)%category == category .AND. &
          TRIM(state%entries(i)%name) == TRIM(name)) THEN
        type_id = state%entries(i)%type_id
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "[AP_Registry]: entry not found"
  END SUBROUTINE lookup_entry

END MODULE AP_Reg_Core
