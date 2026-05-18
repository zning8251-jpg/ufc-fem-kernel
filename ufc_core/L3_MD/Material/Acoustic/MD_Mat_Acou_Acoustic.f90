!===============================================================================
! Module: MD_MatMPHAcoustic
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Multi-Physics (Acoustic, mat_id=607)
! Purpose: Descriptor type and input validation for acoustic medium model.
!
! Props layout (2 required):
!   props(1) = K        : Bulk modulus [Pa]
!   props(2) = rho      : Density [kg/m³]
!
! nProps_min = 2 (bulk modulus + density)
! Statev: (1)=p_dynamic (dynamic pressure), (2)=vol_strain (volumetric strain)
! **W1**：**Acoustic_MatDesc** 扩展 **MD_Mat_Desc**；**props(1:2)** 与 **Populate** /
!   **`desc%props`** 金线一致（与 **MD_Mat_Acous_*** 分支并存时注意 **mat_id** / 族路由）。
!===============================================================================
MODULE MD_Mat_Acou_Acoustic
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_607
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: Acoustic_MatDesc
  PUBLIC :: UF_Acoustic_L3_ValidateProps
  PUBLIC :: UF_Acoustic_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_ACOU = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_607 = MD_MAT_ID_607

  !> L3 descriptor for Acoustic medium model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Acoustic_MatDesc
    REAL(wp) :: bulk_modulus = 0.0_wp     ! Bulk modulus K [Pa]
    REAL(wp) :: density = 0.0_wp          ! Density ρ [kg/m³]
    LOGICAL :: is_incompressible = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE Acoustic_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_Acoustic_L3_ValidateProps
  !   Validates flat props array for acoustic medium model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Acoustic_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_ACOU) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Acoustic: need 2 props (K,rho)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Acoustic: bulk modulus must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Acoustic: density must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Acoustic_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_Acoustic_L3_InitFromProps
  !   Unpacks flat props array into a Acoustic_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Acoustic_L3_InitFromProps(desc, nprops, props, st)
    TYPE(Acoustic_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_Acoustic_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%bulk_modulus = props(1)
    desc%density = props(2)
    desc%is_incompressible = .FALSE.
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Acoustic_L3_InitFromProps

END MODULE MD_Mat_Acou_Acoustic

