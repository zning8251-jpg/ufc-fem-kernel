!===============================================================================
! MODULE:  MD_Part_Core
! LAYER:   L3_MD
! DOMAIN:  Part
! ROLE:    _Core
! BRIEF:   Part CRUD + Clone/Transform — P0 Init/Build/Validate operations.
!===============================================================================
MODULE MD_Part_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Part_Def,     ONLY: MD_Part_Desc, MD_Part_State, MD_Part_Entry_Desc, &
                              MD_Part_Domain, MD_PART_MAX, MD_PART_NAME_LEN
  USE IF_Base_SymTbl,  ONLY: register_variable, symbol_table_exists, &
                              IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_STRUCT
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Part_Core_Init
  PUBLIC :: MD_Part_Core_Finalize
  PUBLIC :: MD_Part_Add
  PUBLIC :: MD_Part_Get_By_ID
  PUBLIC :: MD_Part_Get_By_Name
  PUBLIC :: MD_Part_Assign_Section
  PUBLIC :: MD_Part_Validate
  PUBLIC :: MD_Part_Clone
  PUBLIC :: MD_Part_Transform
  PUBLIC :: MD_Part_Append_To_Domain

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize Desc and State to blank slate
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Core_Init(desc, state, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Part_State),   INTENT(OUT)   :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    desc%n_parts = 0
    DO i = 1, MD_PART_MAX
      desc%parts(i)%id         = 0
      desc%parts(i)%name       = ""
      desc%parts(i)%section_id = 0
      desc%parts(i)%valid      = .FALSE.
    END DO

    state%sections_assigned = .FALSE.
    state%materials_bound   = .FALSE.
    state%validated         = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Core_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Reset Desc/State to released state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Core_Finalize(desc, state, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Part_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    desc%n_parts       = 0
    state%validated    = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Core_Finalize

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Add
  ! PHASE:      P0
  ! PURPOSE:    Register a new part entry in Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Add(desc, id, name, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: id
    CHARACTER(LEN=*),      INTENT(IN)    :: name
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)

    IF (desc%n_parts >= MD_PART_MAX) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    idx = desc%n_parts + 1
    desc%parts(idx)%id    = id
    desc%parts(idx)%name  = name
    desc%parts(idx)%valid = .TRUE.
    desc%n_parts = idx

    ! SymTbl: register user-named part for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80)     :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "PART:", TRIM(name)
        WRITE(sym_val, '(I0)') idx
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Add

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Get_By_ID
  ! PHASE:      P0
  ! PURPOSE:    Linear search by part ID — return entry Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Get_By_ID(desc, id, part, status)
    TYPE(MD_Part_Desc),       INTENT(IN)  :: desc
    INTEGER(i4),              INTENT(IN)  :: id
    TYPE(MD_Part_Entry_Desc), INTENT(OUT) :: part
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_parts
      IF (desc%parts(i)%id == id .AND. desc%parts(i)%valid) THEN
        part = desc%parts(i)
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
  END SUBROUTINE MD_Part_Get_By_ID

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Assign_Section
  ! PHASE:      P0
  ! PURPOSE:    Bind section_id to a part entry
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Assign_Section(desc, part_id, section_id, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: part_id
    INTEGER(i4),           INTENT(IN)    :: section_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_parts
      IF (desc%parts(i)%id == part_id .AND. desc%parts(i)%valid) THEN
        desc%parts(i)%section_id = section_id
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
  END SUBROUTINE MD_Part_Assign_Section

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate all parts have section assignment
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Validate(desc, status)
    TYPE(MD_Part_Desc),    INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_parts
      IF (desc%parts(i)%valid .AND. desc%parts(i)%section_id <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Validate

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Get_By_Name
  ! PHASE:      P0
  ! PURPOSE:    Linear search by part name — return entry + index
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Get_By_Name(desc, name, part, part_idx, status)
    TYPE(MD_Part_Desc),       INTENT(IN)  :: desc
    CHARACTER(LEN=*),         INTENT(IN)  :: name
    TYPE(MD_Part_Entry_Desc), INTENT(OUT) :: part
    INTEGER(i4),              INTENT(OUT) :: part_idx
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    part_idx = 0

    DO i = 1, desc%n_parts
      IF (TRIM(desc%parts(i)%name) == TRIM(name) .AND. &
          desc%parts(i)%valid) THEN
        part     = desc%parts(i)
        part_idx = i
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
    status%message = "Part not found: " // TRIM(name)
  END SUBROUTINE MD_Part_Get_By_Name

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Clone
  ! PHASE:      P0
  ! PURPOSE:    Deep copy a part entry under a new name/id
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Clone(desc, src_id, new_id, new_name, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: src_id
    INTEGER(i4),           INTENT(IN)    :: new_id
    CHARACTER(LEN=*),      INTENT(IN)    :: new_name
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(MD_Part_Entry_Desc) :: src_entry
    INTEGER(i4)              :: i, idx

    CALL init_error_status(status)

    ! Find source
    DO i = 1, desc%n_parts
      IF (desc%parts(i)%id == src_id .AND. desc%parts(i)%valid) THEN
        src_entry = desc%parts(i)
        GO TO 100
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "Clone source part not found"
    RETURN

100 CONTINUE
    ! Check capacity
    IF (desc%n_parts >= MD_PART_MAX) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Part capacity exceeded"
      RETURN
    END IF

    ! Check name uniqueness
    DO i = 1, desc%n_parts
      IF (TRIM(desc%parts(i)%name) == TRIM(new_name) .AND. &
          desc%parts(i)%valid) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Clone target name already exists"
        RETURN
      END IF
    END DO

    idx = desc%n_parts + 1
    desc%parts(idx)      = src_entry
    desc%parts(idx)%id   = new_id
    desc%parts(idx)%name = new_name
    desc%n_parts = idx

    ! SymTbl registration
    IF (symbol_table_exists() .AND. LEN_TRIM(new_name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80)     :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "PART:", TRIM(new_name)
        WRITE(sym_val, '(I0)') idx
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Clone

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Transform
  ! PHASE:      P0
  ! PURPOSE:    Validate part exists for coordinate transform request.
  !             Actual transform applied at Assembly instantiation level.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Transform(desc, part_id, translation, rotation, status)
    TYPE(MD_Part_Desc),    INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: part_id
    REAL(wp),              INTENT(IN)    :: translation(3)
    REAL(wp),              INTENT(IN)    :: rotation(3,3)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_parts
      IF (desc%parts(i)%id == part_id .AND. desc%parts(i)%valid) THEN
        ! Part found: transform will be applied at instantiation
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
    status%message = "Part not found for transform"
  END SUBROUTINE MD_Part_Transform

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Append_To_Domain
  ! PHASE:      P1
  ! PURPOSE:    Append one part entry; keep domain%n_parts aligned with desc%n_parts
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Append_To_Domain(domain, id, name, status)
    TYPE(MD_Part_Domain),  INTENT(INOUT) :: domain
    INTEGER(i4),           INTENT(IN)    :: id
    CHARACTER(LEN=*),      INTENT(IN)    :: name
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL MD_Part_Add(domain%desc, id, name, status)
    IF (status%status_code == IF_STATUS_OK) domain%n_parts = domain%desc%n_parts
  END SUBROUTINE MD_Part_Append_To_Domain

END MODULE MD_Part_Core
