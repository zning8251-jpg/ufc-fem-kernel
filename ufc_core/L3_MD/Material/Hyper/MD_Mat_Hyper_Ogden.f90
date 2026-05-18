!======================================================================
! Module: MD_MatHYPOgden
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Hyperelastic (Ogden, mat_id=302)
! Purpose: Descriptor type for Ogden hyperelastic model.
! **W1**：**props** ↔ **Populate** / **`desc%props`**；**`MD_MAT_ID_302`**；L4 **超弹** / **`PH_MatHYP_*`**（**302**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_HyperElas_Ogden
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_302
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: Ogden_MatDesc
  PUBLIC :: UF_Ogden_L3_ValidateProps
  PUBLIC :: UF_Ogden_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_MAX_OGDEN_TERMS = 5_i4
  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_OGDEN = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_302 = MD_MAT_ID_302

  !> L3 descriptor for Ogden hyperelastic model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Ogden_MatDesc
    INTEGER(i4) :: N_terms = 0_i4       ! Number of Ogden terms
    REAL(wp) :: mu(MD_MAT_MAX_OGDEN_TERMS)     ! Shear moduli
    REAL(wp) :: alpha(MD_MAT_MAX_OGDEN_TERMS)  ! Exponents
    REAL(wp) :: D1 = 0.0_wp             ! Compressibility parameter
    LOGICAL :: is_incompressible = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE Ogden_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_Ogden_L3_ValidateProps
  !   Validates flat props array for Ogden hyperelastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Ogden_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    INTEGER(i4) :: N_terms, i
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_OGDEN) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Ogden: need at least 3 props (N_terms,mu1,alpha1,D1)"
      RETURN
    END IF
    N_terms = INT(props(1))
    IF (N_terms < 1_i4 .OR. N_terms > MD_MAT_MAX_OGDEN_TERMS) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Ogden: N_terms must be 1-5"
      RETURN
    END IF
    IF (nprops < 1_i4 + 2_i4 * N_terms) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Ogden: insufficient props for N_terms"
      RETURN
    END IF
    DO i = 1, N_terms
      IF (props(1 + i) <= 0.0_wp) THEN
        st%status_code = MD_MAT_STATUS_INVALID
        st%message = "Ogden: mu_i must be > 0"
        RETURN
      END IF
    END DO
    IF (nprops >= 1_i4 + 2_i4 * N_terms + 1_i4) THEN
      IF (props(1_i4 + 2_i4 * N_terms + 1_i4) < 0.0_wp) THEN
        st%status_code = MD_MAT_STATUS_INVALID
        st%message = "Ogden: D1 must be >= 0"
        RETURN
      END IF
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Ogden_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_Ogden_L3_InitFromProps
  !   Unpacks flat props array into a Ogden_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Ogden_L3_InitFromProps(desc, nprops, props, st)
    TYPE(Ogden_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    INTEGER(i4) :: i
    CALL UF_Ogden_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%N_terms = INT(props(1))
    DO i = 1, desc%N_terms
      desc%mu(i) = props(1 + i)
      desc%alpha(i) = props(1 + desc%N_terms + i)
    END DO
    desc%D1 = 0.0_wp
    IF (nprops >= 1_i4 + 2_i4 * desc%N_terms + 1_i4) THEN
      desc%D1 = props(1_i4 + 2_i4 * desc%N_terms + 1_i4)
    END IF
    desc%is_incompressible = (desc%D1 == 0.0_wp)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Ogden_L3_InitFromProps

END MODULE MD_Mat_HyperElas_Ogden

