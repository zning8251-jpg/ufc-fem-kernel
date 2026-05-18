# 01. L5_RT_StepDriver (分析步驱动) 闭环落地设计与十件套固化

## 1. 业务职责与边界

`L5_RT_StepDriver` 位于 UFC 运行时的最高层（除 L6_AP 作业调度之外），其核心职责是**控制非线性有限元求解的时间推进（Time Marching）与增量迭代（Newton-Raphson / L-BFGS）**。

在全新闭环中，`StepDriver` 不再包含具体的力学积分逻辑，而是通过标准**合同卡**向 L4_PH（Element）、L5_RT（Assembly）以及 L5_RT（Solver）发送指令，扮演“交响乐指挥家”的角色。

---

## 2. 域级合同卡 (Domain Contract)

`StepDriver` 暴露给 L6_AP 层的调用合同如下：

```yaml
# 域级合同卡：L5_RT_StepDriver
Interface: RT_StepDriver_Run
Description: 驱动单步分析（Step）的执行，完成指定载荷下的非线性收敛。
Inputs:
  - job_desc (RT_StepDrv_Desc, IN)      : 当前分析步的参数配置（最大增量步、容差、最大迭代次数等）。
  - job_state (RT_StepDrv_State, INOUT) : 分析步全局状态（当前时间步、当前增量号、收敛标识、全局位移U）。
  - job_ctx (RT_StepDrv_Ctx, INOUT)     : 运行时上下文工作空间（包含全局残余力向量 R、临时位移增量 dU、单元计算所需的缓存池）。
Outputs:
  - status (ErrorStatusType, OUT)       : 分析步执行状态（如 Cut-back 失败、达到最大迭代次数等）。
```

### 与下层域的联动契约：
- **装配请求**：向 `RT_Asm` 发起 `RT_Asm_Reset`、`RT_Asm_AddElemStiff_Structured` 操作。
- **单元计算请求**：提取特定单元的切片配置 `elem_cfg`、状态 `elem_state`、上下文 `elem_ctx`，并调用 `PH_Elem_Compute(elem_cfg, elem_state, elem_ctx, mat_cfg, status)`。
- **求解请求**：向 `RT_Solv` 传递 CSR 稀疏刚度矩阵与残差向量，索要位移增量，即 `RT_Solv_Bridge_Unified(K_csr, f_residual, dU)`。

---

## 3. 十件套 (Ten-Piece Set) 物理固化映射

为了确保该域的整洁，将 `RT_StepDriver` 拆解为以下十件套代码结构，部署于 `ufc_core/L5_RT/StepDriver/`：

| 模块名 | 对应十件套 | 核心内容 / 属性列表 |
|---|---|---|
| `RT_StepDrv_Def.f90` | _Def | 迭代控制策略枚举（如 `NR_STANDARD`, `L_BFGS`, `ARC_LENGTH_CW`）。 |
| `RT_StepDrv_Desc.f90` | _Desc | `RT_StepDrv_Desc` 类型：`initial_dt`, `max_increments`, `max_iterations`, `force_tol`, `energy_tol` 等常量配置。 |
| `RT_StepDrv_State.f90` | _State | `RT_StepDrv_State` 类型：`current_time`, `current_increment`, `step_converged`。这是持久化的场状态。 |
| `RT_StepDrv_Ctx.f90` | _Ctx | `RT_StepDrv_Ctx` 类型：包含全局大小的数组 `f_residual(:)`，`dU_global(:)` 以及单元计算环境池 `elem_ctx_pool(:)`。 |
| `RT_StepDrv.f90`（旧称 `RT_StepDrv_Algo.f90`） | _Algo | `Algo_NewtonRaphson_Loop` 等无状态核心迭代控制算法（计算残差范数、能量范数、更新步长 dt）。 |
| `RT_StepDriver_Brg.f90` | _Brg | **本域防腐门面**。持有 `RT_StepDriver_Run` 例程，承接上层调用并组装 `_Algo`。 |
| `RT_StepDrv_Reg.f90` | _Reg | 用于注册并分发不同类型的分析步（Static, Dynamic, Riks）。 |
| `RT_StepDrv_Err.f90` | _Err | `ERR_NONLINEAR_DIVERGENCE`, `ERR_MAX_CUTBACK_REACHED`。 |
| `RT_StepDrv_Util.f90` | _Util | 日志输出工具，如 `Print_Iteration_Convergence_Info()`。 |
| `RT_StepDrv_Test.f90` | _Test | 在不连接实际物理单元的情况下，使用 Dummy Matrix 测试 NR 逻辑能否正确 Cut-back 的测试例程。 |

---

## 4. 核心逻辑流转 (Algorithm Flow)

`RT_StepDriver_Algo` 中的牛顿迭代流转设计如下：

1. **增量步级初始化 (Increment Setup)**：
   - 提取 `current_dt`，初始化本增量步累积位移增量 $\Delta U = 0$。
2. **非线性迭代内循环 (Nonlinear Iteration)**：
   - **Step A: 装配准备** -> 调用 `RT_Asm_Ctx` 清零全局刚度与残余力 $R = 0$。
   - **Step B: 黄金遍历** -> `$OMP PARALLEL DO` 遍历所有单元：
     - 为每个线程分配私有 `elem_ctx`。
     - 调用 `PH_Elem_Compute` 计算局部 $K_e$ 与 $R_{int}$。
     - 将计算结果写入局部 Thread 缓存，最后规约注入到 CSR `K_csr` 和全局 $R$。
   - **Step C: 收敛性检查** -> 若 $||R|| < \text{Tol}_{force}$ 或能量满足准则，跳出循环，该增量步收敛。
   - **Step D: 方程组求解** -> 调用 `RT_Solv_Bridge_Unified` 求解 $\delta U = K^{-1} R$。
   - **Step E: 状态更新** -> 演化全局状态 $U = U + \delta U$。
3. **后处理与推进**：
   - 如果发生发散（Divergence），执行步长折减（Cut-back）并重试，直至达到最大重试次数。
   - 若收敛，将 `current_time` 前进 `current_dt`，提交并归档当前增量步结果（写入历史文件）。

---

## 5. 待执行动作清单 (Action Items)

- [ ] 在 `ufc_core/L5_RT/StepDriver/` 创建/重构缺失的十件套文件。
- [ ] 净化 `RT_StepDriver_Run`，确保没有任何硬编码的数组维度，完全依赖 `job_ctx` 动态分配的空间。
- [ ] 确保与 `RT_Asm` (组装模块) 的交接过程无缝且线程安全。