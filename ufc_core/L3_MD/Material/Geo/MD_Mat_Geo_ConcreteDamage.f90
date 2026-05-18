!===============================================================================
! Module: MD_MatPLGConcreteDamage
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plasticity (Concrete Damaged Plasticity, mat_id=222)
! Purpose: Descriptor type and input validation for Concrete Damaged Plasticity
!          model based on Lubliner yield surface with tension-compression
!          asymmetric damage evolution.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**222**）。
!
! Props layout (10+ required):
!   props(1) = E        : Young's modulus [Pa]
!   props(2) = nu       : Poisson's ratio [-]
!   props(3) = f_t0     : Uniaxial tensile strength [Pa]
!   props(4) = f_c0     : Uniaxial compressive strength [Pa]
!   props(5) = psi      : Dilation angle [deg]
!   props(6) = epsilon  : Eccentricity parameter [-]
!   props(7) = sigma_b0_sigma_c0 : Biaxial/uniaxial strength ratio [-]
!   props(8) = K_c      : Shape factor [-]
!   props(9) = w_t      : Tensile stiffness recovery [-]
!   props(10) = w_c     : Compressive stiffness recovery [-]
!
! nProps_min = 10 (elastic + strength + dilation + damage parameters)
! Statev: (1)=d_t, (2)=d_c, (3)=eps_t_pl, (4)=eps_c_pl, (5:10)=sigma(1:6)
!===============================================================================
MODULE MD_Mat_Geo_ConcreteDamage
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_222
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CDP_MatDesc
  PUBLIC :: UF_CDP_L3_ValidateProps
  PUBLIC :: UF_CDP_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_CDP = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_222 = MD_MAT_ID_222
  !> L3 descriptor for Concrete Damaged Plasticity model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CDP_MatDesc
    ! Elastic parameters
    REAL(wp) :: MD_MAT_E_young = 0.0_wp            ! Young's modulus E [Pa]
    REAL(wp) :: nu_poisson = 0.0_wp         ! Poisson's ratio ν [-]
    
    ! Strength parameters
    REAL(wp) :: f_t0_tensile = 0.0_wp       ! Uniaxial tensile strength f_t0 [Pa]
    REAL(wp) :: f_c0_compressive = 0.0_wp   ! Uniaxial compressive strength f_c0 [Pa]
    
    ! Plastic flow parameters
    REAL(wp) :: psi_dilation = 0.0_wp       ! Dilation angle ψ [deg]
    REAL(wp) :: epsilon_ecc = 0.1_wp        ! Eccentricity parameter ε [-]
    REAL(wp) :: sigma_b0_ratio = 1.16_wp    ! Biaxial/uniaxial ratio σ_b0/σ_c0 [-]
    REAL(wp) :: K_c_shape = 0.667_wp        ! Shape factor K_c [-]
    
    ! Damage parameters
    REAL(wp) :: w_t_recovery = 1.0_wp       ! Tensile stiffness recovery w_t [-]
    REAL(wp) :: w_c_recovery = 0.0_wp       ! Compressive stiffness recovery w_c [-]
    
    LOGICAL :: is_initialized = .FALSE.
  END TYPE CDP_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_CDP_L3_ValidateProps
  !   Validates flat props array for Concrete Damaged Plasticity model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_CDP_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL init_error_status(st)
    
    IF (nprops < MD_MAT_NPROPS_MIN_CDP) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: need at least 10 props (E,nu,f_t0,f_c0,psi,eps,K_c,w_t,w_c)"
      RETURN
    END IF
    
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: Young's modulus must be > 0"
      RETURN
    END IF
    
    IF (props(2) < 0.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: Poisson's ratio must be in [0, 0.5)"
      RETURN
    END IF
    
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: tensile strength f_t0 must be > 0"
      RETURN
    END IF
    
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: compressive strength f_c0 must be > 0"
      RETURN
    END IF
    
    IF (props(5) < 0.0_wp .OR. props(5) > 90.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: dilation angle psi must be in [0, 90] deg"
      RETURN
    END IF
    
    IF (props(6) <= 0.0_wp .OR. props(6) > 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: eccentricity epsilon must be in (0, 1]"
      RETURN
    END IF
    
    IF (props(7) < 1.0_wp .OR. props(7) > 2.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: sigma_b0/sigma_c0 ratio must be in [1, 2]"
      RETURN
    END IF
    
    IF (props(8) < 0.5_wp .OR. props(8) > 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: K_c shape factor must be in [0.5, 1]"
      RETURN
    END IF
    
    IF (props(9) < 0.0_wp .OR. props(9) > 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: tensile recovery w_t must be in [0, 1]"
      RETURN
    END IF
    
    IF (props(10) < 0.0_wp .OR. props(10) > 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "CDP: compressive recovery w_c must be in [0, 1]"
      RETURN
    END IF
    
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_CDP_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_CDP_L3_InitFromProps
  !   Unpacks flat props array into a CDP_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_CDP_L3_InitFromProps(desc, nprops, props, st)
    TYPE(CDP_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL UF_CDP_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    
    ! Extract properties
    desc%MD_MAT_E_young = props(1)
    desc%nu_poisson = props(2)
    desc%f_t0_tensile = props(3)
    desc%f_c0_compressive = props(4)
    desc%psi_dilation = props(5)
    desc%epsilon_ecc = props(6)
    desc%sigma_b0_ratio = props(7)
    desc%K_c_shape = props(8)
    desc%w_t_recovery = props(9)
    desc%w_c_recovery = props(10)
    
    ! Set base class fields
    desc%cfg%id = MD_MAT_ID_LEAF_222
    desc%cfg%id = MD_MAT_ID_LEAF_222
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%pop%nStateV = 10_i4
    desc%pop%nStateV = 10_i4
    
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_CDP_L3_InitFromProps
END MODULE MD_Mat_Geo_ConcreteDamage