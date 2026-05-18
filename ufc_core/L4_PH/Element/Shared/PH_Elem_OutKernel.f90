!===============================================================================
! MODULE: PH_Elem_OutKernel
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  单元输出采集内核，封装积分点→节点外推、应力应变聚�?
!===============================================================================
MODULE PH_Elem_OutKernel
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: Elem_Out_In
  ! Input type for element output
  !============================================================================

  !============================================================================
  ! TYPE: Elem_Out_Out
  ! Output type for element output
  !============================================================================
  TYPE, PUBLIC :: Elem_Out_Arg
    INTEGER(i4) :: elem_type_id                   ! [IN]
    INTEGER(i4) :: n_nodes                   ! [IN]
    INTEGER(i4) :: n_ip                   ! [IN]
    INTEGER(i4) :: n_vars                   ! [IN]
  END TYPE Elem_Out_Arg


  PUBLIC :: Elem_Output_Collect

CONTAINS

  !============================================================================
  ! Subroutine: Elem_Output_Collect
  ! Purpose: 从积分点变量聚合到节点变�?
  ! 输入: elem_type, coords, ip_vars
  ! 输出: node_vars, elem_avg
  !============================================================================
  SUBROUTINE Elem_Output_Collect(in_data, out_data, status)
    TYPE(Elem_Out_Arg),  INTENT(IN)  :: in_data
    TYPE(Elem_Out_Arg), INTENT(OUT) :: out_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, n_nodes, n_ip, n_vars

    n_nodes = in_data%pop%n_nodes
    n_ip = in_data%n_ip
    n_vars = in_data%n_vars

    ! 初始化输�?
    ALLOCATE(out_data%node_vars(n_vars, n_nodes))
    ALLOCATE(out_data%elem_avg(n_vars))
    out_data%node_vars = 0.0_wp
    out_data%elem_avg = 0.0_wp

    ! 方法1：简单平均（默认�?
    DO j = 1, n_vars
      out_data%elem_avg(j) = SUM(in_data%ip_vars(j, 1:n_ip)) / REAL(n_ip, wp)
      
      DO i = 1, n_nodes
        ! 简化：等权外推（实际应根据外推矩阵�?
        out_data%node_vars(j, i) = out_data%elem_avg(j)
      END DO
    END DO

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Elem_Output_Collect

  !============================================================================
  ! Subroutine: Elem_Output_Extrap
  ! Purpose: 高阶外推（积分点→节点）
  !============================================================================
  SUBROUTINE Elem_Output_Extrap(in_data, extrap_mat, out_data, status)
    TYPE(Elem_Out_Arg),  INTENT(IN)  :: in_data
    REAL(wp),          INTENT(IN)  :: extrap_mat(:,:) ! [n_nodes, n_ip]
    TYPE(Elem_Out_Arg), INTENT(OUT) :: out_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_vars, n_nodes

    n_vars = in_data%n_vars
    n_nodes = in_data%pop%n_nodes

    ! node_vars = ip_vars * extrap_mat^T
    ALLOCATE(out_data%node_vars(n_vars, n_nodes))
    out_data%node_vars = MATMUL(in_data%ip_vars, TRANSPOSE(extrap_mat))

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Elem_Output_Extrap

  !============================================================================
  ! Subroutine: Elem_Output_StressStrain
  ! Purpose: 应力应变张量转换（Voigt �?主应�?应变�?
  !============================================================================
  SUBROUTINE Elem_Output_StressStrain(stress_voigt, stress_principal, status)
    REAL(wp), INTENT(IN)  :: stress_voigt(6)
    REAL(wp), INTENT(OUT) :: stress_principal(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! 占位：计算主应力
    stress_principal = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Elem_Output_StressStrain

END MODULE PH_Elem_OutKernel