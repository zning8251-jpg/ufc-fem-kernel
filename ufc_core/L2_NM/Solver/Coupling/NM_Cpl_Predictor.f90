!===============================================================================
! MODULE: NM_Cpl_Predictor
! LAYER:  L2_NM
! DOMAIN: Solver/Coupling
! ROLE:   Proc (multi-physics predictor)
! BRIEF:  Coupling predictors: zero-order, constant, linear, quadratic extrapolation
!
! Status: CORE | Last verified: 2026-04-13
!===============================================================================
MODULE NM_Cpl_Predictor
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_Coupling_Pred_Init
  PUBLIC :: NM_Coupling_Pred_ZeroOrder
  PUBLIC :: NM_Coupling_Pred_Constant
  PUBLIC :: NM_Coupling_Pred_Linear
  PUBLIC :: NM_Coupling_Pred_Quadratic
  PUBLIC :: NM_Coupling_Pred_Predict
  PUBLIC :: NM_Coupling_Pred_Cleanup

  !====================================================================
  !> @brief 预测器初始化
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Init(pred_type, n_dof, pred_ctx, status)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: pred_type, n_dof
    TYPE(*), INTENT(OUT) :: pred_ctx
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 预测器初始化实现
  END SUBROUTINE NM_Coupling_Pred_Init

  !====================================================================
  !> @brief 零阶预测器（常数外推）
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_ZeroOrder(state_old, state_pred, dt, status)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: state_old(:)
    REAL(8), INTENT(OUT) :: state_pred(:)
    REAL(8), INTENT(IN) :: dt
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 零阶预测：y(t+dt) = y(t)
    state_pred = state_old
  END SUBROUTINE NM_Coupling_Pred_ZeroOrder

  !====================================================================
  !> @brief 常数预测器
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Constant(state_history, state_pred, dt, status)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: state_history(:,:)
    REAL(8), INTENT(OUT) :: state_pred(:)
    REAL(8), INTENT(IN) :: dt
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 常数预测：y(t+dt) = mean(y(t-n), ..., y(t))
  END SUBROUTINE NM_Coupling_Pred_Constant

  !====================================================================
  !> @brief 线性预测器
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Linear(state_old, state_older, state_pred, dt, status)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: state_old(:), state_older(:)
    REAL(8), INTENT(OUT) :: state_pred(:)
    REAL(8), INTENT(IN) :: dt
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 线性预测：y(t+dt) = y(t) + (y(t) - y(t-dt))
    state_pred = 2.0d0 * state_old - state_older
  END SUBROUTINE NM_Coupling_Pred_Linear

  !====================================================================
  !> @brief 二次预测器
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Quadratic(state_history, state_pred, dt, status)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: state_history(:,:,:)
    REAL(8), INTENT(OUT) :: state_pred(:)
    REAL(8), INTENT(IN) :: dt
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 二次预测：使用二次插值
    ! y(t+dt) = a*dt^2 + b*dt + c
  END SUBROUTINE NM_Coupling_Pred_Quadratic

  !====================================================================
  !> @brief 状态预测（通用接口）
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Predict(pred_type, state_history, state_pred, dt, status)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: pred_type
    REAL(8), INTENT(IN) :: state_history(:,:,:)
    REAL(8), INTENT(OUT) :: state_pred(:)
    REAL(8), INTENT(IN) :: dt
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 根据预测器类型选择具体实现
    SELECT CASE (pred_type)
    CASE (0)
      CALL NM_Coupling_Pred_ZeroOrder(state_history(:,1), state_pred, dt, status)
    CASE (1)
      CALL NM_Coupling_Pred_Constant(state_history, state_pred, dt, status)
    CASE (2)
      CALL NM_Coupling_Pred_Linear(state_history(:,1), state_history(:,2), state_pred, dt, status)
    CASE (3)
      CALL NM_Coupling_Pred_Quadratic(state_history, state_pred, dt, status)
    CASE DEFAULT
      status = -1
    END SELECT
  END SUBROUTINE NM_Coupling_Pred_Predict

  !====================================================================
  !> @brief 预测器清理
  !====================================================================
  SUBROUTINE NM_Coupling_Pred_Cleanup(pred_ctx, status)
    IMPLICIT NONE
    TYPE(*), INTENT(INOUT) :: pred_ctx
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    ! 清理实现
  END SUBROUTINE NM_Coupling_Pred_Cleanup

END MODULE NM_Cpl_Predictor