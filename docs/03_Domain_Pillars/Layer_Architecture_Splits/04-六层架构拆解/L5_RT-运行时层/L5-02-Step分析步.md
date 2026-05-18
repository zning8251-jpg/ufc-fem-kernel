# L5_RT Step分析步

> **文档位置**：`六层架构拆分/04-六层架构拆解/L5_RT-运行时层/L5-02-Step分析步.md`  
> **来源章节**：原文档相关章节  
> **最后更新**：2026-02-17  
> **相关文档**：[运行时层总览](L5-01-运行时层总览.md)、[求解器控制](L5-06-分析类型完整手册.md)

---

## 概述

L5_RT层的Step分析步是有限元分析的核心控制流程，负责管理分析步循环、增量步控制、迭代求解、收敛判断等运行时操作。这是连接前处理模型定义和后处理结果输出的关键环节。

**核心功能**：

- Step分析步循环
- Increment增量步控制
- Newton-Raphson迭代循环
- 收敛判断（力收敛、位移收敛、能量收敛）
- 自动增量步调整
- 载荷增量控制

## Step分析步结构

### Step定义

```fortran
TYPE, PUBLIC :: RT_StepDesc
    CHARACTER(LEN=64) :: step_name = ""            ! 分析步名称
    INTEGER(i4) :: step_number = 0                 ! 分析步编号
    INTEGER(i4) :: procedure_type = 0              ! 分析过程类型
    INTEGER(i4) :: max_increments = 1000            ! 最大增量步数
    REAL(wp) :: initial_increment = 1.0_wp         ! 初始增量步长
    REAL(wp) :: min_increment = 1.0E-12_wp         ! 最小增量步长
    REAL(wp) :: max_increment = 1.0_wp             ! 最大增量步长
    LOGICAL :: use_automatic_increment = .TRUE.    ! 自动增量步控制
END TYPE RT_StepDesc
```

### 分析过程类型

- **STATIC**：静力分析
- **DYNAMIC**：动力分析（隐式）
- **DYNAMIC, EXPLICIT**：显式动力分析
- **FREQUENCY**：频率提取
- **BUCKLE**：屈曲分析
- **HEAT TRANSFER**：热传导分析
- **COUPLED TEMPERATURE-DISPLACEMENT**：热力耦合分析

## Step执行流程

### 整体流程

```
1. Step初始化
   - 分配工作空间
   - 初始化增量步参数
   - 设置求解器配置

2. Increment循环（n = 1 to max_increments）
   a. 计算增量步大小 Δt
   b. 预测位移 u_predict
   c. Newton-Raphson迭代循环
      - 计算残差 R
      - 计算切线刚度 K_T
      - 求解线性系统 K_T·Δu = R
      - 更新位移 u
      - 收敛检查
   d. 如果收敛：继续下一个增量步
   e. 如果不收敛：切割增量步，重新开始

3. Step完成
   - 提取结果
   - 清理工作空间
```

### Step初始化

```fortran
SUBROUTINE RT_Step_Init(step_desc, model, step_ctx, status)
    TYPE(RT_StepDesc), INTENT(IN) :: step_desc
    TYPE(MD_ModelDesc), INTENT(IN) :: model
    TYPE(RT_Step_Ctx), INTENT(OUT) :: step_ctx
    INTEGER(i4), INTENT(OUT) :: status
    
    ! 1. 分配工作空间
    CALL RT_AllocateWorkspace(step_desc, step_ctx%workspace, status)
    
    ! 2. 初始化增量步参数
    step_ctx%increment_size = step_desc%initial_increment
    step_ctx%current_increment = 0
    
    ! 3. 设置求解器配置
    CALL RT_SetupSolverConfig(step_desc, step_ctx%solver_cfg, status)
    
    ! 4. 初始化状态变量
    CALL RT_InitializeStateVars(model, step_ctx%state, status)
END SUBROUTINE
```

## Increment增量步控制

### 增量步循环

```fortran
SUBROUTINE RT_Step_RunIncrement(step_ctx, increment_num, converged, status)
    TYPE(RT_Step_Ctx), INTENT(INOUT) :: step_ctx
    INTEGER(i4), INTENT(IN) :: increment_num
    LOGICAL, INTENT(OUT) :: converged
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: dt, lambda, delta_lambda
    REAL(wp), ALLOCATABLE :: u_predict(:)
    
    ! 1. 计算增量步大小
    CALL RT_ComputeIncrementSize(step_ctx, increment_num, dt)
    
    ! 2. 计算载荷增量
    delta_lambda = dt * step_ctx%load_factor
    lambda = step_ctx%lambda_old + delta_lambda
    
    ! 3. 预测位移
    CALL RT_PredictDisplacement(step_ctx, u_predict)
    
    ! 4. Newton-Raphson迭代
    CALL RT_NewtonRaphsonIteration(step_ctx, u_predict, lambda, converged, status)
    
    IF (converged) THEN
        ! 5. 更新状态
        step_ctx%lambda = lambda
        step_ctx%u = u_predict
        step_ctx%current_increment = increment_num
        
        ! 6. 自适应增量步调整
        IF (step_ctx%step_desc%use_automatic_increment) THEN
            CALL RT_AdjustIncrementSize(step_ctx, increment_num)
        END IF
    ELSE
        ! 7. 增量步切割
        CALL RT_CutIncrement(step_ctx, increment_num, status)
    END IF
END SUBROUTINE
```

### 自动增量步控制

**自适应策略**：

```
if 迭代次数 < 理想迭代次数下限:
    增大增量步：dt_new = dt_old * factor_increase
else if 迭代次数 > 理想迭代次数上限:
    减小增量步：dt_new = dt_old * factor_decrease
else:
    保持增量步：dt_new = dt_old
```

**增量步调整因子**：

- **增长因子**：通常1.25（如果迭代次数少，可以增大步长）
- **减小因子**：通常0.75（如果迭代次数多，需要减小步长）
- **理想迭代次数**：通常5-8次

## Newton-Raphson迭代循环

### 迭代流程

```fortran
SUBROUTINE RT_NewtonRaphsonIteration(step_ctx, u_init, lambda, converged, status)
    TYPE(RT_Step_Ctx), INTENT(INOUT) :: step_ctx
    REAL(wp), INTENT(INOUT) :: u_init(:)
    REAL(wp), INTENT(IN) :: lambda
    LOGICAL, INTENT(OUT) :: converged
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp), ALLOCATABLE :: R(:), K_T(:,:), du(:)
    INTEGER(i4) :: iter
    
    converged = .FALSE.
    
    DO iter = 1, step_ctx%solver_cfg%max_iterations
        ! 1. 组装残差向量
        CALL RT_AssembleResidual(step_ctx, u_init, lambda, R, status)
        
        ! 2. 组装切线刚度矩阵
        CALL RT_AssembleTangentStiffness(step_ctx, u_init, K_T, status)
        
        ! 3. 求解线性系统
        CALL NM_Solve_Linear(K_T, R, du, step_ctx%solver_cfg%linear_cfg, status)
        
        ! 4. 更新位移
        u_init = u_init + du
        
        ! 5. 收敛检查
        CALL RT_CheckConvergence(R, du, step_ctx%solver_cfg, converged, status)
        
        IF (converged) THEN
            step_ctx%iteration_count = iter
            EXIT
        END IF
        
        ! 6. 发散检测
        IF (RT_CheckDivergence(R, step_ctx%solver_cfg)) THEN
            status = STATUS_DIVERGED
            RETURN
        END IF
    END DO
    
    IF (.NOT. converged) THEN
        status = STATUS_NOT_CONVERGED
    END IF
END SUBROUTINE
```

### 残差组装

```fortran
SUBROUTINE RT_AssembleResidual(step_ctx, u, lambda, R, status)
    TYPE(RT_Step_Ctx), INTENT(INOUT) :: step_ctx
    REAL(wp), INTENT(IN) :: u(:)
    REAL(wp), INTENT(IN) :: lambda
    REAL(wp), INTENT(OUT) :: R(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp), ALLOCATABLE :: F_int(:), F_ext(:)
    
    ! 1. 计算内力向量
    CALL RT_AssembleInternalForce(step_ctx, u, F_int, status)
    
    ! 2. 计算外载荷向量
    F_ext = lambda * step_ctx%reference_load
    
    ! 3. 残差 = 外载荷 - 内力
    R = F_ext - F_int
END SUBROUTINE
```

### 切线刚度组装

```fortran
SUBROUTINE RT_AssembleTangentStiffness(step_ctx, u, K_T, status)
    TYPE(RT_Step_Ctx), INTENT(INOUT) :: step_ctx
    REAL(wp), INTENT(IN) :: u(:)
    REAL(wp), INTENT(OUT) :: K_T(:,:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i_elem
    REAL(wp), ALLOCATABLE :: K_elem(:,:)
    
    K_T = 0.0_wp
    
    ! 单元循环
    DO i_elem = 1, step_ctx%model%num_elements
        ! 计算单元切线刚度矩阵
        CALL PH_ComputeElementTangentStiffness(step_ctx, i_elem, u, K_elem, status)
        
        ! 组装到全局矩阵
        CALL RT_AssembleElementToGlobal(K_T, K_elem, step_ctx%model%elements(i_elem), status)
    END DO
END SUBROUTINE
```

## 收敛判断

### 力收敛

```
||R|| / ||F_ref|| < tol_force

其中：
- ||R||：残差向量范数
- ||F_ref||：参考载荷向量范数
- tol_force：力收敛容差（默认1.0E-6）
```

### 位移收敛

```
||Δu|| / ||u|| < tol_disp

其中：
- ||Δu||：位移增量范数
- ||u||：当前位移范数
- tol_disp：位移收敛容差（默认1.0E-6）
```

### 能量收敛

```
|Δu^T · R| / |Δu₀^T · R₀| < tol_energy

其中：
- Δu^T · R：能量增量
- Δu₀^T · R₀：初始能量增量
- tol_energy：能量收敛容差（默认1.0E-6）
```

### 收敛检查实现

```fortran
SUBROUTINE RT_CheckConvergence(R, du, solver_cfg, converged, status)
    REAL(wp), INTENT(IN) :: R(:), du(:)
    TYPE(RT_SolverConfig), INTENT(IN) :: solver_cfg
    LOGICAL, INTENT(OUT) :: converged
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: force_norm, disp_norm, energy_increment
    LOGICAL :: force_conv, disp_conv, energy_conv
    
    ! 力收敛
    force_norm = NORM2(R) / NORM2(solver_cfg%reference_load)
    force_conv = (force_norm < solver_cfg%tolerance_force)
    
    ! 位移收敛
    disp_norm = NORM2(du) / MAX(NORM2(solver_cfg%u_current), 1.0E-10_wp)
    disp_conv = (disp_norm < solver_cfg%tolerance_displacement)
    
    ! 能量收敛
    energy_increment = ABS(DOT_PRODUCT(du, R))
    energy_conv = (energy_increment < solver_cfg%tolerance_energy * solver_cfg%energy_reference)
    
    ! 综合收敛判断（需要同时满足力收敛和位移/能量收敛）
    converged = force_conv .AND. (disp_conv .OR. energy_conv)
    
    status = IF_STATUS_OK
END SUBROUTINE
```

## 增量步切割

### 切割策略

当迭代不收敛时，需要切割增量步：

```
1. 恢复上一增量步的状态
2. 减小增量步长：dt_new = dt_old * cut_factor（通常0.5）
3. 重新开始当前增量步
4. 如果切割次数 > max_cuts：停止计算
```

### 切割实现

```fortran
SUBROUTINE RT_CutIncrement(step_ctx, increment_num, status)
    TYPE(RT_Step_Ctx), INTENT(INOUT) :: step_ctx
    INTEGER(i4), INTENT(IN) :: increment_num
    INTEGER(i4), INTENT(OUT) :: status
    
    ! 1. 检查切割次数
    IF (step_ctx%cuts >= step_ctx%step_desc%max_cuts) THEN
        status = STATUS_MAX_CUTS_EXCEEDED
        RETURN
    END IF
    
    ! 2. 恢复上一增量步状态
    CALL RT_RestorePreviousIncrement(step_ctx, status)
    
    ! 3. 减小增量步长
    step_ctx%increment_size = step_ctx%increment_size * step_ctx%step_desc%cut_factor
    
    ! 4. 检查最小增量步长
    IF (step_ctx%increment_size < step_ctx%step_desc%min_increment) THEN
        status = STATUS_MIN_INCREMENT_REACHED
        RETURN
    END IF
    
    ! 5. 增加切割计数
    step_ctx%cuts = step_ctx%cuts + 1
    
    ! 6. 重新开始增量步
    CALL RT_Step_RunIncrement(step_ctx, increment_num, converged, status)
END SUBROUTINE
```

## Step执行主循环

### 完整Step执行

```fortran
SUBROUTINE RT_Step_Run(step_desc, model, results, status)
    TYPE(RT_StepDesc), INTENT(IN) :: step_desc
    TYPE(MD_ModelDesc), INTENT(IN) :: model
    TYPE(RT_Results), INTENT(OUT) :: results
    INTEGER(i4), INTENT(OUT) :: status
    
    TYPE(RT_Step_Ctx) :: step_ctx
    LOGICAL :: converged
    INTEGER(i4) :: increment_num
    
    ! 1. Step初始化
    CALL RT_Step_Init(step_desc, model, step_ctx, status)
    IF (status /= IF_STATUS_OK) RETURN
    
    ! 2. Increment循环
    DO increment_num = 1, step_desc%max_increments
        CALL RT_Step_RunIncrement(step_ctx, increment_num, converged, status)
        
        IF (status == STATUS_MAX_CUTS_EXCEEDED .OR. &
            status == STATUS_MIN_INCREMENT_REACHED) THEN
            EXIT
        END IF
        
        IF (.NOT. converged) THEN
            ! 增量步切割后重试
            CYCLE
        END IF
        
        ! 3. 提取结果
        CALL RT_ExtractResults(step_ctx, increment_num, results, status)
        
        ! 4. 检查Step完成条件
        IF (RT_CheckStepComplete(step_ctx, step_desc)) THEN
            EXIT
        END IF
    END DO
    
    ! 5. Step清理
    CALL RT_Step_Cleanup(step_ctx, status)
END SUBROUTINE
```

## 使用示例

```fortran
USE RT_Step_Module
USE MD_Model_Def

TYPE(RT_StepDesc) :: step_desc
TYPE(MD_ModelDesc) :: model
TYPE(RT_Results) :: results
INTEGER(i4) :: status

! 配置分析步
step_desc%step_name = "StaticAnalysis"
step_desc%procedure_type = PROCEDURE_STATIC
step_desc%max_increments = 100
step_desc%initial_increment = 1.0_wp
step_desc%use_automatic_increment = .TRUE.

! 执行分析步
CALL RT_Step_Run(step_desc, model, results, status)

IF (status == IF_STATUS_OK) THEN
    WRITE(*,*) '分析步完成'
    WRITE(*,*) '增量步数：', results%num_increments
    WRITE(*,*) '总迭代次数：', results%total_iterations
ELSE
    WRITE(*,*) '分析步失败，错误码：', status
END IF
```

---

## 相关文档

- [运行时层总览](L5-01-运行时层总览.md)
- [求解器控制](L5-06-分析类型完整手册.md)
- [返回六层详解](../README.md)

