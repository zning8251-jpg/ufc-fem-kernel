!======================================================================
! Module: MD_MatDMGDuctileDamage
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Damage / Ductile Damage (mat_id=501)
! Purpose: Descriptor type and input validation for ductile damage model.
! **W1**：**DuctileDamage_MatDesc**；**props** ↔ **Populate** / **`desc%props`**（**501 / MD_MAT_ID_501**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
! Statev: (1)=eq_plastic_strain, (2)=damage d, (3)=backstress alpha,
!         (4)=yield_stress_current
!===============================================================================
MODULE MD_Mat_Damage_DuctileDamage
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_501
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: DuctileDamage_MatDesc
  PUBLIC :: UF_DuctileDamage_L3_ValidateProps
  PUBLIC :: UF_DuctileDamage_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_DUCTILE = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_501 = MD_MAT_ID_501

  !> L3 descriptor for ductile damage model (Lemaitre CDM)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: DuctileDamage_MatDesc
    REAL(wp) :: E          = 0.0_wp   ! Young's modulus
    REAL(wp) :: nu         = 0.0_wp   ! Poisson's ratio
    REAL(wp) :: sigma_y0   = 0.0_wp   ! Initial yield stress
    REAL(wp) :: Q          = 0.0_wp   ! Hardening modulus
    REAL(wp) :: b          = 0.0_wp   ! Hardening saturation parameter
    REAL(wp) :: S          = 0.0_wp   ! Damage threshold parameter
    REAL(wp) :: s          = 1.0_wp   ! Damage exponent
    REAL(wp) :: D_c        = 0.99_wp  ! Critical damage value
    REAL(wp) :: eps_D      = 0.0_wp   ! Strain threshold for damage
    REAL(wp) :: a          = 0.0_wp   ! Viscoplastic parameter
    LOGICAL :: is_initialized = .FALSE.
  END TYPE DuctileDamage_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_DuctileDamage_L3_ValidateProps
  !   Validates flat props array for ductile damage model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_DuctileDamage_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_DUCTILE) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: need >=10 props (E,nu,sigma_y0,Q,b,S,s,D_c,eps_D,a)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: E must be > 0"
      RETURN
    END IF
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: nu must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: sigma_y0 must be > 0"
      RETURN
    END IF
    IF (props(6) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: S must be > 0"
      RETURN
    END IF
    IF (props(7) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: s must be > 0"
      RETURN
    END IF
    IF (props(8) <= 0.0_wp .OR. props(8) > 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: D_c must be in (0,1]"
      RETURN
    END IF
    IF (nprops >= 10 .AND. props(10) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DuctileDamage: a must be >= 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_DuctileDamage_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_DuctileDamage_L3_InitFromProps
  !   Unpacks flat props array into a DuctileDamage_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_DuctileDamage_L3_InitFromProps(desc, nprops, props, st)
    TYPE(DuctileDamage_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_DuctileDamage_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E        = props(1)
    desc%nu       = props(2)
    desc%sigma_y0 = props(3)
    desc%Q        = props(4)
    desc%b        = props(5)
    desc%S        = props(6)
    desc%s        = props(7)
    desc%D_c      = props(8)
    desc%eps_D    = props(9)
    desc%a        = 0.0_wp
    IF (nprops >= 10) THEN
      desc%a = props(10)
    END IF
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_DuctileDamage_L3_InitFromProps

END MODULE MD_Mat_Damage_DuctileDamage

