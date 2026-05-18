!===============================================================================
! MODULE:  MD_Sect_Brg
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Brg
! BRIEF:   Section bridge — P1 Map: validates Material-Section-Element
!          triples during L3→L4 populate.
!===============================================================================
MODULE MD_Sect_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Sect_Compat, ONLY: MD_SectCompat_Check_Triple, MatTypeToFamily, &
                            SectCompat_Get_StressState
  USE MD_Elem_Family, ONLY: ElemFamilyToSectFamily, ElemTypeToFamily
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Section_Brg_Validate_Assignment
  PUBLIC :: MD_Section_Brg_Get_StressState

CONTAINS

  !--------------------------------------------------------------------
  ! MD_Section_Brg_Validate_Assignment
  !   Full triple check during L3->L4 populate: given an element type
  !   and a material type, derive families and validate compatibility.
  !
  !   compat_status: 0=OK, 1=sect-mat, 2=sect-elem, 3=both, 4=model, -1=bad
  !--------------------------------------------------------------------
  SUBROUTINE MD_Section_Brg_Validate_Assignment(elem_type, mat_type, &
                                                  sect_fam_override, &
                                                  compat_status, status)
    INTEGER(i4), INTENT(IN)  :: elem_type
    INTEGER(i4), INTENT(IN)  :: mat_type
    INTEGER(i4), INTENT(IN)  :: sect_fam_override  ! 0 = auto-derive from elem
    INTEGER(i4), INTENT(OUT) :: compat_status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: elem_fam, sect_fam, mat_fam

    CALL init_error_status(status)

    elem_fam = ElemTypeToFamily(elem_type)
    mat_fam  = MatTypeToFamily(mat_type)

    IF (sect_fam_override > 0_i4) THEN
      sect_fam = sect_fam_override
    ELSE
      sect_fam = ElemFamilyToSectFamily(elem_fam)
    END IF

    IF (mat_fam == 0_i4 .OR. sect_fam == 0_i4) THEN
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

  END SUBROUTINE MD_Section_Brg_Validate_Assignment

  !--------------------------------------------------------------------
  ! MD_Section_Brg_Get_StressState
  !   Derive stress state from section family + element family.
  !   Centralizes the ntens determination for L3->L4 bridge path.
  !--------------------------------------------------------------------
  PURE FUNCTION MD_Section_Brg_Get_StressState(sect_fam, elem_type) RESULT(ss)
    INTEGER(i4), INTENT(IN) :: sect_fam, elem_type
    INTEGER(i4) :: ss
    INTEGER(i4) :: elem_fam

    elem_fam = ElemTypeToFamily(elem_type)
    ss = SectCompat_Get_StressState(sect_fam, elem_fam)
  END FUNCTION MD_Section_Brg_Get_StressState

END MODULE MD_Sect_Brg
