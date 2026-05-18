!===============================================================================
! Module: MD_MatPLGCamClay
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plasticity (Cam-Clay, mat_id=203)
! Purpose: Descriptor type and input validation for Modified Cam-Clay
!          plasticity model for geotechnical materials.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**203**）。
!
! Props layout (6+ required):
!   props(1) = E        : Young's modulus [Pa]
!   props(2) = nu       : Poisson's ratio [-]
!   props(3) = M        : Critical state stress ratio [-]
!   props(4) = lambda   : Compression index [-]
!   props(5) = kappa    : Swelling index [-]
!   props(6) = p0       : Initial preconsolidation pressure [Pa]
!   props(7+) = beta    : Hardening parameter (optional) [-]
!
! nProps_min = 6 (elastic + plastic parameters)
! Statev: (1)=eps_vol, (2)=eps_p_eqv, (3)=p0_current,
!         (4:9)=eps_p(1:6) plastic strain tensor
!===============================================================================
MODULE MD_Mat_Geo_CamClay
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_203
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CamClay_MatDesc
  PUBLIC :: UF_CamClay_L3_ValidateProps
  PUBLIC :: UF_CamClay_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_CAMCLAY = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_203 = MD_MAT_ID_203

  !> L3 descriptor for Modified Cam-Clay model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CamClay_MatDesc
    ! Elastic parameters
    REAL(wp) :: MD_MAT_E_young = 0.0_wp            ! Young's modulus E [Pa]
    REAL(wp) :: nu_poisson = 0.0_wp         ! Poisson's ratio ν [-]
    REAL(wp) :: lambda_lame = 0.0_wp        ! Lamé parameter λ [Pa]
    REAL(wp) :: mu_shear = 0.0_wp           ! Shear modulus μ [Pa]
    REAL(wp) :: K_bulk = 0.0_wp             ! Bulk modulus K [Pa]
    
    ! Cam-Clay plastic parameters
    REAL(wp) :: M_critical = 0.0_wp         ! Critical state stress ratio M [-]
    REAL(wp) :: lambda_comp = 0.0_wp        ! Compression index λ [-]
    REAL(wp) :: kappa_swell = 0.0_wp        ! Swelling index κ [-]
    REAL(wp) :: p0_initial = 0.0_wp         ! Initial preconsolidation pressure p₀ [Pa]
    REAL(wp) :: beta_hard = 1.0_wp          ! Hardening parameter β [-]
    
    LOGICAL :: is_initialized = .FALSE.
  END TYPE CamClay_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_CamClay_L3_ValidateProps
  !   Validates flat props array for Modified Cam-Clay model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_CamClay_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL init_error_status(st)
    
    IF (nprops < MD_MAT_NPROPS_MIN_CAMCLAY) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: need at least 6 props (E,nu,M,lambda,kappa,p0)"
      RETURN
    END IF
    
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: Young's modulus must be > 0"
      RETURN
    END IF
    
    IF (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF
    
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: critical state stress ratio M must be > 0"
      RETURN
    END IF
    
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: compression index lambda must be > 0"
      RETURN
    END IF
    
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: swelling index kappa must be > 0"
      RETURN
    END IF
    
    IF (props(5) >= props(4)) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: kappa must be < lambda (κ < λ)"
      RETURN
    END IF
    
    IF (props(6) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CamClay: initial preconsolidation pressure p0 must be > 0"
      RETURN
    END IF
    
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_CamClay_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_CamClay_L3_InitFromProps
  !   Unpacks flat props array into a CamClay_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_CamClay_L3_InitFromProps(desc, nprops, props, st)
    TYPE(CamClay_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    REAL(wp) :: ONE, TWO, THREE
    
    ONE = 1.0_wp
    TWO = 2.0_wp
    THREE = 3.0_wp
    
    CALL UF_CamClay_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    
    ! Extract properties
    desc%MD_MAT_E_young = props(1)
    desc%nu_poisson = props(2)
    desc%M_critical = props(3)
    desc%lambda_comp = props(4)
    desc%kappa_swell = props(5)
    desc%p0_initial = props(6)
    
    ! Optional hardening parameter
    IF (nprops >= 7) THEN
      desc%beta_hard = props(7)
    ELSE
      desc%beta_hard = 1.0_wp
    END IF
    
    ! Compute derived elastic parameters
    desc%mu_shear = desc%MD_MAT_E_young / (TWO * (ONE + desc%nu_poisson))
    desc%lambda_lame = desc%MD_MAT_E_young * desc%nu_poisson / ((ONE + desc%nu_poisson) * (ONE - TWO * desc%nu_poisson))
    desc%K_bulk = desc%MD_MAT_E_young / (THREE * (ONE - TWO * desc%nu_poisson))
    
    ! Set base class fields
    desc%cfg%id = MD_MAT_ID_LEAF_203
    desc%cfg%id = MD_MAT_ID_LEAF_203
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%pop%nStateV = 9_i4
    desc%pop%nStateV = 9_i4
    
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_CamClay_L3_InitFromProps

END MODULE MD_Mat_Geo_CamClay