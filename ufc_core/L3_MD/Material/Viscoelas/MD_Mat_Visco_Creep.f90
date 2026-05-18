!======================================================================
! Module: MD_Mat_Viscoelas_Creep
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Viscoelastic / Creep (mat_id=403)
! Purpose: L3_MD descriptor for creep viscoelastic model.
!          Align hooks with L4 PH_Mat_VSC_Creep.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**403**）；**`MD_MAT_ID_403`** / **L4**。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Viscoelas_Creep
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_403
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_MAT_ID_LEAF_403
  PUBLIC :: Creep_MatDesc
  PUBLIC :: UF_Creep_L3_ValidateProps
  PUBLIC :: UF_Creep_L3_InitPlaceholder

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_403 = MD_MAT_ID_403

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Creep_MatDesc
    INTEGER(i4) :: reserved = 0_i4
  END TYPE Creep_MatDesc

CONTAINS

  SUBROUTINE UF_Creep_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < 1_i4) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Creep_L3_ValidateProps

  SUBROUTINE UF_Creep_L3_InitPlaceholder(st)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Creep_L3_InitPlaceholder

END MODULE MD_Mat_Viscoelas_Creep

