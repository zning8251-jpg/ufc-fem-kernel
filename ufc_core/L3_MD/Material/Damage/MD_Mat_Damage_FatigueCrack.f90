!======================================================================
! Module: MD_MatDMGFatigueCrack
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Damage / Fatigue Crack Growth (mat_id=506)
! Purpose: Descriptor type and input validation for fatigue crack growth model.
! **W1**：**FatigueCrack_MatDesc**；**props** ↔ **Populate** / **`desc%props`**（**506 / MD_MAT_ID_506**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
! Statev: (1)=crack_length a, (2)=cycles N, (3)=Delta_K, (4)=crack_growth_rate
!===============================================================================
MODULE MD_Mat_Damage_FatigueCrack
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_506
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: FatigueCrack_MatDesc
  PUBLIC :: UF_FatigueCrack_L3_ValidateProps
  PUBLIC :: UF_FatigueCrack_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_FATIGUE = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_506 = MD_MAT_ID_506

  !> L3 descriptor for fatigue crack growth model (Paris law type)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: FatigueCrack_MatDesc
    REAL(wp) :: E           = 0.0_wp   ! Young's modulus
    REAL(wp) :: nu          = 0.0_wp   ! Poisson's ratio
    REAL(wp) :: K_IC        = 0.0_wp   ! Fracture toughness
    REAL(wp) :: C           = 0.0_wp   ! Paris law coefficient
    REAL(wp) :: m           = 0.0_wp   ! Paris law exponent
    REAL(wp) :: da_th       = 0.0_wp   ! Threshold crack growth rate
    REAL(wp) :: Delta_K_th  = 0.0_wp   ! Threshold SIF range
    REAL(wp) :: R_ratio     = 0.0_wp   ! Stress ratio
    REAL(wp) :: a_0         = 0.0_wp   ! Initial crack length
    REAL(wp) :: alpha       = 1.0_wp   ! Geometry correction factor
    LOGICAL :: is_initialized = .FALSE.
  END TYPE FatigueCrack_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_FatigueCrack_L3_ValidateProps
  !   Validates flat props array for fatigue crack growth model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_FatigueCrack_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_FATIGUE) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: need >=10 props (E,nu,K_IC,C,m,da_th,Delta_K_th,R_ratio,a_0,alpha)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: E must be > 0"
      RETURN
    END IF
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: nu must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: K_IC must be > 0"
      RETURN
    END IF
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: C must be > 0"
      RETURN
    END IF
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: m must be > 0"
      RETURN
    END IF
    IF (props(9) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FatigueCrack: a_0 must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_FatigueCrack_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_FatigueCrack_L3_InitFromProps
  !   Unpacks flat props array into a FatigueCrack_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_FatigueCrack_L3_InitFromProps(desc, nprops, props, st)
    TYPE(FatigueCrack_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_FatigueCrack_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E          = props(1)
    desc%nu         = props(2)
    desc%K_IC       = props(3)
    desc%C          = props(4)
    desc%m          = props(5)
    desc%da_th      = props(6)
    desc%Delta_K_th = props(7)
    desc%R_ratio    = props(8)
    desc%a_0        = MAX(props(9), 1.0e-10_wp)
    desc%alpha      = 1.0_wp
    IF (nprops >= 10) THEN
      desc%alpha = props(10)
    END IF
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_FatigueCrack_L3_InitFromProps

END MODULE MD_Mat_Damage_FatigueCrack

