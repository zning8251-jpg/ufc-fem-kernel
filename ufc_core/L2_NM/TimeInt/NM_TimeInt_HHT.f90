!===============================================================================
! MODULE: NM_TimeInt_HHT
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — HHT-α (Hilber-Hughes-Taylor) with numerical dissipation control
! BRIEF:  Implicit HHT scheme with spectral radius rho_inf high-freq filtering
!===============================================================================
MODULE NM_TimeInt_HHT
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def, ONLY: DenseMatrix
  USE NM_TimeInt_Linsolv, ONLY: NM_TimeInt_Dense_LU_Solve
  USE NM_TimeInt_Def, ONLY: HHTIntegrator
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: NM_TimeInt_HHT_Integrate
  PUBLIC :: NM_TimeInt_HHT_Predict, NM_TimeInt_HHT_Correct
  PUBLIC :: NM_TimeInt_HHT_Equilibrium_Iteration
  PUBLIC :: NM_TimeInt_HHT_Compute_Effective_Force
  
CONTAINS
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Integrate
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Integrate(integrator, M, C, K_tan, F_ext, F_int, &
                                      u, v, a, converged)
    ! HHT-α 隐式积分主接�?
    ! 完整实现：预测步 + 平衡迭代 + 校正�?
    
    CLASS(HHTIntegrator), INTENT(INOUT) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K_tan
    REAL(wp), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(wp), INTENT(INOUT) :: u(:), v(:), a(:)
    LOGICAL, INTENT(OUT) :: converged
    
    INTEGER(i4) :: iter, i, ndofs, info_ls
    REAL(wp) :: residual_norm
    REAL(wp), ALLOCATABLE :: R(:), K_eff(:, :), delta_u(:)
    REAL(wp), ALLOCATABLE :: R_effective(:), a_np1(:), v_np1(:)
    
    ndofs = integrator%ndofs
    converged = .FALSE.
    
    ALLOCATE(R(ndofs), K_eff(ndofs, ndofs), delta_u(ndofs), R_effective(ndofs), &
             a_np1(ndofs), v_np1(ndofs))
    
    !-------------------------------------------------------------------------
    ! 步骤 1: 预测步（计算 u_star, v_star�?
    !-------------------------------------------------------------------------
    CALL NM_TimeInt_HHT_Predict(integrator, u, v)
    
    !-------------------------------------------------------------------------
    ! 步骤 2: Newton-Raphson 平衡迭代
    !-------------------------------------------------------------------------
    DO iter = 1, integrator%max_iter
      
      ! 2.1 有效内力在位移迭代点 u_star 上取�?
      CALL NM_TimeInt_HHT_Compute_Effective_Force(integrator, F_int, integrator%u_star, &
                                                  R_effective)
      
      ! 2.2 计算残余�?
      ! RESIDUAL = (1+alpha_m)*F_ext - M*a - C*v_star - R_eff
      DO i = 1, ndofs
        ! 惯性力�?M*a
        R(i) = (1.0_wp + integrator%alpha_m) * F_ext(i)
        R(i) = R(i) - DOT_PRODUCT(M%data(i,:), a)
        R(i) = R(i) - DOT_PRODUCT(C%data(i,:), integrator%v_star)
        R(i) = R(i) - R_effective(i)
      END DO
      
      ! 2.3 检查收�?
      residual_norm = SQRT(DOT_PRODUCT(R, R))
      IF (residual_norm < integrator%tolerance) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! 2.4 构建有效刚度矩阵
      ! K_eff = a0*M + a1*C + (1+alpha_f)*K_tangent
      CALL Build_HHT_Effective_Stiffness(integrator, M, C, K_tan, K_eff)
      
      ! 2.5 求解位移增量 K_eff * delta_u = R
      CALL NM_TimeInt_Dense_LU_Solve(ndofs, K_eff, R, delta_u, info_ls)
      
      ! 2.6 更新预测位移
      integrator%u_star = integrator%u_star + delta_u
      
      ! 2.7 重新计算速度和加速度
      DO CONCURRENT (i = 1:ndofs)
        ! �?Newmark 公式反推
        a_np1(i) = integrator%a0 * (integrator%u_star(i) - integrator%u_old(i)) - &
                   integrator%a1 * integrator%v_old(i) - integrator%a2 * integrator%a_old(i)
        
        v_np1(i) = integrator%v_old(i) + integrator%gamma * integrator%dt * a_np1(i) + &
                   (1.0_wp - integrator%gamma) * integrator%dt * integrator%a_old(i)
      END DO
      
      ! 2.8 更新当前状�?
      u = integrator%u_star
      v = v_np1
      a = a_np1
      
    END DO
    
    !-------------------------------------------------------------------------
    ! 步骤 3: 保存收敛结果并更新历�?
    !-------------------------------------------------------------------------
    IF (converged) THEN
      u = integrator%u_star
      v = v_np1
      a = a_np1
      
      ! 更新历史变量
      CALL NM_TimeInt_HHT_Update_History(integrator, u, v, a, F_int)
      
      integrator%converged = .TRUE.
    ELSE
      integrator%converged = .FALSE.
    END IF
    
    DEALLOCATE(R, K_eff, delta_u, R_effective, a_np1, v_np1)
  END SUBROUTINE NM_TimeInt_HHT_Integrate
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Predict
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Predict(integrator, u_n, v_n)
    ! HHT 预测步：计算 u_star, v_star
    ! 使用 Newmark 预测公式
    
    CLASS(HHTIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(IN) :: u_n(:), v_n(:)
    INTEGER(i4) :: i, ndofs
    REAL(wp) :: coeff_disp, coeff_vel
    
    ndofs = integrator%ndofs
    
    ! 计算 HHT 系数
    ! a0 = 1/(beta*dt^2), a1 = gamma/(beta*dt), a2 = 1/(beta*dt) - 1
    integrator%a0 = 1.0_wp / (integrator%beta * integrator%dt**2)
    integrator%a1 = integrator%gamma / (integrator%beta * integrator%dt)
    integrator%a2 = 1.0_wp / (integrator%beta * integrator%dt) - 1.0_wp
    
    coeff_disp = (0.5_wp - integrator%beta) * integrator%dt**2
    coeff_vel = (1.0_wp - integrator%gamma) * integrator%dt
    
    ! 优化：DO CONCURRENT 并行�?
    ! 伪代码：
    ! u_star[i] = u_n[i] + dt*v_n[i] + coeff_disp*a_n[i]
    ! v_star[i] = v_n[i] + coeff_vel*a_n[i]
    DO CONCURRENT (i = 1:ndofs)
      integrator%u_star(i) = u_n(i) + integrator%dt * v_n(i) + &
                            coeff_disp * integrator%a_old(i)
      
      integrator%v_star(i) = v_n(i) + coeff_vel * integrator%a_old(i)
    END DO
  END SUBROUTINE NM_TimeInt_HHT_Predict
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Correct
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Correct(integrator, a_np1, u_np1, v_np1)
    ! HHT 校正步：根据最终加速度更新速度和位�?
    
    CLASS(HHTIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(IN) :: a_np1(:)
    REAL(wp), INTENT(OUT) :: u_np1(:), v_np1(:)
    INTEGER(i4) :: i, ndofs
    
    ndofs = integrator%ndofs
    
    ! 优化：使用预测值作为基础，只修正加速度相关�?
    ! 伪代码：
    ! v_np1[i] = v_star[i] + gamma*dt*(a_np1[i] - a_n[i])/dt
    ! u_np1[i] = u_star[i]
    DO CONCURRENT (i = 1:ndofs)
      v_np1(i) = integrator%v_star(i) + integrator%gamma * integrator%dt * a_np1(i)
      u_np1(i) = integrator%u_star(i) + integrator%beta * integrator%dt**2 * a_np1(i)
    END DO
  END SUBROUTINE NM_TimeInt_HHT_Correct
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Equilibrium_Iteration
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Equilibrium_Iteration(integrator, M, C, K_tan, &
                                                  F_ext, F_int, u, v, a, &
                                                  max_iter, tol, converged)
    ! HHT 平衡迭代（Newton-Raphson 循环展开�?
    ! 支持切线刚度修正和收敛检�?
    
    CLASS(HHTIntegrator), INTENT(INOUT) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K_tan
    REAL(wp), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(wp), INTENT(INOUT) :: u(:), v(:), a(:)
    INTEGER(i4), INTENT(IN) :: max_iter
    REAL(wp), INTENT(IN) :: tol
    LOGICAL, INTENT(OUT) :: converged
    
    INTEGER(i4) :: iter, i, j, ndofs, info_ls
    REAL(wp) :: residual_norm
    REAL(wp), ALLOCATABLE :: R(:), K_eff(:, :), delta_u(:), R_effective(:)
    
    ndofs = integrator%ndofs
    converged = .FALSE.
    
    ALLOCATE(R(ndofs), K_eff(ndofs, ndofs), delta_u(ndofs), R_effective(ndofs))
    
    !-------------------------------------------------------------------------
    ! Newton-Raphson 迭代循环
    !-------------------------------------------------------------------------
    DO iter = 1, max_iter
      
      ! 1. 计算有效内力
      CALL NM_TimeInt_HHT_Compute_Effective_Force(integrator, F_int, u, R_effective)
      
      ! 2. 组装残余�?
      DO i = 1, ndofs
        R(i) = (1.0_wp + integrator%alpha_m) * F_ext(i)
        R(i) = R(i) - DOT_PRODUCT(M%data(i,:), a)
        R(i) = R(i) - DOT_PRODUCT(C%data(i,:), v)
        R(i) = R(i) - R_effective(i)
      END DO
      
      ! 3. 收敛检�?
      residual_norm = SQRT(DOT_PRODUCT(R, R))
      IF (residual_norm < tol) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! 4. 构建有效刚度
      CALL Build_HHT_Effective_Stiffness(integrator, M, C, K_tan, K_eff)
      
      ! 5. 求解线性系�?
      CALL NM_TimeInt_Dense_LU_Solve(ndofs, K_eff, R, delta_u, info_ls)
      
      ! 6. 更新位移
      u = u + delta_u
      
      ! 7. 更新加速度和速度（Newmark 关系�?
      DO CONCURRENT (i = 1:ndofs)
        a(i) = integrator%a0 * (u(i) - integrator%u_old(i)) - &
               integrator%a1 * integrator%v_old(i) - integrator%a2 * integrator%a_old(i)
        
        v(i) = integrator%v_old(i) + integrator%gamma * integrator%dt * a(i) + &
               (1.0_wp - integrator%gamma) * integrator%dt * integrator%a_old(i)
      END DO
      
    END DO
    
    DEALLOCATE(R, K_eff, delta_u, R_effective)
  END SUBROUTINE NM_TimeInt_HHT_Equilibrium_Iteration
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Compute_Effective_Force
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Compute_Effective_Force(integrator, F_int, u, R_eff)
    ! 计算 HHT 有效内力
    ! R_eff = (1+alpha_f)*R(u) - alpha_f*R_old
    
    CLASS(HHTIntegrator), INTENT(IN) :: integrator
    REAL(wp), INTENT(IN) :: F_int(:), u(:)
    REAL(wp), INTENT(OUT) :: R_eff(:)
    INTEGER(i4) :: i, ndofs
    
    ndofs = integrator%ndofs
    
    ! 优化：DO CONCURRENT 并行�?
    ! 伪代码：R_eff[i] = (1+alpha_f)*F_int[i] - alpha_f*R_old[i]
    DO CONCURRENT (i = 1:ndofs)
      R_eff(i) = (1.0_wp + integrator%alpha_f) * F_int(i) - &
                 integrator%alpha_f * integrator%R_old(i)
    END DO
  END SUBROUTINE NM_TimeInt_HHT_Compute_Effective_Force
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_HHT_Update_History
  !===========================================================================
  SUBROUTINE NM_TimeInt_HHT_Update_History(integrator, u_new, v_new, a_new, R_new)
    ! 更新 HHT 历史变量
    
    CLASS(HHTIntegrator), INTENT(INOUT) :: integrator
    REAL(wp), INTENT(IN) :: u_new(:), v_new(:), a_new(:), R_new(:)
    
    ! 数组整体赋值（编译器优化为块拷贝）
    integrator%u_old = u_new
    integrator%v_old = v_new
    integrator%a_old = a_new
    integrator%R_old = R_new
  END SUBROUTINE NM_TimeInt_HHT_Update_History
  
  !===========================================================================
  ! AUXILIARY: Build_HHT_Effective_Stiffness
  !===========================================================================
  SUBROUTINE Build_HHT_Effective_Stiffness(integrator, M, C, K_tan, K_eff)
    ! 构建 HHT 有效刚度矩阵
    ! K_eff = a0*M + a1*C + (1+alpha_f)*K_tangent
    
    CLASS(HHTIntegrator), INTENT(IN) :: integrator
    TYPE(DenseMatrix), INTENT(IN) :: M, C, K_tan
    REAL(wp), INTENT(OUT) :: K_eff(:,:)
    INTEGER(i4) :: i, j, n
    
    n = M%nrows
    
    DO j = 1, n
      DO i = 1, n
        K_eff(i, j) = integrator%a0 * M%data(i, j) + &
                      integrator%a1 * C%data(i, j) + &
                      (1.0_wp + integrator%alpha_f) * K_tan%data(i, j)
      END DO
    END DO
  END SUBROUTINE Build_HHT_Effective_Stiffness
  
END MODULE NM_TimeInt_HHT