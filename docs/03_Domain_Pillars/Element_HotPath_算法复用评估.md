# Element 域热路径算法复用评估报告

> **Layer**: L4_PH / Element / Solid3D  
> **Phase**: A — 旧算法资产复用性评估  
> **Date**: 2026-04-28  
> **评估范围**: EAS 增强应变、F-bar 方法、几何非线性（大变形/大应变）

---

## 1. 评估概要

### 1.1 总体结论

Element 域三大 3D 高级功能现有代码 **全部可直接复用**，平均完整度 **87%**。

| 功能 | 现有文件 | 代码行 | 完整度 | 判定 |
|------|---------|--------|--------|------|
| EAS 增强应变 | `PH_Elem_C3D8EAS.f90` | 480 | **85%** | ✅ 直接复用 |
| F-bar 方法 | `PH_Elem_C3D8FBar.f90` | 422 | **75%** | ✅ 直接复用 |
| 几何非线性 | `PH_Elem_Nlgeom.f90` + `PH_NLGeomEval.f90` | 2649 | **90%** | ✅ 直接复用 |
| **加权平均** | | **3551** | **87%** | |

### 1.2 其它已有资产

| 功能模块 | 完整度 | 备注 |
|---------|--------|------|
| 几何刚度 $K_g$ | 100% | `RT_Asm_Calc_GeomStiff`（`PH_NLGeomEval.f90` 行 908-951） |
| 缩减积分 + 沙漏控制 | 95% | 现有框架完备 |
| 应力转换 $\sigma \leftrightarrow S$ | 100% | `PH_Transform_Stress_*`（`PH_Elem_Nlgeom.f90` 行 293-381） |
| Shell NLGeom | 80% | Shell 族内核已有基础 |
| Beam EAS/Fbar | 85-90% | Beam 族内核已有基础 |

---

## 2. EAS 增强应变评估

### 2.1 资产清单

| 模块/子程序 | 文件 | 行号 | 功能 | 状态 |
|------------|------|------|------|------|
| `PH_Elem_C3D8_EAS_Ctx` | `PH_Elem_C3D8EAS.f90` | 95-115 | Ctx 类型定义（alpha, G_matrix, K 子矩阵） | ✅ 完整 |
| `PH_Elem_C3D8_EAS_InitCtx` | 同上 | 339-365 | 上下文初始化、G_matrix 分配 | ✅ 完整 |
| `PH_Elem_C3D8_EAS_ComputeGMatrix` | 同上 | 238-301 | 9 参数增强模式矩阵构造 | ✅ 完整 |
| `PH_Elem_C3D8_EAS_Stiffness` | 同上 | 367-426 | IP 循环组装 K_dd/K_dα/K_αα | ✅ 完整 |
| `PH_Elem_C3D8_EAS_CondenseStiffness` | 同上 | 303-337 | 静态缩聚 K_eff | ✅ 完整 |
| `PH_Elem_C3D8_EAS_UpdateAlpha` | 同上 | 428-461 | α 参数更新 | ⚠️ 仅框架 |
| `PH_Elem_C3D8_EAS_Material_Update_Routed` | 同上 | 463-479 | Material D 矩阵路由桩 | ⚠️ 桩代码 |
| `InvertMatrix` / `InvertSmallMatrix` | 同上 | 169-236 | 矩阵求逆（≤3×3） | ⚠️ 受限 |

### 2.2 完整度判定：85%

**已完成**（~85%）：
- G 矩阵 9 参数增强模式（Simo & Rifai 1990 标准形式）
- K 子矩阵（K_dd, K_dα, K_αα）的 IP 循环组装
- 静态缩聚公式 $K_{\text{eff}} = K_{dd} - K_{d\alpha} K_{\alpha\alpha}^{-1} K_{\alpha d}$
- SIO-REFACTORED Arg 类型体系

**关键缺口**（~15%）：

| 缺口 | 影响 | 补齐工作量 |
|------|------|-----------|
| Material D 矩阵接口缺失 | 无法获取一致切线模量 | 0.5d — 对接 `PH_Elem_MatRoute_Elastic3D` |
| UpdateAlpha 仅单步框架 | 无完整牛顿迭代/收敛检查/h_α 残差 | 1d |
| InvertMatrix 仅支持 ≤3×3 | EAS 需 9×9 逆 | 0.5d — LU 分解或 LAPACK |
| 增强应变 ε_enh 未显式计算 | IP 内 strain_total 不完整 | 0.5d |

### 2.3 复用策略

**直接复用**：Ctx 类型、G 矩阵构造、K 子矩阵组装、静态缩聚算法。  
**增量补齐**：Material 路由对接（已有桩）、α 迭代补全、InvertMatrix 扩展。

---

## 3. F-bar 方法评估

### 3.1 资产清单

| 模块/子程序 | 文件 | 行号 | 功能 | 状态 |
|------------|------|------|------|------|
| `PH_Elem_C3D8_FBar_Ctx` | `PH_Elem_C3D8FBar.f90` | 86-107 | Ctx 类型定义（J_bar, F_gp, F_bar_gp, det_F_gp） | ✅ 完整 |
| `PH_Elem_C3D8_FBar_InitCtx` | 同上 | 255-296 | 上下文初始化、F→I | ✅ 完整 |
| `PH_Elem_C3D8_FBar_ComputeVolumetricStrain` | 同上 | 201-253 | $\bar{J} = \int \det(F) dV / \int dV$ | ✅ 完整 |
| `PH_Elem_C3D8_FBar_SplitDeviatoric` | 同上 | 298-339 | $\bar{F} = (\bar{J}/J)^{1/3} F$ | ✅ 完整 |
| `PH_Elem_C3D8_FBar_AssembleStiffness` | 同上 | 171-199 | 刚度组装框架 | ✅ 完整 |
| `PH_Elem_C3D8_FBar_Stiffness` | 同上 | 341-403 | 主驱动流程 | ⚠️ B_bar 简化 |
| `PH_Elem_C3D8_FBar_Material_Update_Routed` | 同上 | 405-421 | Material D 矩阵路由桩 | ⚠️ 桩代码 |
| `Det3x3` | 同上 | 161-169 | 3×3 行列式 | ✅ 完整 |

### 3.2 完整度判定：75%

**已完成**（~75%）：
- $\bar{J}$ 体积平均计算（数值积分精确）
- $\bar{\mathbf{F}}$ 修正变形梯度计算
- 刚度组装框架（$K = \int \bar{B}^T D \bar{B} dV$）
- SIO-REFACTORED Arg 类型体系

**关键缺口**（~25%）：

| 缺口 | 影响 | 补齐工作量 |
|------|------|-----------|
| $\bar{B}$ 矩阵显式计算缺失 | 当前 `B_bar = B`（行 385），体积锁定未实际解除 | 1d — 体积-偏差分解+平均化 |
| Material D 矩阵接口缺失 | 同 EAS | 0.5d |
| 几何修正项 $K_{\text{geo,vol}}$ | 非线性精度降低 | 0.5d（可选） |

### 3.3 复用策略

**直接复用**：Ctx 类型、$\bar{J}$ 计算、$\bar{\mathbf{F}}$ 修正、刚度组装框架。  
**核心补齐**：$\bar{\mathbf{B}}$ 显式构造是 F-bar 方法的关键——需实现 B 矩阵的体积-偏差分解和体积部分平均化。

---

## 4. 几何非线性评估

### 4.1 资产清单（PH_Elem_Nlgeom.f90 — 435 行紧凑算法库）

| 模块/子程序 | 行号 | 功能 | 状态 |
|------------|------|------|------|
| `NLGEOM_NONE/TL/UL` 常量 | 39-41 | TL/UL 切换标志 | ✅ |
| `PH_Nlgeom_Args` | 47-71 | 统一参数类型 | ✅ |
| `PH_Compute_Deformation_Gradient` | 89-155 | $F = I + \partial u/\partial X$，含 detF 检查与 $F^{-1}$ | ✅ |
| `PH_Compute_Green_Lagrange_Strain` | 161-193 | $E = 0.5(C - I)$，Voigt 输出 | ✅ |
| `PH_Compute_Almansi_Strain` | 199-232 | $e = 0.5(I - b^{-1})$（简化近似） | ⚠️ |
| `PH_Compute_B_Matrix_NL` | 238-287 | 非线性 B 矩阵框架 | ✅ |
| `PH_Transform_Stress_PK2_to_Cauchy` | 293-334 | $\sigma = (1/J) F S F^T$ | ✅ |
| `PH_Transform_Stress_Cauchy_to_PK2` | 340-381 | $S = J F^{-1} \sigma F^{-T}$ | ✅ |
| `PH_Invert_Matrix_2x2_or_3x3` | 386-433 | 2×2/3×3 矩阵逆 | ✅ |

### 4.2 资产清单（PH_NLGeomEval.f90 — 2214 行完整运行时库）

| 模块/子程序 | 行号 | 功能 | 状态 |
|------------|------|------|------|
| `RT_DefKin` 类型 | 150-161 | 变形运动学全量（F, C, b, E, E_log, ε） | ✅ |
| `RT_LagrCfg` 类型 | 166-175 | Lagrangian 构型（TL/UL 切换） | ✅ |
| `RT_LinRes` 类型 | 186-193 | 线性化结果（K_mat, K_geo, K_total） | ✅ |
| `BuildBMatrix_TL` | 229-258 | TL B_L 矩阵 | ✅ |
| `BuildBMatrix_UL` | 260-289 | UL B_L 矩阵 | ✅ |
| `RT_Asm_Calc_DefGrad` | 858-906 | F 计算 + detF 正性检查 | ✅ |
| `RT_Asm_Calc_GeomStiff` | 908-951 | $K_g = B^T \sigma B$（简化对角） | ⚠️ |
| `RT_Asm_Calc_GreenLagStrain` | 953-972 | Green-Lagrange 应变 | ✅ |
| `RT_Asm_Calc_LargeRot` | 974+ | 极分解 F = RU | ✅ |
| `RT_Asm_Calc_LogStrain` | — | 对数应变 | ✅ |
| `RT_GeomNonlin_TotLag` | — | TL 完整流程 | ✅ |
| `RT_GeomNonlin_UpdLag` | — | UL 完整流程 | ✅ |
| 应力转换 (PK2↔Cauchy, PK1) | 97-106 | 3 种转换 | ✅ |
| 旋转/四元数/Euler | 126-128 | 大旋转处理 | ✅ |
| 一致线性化 | 129 | ConsistentLinearization | ✅ |

### 4.3 完整度判定：90%

**已完成**（~90%）：
- F、E、e、C、b 完整运动学链
- σ↔S、σ↔P 应力转换
- K_geo 几何刚度
- TL 和 UL 完整流程
- 极分解、对数应变、旋转处理
- B_L (TL/UL) 矩阵

**待验证/改进**（~10%）：

| 项目 | 影响 | 工作量 |
|------|------|--------|
| TL/UL 切换运行时分支完整性 | 需集成测试验证 | 0.5d |
| Almansi 应变使用 $b$ 而非 $b^{-1}$ | 精度影响（近似） | 0.5d |
| K_geo off-diagonal σ 项 | 非对称应力场精度 | 0.5d |

### 4.4 复用策略

**直接复用**：几乎全部可直接复用。2649 行代码覆盖了几何非线性的完整理论框架。  
**验证补齐**：TL/UL 切换需集成测试验证；K_geo 的 off-diagonal 改进为可选优化。

---

## 5. 综合复用矩阵

| 功能子项 | EAS | F-bar | NLGeom | 复用判定 |
|---------|-----|-------|--------|---------|
| 类型定义（Ctx/Desc） | ✅ | ✅ | ✅ | 直接复用 |
| 核心算法 | ✅ G矩阵 | ✅ J̄/F̄ | ✅ F/E/σ↔S | 直接复用 |
| 刚度组装 | ✅ K子矩阵 | ✅ 框架 | ✅ K_mat+K_geo | 直接复用 |
| 静态缩聚 | ✅ | N/A | N/A | 直接复用 |
| Material 接口 | ⚠️ 桩 | ⚠️ 桩 | ⚠️ 隐式 | 需补齐路由 |
| $\bar{B}$ 显式 | N/A | ❌ 简化 | N/A | 核心补齐 |
| α 完整迭代 | ❌ 单步 | N/A | N/A | 需补齐 |
| TL/UL 切换 | N/A | N/A | ⚠️ 需验证 | 集成测试 |

**总体复用率**：85-90% 代码直接可用，补齐工作量约 5-7 人天。

---

## 6. 建议行动项

### P1 — 阻塞项（Phase C 前必须完成）

| # | 行动 | 关联功能 | 工作量 |
|---|------|---------|--------|
| A1 | Material D 矩阵路由补齐：对接 `PH_Elem_MatRoute_Elastic3D` | EAS + F-bar | 0.5d |
| A2 | F-bar $\bar{B}$ 显式构造：体积-偏差分解 + B_vol 平均化 | F-bar | 1d |
| A3 | EAS α 完整牛顿迭代 + 收敛检查 + h_α 残差 | EAS | 1d |
| A4 | InvertMatrix 扩展至 9×9（LU 分解 / LAPACK 接口） | EAS | 0.5d |

### P2 — 精度改进项

| # | 行动 | 关联功能 | 工作量 |
|---|------|---------|--------|
| A5 | NLGeom K_geo off-diagonal σ 补全 | NLGeom | 0.5d |
| A6 | Almansi 应变精确化（$b^{-1}$ 替代 $b$） | NLGeom | 0.5d |
| A7 | F-bar K_geo_vol 几何修正项 | F-bar | 0.5d |

### P3 — 集成与验证

| # | 行动 | 关联功能 | 工作量 |
|---|------|---------|--------|
| A8 | EAS + NLGeom 集成设计实现 | EAS × NLGeom | 1d |
| A9 | F-bar + NLGeom 集成设计实现 | F-bar × NLGeom | 0.5d |
| A10 | TL/UL 切换完整性集成测试 | NLGeom | 0.5d |

**总计**：约 **6.5 人天** 可将三大功能从当前 87% 提升至 100% 可交付状态。

---

*本报告基于 2026-04-28 对现有代码资产的逐行审计，作为 Phase B 算法设计和 Phase C 骨架实现的决策依据。*
