!===============================================================================
! MODULE: PH_Elem_MassDispatch
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Dispatch
! BRIEF:  �?PH_ElemDomain_Ops 拆分的质�?阻尼矩阵计算路由
!===============================================================================
MODULE PH_Elem_MassDispatch
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Compute_Me
  PUBLIC :: Compute_Ce

CONTAINS

  !----------------------------------------------------------------------------
  ! Compute_Me - 质量矩阵计算
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Me(elem_type, coords, density, mass_type, Me, status)
    INTEGER(i4), INTENT(IN)  :: elem_type    ! 单元类型ID
    REAL(wp),   INTENT(IN)  :: coords(:,:)  ! [ndim, n_nodes] 坐标
    REAL(wp),   INTENT(IN)  :: density     ! 质量密度
    INTEGER(i4), INTENT(IN)  :: mass_type   ! 0=一致质�?1=集中质量
    REAL(wp),   INTENT(OUT) :: Me(:,:)     ! [n_dof, n_dof] 质量矩阵
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = SIZE(Me, 1)
    Me = 0.0_wp

    ! 占位骨架：调�?PH_Mass_Algo 或族专用模块
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Compute_Me

  !----------------------------------------------------------------------------
  ! Compute_Ce - 阻尼矩阵计算
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Ce(elem_type, coords, alpha, beta, Ce, status)
    INTEGER(i4), INTENT(IN)  :: elem_type  ! 单元类型ID
    REAL(wp),   INTENT(IN)  :: coords(:,:)
    REAL(wp),   INTENT(IN)  :: alpha     ! Rayleigh α（质量比例阻尼）
    REAL(wp),   INTENT(IN)  :: beta      ! Rayleigh β（刚度比例阻尼）
    REAL(wp),   INTENT(OUT) :: Ce(:,:)   ! [n_dof, n_dof] 阻尼矩阵
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = SIZE(Ce, 1)
    Ce = 0.0_wp

    ! 占位骨架：Ce = α*M + β*K
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Compute_Ce

END MODULE PH_Elem_MassDispatch