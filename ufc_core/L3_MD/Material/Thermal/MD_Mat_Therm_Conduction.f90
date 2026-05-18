!===============================================================================
! Module: MD_MatMPHThermalConduction
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Multi-Physics (Thermal Conduction, mat_id=601)
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**601**）；**`MD_MAT_ID_601`**；**L4 热传导核**。
! Purpose: Descriptor type and input validation for thermal conduction
!          material model based on Fourier's law.
!
! Props layout (3+ required):
!   props(1) = k_cond    : Thermal conductivity [W/(m·K)]
!   props(2) = rho       : Density [kg/m³]
!   props(3) = c_p       : Specific heat capacity [J/(kg·K)]
!   props(4+) = k(T)     : Temperature-dependent conductivity (optional)
!
! nProps_min = 3 (conductivity + density + specific heat)
! Statev: (1)=T_temperature, (2)=heat_flux_mag, (3)=temp_gradient_mag
!===============================================================================
MODULE MD_Mat_Therm_Conduction
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_601
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: ThermalConduction_MatDesc
  PUBLIC :: UF_ThermalConduction_L3_ValidateProps
  PUBLIC :: UF_ThermalConduction_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_THERM_COND = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_601 = MD_MAT_ID_601

  !> L3 descriptor for Thermal Conduction model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ThermalConduction_MatDesc
    REAL(wp) :: conductivity = 0.0_wp   ! Thermal conductivity k [W/(m·K)]
    REAL(wp) :: density = 0.0_wp        ! Density ρ [kg/m³]
    REAL(wp) :: specific_heat = 0.0_wp ! Specific heat c_p [J/(kg·K)]
    REAL(wp) :: diffusivity = 0.0_wp   ! Thermal diffusivity α = k/(ρ·c_p) [m²/s]
    LOGICAL :: is_isotropic = .TRUE.   ! Isotropic conductivity?
    LOGICAL :: is_temp_dep = .FALSE.   ! k depends on temperature?
    LOGICAL :: is_initialized = .FALSE.
  END TYPE ThermalConduction_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_ThermalConduction_L3_ValidateProps
  !   Validates flat props array for thermal conduction model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_ThermalConduction_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_THERM_COND) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalCond: need at least 3 props (k,rho,cp)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalCond: conductivity must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalCond: density must be > 0"
      RETURN
    END IF
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalCond: specific heat must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_ThermalConduction_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_ThermalConduction_L3_InitFromProps
  !   Unpacks flat props array into a ThermalConduction_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_ThermalConduction_L3_InitFromProps(desc, nprops, props, st)
    TYPE(ThermalConduction_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_ThermalConduction_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%conductivity = props(1)
    desc%density = props(2)
    desc%specific_heat = props(3)
    desc%diffusivity = props(1) / (props(2) * props(3))
    desc%is_isotropic = .TRUE.
    desc%is_temp_dep = (nprops > 3)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_ThermalConduction_L3_InitFromProps

END MODULE MD_Mat_Therm_Conduction

