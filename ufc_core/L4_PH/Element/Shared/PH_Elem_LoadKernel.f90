!===============================================================================
! MODULE: PH_Elem_LoadKernel
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  跨族通用载荷积分内核（体�?面力/边力�?
!===============================================================================
MODULE PH_Elem_LoadKernel
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Def, ONLY: PH_Elem_Desc
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! 输入/输出结构体（SIO 规范�?
  !---------------------------------------------------------------------------

  TYPE, PUBLIC :: Elem_Load_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE Elem_Load_Arg


  PUBLIC :: Compute_BodyForce
  PUBLIC :: Compute_SurfPressure
  PUBLIC :: Compute_EdgePressure

CONTAINS

  !----------------------------------------------------------------------------
  ! Compute_BodyForce - 体力等效节点�?
  ! 输入: desc+in%coords+in%magn; 输出: out%Fe
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_BodyForce(desc, in, out, status)
    TYPE(PH_Elem_Desc), INTENT(IN)  :: desc
    TYPE(Elem_Load_Arg), INTENT(IN)  :: in
    TYPE(Elem_Load_Arg), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = desc%pop%n_dof

    ! 默认初始�?
    IF (.NOT. ALLOCATED(out%Fe)) ALLOCATE(out%Fe(n_dof))
    out%Fe = 0.0_wp

    ! 占位骨架：待 ST-2 / ST-4 阶段填充具体算法
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Compute_BodyForce

  !----------------------------------------------------------------------------
  ! Compute_SurfPressure - 3D 面压力等效节点力
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_SurfPressure(desc, in, out, status)
    TYPE(PH_Elem_Desc), INTENT(IN)  :: desc
    TYPE(Elem_Load_Arg), INTENT(IN)  :: in
    TYPE(Elem_Load_Arg), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = desc%pop%n_dof

    IF (.NOT. ALLOCATED(out%Fe)) ALLOCATE(out%Fe(n_dof))
    out%Fe = 0.0_wp

    ! 占位骨架：需要面积分 + 形函数积�?
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Compute_SurfPressure

  !----------------------------------------------------------------------------
  ! Compute_EdgePressure - 2D 边压力等效节点力
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_EdgePressure(desc, in, out, status)
    TYPE(PH_Elem_Desc), INTENT(IN)  :: desc
    TYPE(Elem_Load_Arg), INTENT(IN)  :: in
    TYPE(Elem_Load_Arg), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = desc%pop%n_dof

    IF (.NOT. ALLOCATED(out%Fe)) ALLOCATE(out%Fe(n_dof))
    out%Fe = 0.0_wp

    ! 占位骨架：需要边长计�?+ 形函数积�?
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Compute_EdgePressure

END MODULE PH_Elem_LoadKernel