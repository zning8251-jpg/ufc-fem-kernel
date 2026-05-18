!===============================================================================
! MODULE: PH_ElemDomain_Ops
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Domain
! BRIEF:  Element physics domain - B-Element v5.0 精简�?!
!===============================================================================
MODULE PH_ElemDomain_Ops
  USE IF_Base_Def,   ONLY: ZERO, ONE, TWO
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx, PH_Elem_State

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Public Interfaces (B-Element v5.0 风格)
  !============================================================================
  PUBLIC :: PH_Elem_Compute_Ke_Args
  PUBLIC :: PH_Elem_Compute_Fe_Args
  PUBLIC :: PH_Elem_ComputeStiffness
  PUBLIC :: PH_Elem_ComputeInternalForce

  ! Legacy 接口（向后兼容，逐步迁移�?  PUBLIC :: PH_Element_Ctan6_RotateCt_LabToRThetaZ
  PUBLIC :: PH_Element_StressVoigt6_ToPlane3_124
  PUBLIC :: PH_Element_StressVoigt6_ToCax4_1325
  PUBLIC :: PH_Element_TM_AssembleKe_Coupled

CONTAINS

  !============================================================================
  ! TYPE: PH_Elem_Compute_Ke_Args
  ! Arguments for stiffness computation (B-Element enhanced)
  !============================================================================
  TYPE, PUBLIC :: PH_Elem_Compute_Ke_Args
    INTEGER(i4) :: elem_idx
    INTEGER(i4) :: mat_pt_idx
    INTEGER(i4) :: ndofel
    INTEGER(i4) :: nstrs
    
    TYPE(PH_Elem_Ctx), INTENT(IN)    :: ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    INTEGER(i4) :: status
  END TYPE PH_Elem_Compute_Ke_Args

  !============================================================================
  ! TYPE: PH_Elem_Compute_Fe_Args
  ! Arguments for internal force computation (B-Element enhanced)
  !============================================================================
  TYPE, PUBLIC :: PH_Elem_Compute_Fe_Args
    INTEGER(i4) :: elem_idx
    INTEGER(i4) :: mat_pt_idx
    INTEGER(i4) :: ndofel
    INTEGER(i4) :: nstrs
    
    TYPE(PH_Elem_Ctx), INTENT(IN)    :: ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    
    ! 边界积分支持
    INTEGER(i4) :: integrate_boundary = 0_i4
    INTEGER(i4) :: face_id = 0_i4
    INTEGER(i4) :: edge_id = 0_i4
    REAL(wp), ALLOCATABLE :: traction(:)
    
    REAL(wp), ALLOCATABLE :: Fe(:,:)
    REAL(wp), ALLOCATABLE :: stress(:,:)
    INTEGER(i4) :: status
  END TYPE PH_Elem_Compute_Fe_Args

  !============================================================================
  ! Subroutine: PH_Elem_ComputeStiffness
  ! Purpose: Compute element stiffness matrix
  !          Ke = �?B^T C B dΩ (Gauss quadrature)
  !============================================================================
  SUBROUTINE PH_Elem_ComputeStiffness(args)
    TYPE(PH_Elem_Compute_Ke_Args), INTENT(INOUT) :: args

    TYPE(ErrorStatusType) :: ke_status

    ! 委托�?Dispatcher（ST-3 拆分�?    USE PH_ElemKeDispatch, ONLY: Compute_Ke

    args%status = 0
    CALL init_error_status(ke_status)

    IF (.NOT. ALLOCATED(args%Ke)) THEN
      ALLOCATE(args%Ke(args%ndofel, args%ndofel))
    END IF
    args%Ke = 0.0_wp

    ! Delegate to Ke dispatcher (SELECT CASE on elem_type)
    CALL Compute_Ke(args%elem_idx, args%ctx%coords, args%ctx%mat_props, &
                    args%ctx%algo_params, args%Ke, ke_status)
    IF (ke_status%status_code /= IF_STATUS_OK) THEN
      args%status = -1
    END IF

  END SUBROUTINE PH_Elem_ComputeStiffness

  !============================================================================
  ! Subroutine: PH_Elem_ComputeInternalForce
  ! Purpose: Compute internal force vector
  !          Fe = �?B^T σ dΩ (Gauss quadrature)
  !============================================================================
  SUBROUTINE PH_Elem_ComputeInternalForce(args)
    TYPE(PH_Elem_Compute_Fe_Args), INTENT(INOUT) :: args

    ! 委托�?Dispatcher（ST-3 拆分�?    USE PH_ElemFeDispatch, ONLY: Compute_Fe

    args%status = 0

    IF (.NOT. ALLOCATED(args%Fe)) THEN
      ALLOCATE(args%Fe(args%ndofel, 1))
    END IF
    args%Fe = 0.0_wp

    ! Delegate to Fe dispatcher (SELECT CASE on elem_type)
    CALL Compute_Fe(args%elem_idx, args%ctx%coords, args%ctx%mat_props, &
                    args%ctx%algo_params, args%Fe, fe_status)
    IF (fe_status%status_code /= IF_STATUS_OK) THEN
      args%status = -1
    END IF

  END SUBROUTINE PH_Elem_ComputeInternalForce

  !============================================================================
  ! Legacy: 应力转换工具（向后兼容）
  !============================================================================
  SUBROUTINE PH_Element_Ctan6_RotateCt_LabToRThetaZ(R, C_lab, C_rtz)
    REAL(wp), INTENT(IN)  :: R(:,:)
    REAL(wp), INTENT(IN)  :: C_lab(:,:)
    REAL(wp), INTENT(OUT) :: C_rtz(:,:)
    
    ! 占位实现
    C_rtz = C_lab
  END SUBROUTINE PH_Element_Ctan6_RotateCt_LabToRThetaZ

  SUBROUTINE PH_Element_StressVoigt6_ToPlane3_124(sigma6, sigma3)
    REAL(wp), INTENT(IN)  :: sigma6(:)
    REAL(wp), INTENT(OUT) :: sigma3(:)
    sigma3(1) = sigma6(1)
    sigma3(2) = sigma6(2)
    sigma3(3) = sigma6(4)
  END SUBROUTINE PH_Element_StressVoigt6_ToPlane3_124

  SUBROUTINE PH_Element_StressVoigt6_ToCax4_1325(sigma6, sigma4)
    REAL(wp), INTENT(IN)  :: sigma6(:)
    REAL(wp), INTENT(OUT) :: sigma4(:)
    sigma4(1) = sigma6(1)
    sigma4(2) = sigma6(3)
    sigma4(3) = sigma6(2)
    sigma4(4) = sigma6(4)
  END SUBROUTINE PH_Element_StressVoigt6_ToCax4_1325

  SUBROUTINE PH_Element_TM_AssembleKe_Coupled(elem_type_id, coords, props, Ke, status)
    INTEGER(i4), INTENT(IN)  :: elem_type_id
    REAL(wp),   INTENT(IN)  :: coords(:,:)
    REAL(wp),   INTENT(IN)  :: props(:)
    REAL(wp),   INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! �?机械耦合占位
    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE PH_Element_TM_AssembleKe_Coupled

END MODULE PH_ElemDomain_Ops