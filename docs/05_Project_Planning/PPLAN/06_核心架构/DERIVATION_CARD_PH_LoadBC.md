# 推演卡：L4_PH / LoadBC

> 推演引擎 v1.0 | 2026-04-26 | 域类型：混合域（计算 + 施加推演）

---

## [A] 意图推断

**域**：L4_PH / LoadBC

**CONTRACT 摘要**：载荷/边界条件 PH 侧表示与数值准备。Populate 后持有步内可用的载荷/BC 视图；为单元场和 L5 施加逻辑提供已解析的数据结构。

**核心意图**：
- 域级生命周期管理
- 集中力、分布力、压力、体积力、重力、热载荷组装
- Dirichlet 边界条件施加
- 幅值曲线求值

**Verb 族分布**：Init, Compute, Assemble(Apply), Bridge

**Phase 分布**：Config, Populate, Iteration

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | PH_Load_Cache_Type, PH_BC_Cache_Type | Populate 后载荷/BC slot |
| **State** | Y | F_ext, F_body, F_thermal, reaction | 步级外力向量（跨增量） |
| **Algo** | Y | 处置方法(Elimination/Penalty/Lagrange)、分布积分 | 方法选择参数 |
| **Ctx** | Y | 活跃载荷/BC 列表、step_idx/incr_idx、压力面列表 | 增量级临时工作区 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：载荷侧 = 计算域（力向量组装），BC 侧 = 施加域（Dirichlet 处置）

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(1) | 域级初始化 |
| S2 | Core_Finalize | Config | Init(Fin) | O(1) | 域级清理 |
| S3 | Concentrated_Force | Iteration | Compute | O(n_loads) | 集中力组装到 F_ext |
| S4 | Distributed_Load | Iteration | Compute | O(n_elem*n_gp) | 分布面载/体载积分 |
| S5 | Pressure_Load | Iteration | Compute | O(n_face*n_gp) | 压力载荷积分 |
| S6 | Body_Force | Iteration | Compute | O(n_elem*n_gp) | 体积力积分 |
| S7 | Gravity_Load | Iteration | Compute | O(n_elem) | 重力载荷 |
| S8 | Thermal_Load | Iteration | Compute | O(n_elem*n_gp) | 热载荷向量 |
| S9 | Apply_Dirichlet | Iteration | Assemble(Apply) | O(n_bc) | Dirichlet BC 处置 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `PH_LoadBC_Core_Init` | Config | Init | (..., status) | COLD | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Core_Finalize` | Config | Init(Fin) | (..., status) | COLD | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Concentrated_Force` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Distributed_Load` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Pressure_Load` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Body_Force` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Gravity_Load` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Thermal_Load` | Iteration | Compute | (..., F_ext, status) | HOT | PH_LoadBC_Core.f90 |
| `PH_LoadBC_Apply_Dirichlet` | Iteration | Assemble(Apply) | (..., K, F, status) | HOT | PH_LoadBC_Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| PH_LoadBC_Core.f90 | ~250 | 9 个过程（全部已实现） |
| PH_LoadBC_Def.f90 | — | TYPE 定义 |
| PH_Load_Def.f90 | — | 载荷 TYPE |
| PH_BC_Def.f90 | — | BC TYPE |
| PH_BC_Brg.f90 | — | Bridge |
| 11 个文件 | — | 域完整实现 |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 现有 9 个过程缺少标准 Phase 注释 |

### 评估结论

**PH_LoadBC 域核心过程已完整（9 个）。** 覆盖 6 种载荷类型 + Dirichlet BC 施加。待补全 Phase 注释标注。
