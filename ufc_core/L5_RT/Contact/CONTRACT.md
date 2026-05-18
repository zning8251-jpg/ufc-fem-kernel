# Contact 域级合同卡 (L5_RT)

- **层级**: L5_RT
- **域名**: Contact / 接触运行时调度与编排
- **缩写**: Cont (`RT_Cont_*`, `RT_Contact_*`)
- **版本**: v3.0
- **更新**: 2026-04-28
- **状态**: ACTIVE

---

## 1. 域职责定义

- **核心职责（一句话）**: 运行时接触处理调度 — 接触搜索调度、接触力组装协调、接触状态更新、增广 Lagrange (Uzawa) 外迭代编排，仅负责调度编排，物理计算由 L4_PH/Contact 处理。
- **职责边界**:
  - **做什么**: 接触搜索调度（→ L4 `PH_ContSearch`）、接触力计算调度（→ L4 `PH_Cont_*`）、接触贡献全局装配协调（→ `RT_Asm_ApplyContact`）、接触状态更新与收敛检查、增广 Lagrange (Uzawa) 外迭代管理（乘子更新/收敛检查/回滚）、显式动力学接触适配（→ L4 `PH_ContExpl`）、L3→L5 接触 Populate 桥接、接触运行时诊断回写
  - **不做什么**: 不计算接触穿透/法向力/摩擦力（L4_PH/Contact 负责）；不定义接触对几何（L3_MD/Interaction 负责）；不组装全局矩阵（L5_RT/Assembly 负责）；不执行搜索树构建（L4_PH/Contact 负责）
- **依赖**: L4_PH/Contact (物理计算), L3_MD/Interaction (Desc 定义)

---

## 2. 四类 TYPE 清单

**AUTHORITY 模块**: `RT_Cont_Def.f90` (`MODULE RT_Cont_Def`)

### 2.1 Desc 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Contact_Desc` | `RT_Cont_Def` | 接触对配置（冷，步级只读） | `n_contact_pairs`, `contact_name`, `master_surf_ids(:)`, `slave_surf_ids(:)`, `contact_types(:)`, `friction_models(:)`, `friction_coeffs(:)`, `penalty_stiffness(:)`, `clearance(:)`, `global/local_search_tol`, `search_radius_factor`, `adjust_slave_nodes/tolerance` |

**TBP**: `Init`, `AddPair`, `SetFriction`, `Finalize`

### 2.2 State 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Contact_State` | `RT_Cont_Def` | 运行时状态（温，迭代级） | `pair_active(:)`, `pair_status(:)` (OPEN/CLOSED/SLIDING/STICKING), `n_active/open/closed_pairs`, `f_contact(:)`, `total/max_contact_force`, `penetration(:)`, `max/avg_penetration`, `friction_force(:)`, `is_sticking(:)`, `contact_energy`, `converged`, `iterations`, `lambda_n(:)` (Uzawa 已提交乘子), `lambda_trial(:)` (Uzawa 试探乘子), `uzawa_iter`, `uzawa_converged` |

**TBP**: `Reset`, `UpdateStatus`, `AggregateStatistics`, `AugLagInit`, `AugLagCommit`, `AugLagRollback`

### 2.3 Algo 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Contact_Algo` | `RT_Cont_Def` | 算法参数（冷，步级） | `discretization_method` (NTS/STS/Mortar), `enforcement_method` (Penalty/Lagrange/AugLagrange), `penalty_scale_factor`, `friction_model` (None/Coulomb/Rough/Viscous/User), `search_frequency`, `use_global_search`, `use_adaptive_rebuild`, `use_damping`, `damping_factor`, `n_aug_max`, `rho_aug`, `tol_aug` |

**TBP**: `Init`, `SelectEnforcement`, `ConfigureFriction`, `ConfigureSearch`, `ConfigureAugLag`

### 2.4 Ctx 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Contact_Ctx` | `RT_Cont_Def` | 热路径上下文（栈标量，无 ALLOCATABLE） | `current_pair_idx`, `gap_distance`, `penetration_depth`, `contact_pressure`, `normal_vector(3)`, `tangent_vector(3,2)`, `slip_direction(3)`, `closest_pt(3)`, `gp_xi/eta`, `shape_master/slave(4)`, `master/slave_node_id`, `contact_elem_id`, `temp_force(:)`, `temp_disp(:)` |

**TBP**: `AttachBuffers`, `ClearTemporaries`, `Detach`

**常量枚举**:
- 离散化: `RT_CONT_DISC_NODE_TO_SURF/SURF_TO_SURF/MORTAR`
- 约束施加: `RT_CONT_ENFORCE_PENALTY/LAGRANGE/AUG_LAGRANGE`
- 法向接触: `RT_CONT_NORMAL_HARD/SOFT/EXPONENTIAL`
- 摩擦模型: `RT_CONT_FRICTION_NONE/COULOMB/ROUGH/VISCOUS/USER`
- 接触对状态: `RT_CONT_PAIR_OPEN/CLOSED/SLIDING/STICKING`

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `RT_Cont_Def.f90` | `RT_Cont_Def` + `RT_Cont_Types_Impl` | _Def | 四型定义 + 常量 + 绑定过程实现 | **AUTHORITY** |
| `RT_Cont_Solv.f90` | `RT_Cont_Solv` | — | `RT_Cont_Search`, `RT_Cont_ComputeForce`, `RT_Cont_Assemble`, `RT_Cont_GetStats` — 生产 SIO 门面 → L4 | **GOLDEN-LINE** |
| `RT_Cont_Core.f90` | `RT_Cont_Core` | _Core | 简化四型 facade + 生命周期/注册 | **ACTIVE** |
| `RT_Cont_Search.f90` | `RT_Cont_Search` | — | 搜索适配器 → L4 `PH_ContSearch` | **ACTIVE** |
| `RT_Cont_Ctrl.f90` | `RT_Cont_Ctrl` | — | 生产控制器: 检测/力/装配/收敛 | **ACTIVE** |
| `RT_Cont_Expl.f90` | `RT_Cont_Expl` | — | 显式动力学适配器 → L4 `PH_ContExpl` | **ACTIVE** |
| `RT_Cont_AugLagSolv.f90` | `RT_Cont_AugLagSolv` | — | `RT_Cont_AugLag_Solve`, `RT_Cont_AugLag_UpdateLambda`, `RT_Cont_AugLag_CheckConv` — Uzawa 外迭代调度 | **ACTIVE** |
| `RT_Cont_Brg.f90` | `RT_Cont_Brg` | _Brg | `RT_Contact_Brg_FromL3`, `RT_Contact_Brg_ToL4`, `RT_Contact_Brg_WriteBack` — 域柱 Bridge | **ACTIVE** |

**LEGACY 兼容**: `RT_Contact_Def.f90` — Re-exports from `RT_Cont_Def`（向后兼容 wrapper）

**CMake 备注**: L5 Contact 目录在 `CMakeLists.txt` 中被 `EXCLUDE REGEX ".*/Contact/.*\.f90$"` 排除。原因: 部分过程实现缺失。后续需对齐。

---

## 4. 对外接口（公开 API）

### 4.1 生产路径 (GOLDEN-LINE: RT_Cont_Solv)

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_Cont_Search` | `RT_Cont_Solv` | 接触搜索调度 → 调用 L4 搜索算法 |
| `RT_Cont_ComputeForce` | `RT_Cont_Solv` | 接触力计算调度 → 调用 L4 力计算 |
| `RT_Cont_Assemble` | `RT_Cont_Solv` | 接触贡献全局装配 |
| `RT_Cont_GetStats` | `RT_Cont_Solv` | 接触统计查询 |

### 4.2 增广 Lagrange (Uzawa)

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_Cont_AugLag_Solve` | `RT_Cont_AugLagSolv` | Uzawa 外迭代主循环 |
| `RT_Cont_AugLag_UpdateLambda` | `RT_Cont_AugLagSolv` | Lagrange 乘子更新: λ_{k+1} = λ_k + ρ·g |
| `RT_Cont_AugLag_CheckConv` | `RT_Cont_AugLagSolv` | Uzawa 收敛检查: ‖Δλ‖_∞ < tol_aug |

### 4.3 Bridge 接口

| 过程名 | 模块 | 功能 |
|--------|------|------|
| `RT_Contact_Brg_FromL3` | `RT_Cont_Brg` | L3 → L5 Populate（接触对配置填充） |
| `RT_Contact_Brg_ToL4` | `RT_Cont_Brg` | L5 → L4 上下文传递（搜索/力计算参数） |
| `RT_Contact_Brg_WriteBack` | `RT_Cont_Brg` | 接触诊断回写 |

### 4.4 显式动力学适配

| 过程名 | 模块 | 功能 |
|--------|------|------|
| (详见 `RT_Cont_Expl.f90`) | `RT_Cont_Expl` | 显式动力学接触力计算/更新适配 → L4 `PH_ContExpl` |

---

## 5. 跨层数据流

### 5.1 上游（本域消费）

| 来源层/域 | 提供数据 | 消费方式 | 说明 |
|-----------|---------|---------|------|
| L3_MD/Interaction | 接触对定义（n_pairs, surfaces, 参数） | `RT_Contact_Brg_FromL3` Populate | 冷路径 |
| L4_PH/Contact | 接触搜索结果、穿透/法向力/摩擦力 | `RT_Cont_Solv` → `PH_Cont_*` | **核心热路径** |
| L4_PH/Contact | 显式接触力 | `RT_Cont_Expl` → `PH_ContExpl` | 热路径 |

### 5.2 本层输出（下游消费）

| 输出数据 | 消费者 | 载体 |
|---------|--------|------|
| 接触力贡献 Kc/Fc | L5_RT/Assembly (`RT_Asm_ApplyContact`) | 全局 K/F 散射 |
| 接触状态统计 | L5_RT/Solver (收敛判断) | `RT_Contact_State` |
| 接触诊断数据 | L5_RT/Output → WriteBack | `RT_Contact_Brg_WriteBack` |
| Uzawa 收敛信号 | L5_RT/StepDriver (外迭代控制) | `uzawa_converged` 标志 |

### 5.3 域柱数据流 (P3 Contact)

```
[Populate 阶段]
L3_MD/Interaction → RT_Contact_Brg_FromL3 → RT_Contact_Desc (n_pairs, surfaces)

[热路径 - 每增量步/迭代]
StepDriver → RT_Cont_Search → L4 PH_ContSearch (搜索调度)
         ↓
RT_Cont_ComputeForce → L4 PH_Cont_* (穿透→力计算)
         ↓
RT_Cont_Assemble → RT_Asm_ApplyContact (接触贡献→全局 K/F)
         ↓
收敛检查 → (若 AugLagrange) Uzawa 外迭代循环

[回写阶段]
RT_Contact_Brg_WriteBack → 诊断输出
```

**跨层命名对照**: L3 `MD_Interaction` ↔ L4 `PH_Contact`/`PH_Cont` ↔ L5 `RT_Contact`/`RT_Cont`

---

## 6. 域间契约

### 6.1 与 L5 同层其他域的协作关系

| 序号 | 关联域 | 方向 | 契约类型 | 主要接触面 | 备注 |
|------|--------|------|----------|-----------|------|
| R1 | L5_RT/Assembly | 下游供给 | S(服务) | 接触贡献 → `RT_Asm_ApplyContact` | 装配协调 |
| R2 | L5_RT/Solver | 协作 | S | 接触残差 + 收敛检查 | `RT_Solv_Cont_*` |
| R3 | L5_RT/StepDriver | 被调用 | S | 步驱动编排接触流程 | 间接调用 |

### 6.2 与 L4_PH/Contact 的消费关系

| 序号 | L4 接口 | 消费内容 | L5 调用方 |
|------|---------|---------|-----------|
| C1 | `PH_ContSearch` | 接触搜索算法 | `RT_Cont_Search` |
| C2 | `PH_Cont_*` | 接触力计算（穿透/法向/摩擦） | `RT_Cont_Solv` |
| C3 | `PH_ContExpl` | 显式动力学接触 | `RT_Cont_Expl` |

### 6.3 与 L3_MD/Interaction 的 Bridge 关系

| 数据 | 方向 | 载体 |
|------|------|------|
| 接触对配置 (n_pairs, surfaces, 参数) | L3 → L5 | `RT_Contact_Brg_FromL3` |
| 接触状态摘要 | L5 → diag | `RT_Contact_Brg_WriteBack` |

---

## 7. 验收标准

### 7.1 硬约束

| 编号 | 约束 | 说明 |
|------|------|------|
| H-ERR-01 | 不使用 STOP | 错误通过 `ErrorStatusType` 传播 |
| H-L4-01 | 物理计算不越界 | L5 仅调度，不实现搜索/力计算核心算法 |
| H-DEP-01 | 单向依赖 | 不可依赖 L6_AP |
| H-AUG-01 | Uzawa 外迭代状态完整 | `lambda_n/trial` 双缓冲、commit/rollback 完备 |

### 7.2 软约束

| 编号 | 约束 | 说明 |
|------|------|------|
| S-TST-01 | 测试覆盖率 | 基础四型测试已有 (`RT_Contact_test.f90`) |
| S-DOC-01 | 子程序级注释 | 新增模块须含 purpose/theory/status 头 |
| S-CMAKE-01 | CMake 排除待解决 | Contact 目录当前被 CMake 排除 |

### 7.3 功能验收

| 编号 | 验收项 | 判定标准 |
|------|--------|---------|
| V-CNT-01 | Penalty 接触 | Hertz 接触力收敛于解析解（误差 < 5%） |
| V-CNT-02 | 增广 Lagrange | Uzawa 外迭代收敛（‖Δλ‖_∞ < tol_aug） |
| V-CNT-03 | 摩擦接触 | Coulomb 摩擦: 滑动/粘着状态正确切换 |
| V-CNT-04 | 搜索调度 | 搜索频率按 `search_frequency` 正确跳过 |
| V-CNT-05 | 显式接触 | 显式动力学碰撞能量守恒（无穿透累积） |

---

### 错误处理

| 错误码范围 | 场景 | 严重级 |
|------------|------|--------|
| 50200 | 搜索失败（无效几何） | ERROR |
| 50201 | 穿透超阈值 | WARNING |
| 50202 | 接触对配对不匹配 | ERROR |
| 50203 | 搜索树构建失败（内存） | FATAL |
| 50204 | 状态更新不收敛 | WARNING |
| 50205 | 装配溢出（triplet 超限） | ERROR |

不使用 `STOP`。错误通过 `ErrorStatusType` 沿调用链传播。错误码范围: **50200–50299**。

---

### 已知问题 (v3.0)

| 问题 | 状态 | 说明 |
|------|------|------|
| CMake 排除 Contact 目录 | 已记录 | `RT_Solv.f90` 仍 USE `RT_Cont_Solv`，需后续对齐 |
| `MD_Model_Brg` 悬挂引用 | 已修复 | DANGLING-REF (v2.0) 已注释 |

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-17 | 初始版本 |
| v1.1 | 2026-04-25 | 补充错误处理/域际关系 |
| v2.0 | 2026-04-26 | 完全重写: 对齐实际文件; AUTHORITY/LEGACY 标注; Bridge 激活; 域柱合同 |
| v3.0 | 2026-04-28 | 标准化 7 大章节格式; 补全跨层数据流/验收标准; 对齐四型 TYPE 细节 |

---

*维护注记: 新增接触子模块时在「§3 功能模块清单」和「§4 对外接口」补一行。*
