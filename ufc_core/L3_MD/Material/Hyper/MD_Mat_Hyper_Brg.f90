!===============================================================================
! MODULE: MD_Mat_Hyper_Brg
! Layer:  L3_MD / Material / Hyper
! Purpose: L3 hyperelastic descriptor routing / L4 props table populate (cold path).
!===============================================================================
MODULE MD_Mat_Hyper_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Hyper_Def, ONLY: MD_Mat_Hyper_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_HE_SUB_NEOHOOKEAN, MD_MAT_HE_SUB_MOONEY2, &
    MD_MAT_HE_SUB_OGDEN2, MD_MAT_HE_SUB_ARRUDA_BOYCE, MD_MAT_HE_SUB_YEOH
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Hyper_Route_L4
  PUBLIC :: MD_Mat_Hyper_Brg_Populate_L4

CONTAINS

  SUBROUTINE MD_Mat_Hyper_Route_L4(desc, model_id, ierr)
    TYPE(MD_Mat_Hyper_Desc), INTENT(IN)  :: desc
    INTEGER(i4),             INTENT(IN)  :: model_id
    INTEGER(i4),             INTENT(OUT) :: ierr

    ierr = IF_STATUS_OK

    SELECT CASE (model_id)
    CASE (MD_MAT_HE_SUB_NEOHOOKEAN)
      CONTINUE
    CASE (MD_MAT_HE_SUB_MOONEY2)
      CONTINUE
    CASE (MD_MAT_HE_SUB_OGDEN2)
      CONTINUE
    CASE (MD_MAT_HE_SUB_ARRUDA_BOYCE)
      CONTINUE
    CASE (MD_MAT_HE_SUB_YEOH)
      CONTINUE
    CASE DEFAULT
      ierr = IF_STATUS_INVALID
    END SELECT

  END SUBROUTINE MD_Mat_Hyper_Route_L4

  SUBROUTINE MD_Mat_Hyper_Brg_Populate_L4(l3_desc, l4_props, l4_temps, &
                                             l4_nprops, l4_ntemps, status)
    TYPE(MD_Mat_Hyper_Desc), INTENT(IN) :: l3_desc
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: l4_props(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: l4_temps(:)
    INTEGER(i4), INTENT(OUT) :: l4_nprops
    INTEGER(i4), INTENT(OUT) :: l4_ntemps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    l4_nprops = l3_desc%n_coeffs
    l4_ntemps = 0

    IF (l3_desc%dependencies > 0 .AND. l4_ntemps > 0) THEN
      ALLOCATE(l4_props(l4_nprops, 1 + l4_ntemps))
      ALLOCATE(l4_temps(l4_ntemps))
      DO j = 1, 1 + l4_ntemps
        DO i = 1, l4_nprops
          l4_props(i, j) = l3_desc%coeffs(i)
        END DO
      END DO
    ELSE
      IF (l4_nprops < 1) l4_nprops = MAX(1, l3_desc%n_coeffs)
      ALLOCATE(l4_props(l4_nprops, 1))
      DO i = 1, MIN(l4_nprops, SIZE(l3_desc%coeffs))
        l4_props(i, 1) = l3_desc%coeffs(i)
      END DO
      l4_ntemps = 0
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Hyper_Brg_Populate_L4

END MODULE MD_Mat_Hyper_Brg
