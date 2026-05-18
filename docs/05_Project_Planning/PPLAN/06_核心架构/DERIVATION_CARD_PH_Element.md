# 推演卡：L4_PH / Element

> 推演引擎 v1.0 | 2026-04-26 | 域类型：计算域（积分核推演）

---

## [A] 意图推断

**域**：L4_PH / Element

**CONTRACT 摘要**：形函数、Jacobian、B 阵、高斯积分；金线 `Compute_Ke` / `Compute_Fe`；对应 HYPLAS ELEMLIB。不做全局 CSR 组装（L5）。

**核心意图**：
- 单元刚度阵 Ke = integral(B^T D B dOmega)
- 单元力向量 Fe = integral(B^T sigma dOmega)
- 单元内力 Fint
- 单元质量阵 Me
- 管理单元族注册与分发

**Verb 族分布**：Init, Compute, Access

**Phase 分布**：Config, Populate, Local

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | elem_type_id, n_nodes, n_dof_per_node, n_int_points, coords cache | Populate 注入的元数据，步内只读 |
| **State** | Y | stress, strain (per IP) | WriteBack 白名单中的应力/应变态 |
| **Algo** | Y | integration_order, hourglass_control | 积分阶、沙漏控制等选择 |
| **Ctx** | Y | B_matrix, N_shape, detJ, weight, Ke_local, Fe_local | 高斯点级临时工作区 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：计算域 → 高斯积分核心循环

**理论基础**：

```
Ke = SUM_{gp} w_gp * B^T(xi_gp) * D * B(xi_gp) * detJ(xi_gp)
Fe = SUM_{gp} w_gp * B^T(xi_gp) * sigma(xi_gp) * detJ(xi_gp)
Me = SUM_{gp} w_gp * N^T(xi_gp) * rho * N(xi_gp) * detJ(xi_gp)
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(1) | 域级初始化 |
| S2 | Core_Finalize | Config | Init(Finalize) | O(1) | 域级清理 |
| S3 | Compute_Ke | Local | Compute | O(n_gp*ndof^2) | 单元刚度阵（金线） |
| S4 | Compute_Fe | Local | Compute | O(n_gp*ndof) | 单元力向量（金线） |
| S5 | Compute_Fint | Local | Compute | O(n_gp*ndof) | 单元内力 |
| S6 | Compute_Mass | Local | Compute | O(n_gp*ndof^2) | 单元质量阵 |
| S7 | Get_NDof | (any) | Access(Get) | O(1) | 查询自由度数 |
| S8 | Get_NNodes | (any) | Access(Get) | O(1) | 查询节点数 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `PH_Elem_Core_Init` | Config | Init | (desc, state, algo, ctx, status) | COLD | PH_Elem_Core.f90 |
| `PH_Elem_Core_Finalize` | Config | Init(Fin) | (state, ctx, status) | COLD | PH_Elem_Core.f90 |
| `PH_Elem_Core_Compute_Ke` | Local | Compute | (desc, state, algo, ctx, Ke, status) | HOT | PH_Elem_Core.f90 |
| `PH_Elem_Core_Compute_Fe` | Local | Compute | (desc, state, algo, ctx, Fe, status) | HOT | PH_Elem_Core.f90 |
| `PH_Elem_Core_Compute_Fint` | Local | Compute | (desc, state, ctx, Fint, status) | HOT | PH_Elem_Core.f90 |
| `PH_Elem_Core_Compute_Mass` | Local | Compute | (desc, algo, ctx, Me, status) | HOT | PH_Elem_Core.f90 |
| `PH_Elem_Core_Get_NDof` | (any) | Access(Get) | (desc) -> i4 | COLD | PH_Elem_Core.f90 |
| `PH_Elem_Core_Get_NNodes` | (any) | Access(Get) | (desc) -> i4 | COLD | PH_Elem_Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| PH_Elem_Core.f90 | ~200+ | 9 个过程（含 private helper） |
| PH_Elem_Def.f90 | — | TYPE 定义 |
| PH_Elem_Ctx.f90 | — | 上下文 TYPE |
| 203 个族文件 | — | Beam/Shell/Solid/Truss/Thermal 等 |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 现有过程缺少标准 Phase 注释 |

### 评估结论

**PH_Element 域级核心过程已完整。** 核心计算金线 `Compute_Ke`/`Compute_Fe`/`Compute_Fint`/`Compute_Mass` 均已实现。需补全 Phase 注释标注。
