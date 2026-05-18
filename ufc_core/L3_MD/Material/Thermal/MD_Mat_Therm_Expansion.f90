!===============================================================================
! Module: MD_MatMPHThermalExpansion
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Multi-Physics (Thermal Expansion, mat_id=602)
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**602**）；**`MD_MAT_ID_602`**；**L4 热膨胀槽**。
! Purpose: Descriptor type and input validation for thermal expansion
!          material model based on Duhamel-Neumann law.
!
! Props layout (2+ required):
!   props(1) = alpha     : Thermal expansion coefficient [1/K]
!   props(2) = T_ref     : Reference temperature [K]
!   props(3+) = alpha(T) : Temperature-dependent CTE (optional)
!
! nProps_min = 2 (CTE + reference temperature)
! Statev: (1)=eps_thermal_vol (volumetric thermal strain), (2)=delta_T
!===============================================================================
MODULE MD_Mat_Therm_Expansion
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_602
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: ThermalExpansion_MatDesc
  PUBLIC :: UF_ThermalExpansion_L3_ValidateProps
  PUBLIC :: UF_ThermalExpansion_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_THERM_EXP = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_602 = MD_MAT_ID_602

  !> L3 descriptor for Thermal Expansion model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ThermalExpansion_MatDesc
    REAL(wp) :: alpha_CTE = 0.0_wp        ! Thermal expansion coefficient α [1/K]
    REAL(wp) :: T_reference = 293.15_wp  ! Reference temperature T_ref [K]
    REAL(wp) :: alpha_temp_dep = 0.0_wp  ! Temperature dependency coefficient [1/K²]
    LOGICAL :: is_isotropic = .TRUE.     ! Isotropic expansion?
    LOGICAL :: is_temp_dep = .FALSE.     ! α depends on temperature?
    LOGICAL :: is_initialized = .FALSE.
  END TYPE ThermalExpansion_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_ThermalExpansion_L3_ValidateProps
  !   Validates flat props array for thermal expansion model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_ThermalExpansion_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_THERM_EXP) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalExp: need at least 2 props (alpha,T_ref)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalExp: CTE must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "ThermalExp: reference temperature must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_ThermalExpansion_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_ThermalExpansion_L3_InitFromProps
  !   Unpacks flat props array into a ThermalExpansion_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_ThermalExpansion_L3_InitFromProps(desc, nprops, props, st)
    TYPE(ThermalExpansion_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_ThermalExpansion_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%alpha_CTE = props(1)
    desc%T_reference = props(2)
    IF (nprops >= 3) THEN
      desc%alpha_temp_dep = props(3)
      desc%is_temp_dep = .TRUE.
    END IF
    desc%is_isotropic = .TRUE.
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_ThermalExpansion_L3_InitFromProps

END MODULE MD_Mat_Therm_Expansion

