!===============================================================================
! Module: MD_MatPLGDruckerPrager
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plasticity (Drucker-Prager, mat_id=202)
! Purpose: Descriptor type and input validation for Drucker-Prager plasticity
!          model for pressure-dependent materials (geomaterials, concrete).
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**202**）；与 **MD_Geo_DruckerPrager**/**MAT_GEO_*** 协同。
!
! Props layout (6 required):
!   props(1) = E        : Young's modulus [Pa]
!   props(2) = nu       : Poisson's ratio [-]
!   props(3) = alpha    : Friction parameter α [-]
!   props(4) = k0       : Initial cohesion k₀ [Pa]
!   props(5) = H        : Hardening modulus [Pa] (optional, default=0)
!   props(6) = beta     : Dilation parameter β [-] (optional, default=α)
!
! nProps_min = 4 (E, nu, alpha, k0)
! Statev: (1)=eps_p_eqv, (2)=plastic_work, (3:8)=eps_p(1:6)
!===============================================================================
MODULE MD_Mat_Geo_DruckerPrager
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_202
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_MAT_DP_MatDesc
  PUBLIC :: UF_DP_L3_ValidateProps
  PUBLIC :: UF_DP_L3_InitFromProps
  PUBLIC :: MD_MAT_DRUCKERPRAGER_M, MD_MAT_DRUCKERPRAGER_M_NAME

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_DP = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_202 = MD_MAT_ID_202
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DRUCKERPRAGER_M = MD_MAT_ID_202
  CHARACTER(len=*), PARAMETER, PUBLIC :: MD_MAT_DRUCKERPRAGER_M_NAME = "Drucker-Prager Plasticity"

  !> L3 descriptor for Drucker-Prager plasticity model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_MAT_DP_MatDesc
    ! Elastic parameters
    REAL(wp) :: MD_MAT_E_young = 0.0_wp            ! Young's modulus E [Pa]
    REAL(wp) :: nu_poisson = 0.0_wp         ! Poisson's ratio ν [-]
    
    ! Drucker-Prager parameters
    REAL(wp) :: alpha_friction = 0.0_wp     ! Friction parameter α [-]
    REAL(wp) :: k0_cohesion = 0.0_wp        ! Initial cohesion k₀ [Pa]
    REAL(wp) :: H_hardening = 0.0_wp        ! Hardening modulus H [Pa]
    REAL(wp) :: beta_dilation = 0.0_wp      ! Dilation parameter β [-]
    
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_MAT_DP_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_DP_L3_ValidateProps
  !   Validates flat props array for Drucker-Prager model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_DP_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL init_error_status(st)
    
    IF (nprops < MD_MAT_NPROPS_MIN_DP) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: need at least 4 props (E,nu,alpha,k0)"
      RETURN
    END IF
    
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: Young's modulus must be > 0"
      RETURN
    END IF
    
    IF (props(2) < 0.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: Poisson's ratio must be in [0, 0.5)"
      RETURN
    END IF
    
    IF (props(3) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: friction parameter alpha must be >= 0"
      RETURN
    END IF
    
    IF (props(4) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: initial cohesion k0 must be >= 0"
      RETURN
    END IF
    
    IF (nprops >= 5 .AND. props(5) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: hardening modulus H must be >= 0"
      RETURN
    END IF
    
    IF (nprops >= 6 .AND. props(6) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "DP: dilation parameter beta must be >= 0"
      RETURN
    END IF
    
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_DP_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_DP_L3_InitFromProps
  !   Unpacks flat props array into a MD_MAT_DP_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_DP_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MD_MAT_DP_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL UF_DP_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    
    ! Extract properties
    desc%MD_MAT_E_young = props(1)
    desc%nu_poisson = props(2)
    desc%alpha_friction = props(3)
    desc%k0_cohesion = props(4)
    
    ! Optional parameters
    IF (nprops >= 5) THEN
      desc%H_hardening = props(5)
    ELSE
      desc%H_hardening = 0.0_wp
    END IF
    
    IF (nprops >= 6) THEN
      desc%beta_dilation = props(6)
    ELSE
      desc%beta_dilation = desc%alpha_friction  ! Associated flow by default
    END IF
    
    ! Set base class fields
    desc%cfg%id = MD_MAT_ID_LEAF_202
    desc%pop%nProps = nprops
    desc%pop%nStateV = 8_i4  ! eps_p_eqv + plastic_work + eps_p(6)
    
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_DP_L3_InitFromProps

END MODULE MD_Mat_Geo_DruckerPrager