!===============================================================================
! MODULE: skeleton
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  User family implementation -- skeleton.
! **W1**：**`MD_Mat_Desc` 叶**；**`MD_MAT_ID_708`**（**708**）；**UMAT 占位**；**Populate** / **`desc%props`** / **`MD_MAT_USER_CORE`**。
!===============================================================================
MODULE MD_Mat_User_Umat
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_708
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_MAT_ID_LEAF_708
  PUBLIC :: Umat_MatDesc
  PUBLIC :: UF_Umat_L3_ValidateProps
  PUBLIC :: UF_Umat_L3_InitPlaceholder

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_708 = MD_MAT_ID_708

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Umat_MatDesc
    INTEGER(i4) :: reserved = 0_i4
  END TYPE Umat_MatDesc

CONTAINS

  SUBROUTINE UF_Umat_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < 1_i4) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Umat_L3_ValidateProps

  SUBROUTINE UF_Umat_L3_InitPlaceholder(st)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Umat_L3_InitPlaceholder

END MODULE MD_Mat_User_Umat

