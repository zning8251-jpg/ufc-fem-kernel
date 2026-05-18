# 第 17 件：Iterator (高级迭代与路径控制件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/04_第17件_Iterator_非线性控制件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 17 件  
> **目标**：将弧长法 (ARC-CW)、L-BFGS、显式控制等高级/非标策略与主线求解器解耦，并提供强健的状态试错与回滚能力。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **策略解耦 (Strategy Decoupling)**：标准的 `RT_SolvLin.f90` 只能看到矩阵 $K$ 和残差 $R$，不应知道当前正在缩放载荷弧长。控制逻辑需反转至 Iterator。
2. **状态双缓冲与试错 (State Rollback)**：遇到负主元或材料软化极值点，Iterator 需要撤销当次迭代，回退到步初状态并调整步长/弧长再试。

### 1.2 架构红线 (Red Lines)
- **绝对禁止单缓冲**：涉及 Iterator 调用的域，`_State` 必须维持至少双缓冲：即 `_State_t0` (步初收敛状态) 和 `_State_t1` (当前迭代尝试状态)。
- **IoC 回调隔离**：Iterator 模块只能通过接口指针（`PROCEDURE POINTER`）注入给主求解器，主求解器严禁使用硬编码 `IF (is_arc_length) THEN...`。

---

## 2. 核心架构时序与机制

1. **[Step Start]**：主循环开始，触发全部状态复制 `_State_t1 = _State_t0`。
2. **[Iter Loop]**：进入牛顿下山。主求解器计算出位移增量 $du$。
3. **[Callback]**：主求解器呼叫注入的 `Iterator_Update_Multiplier`。Iterator（如弧长法）根据 $du$ 和残差，计算出新的载荷乘子 $\lambda$。
4. **[Check & Rollback]**：如果发散，Iterator 触发 `Rollback`，`_State_t1` 被清空恢复为 `_State_t0`，并调整步长重启。
5. **[Step Commit]**：如果收敛，Iterator 触发 `Commit`，将 `_State_t0` 更新为 `_State_t1`。

---

## 3. 伪代码模板与合同定义

### 3.1 Iterator 上下文与回调注入
```fortran
!=============================================================================
! MODULE: RT_IterArcLength
! 描述: 弧长法控制件
!=============================================================================
MODULE RT_IterArcLength
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: Iterator_ARC_Init
    PUBLIC :: Iterator_ARC_Update
    
    !> 回调函数接口签名 (Inversion of Control)
    ABSTRACT INTERFACE
        SUBROUTINE I_Update_Strategy(du, residual, lambda, status)
            REAL*8, INTENT(IN) :: du(:), residual(:)
            REAL*8, INTENT(INOUT) :: lambda
            INTEGER, INTENT(OUT) :: status
        END SUBROUTINE I_Update_Strategy
    END INTERFACE

    TYPE :: RT_Iter_Ctx
        PROCEDURE(I_Update_Strategy), POINTER, NOPASS :: cb_update => NULL()
        REAL*8 :: arc_radius
        ! ...
    END TYPE RT_Iter_Ctx

CONTAINS

    !> 初始化注入
    SUBROUTINE Iterator_ARC_Init(ctx)
        TYPE(RT_Iter_Ctx), INTENT(INOUT) :: ctx
        ctx%cb_update => Iterator_ARC_Update_Impl
        ctx%arc_radius = 1.0d0
    END SUBROUTINE Iterator_ARC_Init
    
    !> 具体的弧长法乘子更新实现
    SUBROUTINE Iterator_ARC_Update_Impl(du, residual, lambda, status)
        ! 根据弧长约束方程更新 load multiplier lambda
        ! ... 复杂弧长逻辑 ...
        status = 0
    END SUBROUTINE Iterator_ARC_Update_Impl

END MODULE RT_IterArcLength
```

### 3.2 状态双缓冲管理 (State Buffering)
```fortran
!=============================================================================
! MODULE: RT_StateCtrl_Brg
! 描述: 状态提交与回滚网关
!=============================================================================
MODULE RT_StateCtrl_Brg
    ! ...
CONTAINS

    SUBROUTINE RT_State_Revert_To_T0(state_t0, state_t1)
        ! 迭代发散，丢弃当次尝试
        state_t1 = state_t0 
    END SUBROUTINE RT_State_Revert_To_T0
    
    SUBROUTINE RT_State_Commit_To_T0(state_t1, state_t0)
        ! 迭代收敛，将 t1 固化为 t0
        state_t0 = state_t1
    END SUBROUTINE RT_State_Commit_To_T0

END MODULE RT_StateCtrl_Brg
```

---

## 4. 合同检验点 (Checklist)
1. 检查主求解循环（如 `RT_SolvNonlin.f90`）中是否彻底清除了关于特定算法（如 Riks、L-BFGS）的硬编码 `IF-ELSE`。
2. 检查 `_State` 的更新流，是否只在确认收敛后才调用 `Commit` 覆盖历史数组。如果在迭代中途直接覆盖了 $t0$ 状态，则是灾难性的错误。
3. 检查 Iterator 在返回控制权时，若发现无法越过的极值点，是否能正确触发抛出 `Needs_Rollback` 的 `status` 状态码。