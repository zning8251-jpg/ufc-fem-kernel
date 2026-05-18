!======================================================================
! Module: MD_MatHYPNeoHookean
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Hyperelastic (Neo-Hookean, mat_id=303)
! Purpose: Descriptor type for Neo-Hookean hyperelastic model.
! **W1**：**props** ↔ **Populate** / **`desc%props`**；**`MD_MAT_ID_303`**；L4 **超弹** / **`PH_MatHYP_*`**（**303**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_HyperElas_NeoHookean
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_303
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: NeoHookean_MatDesc
  PUBLIC :: UF_NeoHookean_L3_ValidateProps
  PUBLIC :: UF_NeoHookean_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_NH = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_303 = MD_MAT_ID_303

  !> L3 descriptor for Neo-Hookean hyperelastic model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NeoHookean_MatDesc
    REAL(wp) :: C10 = 0.0_wp          ! Neo-Hookean constant
    REAL(wp) :: D1 = 0.0_wp           ! Compressibility parameter
    LOGICAL :: is_incompressible = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE NeoHookean_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_NeoHookean_L3_ValidateProps
  !   Validates flat props array for Neo-Hookean hyperelastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_NeoHookean_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_NH) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "NeoHookean: need 2 props (C10,D1)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "NeoHookean: C10 must be > 0"
      RETURN
    END IF
    IF (props(2) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "NeoHookean: D1 must be >= 0 (0 for incompressible)"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_NeoHookean_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_NeoHookean_L3_InitFromProps
  !   Unpacks flat props array into a NeoHookean_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_NeoHookean_L3_InitFromProps(desc, nprops, props, st)
    TYPE(NeoHookean_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_NeoHookean_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%C10 = props(1)
    desc%D1 = props(2)
    desc%is_incompressible = (desc%D1 == 0.0_wp)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_NeoHookean_L3_InitFromProps

END MODULE MD_Mat_HyperElas_NeoHookean

