!===============================================================================
! MODULE: NM_TimeInt_Newmark
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Newmark-β time integration (explicit/implicit, predict-correct)
! BRIEF:  Newmark predictor-corrector with DO CONCURRENT parallelization
!===============================================================================
MODULE NM_TimeInt_Newmark
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def, ONLY: DenseMatrix
  USE NM_TimeInt_Linsolv, ONLY: NM_TimeInt_Dense_LU_Solve
  USE NM_TimeInt_Def, ONLY: NewmarkIntegrator
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: NM_TimeInt_Predict, NM_TimeInt_Correct
  PUBLIC :: NM_TimeInt_Solve_Equilibrium, NM_TimeInt_Update_History
  PUBLIC :: NM_Newmark_Explicit, NM_Newmark_Implicit
  
CONTAINS
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_Predict
  !===========================================================================
  SUBROUTINE NM_TimeInt_Predict(integrator, u, v)
    ! 预测步：计算 t_{n+1} 时刻的预测位移和速度
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(OUT) :: u(:), v(:)
    INTEGER(i4) :: i, ndofs
    REAL(wp) :: coeff_disp, coeff_vel
    
    ! 验证初始�?
    IF (.NOT. integrator%is_initialized) THEN
      ERROR STOP "NM_TimeInt_Predict: integrator not initialized"
    END IF
    
    ndofs = integrator%ndofs
    
    ! 计算系数
    coeff_disp = (0.5_wp - integrator%beta) * integrator%dt2
    coeff_vel = (1.0_wp - integrator%gamma) * integrator%dt
    
    ! 优化：DO CONCURRENT 并行�?
    ! 伪代码：
    ! 1. u_pred[i] = u_old[i] + dt*v_old[i] + coeff_disp*a_old[i]
    ! 2. v_pred[i] = v_old[i] + coeff_vel*a_old[i]
    ! 3. u[i] = u_pred[i], v[i] = v_pred[i]
    DO CONCURRENT (i = 1:ndofs)
      integrator%u_pred(i) = integrator%u_old(i) + &
                            integrator%dt * integrator%v_old(i) + &
                            coeff_disp * integrator%a_old(i)
      
      integrator%v_pred(i) = integrator%v_old(i) + &
                            coeff_vel * integrator%a_old(i)
      
      ! 直接输出预测�?
      u(i) = integrator%u_pred(i)
      v(i) = integrator%v_pred(i)
    END DO
  END SUBROUTINE NM_TimeInt_Predict
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_Correct
  !===========================================================================
  SUBROUTINE NM_TimeInt_Correct(integrator, a_new, u_new, v_new)
    ! 校正步：根据新加速度校正速度和位�?
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(IN) :: a_new(:)
    REAL(wp), INTENT(OUT) :: u_new(:), v_new(:)
    INTEGER(i4) :: i, ndofs
    REAL(wp) :: coeff_acc
    
    ! 验证初始�?
    IF (.NOT. integrator%is_initialized) THEN
      ERROR STOP "NM_TimeInt_Correct: integrator not initialized"
    END IF
    
    ndofs = integrator%ndofs
    coeff_acc = integrator%gamma * integrator%dt
    
    ! Newmark 更新：u = u_pred + beta*dt^2*a ; v = v_pred + gamma*dt*a
    DO CONCURRENT (i = 1:ndofs)
      u_new(i) = integrator%u_pred(i) + integrator%beta * integrator%dt2 * a_new(i)
      v_new(i) = integrator%v_pred(i) + coeff_acc * a_new(i)
    END DO
  END SUBROUTINE NM_TimeInt_Correct
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_Solve_Equilibrium
  !===========================================================================
  SUBROUTINE NM_TimeInt_Solve_Equilibrium(integrator, M, C, K, F_ext, F_int, &
                                          u_pred, v_pred, u_new, v_new, a_new, &
                                          use_precond, precond)
    ! 求解 t_{n+1} 时刻的平衡方�?
    ! 有效刚度矩阵：K_eff = a0*M + a1*C + K
    ! 有效载荷向量：F_eff = F_ext - F_int - M*(a0*u_pred+a2*v_pred) - C*(a1*u_pred+v_pred)
    
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K
    REAL(wp), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(wp), INTENT(IN) :: u_pred(:), v_pred(:)
    REAL(wp), INTENT(OUT) :: u_new(:), v_new(:), a_new(:)
    LOGICAL, INTENT(IN), OPTIONAL :: use_precond
    CLASS(*), INTENT(IN), OPTIONAL :: precond
    
    INTEGER(i4) :: ndofs, i, j, info_ls
    REAL(wp), ALLOCATABLE :: K_eff(:, :), F_eff(:)
    REAL(wp) :: a0, a1, a2
    REAL(wp), ALLOCATABLE :: temp_m(:), temp_c(:), rhs_m(:), rhs_c(:)
    
    ndofs = integrator%ndofs
    
    IF (.NOT. M%is_allocated .OR. .NOT. C%is_allocated .OR. .NOT. K%is_allocated) THEN
      ERROR STOP "NM_TimeInt_Solve_Equilibrium: matrices not allocated"
    END IF
    IF (M%nrows /= ndofs .OR. SIZE(F_ext) /= ndofs) THEN
      ERROR STOP "NM_TimeInt_Solve_Equilibrium: dimension mismatch"
    END IF
    
    ! 获取 Newmark 系数
    CALL integrator%GetCoeffs(a0, a1, a2)
    
    ALLOCATE(K_eff(ndofs, ndofs), F_eff(ndofs), temp_m(ndofs), temp_c(ndofs), &
             rhs_m(ndofs), rhs_c(ndofs))
    
    !-------------------------------------------------------------------------
    ! K_eff = a0*M + a1*C + K
    !-------------------------------------------------------------------------
    DO j = 1, ndofs
      DO i = 1, ndofs
        K_eff(i, j) = a0 * M%data(i, j) + a1 * C%data(i, j) + K%data(i, j)
      END DO
    END DO
    
    !-------------------------------------------------------------------------
    ! M*(a0*u_pred + a2*v_pred), C*(a1*u_pred + v_pred)
    !-------------------------------------------------------------------------
    DO CONCURRENT (i = 1:ndofs)
      temp_m(i) = a0 * u_pred(i) + a2 * v_pred(i)
      temp_c(i) = a1 * u_pred(i) + v_pred(i)
    END DO
    
    rhs_m = MATMUL(M%data(1:ndofs, 1:ndofs), temp_m)
    rhs_c = MATMUL(C%data(1:ndofs, 1:ndofs), temp_c)
    
    !-------------------------------------------------------------------------
    ! 步骤 4: 组装有效载荷向量 F_eff
    !-------------------------------------------------------------------------
    ! 伪代码：F_eff = F_ext - F_int - temp_m - temp_c
    DO CONCURRENT (i = 1:ndofs)
      F_eff(i) = F_ext(i) - F_int(i) - rhs_m(i) - rhs_c(i)
    END DO
    
    !-------------------------------------------------------------------------
    ! K_eff * u_new = F_eff（K_eff �?LU 覆盖�?
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_Dense_LU_Solve(ndofs, K_eff, F_eff, u_new, info_ls)
    
    !-------------------------------------------------------------------------
    ! 步骤 6: 计算新加速度和速度
    !-------------------------------------------------------------------------
    ! �?Newmark 公式反推加速度
    ! a_new = a0 * (u_new - u_pred)
    DO CONCURRENT (i = 1:ndofs)
      a_new(i) = a0 * (u_new(i) - u_pred(i))
    END DO
    
    ! 计算新速度
    ! v_new = v_pred + gamma*dt*a_new
    CALL NM_TimeInt_Correct(integrator, a_new, u_new, v_new)
    
    ! 清理
    DEALLOCATE(K_eff, F_eff, temp_m, temp_c, rhs_m, rhs_c)
  END SUBROUTINE NM_TimeInt_Solve_Equilibrium
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_Update_History
  !===========================================================================
  SUBROUTINE NM_TimeInt_Update_History(integrator, u_new, v_new, a_new)
    ! 更新历史变量：t_n <- t_{n+1}
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(IN) :: u_new(:), v_new(:), a_new(:)
    INTEGER(i4) :: i, ndofs
    
    ndofs = integrator%ndofs
    
    ! 优化：使用数组整体赋值（编译器自动优化为块拷贝）
    ! 伪代码：
    ! u_old = u_new, v_old = v_new, a_old = a_new
    integrator%u_old = u_new
    integrator%v_old = v_new
    integrator%a_old = a_new
  END SUBROUTINE NM_TimeInt_Update_History
  
  !===========================================================================
  ! SUBROUTINE: NM_Newmark_Explicit
  !===========================================================================
  SUBROUTINE NM_Newmark_Explicit(integrator, M, C, K, F_ext, F_int, u, v, a)
    ! 显式 Newmark 格式（中心差分法，gamma=0.5, beta=0�?
    ! 适用于高速动力问题，无需迭代求解
    
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K
    REAL(wp), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(wp), INTENT(INOUT) :: u(:), v(:), a(:)
    
    INTEGER(i4) :: ndofs, i
    REAL(wp), ALLOCATABLE :: R(:)
    
    ndofs = integrator%ndofs
    ALLOCATE(R(ndofs))
    
    !-------------------------------------------------------------------------
    ! 步骤 1: 预测�?
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_Predict(integrator, u, v)
    
    !-------------------------------------------------------------------------
    ! 步骤 2: 计算不平衡力 R = F_ext - F_int - C*v
    !-------------------------------------------------------------------------
    ! 优化：DOT_PRODUCT 避免临时数组
    DO i = 1, ndofs
      R(i) = F_ext(i) - F_int(i)
      ! C*v 的第 i 个分�?
      R(i) = R(i) - DOT_PRODUCT(C%data(i,:), v)
    END DO
    
    !-------------------------------------------------------------------------
    ! 步骤 3: 求解加速度 a = M^(-1) * R
    !-------------------------------------------------------------------------
    ! 显式格式：假�?M 是对角阵（质量集中）
    ! 优化：直接除以对角元，避免求�?
    DO i = 1, ndofs
      a(i) = R(i) / M%data(i,i)
    END DO
    
    !-------------------------------------------------------------------------
    ! 步骤 4: 校正�?
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_Correct(integrator, a, u, v)
    
    !-------------------------------------------------------------------------
    ! 步骤 5: 更新历史
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_Update_History(integrator, u, v, a)
    
    DEALLOCATE(R)
  END SUBROUTINE NM_Newmark_Explicit
  
  !===========================================================================
  ! SUBROUTINE: NM_Newmark_Implicit
  !===========================================================================
  SUBROUTINE NM_Newmark_Implicit(integrator, M, C, K, F_ext, F_int, u, v, a, &
                                 max_iter, tol, converged)
    ! 隐式 Newmark 格式（平均加速度法，gamma=0.5, beta=0.25�?
    ! 需�?Newton-Raphson 迭代求解非线性方�?
    
    CLASS(NewmarkIntegrator), INTENT(INOUT) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K
    REAL(wp), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(wp), INTENT(INOUT) :: u(:), v(:), a(:)
    INTEGER(i4), INTENT(IN) :: max_iter
    REAL(wp), INTENT(IN) :: tol
    LOGICAL, INTENT(OUT) :: converged
    
    INTEGER(i4) :: iter, i, j, ndofs, info_ls
    REAL(wp), ALLOCATABLE :: R(:), K_eff(:, :), delta_u(:)
    REAL(wp) :: residual_norm
    REAL(wp) :: a0, a1, a2
    
    ndofs = integrator%ndofs
    converged = .FALSE.
    
    ALLOCATE(R(ndofs), K_eff(ndofs,ndofs), delta_u(ndofs))
    
    ! 获取 Newmark 系数
    CALL integrator%GetCoeffs(a0, a1, a2)
    
    !-------------------------------------------------------------------------
    ! 步骤 1: 预测�?
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_Predict(integrator, u, v)
    
    !-------------------------------------------------------------------------
    ! 步骤 2: Newton-Raphson 平衡迭代
    !-------------------------------------------------------------------------
    DO iter = 1, max_iter
      
      ! 2.1 计算残余�?R = F_ext - F_int - M*a - C*v
      DO i = 1, ndofs
        R(i) = F_ext(i) - F_int(i)
        ! M*a �?
        R(i) = R(i) - DOT_PRODUCT(M%data(i,:), a)
        ! C*v �?
        R(i) = R(i) - DOT_PRODUCT(C%data(i,:), v)
      END DO
      
      ! 2.2 检查收�?
      residual_norm = SQRT(DOT_PRODUCT(R, R))
      IF (residual_norm < tol) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! 2.3 构建有效刚度 K_eff = a0*M + a1*C + K
      DO j = 1, ndofs
        DO i = 1, ndofs
          K_eff(i, j) = a0 * M%data(i, j) + a1 * C%data(i, j) + K%data(i, j)
        END DO
      END DO
      
      ! 2.4 求解位移增量 K_eff * delta_u = R
      CALL NM_TimeInt_Dense_LU_Solve(ndofs, K_eff, R, delta_u, info_ls)
      
      ! 2.5 更新位移
      u = u + delta_u
      
      ! 2.6 更新加速度和速度
      DO CONCURRENT (i = 1:ndofs)
        a(i) = a0 * (u(i) - integrator%u_pred(i))
        v(i) = integrator%v_pred(i) + integrator%gamma * integrator%dt * a(i)
      END DO
      
    END DO
    
    !-------------------------------------------------------------------------
    ! 步骤 3: 更新历史变量
    !-------------------------------------------------------------------------
    IF (converged) THEN
      CALL NM_TimeInt_Update_History(integrator, u, v, a)
    END IF
    
    DEALLOCATE(R, K_eff, delta_u)
  END SUBROUTINE NM_Newmark_Implicit
  
END MODULE NM_TimeInt_Newmark