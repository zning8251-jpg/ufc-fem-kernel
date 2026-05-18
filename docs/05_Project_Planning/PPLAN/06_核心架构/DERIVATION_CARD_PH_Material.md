# 推演卡：L4_PH / Material（域级总览）

> 推演引擎 v1.0 | 2026-04-26 | 域类型：计算域 + 分发域（公式推演 + 注册路由）

---

## [A] 意图推断

**域**：L4_PH / Material（域级，含 11 族子域）

**CONTRACT 摘要**：给定应变/变形增量，计算应力、一致切线 C_tan、更新 SDV；支持弹塑/粘弹/损伤/超弹/蠕变/UMAT。对应 HYPLAS MATLIB 求值侧。

**核心意图**：
- 域级初始化/终结化
- 应力更新（通用分发 → 族内核）
- 一致切线计算
- 状态变量初始化/更新/回滚
- 材料模型注册与分发

**Verb 族分布**：Init, Validate, Compute, Evolve, Access, Control(Route), Bridge

**Phase 分布**：Config, Populate, Step, Increment, Local

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | matModel, props, matId (slot 内) | Populate 后的材料参数视图 |
| **State** | Y | stress, C_tan, stateVars, stateVars_n | IP 级演化态（跨步持久） |
| **Algo** | Y | integration_scheme, sub_stepping, finite_strain | 积分格式等选择参数 |
| **Ctx** | Y | 统一上下文 PH_Mat_Ctx | IP 级临时计算工作区 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：分发域 → 注册路由 + 族内核调用

**域级架构**：

```
Route(matModel):
  Elastic/   → PH_Mat_Elas_* (Elas 推演卡已单独覆盖)
  Plastic/   → PH_MatPlast_* (J2/Hill/Chaboche/Barlat/Crystal)
  Geotech/   → PH_MatGeo_*   (MohrCoulomb/DruckerPrager/CamClay)
  HyperElas/ → PH_MatHyper_*
  Damage/    → PH_MatDam_*   (Gurson 等)
  Visc/      → PH_MatVisc_*  (粘弹+蠕变)
  Composite/ → PH_MatComp_*
  Coupling/  → PH_MatCpl_*
  Special/   → PH_MatSpcl_*
  PorousFoam/→ PH_MatPor_*
  UMAT/      → PH_UserSub_UMAT (用户子程序)
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(n_mat) | 域级初始化，slot 池分配 |
| S2 | Core_Finalize | Config | Init(Finalize) | O(n_mat) | 域级清理 |
| S3 | Update_Stress | Local | Compute | O(36+) | 通用分发：route → 族内核应力更新 |
| S4 | Compute_Tangent | Local | Compute | O(36+) | 通用分发：route → 族内核切线计算 |
| S5 | Init_SDV | Config | Init | O(n_sdv) | 状态变量初始化 |
| S6 | Get_NSDV | (any) | Access(Get) | O(1) | 查询 SDV 数量 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `PH_Mat_Core_Init` | Config | Init | (domain, status) | COLD | PH_Mat_Core.f90 |
| `PH_Mat_Core_Finalize` | Config | Init(Fin) | (domain, status) | COLD | PH_Mat_Core.f90 |
| `PH_Mat_Core_Update_Stress` | Local | Compute | (slot, strain_inc, status) | HOT | PH_Mat_Core.f90 |
| `PH_Mat_Core_Compute_Tangent` | Local | Compute | (slot, tangent, status) | HOT | PH_Mat_Core.f90 |
| `PH_Mat_Core_Init_SDV` | Config | Init | (slot, status) | COLD | PH_Mat_Core.f90 |
| `PH_Mat_Core_Get_NSDV` | (any) | Access(Get) | (slot) -> i4 | COLD | PH_Mat_Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| PH_Mat_Core.f90 | ~150 | 6 个域级过程 |
| Elas/PH_Mat_Elas_Core.f90 | ~210 | 6 个族内核过程（已标注） |
| Plast/PH_MatPlast*.f90 | 5 文件 | J2/Hill/Chaboche/Barlat/Crystal |
| Geo/PH_MatGeo*.f90 | 3 文件 | MC/DP/CamClay |
| Damage/PH_MatDam*.f90 | 1 文件 | Gurson |
| Dispatch/PH_MatEval.f90 等 | 4 文件 | 分发与求值 |
| Base/PH_MatReg.f90 等 | 3 文件 | 注册表 |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | PH_Mat_Core.f90 缺标准 Phase 注释 |
| 族内核 Phase 标注 | — | P2 | 各子族 Core 文件统一标注 |

### 评估结论

**PH_Material 域级核心 6 个过程已完整。** 族内核实现分布在 11 个子目录中。关键分发链路（注册表→求值器）完整。待补全 Phase 注释标注。
