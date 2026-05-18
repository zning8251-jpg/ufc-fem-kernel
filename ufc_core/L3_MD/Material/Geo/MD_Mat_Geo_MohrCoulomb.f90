!===============================================================================
! Module: MD_MatPLGMohrCoulomb
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plasticity (Mohr-Coulomb, mat_id=204)
! Purpose: Descriptor type and input validation for Mohr-Coulomb plasticity
!          model for soils and rocks with friction and cohesion.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**204**）；与 **MD_Geo_MohrCoulomb**/**MAT_GEO_MC** 协同。
!
! Props layout (9 required):
!   props(1) = E      : Young's modulus [Pa]
!   props(2) = nu     : Poisson's ratio [-]
!   props(3) = c      : Cohesion [Pa]
!   props(4) = phi    : Friction angle [deg]
!   props(5) = psi    : Dilation angle [deg]
!   props(6) = alpha  : Thermal expansion coefficient [1/K] (optional)
!   props(7) = H_c    : Cohesion hardening modulus [Pa] (optional)
!   props(8) = H_phi  : Friction hardening [deg] (optional)
!   props(9) = H_psi  : Dilation hardening [deg] (optional)
!
! nProps_min = 5 (E, nu, c, phi, psi)
! Statev: (1)=eps_p_eqv, (2)=plastic_work, (3)=c_curr, (4)=phi_curr,
!         (5)=psi_curr, (6:11)=eps_p(6)
!===============================================================================
MODULE MD_Mat_Geo_MohrCoulomb
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_204
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MohrCoulomb_MatDesc
  PUBLIC :: UF_MohrCoulomb_L3_ValidateProps
  PUBLIC :: UF_MohrCoulomb_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_MC = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_204 = MD_MAT_ID_204

  !> L3 descriptor for Mohr-Coulomb plasticity model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MohrCoulomb_MatDesc
    ! Elastic parameters
    REAL(wp) :: E = 0.0_wp              ! Young's modulus E [Pa]
    REAL(wp) :: nu = 0.0_wp             ! Poisson's ratio ν [-]
    REAL(wp) :: lambda = 0.0_wp         ! Lamé parameter λ [Pa]
    REAL(wp) :: mu = 0.0_wp             ! Shear modulus G [Pa]
    REAL(wp) :: K = 0.0_wp              ! Bulk modulus K [Pa]
    
    ! Mohr-Coulomb parameters
    REAL(wp) :: c = 0.0_wp              ! Cohesion c [Pa]
    REAL(wp) :: phi = 0.0_wp            ! Friction angle φ [rad]
    REAL(wp) :: psi = 0.0_wp            ! Dilation angle ψ [rad]
    REAL(wp) :: sin_phi = 0.0_wp        ! sin(φ)
    REAL(wp) :: cos_phi = 0.0_wp        ! cos(φ)
    REAL(wp) :: sin_psi = 0.0_wp        ! sin(ψ)
    REAL(wp) :: cos_psi = 0.0_wp        ! cos(ψ)
    
    ! Optional parameters
    REAL(wp) :: alpha = 0.0_wp          ! Thermal expansion α [1/K]
    REAL(wp) :: H_c = 0.0_wp            ! Cohesion hardening H꜀ [Pa]
    REAL(wp) :: H_phi = 0.0_wp          ! Friction hardening Hφ [deg]
    REAL(wp) :: H_psi = 0.0_wp          ! Dilation hardening Hψ [deg]
    
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MohrCoulomb_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_MohrCoulomb_L3_ValidateProps
  !   Validates flat props array for Mohr-Coulomb plasticity model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_MohrCoulomb_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    REAL(wp) :: phi_deg, psi_deg
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_MC) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: need >=5 props (E,nu,c,phi,psi)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: E must be > 0"
      RETURN
    END IF
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: nu must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(3) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: c must be >= 0"
      RETURN
    END IF
    phi_deg = props(4)
    IF (phi_deg < 0.0_wp .OR. phi_deg >= 90.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: phi must be in [0,90) deg"
      RETURN
    END IF
    psi_deg = props(5)
    IF (psi_deg < 0.0_wp .OR. psi_deg >= 90.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: psi must be in [0,90) deg"
      RETURN
    END IF
    IF (psi_deg > phi_deg) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "MohrCoulomb: psi must be <= phi"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_MohrCoulomb_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_MohrCoulomb_L3_InitFromProps
  !   Unpacks flat props array into a MohrCoulomb_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_MohrCoulomb_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MohrCoulomb_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    REAL(wp), PARAMETER :: PI = 3.1415926535897932384626433832795_wp
    REAL(wp), PARAMETER :: DEG_TO_RAD = PI / 180.0_wp
    CALL UF_MohrCoulomb_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E = props(1)
    desc%nu = props(2)
    desc%c = props(3)
    desc%phi = props(4) * DEG_TO_RAD
    desc%psi = props(5) * DEG_TO_RAD
    desc%alpha = 0.0_wp
    IF (nprops >= 6) THEN
      desc%alpha = props(6)
    END IF
    desc%H_c = 0.0_wp
    IF (nprops >= 7) THEN
      desc%H_c = props(7)
    END IF
    desc%H_phi = 0.0_wp
    IF (nprops >= 8) THEN
      desc%H_phi = props(8)
    END IF
    desc%H_psi = 0.0_wp
    IF (nprops >= 9) THEN
      desc%H_psi = props(9)
    END IF
    desc%mu = desc%E / (2.0_wp * (1.0_wp + desc%nu))
    desc%lambda = desc%E * desc%nu / ((1.0_wp + desc%nu) * (1.0_wp - 2.0_wp * desc%nu))
    desc%K = desc%E / (3.0_wp * (1.0_wp - 2.0_wp * desc%nu))
    desc%sin_phi = SIN(desc%phi)
    desc%cos_phi = COS(desc%phi)
    desc%sin_psi = SIN(desc%psi)
    desc%cos_psi = COS(desc%psi)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_MohrCoulomb_L3_InitFromProps


END MODULE MD_Mat_Geo_MohrCoulomb