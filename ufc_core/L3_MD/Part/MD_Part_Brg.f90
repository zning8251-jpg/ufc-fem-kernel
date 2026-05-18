!===============================================================================
! MODULE:  MD_Part_Brg
! LAYER:   L3_MD
! DOMAIN:  Part
! ROLE:    _Brg
! BRIEF:   Part bridge — P1 Map: cross-layer type adaptation.
!          Validates Part-Section binding; provides section ref for L4 Populate.
!===============================================================================
MODULE MD_Part_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Part_Def,  ONLY: MD_Part_Desc, MD_Part_State, MD_Part_Entry_Desc, &
                           MD_Part_Domain, MD_PART_MAX
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Part_Brg_Validate_Binding
  PUBLIC :: MD_Part_Brg_Get_Section_Ref
  PUBLIC :: MD_Part_Brg_Get_Part_Count

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Brg_Validate_Binding
  ! PHASE:      P1
  ! PURPOSE:    Pre-Populate validation — every valid part must have section_id > 0
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Brg_Validate_Binding(domain, n_unassigned, status)
    TYPE(MD_Part_Domain),  INTENT(IN)  :: domain
    INTEGER(i4),           INTENT(OUT) :: n_unassigned
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    n_unassigned = 0

    IF (.NOT. domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_Brg: domain not initialized"
      RETURN
    END IF

    DO i = 1, domain%desc%n_parts
      IF (domain%desc%parts(i)%valid .AND. &
          domain%desc%parts(i)%section_id <= 0) THEN
        n_unassigned = n_unassigned + 1
      END IF
    END DO

    IF (n_unassigned > 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Part_Brg: parts without section assignment"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE MD_Part_Brg_Validate_Binding

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_Brg_Get_Section_Ref
  ! PHASE:      P1
  ! PURPOSE:    Bridge query — get section_id for a given part index
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_Brg_Get_Section_Ref(domain, part_idx, section_id, status)
    TYPE(MD_Part_Domain),  INTENT(IN)  :: domain
    INTEGER(i4),           INTENT(IN)  :: part_idx
    INTEGER(i4),           INTENT(OUT) :: section_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    section_id = 0

    IF (.NOT. domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (part_idx < 1 .OR. part_idx > domain%desc%n_parts) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. domain%desc%parts(part_idx)%valid) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    section_id = domain%desc%parts(part_idx)%section_id
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_Brg_Get_Section_Ref

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Part_Brg_Get_Part_Count
  ! PHASE:      P1
  ! PURPOSE:    Bridge query — return valid part count
  !---------------------------------------------------------------------------
  PURE FUNCTION MD_Part_Brg_Get_Part_Count(domain) RESULT(n)
    TYPE(MD_Part_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n

    IF (domain%initialized) THEN
      n = domain%desc%n_parts
    ELSE
      n = 0_i4
    END IF
  END FUNCTION MD_Part_Brg_Get_Part_Count

END MODULE MD_Part_Brg
