# 推演卡：L4_PH / Material / Elas（各向同性线弹性）

> 推演引擎 v1.0 | 2026-04-26 | 域类型：计算域（公式→步骤链推演）

---

## [A] 意图推断

**域**：L4_PH / Material / Elas

**CONTRACT 摘要**：各向同性线弹性本构关系——从材料参数(E, nu)计算 Voigt 弹性矩阵 D_el，执行应力更新 sigma = D_el * epsilon，提供一致切线矩阵。

**核心意图**：
- 校验材料参数合法性
- 从参数计算派生量（Lame 参数、体积模量）
- 构造 6x6 弹性刚度矩阵 D_el
- 计算应力 sigma = D_el * epsilon
- 返回一致切线 C_tan = D_el

**Verb 族分布**：Init, Validate, Compute

**Phase 分布**：Config, Local

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | mat_id, elas_type, E, nu, G, K_bulk, lambda, rho, is_valid | 材料参数 + 派生常数，分析期不变 |
| **State** | N | — | 线弹性无内变量演化 |
| **Algo** | N | — | 固定算法（Voigt 矩阵乘法），无选择 |
| **Ctx** | Y | D_el(6,6), stress_trial(6), D_el_cached | 热路径临时工作数组 |

**签名模式**：`(desc, ctx, status)` — 无 State/Algo

---

## [C] 算法锚定

**推演策略**：计算域 → 物理公式 → 有序步骤链

**理论基础**：

```
sigma = D_el : epsilon   (各向同性线弹性, Voigt 记法)

D_el = [lambda+2G  lambda   lambda    0  0  0]
       [lambda    lambda+2G  lambda    0  0  0]
       [lambda     lambda   lambda+2G  0  0  0]
       [0          0         0         G  0  0]
       [0          0         0         0  G  0]
       [0          0         0         0  0  G]

G = E / (2(1+nu))
lambda = E*nu / ((1+nu)(1-2nu))
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Validate_Props | Config | Validate | O(1) | E > 0, -1 < nu < 0.5 |
| S2 | Init_From_Props | Config | Init | O(1) | props → desc (含 G, lambda, K) |
| S3 | Build_D_el | Local | Compute(Build) | O(36) | 构造 6x6 Voigt 弹性矩阵 |
| S4 | Compute_Stress | Local | Compute | O(36) | sigma = D_el * epsilon |
| S5 | Compute_Tangent | Local | Compute | O(36) | C_tan = D_el (线弹性恒等) |
| S6 | Init_SDV | Config | Init | O(1) | 弹性无状态变量，空操作 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `PH_Mat_Elas_Validate_Props` | Config | Validate | (nprops, props, status) | COLD | _Core.f90 |
| `PH_Mat_Elas_Init_From_Props` | Config | Init | (desc, nprops, props, status) | COLD | _Core.f90 |
| `PH_Mat_Elas_Build_D_el` | Local | Compute(Build) | (desc, ctx, status) | HOT | _Core.f90 |
| `PH_Mat_Elas_Compute_Stress` | Local | Compute | (ctx, strain, stress, status) | HOT | _Core.f90 |
| `PH_Mat_Elas_Compute_Tangent` | Local | Compute | (ctx, tangent, status) | HOT | _Core.f90 |
| `PH_Mat_Elas_Init_SDV` | Config | Init | (nsdv, sdv, status) | COLD | _Core.f90 |
| `PH_Mat_Elas_Brg_FromL3Desc` | Populate | Bridge | (l3_desc, l4_desc, status) | COLD | _Brg.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| PH_Mat_Elas_Def.f90 (模板) | ~40 | Desc + Ctx TYPE 定义 |
| PH_Mat_Elas_Core.f90 (模板) | ~180 | 6 个过程（模板中已完整） |
| PH_Mat_Elas_Brg.f90 (模板) | ~40 | 1 个 Bridge 过程 |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 模板中过程缺少标准 Phase 注释 |
| 实际 f90 文件落地 | — | P0 | 模板在 docs/templates，需确认 ufc_core 有对应实现 |

### 评估结论

**PH_Mat_Elas 是推演引擎在计算域的黄金样板——算法步骤链完整对应 Phase x Verb 双轴。** 模板已包含全部 6+1 个过程的完整 Fortran 实现。
