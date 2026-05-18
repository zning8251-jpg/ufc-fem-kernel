!===============================================================================
! Module: MD_MatCMPFabric
! Layer:  L3_MD - Model Description Layer
! Domain: Material - CMP (Fabric Plasticity, mat_id=215)
! Purpose: Descriptor type and input validation for anisotropic fabric
!          plasticity model for woven composite materials.
!
! Props layout (10 required):
!   props(1)  = MD_MAT_E_warp  : warp-direction Young's modulus
!   props(2)  = MD_MAT_E_fill  : fill-direction Young's modulus
!   props(3)  = nu_wf   : warp-fill Poisson's ratio
!   props(4)  = G_wf    : in-plane shear modulus
!   props(5)  = sigma_y1_0 : warp-direction initial yield stress
!   props(6)  = sigma_y2_0 : fill-direction initial yield stress
!   props(7)  = tau_y12_0  : shear yield stress
!   props(8)  = H1      : warp isotropic hardening modulus
!   props(9)  = H2      : fill isotropic hardening modulus
!   props(10) = H12     : shear hardening modulus
!
! nProps_min = 10
! Statev: (1)=eps_pl_warp, (2)=eps_pl_fill, (3)=gamma_pl_12,
!         (4)=kappa_1, (5)=kappa_2, (6)=gamma_pl_12_cum
! **W1**：**FabricPlast_MatDesc**（见模块内 **TYPE** 名）扩展 **MD_Mat_Desc**；**props** 与 **Populate** /
!   **`desc%props`** 金线一致（**215**）。
!===============================================================================
MODULE MD_Mat_Composite_Fabric
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_215
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: FabricPlast_MatDesc
  PUBLIC :: UF_FabricPlast_L3_ValidateProps
  PUBLIC :: UF_FabricPlast_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_FABRIC = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_215 = MD_MAT_ID_215

  !> L3 descriptor for fabric anisotropic plasticity model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: FabricPlast_MatDesc
    REAL(wp) :: MD_MAT_E_warp      = 0.0_wp   ! Warp Young's modulus
    REAL(wp) :: MD_MAT_E_fill      = 0.0_wp   ! Fill Young's modulus
    REAL(wp) :: nu_wf       = 0.0_wp   ! Warp-fill Poisson's ratio
    REAL(wp) :: G_wf        = 0.0_wp   ! In-plane shear modulus
    REAL(wp) :: sigma_y1_0  = 0.0_wp   ! Warp initial yield stress
    REAL(wp) :: sigma_y2_0  = 0.0_wp   ! Fill initial yield stress
    REAL(wp) :: tau_y12_0   = 0.0_wp   ! Shear yield stress
    REAL(wp) :: H1          = 0.0_wp   ! Warp hardening modulus
    REAL(wp) :: H2          = 0.0_wp   ! Fill hardening modulus
    REAL(wp) :: H12         = 0.0_wp   ! Shear hardening modulus
    LOGICAL :: is_initialized = .FALSE.
  END TYPE FabricPlast_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_FabricPlast_L3_ValidateProps
  !   Validates flat props array for fabric plasticity model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_FabricPlast_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_FABRIC) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: need >=10 props"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: MD_MAT_E_warp must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: MD_MAT_E_fill must be > 0"
      RETURN
    END IF
    IF (props(3) <= -1.0_wp .OR. props(3) >= 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: nu_wf must be in (-1,1)"
      RETURN
    END IF
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: G_wf must be > 0"
      RETURN
    END IF
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: sigma_y1_0 must be > 0"
      RETURN
    END IF
    IF (props(6) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: sigma_y2_0 must be > 0"
      RETURN
    END IF
    IF (props(7) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: tau_y12_0 must be > 0"
      RETURN
    END IF
    ! H1, H2, H12 can be zero (perfectly plastic)
    IF (props(8) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: H1 must be >= 0"
      RETURN
    END IF
    IF (props(9) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: H2 must be >= 0"
      RETURN
    END IF
    IF (props(10) < 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "FabricPlast: H12 must be >= 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_FabricPlast_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_FabricPlast_L3_InitFromProps
  !   Unpacks flat props array into a FabricPlast_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_FabricPlast_L3_InitFromProps(desc, nprops, props, st)
    TYPE(FabricPlast_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_FabricPlast_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%MD_MAT_E_warp     = props(1)
    desc%MD_MAT_E_fill     = props(2)
    desc%nu_wf      = props(3)
    desc%G_wf       = props(4)
    desc%sigma_y1_0 = props(5)
    desc%sigma_y2_0 = props(6)
    desc%tau_y12_0  = props(7)
    desc%H1         = props(8)
    desc%H2         = props(9)
    desc%H12        = props(10)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_FabricPlast_L3_InitFromProps

END MODULE MD_Mat_Composite_Fabric

