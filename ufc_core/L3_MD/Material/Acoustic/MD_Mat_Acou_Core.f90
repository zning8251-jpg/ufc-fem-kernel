!===============================================================================
! MODULE: MD_Mat_Acou_Core
! LAYER:  L3_MD
! DOMAIN: Material / Acoustic
!===============================================================================
MODULE MD_Mat_Acou_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Acou_Def
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_ACOUSTIC, &
                               MD_MAT_ACOU_SUB_LINEAR, &
                               MD_MAT_ACOU_SUB_ABSORB

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Acou_Create_From_Props
  PUBLIC :: MD_Mat_Acou_Parse_ABAQUS_Keyword
  PUBLIC :: MD_Mat_Acou_Register

CONTAINS

  SUBROUTINE MD_Mat_Acou_Create_From_Props(desc, sub_type, nprops, props, dependencies, status)
    TYPE(MD_Mat_Acou_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type, nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, deps

    CALL init_error_status(status)
    deps = 0; IF (PRESENT(dependencies)) deps = dependencies
    CALL MD_Mat_Acou_Desc_Init(desc, sub_type, nprops, deps, status)
    IF (status%status_code /= 0) RETURN

    DO i = 1, nprops
      desc%constants(i, 1) = props(i)
    END DO

    CALL MD_Mat_Acou_Desc_ComputeDerived(desc, status)
    CALL MD_Mat_Acou_Desc_Validate(desc, status)
  END SUBROUTINE MD_Mat_Acou_Create_From_Props

  SUBROUTINE MD_Mat_Acou_Parse_ABAQUS_Keyword(desc, keyword_type, nprops, props, dependencies, status)
    TYPE(MD_Mat_Acou_Desc), INTENT(OUT) :: desc
    CHARACTER(LEN=*), INTENT(IN) :: keyword_type
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: sub_type

    CALL init_error_status(status)
    SELECT CASE (TRIM(keyword_type))
    CASE ("ACOUSTIC MEDIUM", "LINEAR")
      sub_type = MD_MAT_ACOU_SUB_LINEAR
    CASE ("ABSORPTIVE")
      sub_type = MD_MAT_ACOU_SUB_ABSORB
    CASE DEFAULT
      status%status_code = 1
      RETURN
    END SELECT
    CALL MD_Mat_Acou_Create_From_Props(desc, sub_type, nprops, props, dependencies, status)
  END SUBROUTINE MD_Mat_Acou_Parse_ABAQUS_Keyword

  SUBROUTINE MD_Mat_Acou_Register(desc, mat_id, status)
    USE MD_Mat_Registry, ONLY: MD_Mat_Registry_Register
    TYPE(MD_Mat_Acou_Desc), INTENT(IN) :: desc
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL MD_Mat_Registry_Register(mat_id, MD_MAT_FAMILY_ACOUSTIC, desc%sub_type, desc, status)
  END SUBROUTINE MD_Mat_Acou_Register

END MODULE MD_Mat_Acou_Core