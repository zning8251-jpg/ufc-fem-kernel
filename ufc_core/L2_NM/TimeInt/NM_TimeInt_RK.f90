!===============================================================================
! MODULE: NM_TimeInt_RK
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Runge-Kutta time integration (RK4 + adaptive step control)
! BRIEF:  Classic RK4 with Fehlberg error estimation and step adaptation
!===============================================================================
MODULE NM_TimeInt_RK
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_TimeInt_Def, ONLY: RKIntegrator
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: NM_TimeInt_RK4_Integrate
  PUBLIC :: NM_TimeInt_RK_Compute_Stage
  PUBLIC :: NM_TimeInt_RK_Update_Solution
  PUBLIC :: NM_TimeInt_RK_Adaptive_Step
  
CONTAINS
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_RK4_Integrate
  !===========================================================================
  SUBROUTINE NM_TimeInt_RK4_Integrate(integrator, dydt, t, y, dt)
    ! 经典 RK4 积分（固定步长）
    ! 伪代码：
    ! k1 = f(t, y)
    ! k2 = f(t+dt/2, y+dt*k1/2)
    ! k3 = f(t+dt/2, y+dt*k2/2)
    ! k4 = f(t+dt, y+dt*k3)
    ! y_new = y + dt*(b1*k1 + b2*k2 + b3*k3 + b4*k4)
    
    CLASS(RKIntegrator), INTENT(INOUT) :: integrator
    INTERFACE
      SUBROUTINE dydt(t, y, dydt_vec)
        IMPORT :: wp
        REAL(wp), INTENT(IN) :: t, y(:)
        REAL(wp), INTENT(OUT) :: dydt_vec(:)
      END SUBROUTINE
    END INTERFACE
    REAL(wp), INTENT(INOUT) :: t, y(:)
    REAL(wp), INTENT(IN) :: dt
    INTEGER(i4) :: i, ndofs
    REAL(wp) :: t_temp
    REAL(wp), ALLOCATABLE :: y_temp(:)
    
    ! 验证初始�?
    IF (.NOT. integrator%is_initialized) THEN
      ERROR STOP "NM_TimeInt_RK4_Integrate: RK integrator not initialized"
    END IF
    
    ndofs = integrator%ndofs
    ALLOCATE(y_temp(ndofs))
    
    !-------------------------------------------------------------------------
    ! 步骤 1: 计算 k1 = f(t, y)
    !-------------------------------------------------------------------------
    CALL dydt(t, y, integrator%k1)
    
    !-------------------------------------------------------------------------
    ! 步骤 2: 计算 k2 = f(t+dt/2, y+dt*k1/2)
    !-------------------------------------------------------------------------
    t_temp = t + 0.5_wp * dt
    DO CONCURRENT (i = 1:ndofs)
      y_temp(i) = y(i) + 0.5_wp * dt * integrator%k1(i)
    END DO
    CALL dydt(t_temp, y_temp, integrator%k2)
    
    !-------------------------------------------------------------------------
    ! 步骤 3: 计算 k3 = f(t+dt/2, y+dt*k2/2)
    !-------------------------------------------------------------------------
    DO CONCURRENT (i = 1:ndofs)
      y_temp(i) = y(i) + 0.5_wp * dt * integrator%k2(i)
    END DO
    CALL dydt(t_temp, y_temp, integrator%k3)
    
    !-------------------------------------------------------------------------
    ! 步骤 4: 计算 k4 = f(t+dt, y+dt*k3)
    !-------------------------------------------------------------------------
    t_temp = t + dt
    DO CONCURRENT (i = 1:ndofs)
      y_temp(i) = y(i) + dt * integrator%k3(i)
    END DO
    CALL dydt(t_temp, y_temp, integrator%k4)
    
    !-------------------------------------------------------------------------
    ! 步骤 5: 更新�?y_new = y + dt*(b1*k1 + b2*k2 + b3*k3 + b4*k4)
    !-------------------------------------------------------------------------
    ! 优化：使�?Butcher 系数加权求和
    DO CONCURRENT (i = 1:ndofs)
      y(i) = y(i) + dt * (integrator%b1 * integrator%k1(i) + &
                         integrator%b2 * integrator%k2(i) + &
                         integrator%b3 * integrator%k3(i) + &
                         integrator%b4 * integrator%k4(i))
    END DO
    
    ! 更新时间
    t = t + dt
    
    DEALLOCATE(y_temp)
  END SUBROUTINE NM_TimeInt_RK4_Integrate
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_RK_Compute_Stage
  !===========================================================================
  SUBROUTINE NM_TimeInt_RK_Compute_Stage(integrator, stage, dydt, t, y, dt, k_stage)
    ! 计算 RK 中间级斜�?
    ! 通用接口，支持任意级�?
    
    CLASS(RKIntegrator), INTENT(IN) :: integrator
    INTEGER(i4), INTENT(IN) :: stage
    INTERFACE
      SUBROUTINE dydt(t, y, dydt_vec)
        IMPORT :: wp
        REAL(wp), INTENT(IN) :: t, y(:)
        REAL(wp), INTENT(OUT) :: dydt_vec(:)
      END SUBROUTINE
    END INTERFACE
    REAL(wp), INTENT(IN) :: t, y(:), dt
    REAL(wp), INTENT(OUT) :: k_stage(:)
    INTEGER(i4) :: i, ndofs
    REAL(wp) :: t_eval
    REAL(wp), ALLOCATABLE :: y_eval(:)
    
    ndofs = integrator%ndofs
    ALLOCATE(y_eval(ndofs))
    
    SELECT CASE(stage)
    CASE(1)
      ! k1 = f(t, y)
      t_eval = t
      y_eval = y
      
    CASE(2)
      ! k2 = f(t+c2*dt, y+dt*a21*k1)
      t_eval = t + integrator%c2 * dt
      DO CONCURRENT (i = 1:ndofs)
        y_eval(i) = y(i) + dt * integrator%a21 * integrator%k1(i)
      END DO
      
    CASE(3)
      ! k3 = f(t+c3*dt, y+dt*(a31*k1+a32*k2))
      t_eval = t + integrator%c3 * dt
      DO CONCURRENT (i = 1:ndofs)
        y_eval(i) = y(i) + dt * (integrator%a31 * integrator%k1(i) + &
                                integrator%a32 * integrator%k2(i))
      END DO
      
    CASE(4)
      ! k4 = f(t+c4*dt, y+dt*(a41*k1+a42*k2+a43*k3))
      t_eval = t + integrator%c4 * dt
      DO CONCURRENT (i = 1:ndofs)
        y_eval(i) = y(i) + dt * (integrator%a41 * integrator%k1(i) + &
                                integrator%a42 * integrator%k2(i) + &
                                integrator%a43 * integrator%k3(i))
      END DO
      
    CASE DEFAULT
      ERROR STOP "NM_TimeInt_RK_Compute_Stage: invalid RK stage"
    END SELECT
    
    ! 计算该级斜率
    CALL dydt(t_eval, y_eval, k_stage)
    
    DEALLOCATE(y_eval)
  END SUBROUTINE NM_TimeInt_RK_Compute_Stage
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_RK_Update_Solution
  !===========================================================================
  SUBROUTINE NM_TimeInt_RK_Update_Solution(integrator, y, dt)
    ! 使用 RK 斜率更新�?
    ! y_new = y + dt*SUM(b_i*k_i)
    
    CLASS(RKIntegrator), INTENT(IN) :: integrator
    REAL(wp), INTENT(INOUT) :: y(:)
    REAL(wp), INTENT(IN) :: dt
    INTEGER(i4) :: i, ndofs
    
    ndofs = integrator%ndofs
    
    ! 优化：DO CONCURRENT 并行�?
    ! 伪代码：y[i] += dt*(b1*k1[i] + b2*k2[i] + b3*k3[i] + b4*k4[i])
    DO CONCURRENT (i = 1:ndofs)
      y(i) = y(i) + dt * (integrator%b1 * integrator%k1(i) + &
                         integrator%b2 * integrator%k2(i) + &
                         integrator%b3 * integrator%k3(i) + &
                         integrator%b4 * integrator%k4(i))
    END DO
  END SUBROUTINE NM_TimeInt_RK_Update_Solution
  
  !===========================================================================
  ! SUBROUTINE: NM_TimeInt_RK_Adaptive_Step
  !===========================================================================
  SUBROUTINE NM_TimeInt_RK_Adaptive_Step(integrator, dydt, t, y, dt, success)
    ! 自适应步长 RK 方法（Fehlberg 嵌入误差估计�?
    ! 策略�?
    ! 1. 用当�?dt 计算 RK4 �?y1
    ! 2. 用两�?dt/2 步计�?RK4 �?y2
    ! 3. 估计误差 e = |y1 - y2|
    ! 4. 如果 e > tol，减�?dt 并重�?
    ! 5. 如果 e << tol，增�?dt 并接收结�?
    
    CLASS(RKIntegrator), INTENT(INOUT) :: integrator
    INTERFACE
      SUBROUTINE dydt(t, y, dydt_vec)
        IMPORT :: wp
        REAL(wp), INTENT(IN) :: t, y(:)
        REAL(wp), INTENT(OUT) :: dydt_vec(:)
      END SUBROUTINE
    END INTERFACE
    REAL(wp), INTENT(INOUT) :: t, y(:)
    REAL(wp), INTENT(INOUT) :: dt
    LOGICAL, INTENT(OUT) :: success
    
    INTEGER(i4) :: i, iter, ndofs
    REAL(wp) :: t_save, dt_half, error_norm, scale
    REAL(wp), ALLOCATABLE :: y_save(:), y1(:), y2(:), error(:)
    
    ndofs = integrator%ndofs
    success = .FALSE.
    
    ALLOCATE(y_save(ndofs), y1(ndofs), y2(ndofs), error(ndofs))
    
    ! 保存初始状�?
    y_save = y
    t_save = t
    
    !-------------------------------------------------------------------------
    ! 自适应迭代循环
    !-------------------------------------------------------------------------
    DO iter = 1, 10  ! 最多尝�?10 �?
      
      !---------------------------------------------------------------------
      ! 步骤 1: �?dt 计算单步�?y1
      !---------------------------------------------------------------------
      y1 = y_save
      t = t_save
      CALL NM_TimeInt_RK4_Integrate(integrator, dydt, t, y1, dt)
      
      !---------------------------------------------------------------------
      ! 步骤 2: 用两�?dt/2 步计算双半步�?y2
      !---------------------------------------------------------------------
      y2 = y_save
      t = t_save
      dt_half = dt / 2.0_wp
      
      CALL NM_TimeInt_RK4_Integrate(integrator, dydt, t, y2, dt_half)
      CALL NM_TimeInt_RK4_Integrate(integrator, dydt, t, y2, dt_half)
      
      !---------------------------------------------------------------------
      ! 步骤 3: 计算误差估计 e = |y1 - y2|
      !---------------------------------------------------------------------
      ! 优化：使�?DOT_PRODUCT 计算 L2 范数
      DO CONCURRENT (i = 1:ndofs)
        error(i) = ABS(y1(i) - y2(i))
      END DO
      
      error_norm = SQRT(DOT_PRODUCT(error, error))
      
      !---------------------------------------------------------------------
      ! 步骤 4: 自适应步长控制
      !---------------------------------------------------------------------
      ! 计算缩放因子 scale = safety * (tol/error)^(1/5)
      ! 对于 RK4，阶�?p=4，使�?1/(p+1) = 1/5
      IF (error_norm > integrator%tol_abs) THEN
        scale = integrator%safety * (integrator%tol_rel / error_norm)**0.2_wp
      ELSE
        scale = 2.0_wp  ! 误差很小，直接加�?
      END IF
      
      ! 检查是否满足容�?
      IF (error_norm <= integrator%tol_rel) THEN
        ! 接受该步
        y = y1
        t = t_save + dt
        success = .TRUE.
        
        ! 建议下一步步�?
        IF (scale > 1.0_wp) THEN
          dt = MIN(dt * scale, integrator%dt_max)
        END IF
        
        EXIT
      ELSE
        ! 拒绝该步，减小步长重�?
        dt = MAX(dt * scale, integrator%dt_min)
        
        IF (dt <= integrator%dt_min) THEN
          EXIT
        END IF
      END IF
      
    END DO
    
    IF (.NOT. success) THEN
      ! 恢复初始状�?
      y = y_save
      t = t_save
    END IF
    
    DEALLOCATE(y_save, y1, y2, error)
  END SUBROUTINE NM_TimeInt_RK_Adaptive_Step
  
END MODULE NM_TimeInt_RK