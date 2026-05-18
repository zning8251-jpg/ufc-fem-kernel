# 推演卡：L5_RT / StepDriver

> 推演引擎 v1.0 | 2026-04-26 | 域类型：编排域（状态机推演）

---

## [A] 意图推断

**域**：L5_RT / StepDriver

**CONTRACT 摘要**：分析步/增量/迭代三层状态机、时间增量控制、收敛判断、切回/重试逻辑。调用 L4 数值核与 L2 求解器，协调 Output/WriteBack。

**核心意图**：
- 驱动三层嵌套循环（步→增量→迭代）
- 管理时间推进和自适应步长
- 处理不收敛时的切回/重试
- 提供步/增量级生命周期管理

**Verb 族分布**：Init, Evolve, Access, Control

**Phase 分布**：Config, Step, Increment, Iteration

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | step_id, time_start/end, dt_init/min/max, max_inc, max_cutbacks | 步配置参数，分析期不变 |
| **State** | Y | step_status, inc_num, n_cutbacks, total_iters, time_current, dt | 步级演化状态，跨增量持久 |
| **Algo** | Y | cutback_factor, growth_factor, auto_dt, target_iters | 自适应策略参数，运行期只读 |
| **Ctx** | Y | dt_trial, time_at_inc_start, inc_converged, inc_iters | 增量级临时工作区 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：编排域 → 状态机

**状态机结构**：

```
Begin_Step → Loop {
  Begin_Increment → Loop {
    NR_Iteration (callback: assemble_and_solve, update_state)
    Check_Convergence
  } → End_Increment (converged → Advance | not → Cutback)
  Check_Step_Complete
} → End_Step
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(1) | 初始化四型数据 |
| S2 | Core_Finalize | Config | Init(Finalize) | O(1) | 清理步状态 |
| S3 | Begin_Step | Step | Control(Begin) | O(1) | 步开始：重置计数器，设初始 dt |
| S4 | End_Step | Step | Control(End) | O(1) | 步结束：标记 COMPLETED |
| S5 | Begin_Increment | Increment | Control(Begin) | O(1) | 增量开始：递增 inc_num，截断 dt |
| S6 | End_Increment | Increment | Control(End) | O(1) | 增量结束：收敛→推进 / 不收敛→切回 |
| S7 | Advance_Time | Increment | Evolve(Advance) | O(1) | 推进 time_current += dt_trial |
| S8 | Cutback | Increment | Control(Route) | O(1) | 切回：dt *= cutback_factor，回退 |
| S9 | Check_Step_Complete | Step | Control(Check) | O(1) | 检查是否达到 time_end |
| S10 | Get_Current_Time | (any) | Access(Get) | O(1) | 查询当前时间 |
| S11 | Get_DT | (any) | Access(Get) | O(1) | 查询当前 dt |
| S12 | NR_Increment | Iteration | Control(Loop) | O(n_iter) | Newton-Raphson 迭代循环 |
| S13 | Run_Step | Step | Control(Loop) | O(n_inc) | 完整步驱动：增量循环 + 切回 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `RT_StepDriver_Core_Init` | Config | Init | (desc, state, algo, ctx, status) | COLD | _Core.f90 |
| `RT_StepDriver_Core_Finalize` | Config | Init(Fin) | (state, ctx, status) | COLD | _Core.f90 |
| `RT_StepDriver_Begin_Step` | Step | Control(Begin) | (desc, state, ctx, status) | COLD | _Core.f90 |
| `RT_StepDriver_End_Step` | Step | Control(End) | (state, status) | COLD | _Core.f90 |
| `RT_StepDriver_Begin_Increment` | Increment | Control(Begin) | (desc, state, ctx, status) | HOT | _Core.f90 |
| `RT_StepDriver_End_Increment` | Increment | Control(End) | (desc, state, algo, ctx, converged, status) | HOT | _Core.f90 |
| `RT_StepDriver_Advance_Time` | Increment | Evolve(Advance) | (state, ctx, status) | HOT | _Core.f90 |
| `RT_StepDriver_Cutback` | Increment | Control(Route) | (desc, state, algo, ctx, status) | HOT | _Core.f90 |
| `RT_StepDriver_Check_Step_Complete` | Step | Control(Check) | (desc, state) → LOGICAL | COLD | _Core.f90 |
| `RT_StepDriver_Get_Current_Time` | (any) | Access(Get) | (state) → REAL(wp) | COLD | _Core.f90 |
| `RT_StepDriver_Get_DT` | (any) | Access(Get) | (state) → REAL(wp) | COLD | _Core.f90 |
| `RT_StepDriver_NR_Increment` | Iteration | Control(Loop) | (desc, state, algo, ctx, n_dof, u, du, callbacks, nr_tol, nr_maxiter, converged, status) | HOT | _Core.f90 |
| `RT_StepDriver_Run_Step` | Step | Control(Loop) | (desc, state, algo, ctx, n_dof, u, du, callbacks, nr_tol, nr_maxiter, status) | HOT | _Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| RT_StepDriver_Def.f90 | 83 | 四型 TYPE 定义 + 状态枚举 |
| RT_StepDriver_Core.f90 | 327 | 13 个过程（全部已实现） |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 现有 13 个过程缺少标准 Phase 注释 |

### 评估结论

**RT_StepDriver 是推演引擎在编排域的黄金样板——过程清单已完整。** 仅需补全 Phase 注释标注。
