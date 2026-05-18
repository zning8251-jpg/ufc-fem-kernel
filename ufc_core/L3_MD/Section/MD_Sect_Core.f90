!===============================================================================
! MODULE:  MD_Sect_Core
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Core
! BRIEF:   Section CRUD — P0 Init/Build/Validate operations.
!===============================================================================
MODULE MD_Sect_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Sect_Def, ONLY: MD_Sect_Catalog_Desc, MD_Sect_Desc, MD_SECTION_MAX
  USE MD_Sect_Def,    ONLY: MD_Sect_State
  USE MD_Sect_Compat, ONLY: MD_SectCompat_Check_Triple, MatTypeToFamily
  USE IF_Base_SymTbl, ONLY: register_variable, symbol_table_exists, &
                            IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_STRUCT
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Section_Core_Init
  PUBLIC :: MD_Section_Core_Finalize
  PUBLIC :: MD_Section_Add
  PUBLIC :: MD_Section_Get_By_ID
  PUBLIC :: MD_Section_Get_Material_ID
  PUBLIC :: MD_Section_Set_Thickness
  PUBLIC :: MD_Section_Validate
  PUBLIC :: MD_Section_Validate_Triple

CONTAINS

  SUBROUTINE MD_Section_Core_Init(desc, state, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(INOUT) :: desc
    TYPE(MD_Sect_State), INTENT(OUT)   :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    desc%n_sections = 0
    DO i = 1, MD_SECTION_MAX
      desc%sections(i)%section_id   = 0
      desc%sections(i)%name         = ""
      desc%sections(i)%section_type = 0
      desc%sections(i)%material_ref = 0
      desc%sections(i)%thickness    = 0.0_wp
      desc%sections(i)%valid        = .FALSE.
    END DO

    state%active_sections    = 0
    state%total_sections     = 0
    state%total_section_area = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_Core_Init

  SUBROUTINE MD_Section_Core_Finalize(desc, state, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(INOUT) :: desc
    TYPE(MD_Sect_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    desc%n_sections = 0
    state%active_sections    = 0
    state%total_sections     = 0
    state%total_section_area = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_Core_Finalize

  SUBROUTINE MD_Section_Add(desc, id, name, section_type, material_id, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: id
    CHARACTER(LEN=*),      INTENT(IN)    :: name
    INTEGER(i4),           INTENT(IN)    :: section_type
    INTEGER(i4),           INTENT(IN)    :: material_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)

    IF (desc%n_sections >= MD_SECTION_MAX) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    idx = desc%n_sections + 1
    desc%sections(idx)%section_id   = id
    desc%sections(idx)%name         = name
    desc%sections(idx)%section_type = section_type
    desc%sections(idx)%material_ref  = material_id
    desc%sections(idx)%valid        = .TRUE.
    desc%n_sections = idx

    ! SymTbl: register named section for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80)     :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "SECT:", TRIM(name)
        WRITE(sym_val, '(I0)') idx
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
             IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_Add

  SUBROUTINE MD_Section_Get_By_ID(desc, id, section, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: id
    TYPE(MD_Sect_Desc),     INTENT(OUT) :: section
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_sections
      IF (desc%sections(i)%section_id == id .AND. desc%sections(i)%valid) THEN
        section = desc%sections(i)
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
  END SUBROUTINE MD_Section_Get_By_ID

  SUBROUTINE MD_Section_Get_Material_ID(desc, section_id, mat_id, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: section_id
    INTEGER(i4),           INTENT(OUT) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    mat_id = 0

    DO i = 1, desc%n_sections
      IF (desc%sections(i)%section_id == section_id .AND. desc%sections(i)%valid) THEN
        mat_id = desc%sections(i)%material_ref
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
  END SUBROUTINE MD_Section_Get_Material_ID

  SUBROUTINE MD_Section_Set_Thickness(desc, section_id, thickness, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: section_id
    REAL(wp),              INTENT(IN)    :: thickness
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_sections
      IF (desc%sections(i)%section_id == section_id .AND. desc%sections(i)%valid) THEN
        desc%sections(i)%thickness = thickness
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
  END SUBROUTINE MD_Section_Set_Thickness

  SUBROUTINE MD_Section_Validate(desc, status)
    TYPE(MD_Sect_Catalog_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, desc%n_sections
      IF (desc%sections(i)%valid .AND. desc%sections(i)%material_ref <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_Validate

  !--------------------------------------------------------------------
  ! MD_Section_Validate_Triple: Validate (sect_fam, mat_type, elem_fam)
  !   compatibility via the orthogonal sparse matrix.
  !   compat_status:
  !     0 = OK, 1 = sect-mat incompatible, 2 = sect-elem incompatible,
  !     3 = both incompatible, 4 = model-level override,  -1 = bad index
  !--------------------------------------------------------------------
  SUBROUTINE MD_Section_Validate_Triple(sect_fam, mat_type, elem_fam, &
                                         compat_status, status)
    INTEGER(i4), INTENT(IN)  :: sect_fam
    INTEGER(i4), INTENT(IN)  :: mat_type
    INTEGER(i4), INTENT(IN)  :: elem_fam
    INTEGER(i4), INTENT(OUT) :: compat_status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: mat_fam

    CALL init_error_status(status)

    mat_fam = MatTypeToFamily(mat_type)
    IF (mat_fam == 0_i4) THEN
      compat_status = -1_i4
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    CALL MD_SectCompat_Check_Triple(sect_fam, mat_fam, elem_fam, &
                                     compat_status, mat_type)

    IF (compat_status /= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE MD_Section_Validate_Triple

END MODULE MD_Sect_Core
