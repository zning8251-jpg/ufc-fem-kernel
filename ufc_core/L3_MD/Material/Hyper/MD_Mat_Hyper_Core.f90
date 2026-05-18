!===============================================================================
! MODULE: MD_Mat_Hyper_Core
! Layer:  L3_MD / Material / Hyper
! Purpose: Validate & populate MD_Mat_Hyper_Desc from props (no constitutive compute).
!===============================================================================
MODULE MD_Mat_Hyper_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Hyper_Def, ONLY: MD_Mat_Hyper_Desc, MD_HYPER_MAX_COEFFS, &
    MD_MAT_HE_SUB_NEOHOOKEAN, MD_MAT_HE_SUB_MOONEY2
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Hyper_Validate_Params
  PUBLIC :: MD_Mat_Hyper_Populate

CONTAINS

  SUBROUTINE MD_Mat_Hyper_Validate_Params(desc, ierr)
    TYPE(MD_Mat_Hyper_Desc), INTENT(IN)  :: desc
    INTEGER(i4),             INTENT(OUT) :: ierr

    ierr = IF_STATUS_OK

    SELECT CASE (desc%sub_type)
    CASE (MD_MAT_HE_SUB_NEOHOOKEAN)
      IF (desc%mu <= 0.0_wp) ierr = IF_STATUS_INVALID
    CASE (MD_MAT_HE_SUB_MOONEY2)
      IF ((desc%C10 + desc%C01) <= 0.0_wp) ierr = IF_STATUS_INVALID
    CASE DEFAULT
      IF (desc%n_coeffs < 1_i4) ierr = IF_STATUS_INVALID
    END SELECT

  END SUBROUTINE MD_Mat_Hyper_Validate_Params

  SUBROUTINE MD_Mat_Hyper_Populate(desc, sub_type, nprops, props, ierr)
    TYPE(MD_Mat_Hyper_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),             INTENT(IN)    :: sub_type
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),                 INTENT(IN)    :: props(:)
    INTEGER(i4),             INTENT(OUT)   :: ierr

    ierr = IF_STATUS_OK
    desc%sub_type = sub_type

    SELECT CASE (sub_type)
    CASE (MD_MAT_HE_SUB_NEOHOOKEAN)
      IF (nprops < 2) THEN
        ierr = IF_STATUS_INVALID
        RETURN
      END IF
      desc%mu     = props(1)
      desc%lambda = props(2)

    CASE (MD_MAT_HE_SUB_MOONEY2)
      IF (nprops < 3) THEN
        ierr = IF_STATUS_INVALID
        RETURN
      END IF
      desc%C10 = props(1)
      desc%C01 = props(2)
      desc%D1  = props(3)

    CASE DEFAULT
      IF (nprops < 1) THEN
        ierr = IF_STATUS_INVALID
        RETURN
      END IF
      desc%n_coeffs = MIN(nprops, MD_HYPER_MAX_COEFFS)
      desc%coeffs(1:desc%n_coeffs) = props(1:desc%n_coeffs)
    END SELECT

    CALL MD_Mat_Hyper_Validate_Params(desc, ierr)

  END SUBROUTINE MD_Mat_Hyper_Populate

END MODULE MD_Mat_Hyper_Core
