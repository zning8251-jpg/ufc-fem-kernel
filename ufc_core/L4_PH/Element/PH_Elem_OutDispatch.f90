!===============================================================================
! MODULE: PH_Elem_OutDispatch
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Dispatch
! BRIEF:  �?PH_ElemDomain_Ops 拆分的输出采集路�?
!===============================================================================
MODULE PH_Elem_OutDispatch
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Def, ONLY: PH_Elem_State

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Collect_IPVars
  PUBLIC :: Map_To_Nodes
  PUBLIC :: Get_Extrap_Matrix

CONTAINS

  !----------------------------------------------------------------------------
  ! Collect_IPVars - 积分点变量采�?
  !----------------------------------------------------------------------------
  SUBROUTINE Collect_IPVars(elem_type, coords, stress, strain, svars, ip_vars, status)
    INTEGER(i4), INTENT(IN)  :: elem_type
    REAL(wp),   INTENT(IN)  :: coords(:,:)
    REAL(wp),   INTENT(IN)  :: stress(:,:)  ! [6, n_ip]
    REAL(wp),   INTENT(IN)  :: strain(:,:) ! [6, n_ip]
    REAL(wp),   INTENT(IN)  :: svars(:)    ! [nsvars]
    REAL(wp),   INTENT(OUT) :: ip_vars(:,:) ! [n_vars, n_ip]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_ip, n_vars

    n_ip = SIZE(stress, 2)
    n_vars = SIZE(ip_vars, 1)

    ip_vars = 0.0_wp

    ! 占位骨架：按单元类型组装输出变量
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Collect_IPVars

  !----------------------------------------------------------------------------
  ! Map_To_Nodes - 节点外推
  !----------------------------------------------------------------------------
  SUBROUTINE Map_To_Nodes(elem_type, ip_vars, extrap_mat, node_vars, status)
    INTEGER(i4), INTENT(IN)  :: elem_type
    REAL(wp),   INTENT(IN)  :: ip_vars(:,:)  ! [n_vars, n_ip]
    REAL(wp),   INTENT(IN)  :: extrap_mat(:,:) ! [n_nodes, n_ip]
    REAL(wp),   INTENT(OUT) :: node_vars(:,:) ! [n_vars, n_nodes]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! node_vars = ip_vars * extrap_mat^T
    node_vars = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Map_To_Nodes

  !----------------------------------------------------------------------------
  ! Get_Extrap_Matrix - 获取外推矩阵
  !----------------------------------------------------------------------------
  SUBROUTINE Get_Extrap_Matrix(elem_type, extrap_mat, status)
    INTEGER(i4), INTENT(IN)  :: elem_type
    REAL(wp),   INTENT(OUT) :: extrap_mat(:,:) ! [n_nodes, n_ip]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_nodes, n_ip

    n_nodes = SIZE(extrap_mat, 1)
    n_ip = SIZE(extrap_mat, 2)

    extrap_mat = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Get_Extrap_Matrix

END MODULE PH_Elem_OutDispatch