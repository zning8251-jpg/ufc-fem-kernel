!===============================================================================
! MODULE:  MD_Part_Sync
! LAYER:   L3_MD
! DOMAIN:  Part
! ROLE:    _Sync
! BRIEF:   Part sync — P1 Sync legacy UF_PartDef to MD_Part_Domain;
!          P1 Verify domain queries (GetFromDomain, GetFromDomainByName).
!          Vertical slice: use MD_Part_Entry_Desc for single-part query (not
!          the collection type MD_Part_Desc).
!===============================================================================
MODULE MD_Part_Sync
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Part_Mgr,  ONLY: MD_Part_Domain
  USE MD_Part_Def,  ONLY: MD_Part_Entry_Desc
  USE MD_Part_Core, ONLY: MD_Part_Append_To_Domain, MD_Part_Get_By_Name
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  USE MD_L3_Layer,  ONLY: MD_L3_LayerContainer
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Part_SyncFromLegacy
  PUBLIC :: MD_Part_GetFromDomain
  PUBLIC :: MD_Part_GetFromDomainByName

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_SyncFromLegacy
  ! PHASE:      P1
  ! PURPOSE:    Sync model%parts (legacy) into MD_Part_Domain
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef),          INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4)     :: i, n_parts, part_id

    CALL init_error_status(status)
    IF (.NOT. md_layer%state%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_Sync: md_layer not initialized"
      RETURN
    END IF

    n_parts = model_def%num_parts
    IF (n_parts <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. ALLOCATED(model_def%parts)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    DO i = 1, n_parts
      IF (i > SIZE(model_def%parts)) EXIT
      part_id = model_def%parts(i)%cfg%id
      IF (part_id <= 0) part_id = i
      CALL MD_Part_Append_To_Domain(md_layer%desc%part, part_id, &
        TRIM(model_def%parts(i)%name), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_SyncFromLegacy

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_GetFromDomain
  ! PHASE:      P1
  ! PURPOSE:    Bridge query — get one part entry by 1-based index
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_GetFromDomain(domain, part_id, part_entry, status)
    TYPE(MD_Part_Domain),     INTENT(IN)  :: domain
    INTEGER(i4),               INTENT(IN)  :: part_id
    TYPE(MD_Part_Entry_Desc), INTENT(OUT) :: part_entry
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_GetFromDomain: domain not initialized"
      RETURN
    END IF
    IF (part_id < 1 .OR. part_id > domain%n_parts) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_GetFromDomain: part_id out of range"
      RETURN
    END IF
    part_entry = domain%desc%parts(part_id)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_GetFromDomain

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_GetFromDomainByName
  ! PHASE:      P1
  ! PURPOSE:    Bridge query — get part entry by name
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_GetFromDomainByName(domain, name, part_entry, status)
    TYPE(MD_Part_Domain),     INTENT(IN)  :: domain
    CHARACTER(LEN=*),          INTENT(IN)  :: name
    TYPE(MD_Part_Entry_Desc), INTENT(OUT) :: part_entry
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    IF (.NOT. domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_GetFromDomainByName: domain not initialized"
      RETURN
    END IF

    CALL MD_Part_Get_By_Name(domain%desc, name, part_entry, idx, status)
  END SUBROUTINE MD_Part_GetFromDomainByName

END MODULE MD_Part_Sync
