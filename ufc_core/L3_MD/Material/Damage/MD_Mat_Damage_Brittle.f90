!======================================================================
! Module: MD_MatDMGBrittle
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Damage / Brittle Damage (mat_id=505)
! Purpose: Descriptor type and input validation for brittle damage model.
! **W1**：**Brittle_MatDesc**；**props** ↔ **Populate** / **`desc%props`**（**505 / MD_MAT_ID_505**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Damage_Brittle
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_505
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: Brittle_MatDesc
  PUBLIC :: UF_Brittle_L3_ValidateProps
  PUBLIC :: UF_Brittle_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_BRITTLE = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_505 = MD_MAT_ID_505

  !> L3 descriptor for brittle damage model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Brittle_MatDesc
    REAL(wp) :: E       = 0.0_wp   ! Young's modulus
    REAL(wp) :: nu      = 0.0_wp   ! Poisson's ratio
    REAL(wp) :: ft      = 0.0_wp   ! Tensile strength
    REAL(wp) :: fc      = 0.0_wp   ! Compressive strength
    REAL(wp) :: Gf      = 0.0_wp   ! Fracture energy
    REAL(wp) :: eps_f0  = 0.0_wp   ! Strain at peak stress
    REAL(wp) :: alpha   = 0.01_wp  ! Residual strength ratio
    REAL(wp) :: beta    = 1.0_wp   ! Softening exponent
    LOGICAL :: is_initialized = .FALSE.
  END TYPE Brittle_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_Brittle_L3_ValidateProps
  !   Validates flat props array for brittle damage model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Brittle_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_BRITTLE) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: need >=8 props (E,nu,ft,fc,Gf,eps_f0,alpha,beta)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: E must be > 0"
      RETURN
    END IF
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: nu must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: ft must be > 0"
      RETURN
    END IF
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: fc must be > 0"
      RETURN
    END IF
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: Gf must be > 0"
      RETURN
    END IF
    IF (nprops >= 7 .AND. props(7) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: alpha must be >= 0"
      RETURN
    END IF
    IF (nprops >= 8 .AND. props(8) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Brittle: beta must be >= 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Brittle_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_Brittle_L3_InitFromProps
  !   Unpacks flat props array into a Brittle_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Brittle_L3_InitFromProps(desc, nprops, props, st)
    TYPE(Brittle_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_Brittle_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E      = props(1)
    desc%nu     = props(2)
    desc%ft     = props(3)
    desc%fc     = props(4)
    desc%Gf     = props(5)
    desc%eps_f0 = props(1) / props(3)  ! default: ft/E
    IF (nprops >= 6) THEN
      desc%eps_f0 = MAX(props(6), props(1) / props(3))
    END IF
    desc%alpha  = 0.01_wp
    IF (nprops >= 7) THEN
      desc%alpha = props(7)
    END IF
    desc%beta   = 1.0_wp
    IF (nprops >= 8) THEN
      desc%beta = props(8)
    END IF
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Brittle_L3_InitFromProps

END MODULE MD_Mat_Damage_Brittle

