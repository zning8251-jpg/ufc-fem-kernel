# LoadBC 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: LoadBC (运行时 `Load` / `BC` split + umbrella support)  
**Prefix**: `RT_Load_*`, `RT_BC_*`（canonical split）；`RT_LoadBC_*`（仅 umbrella/support）  
**Version**: v2.2  
**Created**: 2026-04-26  
**Updated**: 2026-05-14  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 LoadBC 域，负责运行时 `Load Assemble` 与 `BC Apply` 的编排、桥接和状态维护。
- **职责**:
  - 消费 L4 已 Populate 的 `PH_Load_*` / `PH_BC_*` 双柱数据。
  - 维护 L5 `RT_Load_*` / `RT_BC_*` 分柱运行时四型与实现层四型。
  - 将载荷贡献写入全局外载向量 `F_ext`，并将 BC 施加到全局 `K/F` 或约束 CSR。
  - 执行步内更新、收敛检查、自适应 cutback 与反力恢复。
  - 通过 `RT_LoadBC_ConstApply` 处理 Tie / MPC / Coupling / RigidBody 的 penalty/CSR 约束施加。
  - 与 `RT_Asm_*`、`StepDriver` 的调用顺序保持一致。

### 非职责
- 不解析 INP 载荷卡或边界卡（L3 负责）。
- 不实现单元等效力积分核（L4 `PH_Load_Core` / `PH_BC_Core` 负责）。
- 不回写 L3 Desc 真源（L3 为 write-once；仅允许诊断型白名单回写）。
- 不承担最终线性/非线性方程求解。

---

## 2. 运行时真源与文件布局

### 2.1 Canonical split 文件族

| 柱 | 文件 | MODULE | 角色 | 状态 |
|----|------|--------|------|------|
| Load | `RT_Load_Def.f90` | `RT_Load_Def` | routing 四型定义 | **ACTIVE** |
| Load | `RT_Load_Impl_Def.f90` | `RT_Load_Impl_Def` | implementation 四型定义（cutback / amp / time） | **ACTIVE** |
| Load | `RT_Load_Impl.f90` | `RT_Load_Impl` | 载荷运行时实现 | **ACTIVE** |
| Load | `RT_Load_Brg.f90` | `RT_Load_Brg` | L3/L4/L5 桥接与类型路由 | **ACTIVE** |
| BC | `RT_BC_Def.f90` | `RT_BC_Def` | routing 四型定义 | **ACTIVE** |
| BC | `RT_BC_Impl_Def.f90` | `RT_BC_Impl_Def` | implementation 四型定义（cutback / convergence / time） | **ACTIVE** |
| BC | `RT_BC_Impl.f90` | `RT_BC_Impl` | BC 运行时实现 | **ACTIVE** |
| BC | `RT_BC_Brg.f90` | `RT_BC_Brg` | L3/L4/L5 桥接与诊断回写 | **ACTIVE** |
| BC | `RT_BC_ReactionForce.f90` | `RT_BC_ReactionForce` | BC penalty/elimination 与反力恢复 | **ACTIVE** |

### 2.2 Umbrella / support 文件族

| 文件 | MODULE | 角色 | 状态 | 说明 |
|------|--------|------|------|------|
| `RT_LoadBC_ConstApply.f90` | `RT_LoadBC_ConstApply` | support bridge | **ACTIVE** | Tie / MPC / Coupling / RigidBody 的 penalty/CSR 约束施加桥 |
| `RT_LoadBC_Proc.f90` | `RT_LoadBC_Proc` | umbrella `_Proc` | **ACTIVE** | SIO facade 入口；仍承接旧 umbrella 语义，不是 canonical 四型真源 |
| `RT_LoadBC_Core.f90` | `RT_LoadBC_Core` | compatibility `_Core` | **LEGACY** | 旧 facade；保留 Init/Apply/Finalize 等兼容实现 |

### 2.3 真源优先级

1. `RT_Load_*` / `RT_BC_*` split 文件族是 L5 LoadBC 的 **canonical 真源**。  
2. `RT_LoadBC_ConstApply`、`RT_LoadBC_Proc`、`RT_LoadBC_Core` 仅是 **umbrella/support/compatibility**。  
3. 历史 `RT_LoadBC_*` 混合叙事只能作为迁移说明，**不得反向覆盖 split 主口径**。

---

## 3. 四类 TYPE 清单

### 3.1 Routing 四型（split 权威入口）

| 载体组 | 模块 | 关键 TYPE | 核心字段 | 说明 |
|--------|------|-----------|----------|------|
| Load routing | `RT_Load_Def` | `RT_Load_Desc` / `RT_Load_State` / `RT_Load_Algo` / `RT_Load_Ctx` | `mat_id`, `l4_slot_index`, `is_active`; `num_ips`, `state_committed`; `dispatch_strategy`; `current_step/current_incr/current_iter` | L5 Load 路由与薄状态载体 |
| BC routing | `RT_BC_Def` | `RT_BC_Desc` / `RT_BC_State` / `RT_BC_Algo` / `RT_BC_Ctx` | `mat_id`, `l4_slot_index`, `is_active`; `num_ips`, `state_committed`; `dispatch_strategy`; `current_step/current_incr/current_iter` | L5 BC 路由与薄状态载体 |

### 3.2 Implementation 四型（热路径控制入口）

| 载体组 | 模块 | 关键 TYPE | 核心字段 | 说明 |
|--------|------|-----------|----------|------|
| Load impl | `RT_Load_Impl_Def` | `RT_Load_Impl_Desc` / `RT_Load_Impl_State` / `RT_Load_Impl_Algo` / `RT_Load_Impl_Ctx` | `n_loads`, `amp_id`; `total_cutbacks`, `current_amp`, `accumulated_work`; `max_cutbacks`, `auto_cutback_enabled`, `cutback_factor`, `min_load_increment`; `analysis_type`, `nlgeom`, `time_increment`, `step_time`, `total_time` | Load 热路径主控制载体 |
| BC impl | `RT_BC_Impl_Def` | `RT_BC_Impl_Desc` / `RT_BC_Impl_State` / `RT_BC_Impl_Algo` / `RT_BC_Impl_Ctx` | `n_bcs`, `amp_id`; `total_cutbacks`, `total_iterations`, `current_amp`, `accumulated_work`; `max_cutbacks`, `auto_cutback_enabled`, `cutback_factor`, `load_convergence_tol`; `analysis_type`, `nlgeom`, `time_increment`, `step_time`, `total_time` | BC 热路径主控制载体 |

### 3.3 权威说明

- **routing 四型真源**：`RT_Load_Def.f90` + `RT_BC_Def.f90`
- **implementation 四型真源**：`RT_Load_Impl_Def.f90` + `RT_BC_Impl_Def.f90`
- `RT_LoadBC_Core.f90` **不是**权威四型模块；其作用仅限兼容/承接旧 umbrella 入口

---

## 4. 对外接口（公开 API）

### 4.1 Load 运行时主链

| 接口 | 模块 | 说明 |
|------|------|------|
| `RT_Load_Init_Impl` | `RT_Load_Impl` | 初始化 Load implementation 状态 |
| `RT_Load_Update_Impl` | `RT_Load_Impl` | 步内更新 |
| `RT_Load_ApplyLoads_Impl` | `RT_Load_Impl` | 将载荷贡献写入外载向量 |
| `RT_Load_CheckConvergence_Impl` | `RT_Load_Impl` | Load 侧收敛检查 |
| `RT_Load_ApplyCutback_Impl` | `RT_Load_Impl` | Load 侧 cutback |
| `RT_Load_Finalize_Impl` | `RT_Load_Impl` | 收尾与清理 |
| `RT_Load_Brg_FromL3` | `RT_Load_Brg` | Populate/桥接 Load 冷数据 |
| `RT_Load_Brg_ToL4` | `RT_Load_Brg` | 向 L4 传递幅值等运行时信息 |
| `RT_Load_Brg_RouteLoadType` | `RT_Load_Brg` | 按 load type 路由载荷施加类型 |

### 4.2 BC 运行时主链

| 接口 | 模块 | 说明 |
|------|------|------|
| `RT_BC_Init_Impl` | `RT_BC_Impl` | 初始化 BC implementation 状态 |
| `RT_BC_Update_Impl` | `RT_BC_Impl` | 步内更新 |
| `RT_BC_ApplyBCs_Impl` | `RT_BC_Impl` | 施加 BC |
| `RT_BC_ComputeReactions_Impl` | `RT_BC_Impl` | 汇总反力 / 反力矩 |
| `RT_BC_CheckConvergence_Impl` | `RT_BC_Impl` | BC 侧收敛检查 |
| `RT_BC_ApplyCutback_Impl` | `RT_BC_Impl` | BC 侧 cutback |
| `RT_BC_Finalize_Impl` | `RT_BC_Impl` | 收尾与清理 |
| `RT_BC_Brg_FromL3` | `RT_BC_Brg` | Populate/桥接 BC 冷数据 |
| `RT_BC_Brg_ToL4` | `RT_BC_Brg` | 向 L4 传递幅值等运行时信息 |
| `RT_BC_Brg_WriteBack` | `RT_BC_Brg` | 输出诊断型回写指标 |
| `RT_BC_Apply_Constraints` | `RT_BC_ReactionForce` | penalty / elimination 约束施加 |
| `RT_BC_Compute_Reactions` | `RT_BC_ReactionForce` | 反力恢复 |
| `RT_BC_Process_Element_Reactions` | `RT_BC_ReactionForce` | 单元反力后处理入口 |

### 4.3 Umbrella / support 接口

| 接口 | 模块 | 说明 |
|------|------|------|
| `RT_LoadBC_ConstApply_All` | `RT_LoadBC_ConstApply` | 统一约束施加入口 |
| `RT_LoadBC_MPCPenalty_AppendTriplets` | `RT_LoadBC_ConstApply` | MPC penalty triplets |
| `RT_LoadBC_TiePenalty_AppendTriplets` | `RT_LoadBC_ConstApply` | Tie penalty triplets |
| `RT_LoadBC_CplPenalty_AppendTriplets` | `RT_LoadBC_ConstApply` | Coupling penalty triplets |
| `RT_LoadBC_RigidPenalty_AppendTriplets` | `RT_LoadBC_ConstApply` | RigidBody penalty triplets |
| `RT_LoadBC_Init` / `RT_LoadBC_Update` / `RT_LoadBC_ApplyLoads` / `RT_LoadBC_ApplyBCs` / `RT_LoadBC_ComputeReactions` / `RT_LoadBC_CheckConvergence` / `RT_LoadBC_ApplyCutback` / `RT_LoadBC_Finalize` | `RT_LoadBC_Proc` | umbrella SIO facade，供旧入口或统一调度承接 |
| `RT_LoadBC_Core_Init` / `RT_LoadBC_Core_Finalize` / `RT_LoadBC_Assemble_Loads` / `RT_LoadBC_Apply_BCs` / `RT_LoadBC_Apply_BCs_ByMode` / `RT_LoadBC_Eval_Amplitude` / `RT_LoadBC_Get_Prescribed_Disps` / `RT_LoadBC_Compute_Incremental` | `RT_LoadBC_Core` | 旧 facade，仅保留兼容 |

---

## 5. 跨层数据流

### 5.1 Load Assemble 主链

```text
L3 MD_Load_Desc / MD_Load_State
  -> Populate / Bridge
  -> L4 PH_Load_* slot
  -> L5 RT_Load_Desc / State / Algo / Ctx
  -> L5 RT_Load_Impl_Desc / State / Algo / Ctx
  -> RT_Load_Impl + RT_Load_Brg
  -> global F_ext (via RT_Asm_*)
```

### 5.2 BC Apply 主链

```text
L3 MD_BC_Desc / MD_BC_State / MD_BC_Algo
  -> Populate / Bridge
  -> L4 PH_BC_* slot
  -> L5 RT_BC_Desc / State / Algo / Ctx
  -> L5 RT_BC_Impl_Desc / State / Algo / Ctx
  -> RT_BC_Impl + RT_BC_Brg
  -> RT_BC_ReactionForce / RT_LoadBC_ConstApply
  -> global K / F / CSR modification
```

### 5.3 Umbrella support 位置

```text
StepDriver / compatibility caller
  -> RT_LoadBC_Proc (SIO facade)
       -> split impl family / support bridges
  -> RT_LoadBC_Core (legacy fallback only)
```

- **热路径零 L3**：步内热路径不得回头读取 L3 真源。
- **所有权约束**：umbrella/support 可以承接入口，但不能反向成为 split 四型的权威来源。

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | `L3_MD/LoadBC` | S (消费 via Populate) | 读取 Load/BC 冷路径定义与幅值引用 |
| R2 | `L3_MD/Analysis/Amplitude` | S (消费) | 消费幅值曲线或其桥接结果 |
| R3 | `L4_PH/LoadBC` | B (桥接) | 消费 `PH_Load_*` / `PH_BC_*` 双柱视图 |
| R4 | `L5_RT/Assembly` | T (提供) | 向全局装配提供 `F_ext`、`K/F`、CSR 贡献 |
| R5 | `L5_RT/StepDriver` | S (被调度) | 在增量步中调度 Load / BC 双主链 |

### 6.1 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| L5 canonical 命名以 `RT_Load_*` / `RT_BC_*` 为准 | **硬** | 合同审查 + manifest 对账 | PR |
| umbrella/support 不得冒充权威四型 | **硬** | 合同审查 | PR |
| 热路径零 L3（步内仅消费 L4 slot 与 L5 状态） | **硬** | 代码审查 + 静态分析 | CI |
| 不使用 STOP | **硬** | 静态扫描 | CI |
| 与 `RT_Asm_*` 调用顺序对齐 | **硬** | 集成测试 | CI |

### 6.2 错误处理

| 错误码范围 | 错误场景 | 严重级 | 恢复策略 |
|------------|----------|--------|----------|
| `ERR_L5_LOADBC_50400` | 载荷 DOF 索引越界 | ERROR | 跳过该载荷 |
| `ERR_L5_LOADBC_50401` | BC 节点 ID 不存在 | ERROR | 跳过该 BC |
| `ERR_L5_LOADBC_50402` | Tie / MPC / Coupling / RigidBody 约束不合法 | ERROR | 终止当前增量步或切换恢复策略 |
| `ERR_L5_LOADBC_50403` | 幅值 / cutback / time_increment 配置不合法 | ERROR | 终止当前增量步 |
| `ERR_L5_LOADBC_50404` | 幅值未命中 | WARNING | 使用默认幅值或保持当前幅值 |
| `ERR_L5_LOADBC_50405` | CSR / triplet 追加失败 | ERROR | 扩容或终止 |

---

## 7. 当前残余缺口与技术债

| 优先级 | 缺口 | 当前状态 | 处理原则 |
|--------|------|----------|----------|
| P0 | `RT_LoadBC_Proc.f90` 仍 `USE RT_LoadBC_Impl_Def` / `RT_LoadBC_Impl` 旧 umbrella 依赖名 | 与 split canonical 命名未完全对齐 | 继续保留为 support facade，但后续代码需收敛到 split 实现族 |
| P0 | `RT_LoadBC_Core.f90` 仍引用 `RT_LoadBC_Def` 旧 umbrella 类型 | 与当前 split 四型口径不一致 | 明确标为 LEGACY compatibility，不作为真源 |
| P1 | `RT_Load_Brg` / `RT_BC_Brg` 的字段预期与当前 routing 四型仍有细部漂移 | 例如桥接侧仍期待 `n_loads` / `n_bcs` / `current_amp` 等字段 | 后续代码修补时以 split 合同为准，不反向改合同迁就旧实现 |
| P1 | 用户载荷 ABI wrapper 未独立成 `RT_DLOAD_*` / `RT_ULOAD_*` | 暂未独立建模 | 需要时在 split 结构上增量扩展 |

**完备性评级**：⚠️ **合同主叙事已收敛到 split canonical + umbrella support**，但 support 层内部仍残留旧依赖名与字段漂移，后续应继续做代码侧收敛。

---

## 8. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | L5 运行时真源明确 | `RT_Load_*` / `RT_BC_*` 被定义为 canonical split | ✅ |
| A2 | routing 四型口径明确 | `RT_Load_Def` + `RT_BC_Def` 成为 routing 真源 | ✅ |
| A3 | implementation 四型口径明确 | `RT_Load_Impl_Def` + `RT_BC_Impl_Def` 成为热路径真源 | ✅ |
| A4 | Load / BC 双主链明确 | `Load Assemble` 与 `BC Apply` 分柱叙事完整 | ✅ |
| A5 | umbrella/support 边界明确 | `RT_LoadBC_ConstApply` / `RT_LoadBC_Proc` / `RT_LoadBC_Core` 被归类为 support/compatibility | ✅ |
| A6 | 合同与 Registry manifest 对齐 | `design/L5_RT/LoadBC/manifest.json` 同口径 | ✅ |
| A7 | 合同与 REPORTS 对齐 | `REPORTS/archive/LoadBC_Procedure_Algorithm.md` 与域库存同口径 | ✅ |
| A8 | support 层内部旧依赖已清零 | `RT_LoadBC_Proc/Core` 不再依赖旧 umbrella 类型名 | ⚠️ 未完成 |

---

## 9. Cross-references

- **L3 合同**: `ufc_core/L3_MD/LoadBC/CONTRACT.md`
- **L4 合同**: `ufc_core/L4_PH/LoadBC/CONTRACT.md`
- **Registry manifest**: `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/LoadBC/manifest.json`
- **过程算法叙事（根 stub）**: [`LoadBC_Procedure_Algorithm.md`](../../../REPORTS/LoadBC_Procedure_Algorithm.md)
- **过程算法叙事（archive 正文）**: [`archive/LoadBC_Procedure_Algorithm.md`](../../../REPORTS/archive/LoadBC_Procedure_Algorithm.md)
- **域库存**: [`REPORTS/LoadBC_Domain_Inventory.md`](../../../REPORTS/LoadBC_Domain_Inventory.md)
- **Registry 对账说明**: [`docs/03_Domain_Pillars/DomainProcedureRegistry/README.md`](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)
