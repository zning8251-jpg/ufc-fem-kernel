# StepDriver 域级合同卡 (L5_RT)

- **层级**: L5_RT
- **域名**: StepDriver / 分析步编排与状态控制核
- **缩写**: StepDrv (`RT_Step_*`)
- **版本**: v3.0
- **更新**: 2026-04-28
- **状态**: ACTIVE

---

## 1. 域职责定义

- **核心职责（一句话）**: 实现 3 种核心计算（隐式静力/隐式动力/显式动力）的分析步/增量/迭代三层状态机，驱动 Assembly 组装、Solver 求解、Output 输出、WriteBack 回写的完整求解流程编排。
- **职责边界**:
  - **做什么**: 步/增量/迭代三层状态机管理、时间增量控制（自适应步长/CFL）、收敛判断与回切、多步类型路由（Static/DynImplicit/DynExplicit）、Runner 编排调度、步间状态传递、L4 数值核调用调度、Output/WriteBack 协调、AI 步长控制（可选插槽）
  - **不做什么**: 不直接计算单元/本构（L4_PH 负责）；不求解方程组（L5_RT/Solver 或 L2_NM 负责）；不组装全局矩阵（L5_RT/Assembly 负责）
- **架构定位**: L5 求解流程链首 — Phase 4 核心闭环链的编排起点

---

## 2. 四类 TYPE 清单

**AUTHORITY 模块**: `RT_Step_Def.f90` (`MODULE RT_Step_Def`)

### 2.1 Desc 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_StepDriver_Desc` | `RT_Step_Def` | 单步冷配置（只读） | `step_idx`, `step_id`, `category` (STD/IMPL/EXPL), `solver_config_id`, `time_cfg`, `name` |
| `RT_StepDriver_TimeCfg` | `RT_Step_Def` | 时间参数描述 | `t_start/end`, `dt_init/min/max`, `target_iter` |
| `RT_StepRuntimeCfg` | `RT_Step_Def` | 运行时配置包 | `time_cfg` + `algo` + `category` |
| `RT_ImplicitStepTimeCfg` | `RT_Step_Def` | 隐式步时间配置 | `t_start/end`, `dt_init/min/max` |
| `RT_ExplicitStepTimeCfg` | `RT_Step_Def` | 显式步时间配置 | `t_start/end`, `dt_init/min/max` |
| `RT_StepDrv_Desc` | `RT_Step_Def` | 精简步描述 (alias) | 待补全 |

### 2.2 State 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_StepDriver_State` | `RT_Step_Def` | 运行时演化量 | `current_step_idx`, `current_increment`, `current_iteration`, `current_time`, `current_load_factor`, `converged` |
| `RT_StepDriver_Result` | `RT_Step_Def` | 步执行结果（非四型，统计用） | `success`, `converged`, `total_increments/iterations/cutbacks`, `final_time/load_factor`, `cpu_time`, `message` |
| `RT_DynImpl_State` | `RT_Step_Def` | 隐式动力学运行时状态 | 待补全 |
| `RT_DynExpl_State` | `RT_Step_Def` | 显式动力学运行时状态 | 待补全 |
| `RT_StepDrv_State` | `RT_Step_Def` | 精简步状态 (alias) | 待补全 |

**TBP** (StepDrv_State): `Reset`

### 2.3 Algo 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_StepDriver_Algo` | `RT_Step_Def` | 收敛准则与迭代控制 | `max_iter`, `tol_residual`, `tol_displ`, `energy_tol`, `line_search`, `conv_mode`, `target_iter` |
| `RT_StepDTCtrl` | `RT_Step_Def` | 步长控制策略 | `grow_factor`, `cutback_factor`, `strategy` |
| `RT_ImplicitStepCfg` | `RT_Step_Def` | 隐式步算法配置 | 待补全 |
| `RT_ExplicitStepCfg` | `RT_Step_Def` | 显式步算法配置 | 待补全 |

### 2.4 Ctx 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Step_Ctx` | `RT_Step_Def` | 热路径工作区（栈标量 + 指针） | `work_vec(:)`, `temp_scalar`, `pool_slot` |
| `RT_DynImpl_Ctx` | `RT_Step_Def` | 隐式动力学上下文 | 待补全 |
| `RT_DynExpl_Ctx` | `RT_Step_Def` | 显式动力学上下文 | 待补全 |
| `RT_NodeDOFMap` | `RT_Step_Ctx` | 节点 DOF 映射上下文 | 节点-方程号映射 |
| `RT_MeshSnapshot` | `RT_Step_Ctx` | 网格快照上下文 | coords/conn/nodeMap |

**附加类型**: `RT_StepDriver_Config`, `StepState`, `StepDriverContext`, `RT_StepDriver_ConfigDomain` (RT_Step_Exec), `JobWS`, `StructWS`, `ThreadWS`, `Owners` (RT_Step_WS), `RT_DynExpl_Runner`, `RT_DynImpl_Runner` (RT_Step_Def)

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `RT_Step_Def.f90` | `RT_Step_Def` | _Def | 四型定义 + 20+ PUBLIC 类型 + 步类别常量 | **AUTHORITY** |
| `RT_Step_Exec.f90` | `RT_Step_Exec` | — | `RT_StepDriver_Execute`, `RT_StepDriver_RunDynamicExplicit/Implicit`, `StepStateMachine`, `RunStep/RunIncrement`, `RT_StepDriver_ConfigDomain_*` | **GOLDEN-LINE** |
| `RT_Step_Impl.f90` | `RT_Step_Impl` | _Impl | `RT_DynExpl_Run`, `RT_DynImpl_Run`, `RT_Dyn_CFL_dt_central_diff`, `RT_Dyn_Estimate_omega_max_csr_lumped`, `RT_Dyn_Clamp_dt_cfl_csr` | **ACTIVE** |
| `RT_Step_Core.f90` | `RT_Step_Core` | _Core | 步驱动核心编排: 初始化/清理/分发逻辑 | **ACTIVE** |
| `RT_Step_Brg.f90` | `RT_Step_Brg` | _Brg | `RT_StepDriver_Run` — 跨层桥接入口 | **ACTIVE** |
| `RT_Step_Ctx.f90` | `RT_Step_Ctx` | — | `RT_Step_Ctx_Init/Finalize`, `RT_Inc_Ctx_Init/Finalize`, `RT_MeshSnapshot_Build` | **ACTIVE** |
| `RT_Step_WS.f90` | `RT_Step_WS` | — | `JobWS/StructWS/ThreadWS/Owners` 工作空间 + 生命周期 | **ACTIVE** |
| `RT_Step_NR_Core.f90` | `RT_Step_NR_Core` | — | Newton-Raphson 步内核心逻辑 | **ACTIVE** |
| `RT_AI_StepCtrAlgo.f90` | `RT_AI_StepCtrAlgo` | — | `AI_StepCtr_Init/Finalize/Predict/Update` (PLACEHOLDER) | **ACTIVE** (AI 插槽) |

---

## 4. 对外接口（公开 API）

### 4.1 执行驱动

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_StepDriver_Execute` | `RT_Step_Exec` | 主入口: 按 PROC 分发至 Static/DynExpl/DynImpl |
| `RT_StepDriver_RunDynamicExplicit` | `RT_Step_Exec` | 显式动力学 Runner |
| `RT_StepDriver_RunDynamicImplicit` | `RT_Step_Exec` | 隐式动力学 Runner |
| `StepStateMachine` | `RT_Step_Exec` | 步/增量/迭代三层状态机 |
| `RunStep` / `RunIncrement` | `RT_Step_Exec` | 步/增量执行入口 |
| `StepDriver_Init` / `StepDriver_Finalize` | `RT_Step_Exec` | 步驱动生命周期 |

### 4.2 配置管理

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_StepDriver_ConfigDomain_Init/Finalize` | `RT_Step_Exec` | Config 域生命周期 |
| `RT_StepDriver_ConfigDomain_AddConfig` | `RT_Step_Exec` | 添加步配置 (Desc + RuntimeCfg) |
| `RT_StepDriver_ConfigDomain_GetConfig` | `RT_Step_Exec` | 获取指定步配置 |
| `RT_StepDriver_ConfigDomain_BindStepRefs` | `RT_Step_Exec` | 绑定 L3 MD_Step 引用 |

### 4.3 算法工具

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_DynExpl_Run` | `RT_Step_Impl` | 显式积分: v_{n+1/2} = v_{n-1/2} + dt·M⁻¹·F |
| `RT_DynImpl_Run` | `RT_Step_Impl` | 隐式积分: Newmark/HHT, Newton 内循环 |
| `RT_Dyn_CFL_dt_central_diff` | `RT_Step_Impl` | CFL 条件: dt_cfl = cfl_safety / ω_max |
| `RT_Dyn_Estimate_omega_max_csr_lumped` | `RT_Step_Impl` | 最高频率估计: ω_max = √(K_max/M_min) |
| `RT_Dyn_Clamp_dt_cfl_csr` | `RT_Step_Impl` | 限制 dt ≤ dt_cfl |

### 4.4 上下文管理

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_Step_Ctx_Init/Finalize` | `RT_Step_Ctx` | Step 级上下文 |
| `RT_Inc_Ctx_Init/Finalize` | `RT_Step_Ctx` | Increment 级上下文 |
| `RT_MeshSnapshot_Build` | `RT_Step_Ctx` | 构建网格快照 |

### 4.5 桥接入口

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_StepDriver_Run` | `RT_Step_Brg` | L6/外部调用的跨层桥接入口 |

---

## 5. 跨层数据流

### 5.1 上游（本域消费）

| 来源层/域 | 提供数据 | 消费方式 | 说明 |
|-----------|---------|---------|------|
| L3_MD/Analysis/Step | `AnalysisStep` Desc（步定义） | 经 Populate → `RT_StepDriver_Desc` | 冷路径 |
| L3_MD/Analysis/Step | 步参数（时间/载荷/求解器选择） | 经 Bridge 填充 `RT_StepRuntimeCfg` | 冷路径 |
| L2_NM/TimeInt | 时间积分底层算子 | `RT_Step_Impl` 调用 | 服务关系 |

### 5.2 本层输出（下游消费）

| 输出数据 | 消费者 | 说明 |
|---------|--------|------|
| 组装调用 | L5_RT/Assembly | StepDriver 驱动全局组装 |
| 求解调用 | L5_RT/Solver | StepDriver 驱动求解 |
| 步末回写 | L5_RT/WriteBack | 步/增量结束时状态回写 |
| 输出调用 | L5_RT/Output | 步/增量结束时结果输出 |
| 步状态 | L6_AP (Job 管理) | 步完成/失败信号 |

### 5.3 L5 步驱动主流程

```
L6_AP/Job → RT_StepDriver_Run (Bridge)
    ↓
RT_StepDriver_Execute (主入口)
    ↓
[步循环 StepStateMachine]
    ↓
    ├─ Static: RunStep → RunIncrement → [Newton 迭代循环]
    │     └→ Assembly(K/F) → Solver(Δu) → 收敛? → WriteBack
    │
    ├─ DynImplicit: RT_DynImpl_Run → Newmark/HHT-α + Newton
    │     └→ Assembly(K/M/C/F) → Solver → 更新 u/v/a → WriteBack
    │
    └─ DynExplicit: RT_DynExpl_Run → Central Difference
          └→ CFL dt 计算 → Assembly(内力) → M⁻¹·F → 更新 u/v/a → WriteBack
```

**热路径零 L3**: 步内禁止直读 `MD_Step_*`，仅消费 Populate 后的 slot。

---

## 6. 域间契约

### 6.1 与 L5 同层其他域的协作关系

| 序号 | 关联域 | 方向 | 契约类型 | 主要接触面 | 备注 |
|------|--------|------|----------|-----------|------|
| R1 | L5_RT/Assembly | 调用 | S(服务) | 调用全局组装 | 每增量步/迭代 |
| R2 | L5_RT/Solver | 调用 | S(服务) | 调用求解器 | 每增量步/迭代 |
| R3 | L5_RT/WriteBack | 调用 | S(服务) | 步末回写 | 每步/增量末尾 |
| R4 | L5_RT/Output | 调用 | S(服务) | 结果输出 | 按输出频率 |
| R5 | L5_RT/Contact | 间接 | — | 经 Assembly/Solver 间接 | — |

### 6.2 与 L3 的消费关系

| 序号 | L3 域 | 消费内容 | 说明 |
|------|-------|---------|------|
| C1 | L3_MD/Analysis/Step | `AnalysisStep` → 步定义、时间参数 | Bridge 填充 |
| C2 | L3_MD/Analysis/Solver | Solver 配置引用 | `solver_config_id` |

### 6.3 Step/Increment/Iteration 与 Phase 对照

| 层级（语义） | 说明 | 与 `RT_PHASE_*` 关系 |
|--------------|------|----------------------|
| **分析步 Step** | Job 内一段过程（静力/动力、荷载历程） | 步进入: `RT_PHASE_INIT`; 步结束: `RT_PHASE_COMPLETED` |
| **增量步 Increment** | 伪时间或真实时间 Δ；驱动荷载/接触更新 | 常处于 `RT_PHASE_INCREMENT`；失败切步 → `RT_PHASE_CUTBACK` |
| **平衡迭代 Iteration** | Newton/拟牛顿/弧长等修正循环 | 仍在 INCREMENT 内；收敛 → `RT_PHASE_CONVERGED`；不收敛 → 切步或 FAILED |

**Runner 钩子**: `OnStepEnter → OnIncrementStart → [OnIterationStart → OnAssembleResidual/Tangent → OnSolve → OnIterationEnd] → OnIncrementEnd`

---

## 7. 验收标准

### 7.1 硬约束

| 编号 | 约束 | 说明 |
|------|------|------|
| H-HOT-01 | 不在热路径直触 L3 巨型模块 | 架构原则 |
| H-ERR-01 | 不使用 STOP | 错误通过 `ErrorStatusType` 沿调用链传播 |
| H-CHAIN-01 | 步驱动为链首 | Phase 4 闭环编排起点 |
| H-DEP-01 | 单向依赖 | 不可依赖 L6_AP（仅被 L6 调用） |

### 7.2 软约束

| 编号 | 约束 | 说明 |
|------|------|------|
| S-TST-01 | 测试覆盖率 | 待建 |
| S-DOC-01 | 子程序级注释 | 新增模块须含 purpose/theory/status 头 |

### 7.3 功能验收

| 编号 | 验收项 | 判定标准 |
|------|--------|---------|
| V-STP-01 | 静力分析步 | 线性弹性问题一步收敛 |
| V-STP-02 | 自适应步长 | 不收敛时自动回切，收敛后步长增长 |
| V-STP-03 | 隐式动力学 | Newmark: 自由振动周期误差 < 1% |
| V-STP-04 | 显式动力学 | CFL 条件正确限制 dt，稳定运行 |
| V-STP-05 | 多步类型路由 | Static → Dynamic 步切换无状态泄漏 |
| V-STP-06 | 步间状态传递 | 前一步末状态 = 下一步初始状态 |

---

### AI Enhancement (插槽 1/2)

| 项 | 插槽 1 | 插槽 2 |
|----|--------|--------|
| **名称** | AI_StepCtr | AI_ConvPredict |
| **模块** | `RT_AI_StepCtrAlgo.f90` | `RT_AI_ConvPredictAlgo.f90` |
| **调用时机** | 增量步收敛后 | 每次迭代内 |
| **用途** | 自适应步长控制 | 收敛预测/早退 |
| **默认** | `NULL()` procedure pointer | `NULL()` procedure pointer |

### Partial Pillar v2.0 (H4a Step)

**半柱分类**: H4a Step 是 L3+L5 半贯通柱。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Step.f90` | **AUTHORITY** — 步定义 Desc | ACTIVE |
| L4 | (不存在) | 步非物理计算概念 | — |
| L5 | `RT_Step_Def.f90` | **AUTHORITY** — 三级状态机四型 | FOUR-TYPE |
| L5 | `RT_Step_Exec.f90` | **GOLDEN-LINE** — 生产步驱动 | ACTIVE |

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | 隐式/显式时间积分策略（Newmark/HHT-α/Central Difference）→ 步驱动分发 |
| **逻辑链** | StepDriver（链首）→ Assembly → Solver → WriteBack → 下一步 |
| **计算链** | 步驱动不直接计算；调度 Assembly 组装 K/F，Solver 求解 Δu |
| **数据链** | `AnalysisStep`(L3 冷) → `StepStateData`(L5 热) → 步驱动消费 → 步末 WriteBack |

---

*维护注记: 新增 Runner 子模块时在「§3 功能模块清单」和「§4 对外接口」补一行。*
