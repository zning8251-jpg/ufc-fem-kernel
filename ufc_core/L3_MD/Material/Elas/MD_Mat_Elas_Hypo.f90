!===============================================================================
! Module: MD_MatELAHypoelastic
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Elastic (Hypoelastic, mat_id=106)
! Purpose: Descriptor type and input validation for hypoelastic material
!          with constant or strain-dependent moduli.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**106**）；率型与 **UF_Elastic_*** 路由一致。
!
! Props layout (2+ required):
!   props(1) = E         : Young's modulus (constant)
!   props(2) = nu        : Poisson's ratio (constant)
!   props(3+) = optional : Strain-dependent parameters (future extension)
!
! nProps_min = 2
! Statev: None (rate-form formulation)
!===============================================================================
MODULE MD_Mat_Elas_Hypo
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_106
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Elas_Hypo_Desc
  PUBLIC :: MD_Mat_Elas_Hypo_L3_ValidateProps
  PUBLIC :: MD_Mat_Elas_Hypo_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_HYPO = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_106 = MD_MAT_ID_106

  !> L3 descriptor for hypoelastic model (rate-form elasticity)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Hypo_Desc
    REAL(wp) :: E = 0.0_wp              ! Young's modulus
    REAL(wp) :: nu = 0.0_wp             ! Poisson's ratio
    LOGICAL :: is_constant = .TRUE.     ! TRUE=constant, FALSE=strain-dependent
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_Hypo_Desc

CONTAINS

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Hypo_L3_ValidateProps
  !   Validates flat props array for hypoelastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Hypo_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_HYPO) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "HypoElastic: need >=2 props (E, nu)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "HypoElastic: E must be > 0"
      RETURN
    END IF
    IF (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "HypoElastic: nu must be in [-1, 0.5)"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Hypo_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Hypo_L3_InitFromProps
  !   Unpacks flat props array into a MD_Mat_Elas_Hypo_Desc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Hypo_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MD_Mat_Elas_Hypo_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL MD_Mat_Elas_Hypo_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E = props(1)
    desc%nu = props(2)
    desc%is_constant = .TRUE.
    IF (nprops > 2) THEN
      desc%is_constant = .FALSE.
    END IF
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Hypo_L3_InitFromProps

END MODULE MD_Mat_Elas_Hypo

