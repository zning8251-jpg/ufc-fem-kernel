# Material Domain Reform Log

**Date**: 2026-05-11  
**Task**: Material域逐族改造实施 (Task #3)

---

## 1. 改造动作清单

### 1.1 Geo族 — 统一Core创建

| 动作 | 文件 | 说明 |
|------|------|------|
| **审查** | `PH_Mat_Geo_DP_Core.f90` | SIO现代风格，typed args (MD_Mat_DP_Desc, PH_Mat_PLM_DP_State) |
| **审查** | `PH_Mat_Geo_DruckerPrager_Core.f90` | Legacy UMAT兼容接口 (props/statev arrays) |
| **结论** | — | 两者**互补**非重复：DP_Core = SIO核心，DruckerPrager_Core = Legacy facade。均保留。 |
| **新增** | `Geo/PH_Mat_Geo_Core.f90` | 族级统一Core，按sub_type分发到DP/MC/CC模型Core |

**PH_Mat_Geo_Core.f90 路由表**：
- `PH_MAT_GEO_SUB_DP_LINEAR (701)` / `PH_MAT_GEO_SUB_DP_CAP (702)` → `PH_Mat_Geo_DP_Core_Update`
- `PH_MAT_GEO_SUB_MC (703)` → `PH_Mat_Geo_MC_Eval_Wrapper`
- `PH_MAT_GEO_SUB_CAM_CLAY (704)` → `PH_Mat_Geo_CC_Eval_Wrapper`

### 1.2 Damage族 — 统一Core创建

| 动作 | 文件 | 说明 |
|------|------|------|
| **新增** | `Damage/PH_Mat_Damage_Core.f90` | 族级统一Core，按sub_type分发到Gurson/Lemaitre |

**PH_Mat_Damage_Core.f90 路由表**：
- `PH_MAT_DMG_SUB_GURSON (704)` → `PH_Mat_Damage_Gurson_Dispatch` (内部adapter)
- `PH_MAT_DMG_SUB_LEMAITRE (705)` → `PH_Mat_Damage_Lemaitre_Dispatch` (内部adapter)

### 1.3 Composite族 — 统一Core创建

| 动作 | 文件 | 说明 |
|------|------|------|
| **新增** | `Composite/PH_Mat_Comp_Core.f90` | 族级统一Core，按sub_type分发到CLT/Hashin/Fabric |

**PH_Mat_Comp_Core.f90 路由表**：
- `PH_MAT_COMP_SUB_CLT (801)` → `PH_Mat_Comp_CLT_Eval` (inline stub)
- `PH_MAT_COMP_SUB_HASHIN (802)` → `PH_Mat_Comp_Hashin_Eval` (delegate)
- `PH_MAT_COMP_SUB_FABRIC (803)` → `PH_Mat_Comp_Fabric_Eval` (delegate)

### 1.4 域级文件重命名

| 动作 | 文件 | 说明 |
|------|------|------|
| **新增** | `PH_Mat_Dsp.f90` | MODULE名 `PH_Mat_Dsp`，过程名不变 (`PH_Mat_Dispatch_Stress/Tangent`) |
| **修改** | `PH_Mat_Core.f90` | `USE PH_Mat_Dispatch` → `USE PH_Mat_Dsp` |
| **保留** | `PH_Mat_Dispatch.f90` | 旧文件保留供参考，未来CI门禁可标记DEPRECATED |

---

## 2. 受影响文件列表

### 新增文件 (4)
| 文件 | MODULE名 |
|------|----------|
| `ufc_core/L4_PH/Material/Geo/PH_Mat_Geo_Core.f90` | `PH_Mat_Geo_Core` |
| `ufc_core/L4_PH/Material/Damage/PH_Mat_Damage_Core.f90` | `PH_Mat_Damage_Core` |
| `ufc_core/L4_PH/Material/Composite/PH_Mat_Comp_Core.f90` | `PH_Mat_Comp_Core` |
| `ufc_core/L4_PH/Material/PH_Mat_Dsp.f90` | `PH_Mat_Dsp` |

### 修改文件 (1)
| 文件 | 修改内容 |
|------|----------|
| `ufc_core/L4_PH/Material/PH_Mat_Core.f90` | `USE PH_Mat_Dispatch` → `USE PH_Mat_Dsp` |

### 未修改文件
- `PH_Mat_Dispatch.f90` — 保留原件，标记候选DEPRECATED
- `LegacyFacadeUMATs.f90` — FROZEN，不动
- 所有现有模型Core — 逻辑不变

---

## 3. Plast族5模型Core签名一致性检查

### 检查结果：**✗ 不一致 — 3种模式共存**

| 模型Core | 签名模式 | PUBLIC接口 |
|-----------|----------|-----------|
| `PH_Mat_Plast_J2_Iso_Core` | **SIO步骤式** | `PH_J2_Init`, `PH_J2_TrialStress`, `PH_J2_YieldCheck`, `PH_J2_RadialReturn`, `PH_J2_ConsistentTangent`, `PH_J2_ComputeStress` |
| `PH_Mat_Plast_J2_UMAT_Core` | **UMAT完整路径** | `PH_Mat_PLM_J2_UpdateStress` (legacy UMAT ABI) |
| `PH_Mat_Plast_Hill_Core` | **UMAT Adapter混合** | `PH_Mat_Hill_Calc_Stress`, `PH_Hill_Plasticity_Eval`; uses `PH_UMAT_Context`, `MatPoint_In/Out` |
| `PH_Mat_Plast_Chaboche_Core` | **UMAT Adapter混合** | 使用`PlastMatBase`, `PH_Mat_Integ_Shared`; 内部类型 |
| `PH_Mat_Plast_Barlat_Core` | **自包含本地TYPE** | 使用`Barlat_Params`, `Barlat_State`; 独立于UMAT adapter |
| `PH_Mat_Plast_Crystal_Core` | **纯UMAT桩** | `UF_CrystalPlasticity_UMAT` (Abaqus ABI签名) |

### 差异摘要

1. **J2_Iso_Core** — 最符合SIO规范：粒度最细的step函数，Error propagation完备
2. **Hill / Chaboche** — 混合模式：通过`PH_Mat_Core_UMAT_Adapter` + `PH_Mat_Integ_Shared`桥接
3. **Barlat** — 自包含TYPE系统，未使用公共adapter
4. **Crystal** — 纯legacy UMAT stub，保留ID 266占位

### 建议（后续Phase）

- 统一目标签名：`PH_Mat_Plast_<Model>_Eval(desc, state, algo, ctx, status)` (5参数SIO)
- J2_Iso_Core已基本就绪，可作为模板
- Hill/Chaboche需重构adapter层到统一签名
- Crystal保持UMAT stub直至物理实现

---

## 4. 设计决策记录

| 决策 | 理由 |
|------|------|
| DP_Core 与 DruckerPrager_Core 均保留 | 互补关系：SIO核心 + Legacy facade |
| MODULE名改为PH_Mat_Dsp，过程名保持PH_Mat_Dispatch_* | 最小化下游影响 |
| 新Core的Dispatch_Eval使用delegate桩而非直接调用 | 避免修改Eval层现有工作代码 |
| PH_Mat_Dispatch.f90旧文件保留 | 向后兼容，未来通过CI标记deprecated |
