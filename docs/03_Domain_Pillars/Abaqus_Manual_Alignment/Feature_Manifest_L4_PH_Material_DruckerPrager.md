# Feature Manifest — L4_PH / Material / Plast / Linear Drucker–Prager

**工单性质**：主/辅 TYPE 分工 + SIO 五参路由 + 与 Abaqus 手册的**理论锚点**（非 Abaqus 目录名）。  
**技能纪律**：`ufc-layer-domain-feature`（六层·四类·四链）、`ufc-structured-io`（五参 `(desc, state, algo, ctx, args)` + 单一 `*_Arg`，禁止新建 `inp`/`out` 对偶）。

---

## 1. 手册锚点（PyMuPDF 物理页，THEORY.pdf）

| 物理页（1-based） | 手册内容（摘录） |
|------------------|------------------|
| 821 | §4.4 总目 — 非金属塑性 |
| 827–831 | **§4.4.2** 颗粒/聚合物 — 子午面屈服：线性形式 **F = t − p tan β − d = 0**；t 与 q、第三不变量及 **K** 的关系；硬化/率相关分解式 (4.4.2–1)~(4.4.2–3) |
| 850+ | §4.4.4 Cap（另工单，勿与本 Feature 混装） |

**提炼的纯数学骨架（与当前 L4 试点一致，K=1 子午线线性）**

- 子午面屈服（手册图 4.4.2–1a）：  
  \[
  F = t - p\tan\beta - d = 0
  \]
  其中 \(p\) 为等效压应力（Abaqus 约定：**压为正**），\(t\) 为偏应力度量；\(K{=}1\) 时与 Mises 等价的 \(q\) 对齐（见手册式 4.4.2–3 附近叙述）。
- 率无关、小应变增量下算子分裂：**试探弹性应力 \(\sigma^{tr}\)** → 若 \(F>0\) 则塑性修正（一致切线由 \(\partial F/\partial\sigma\)、\(\partial G/\partial\sigma\) 与弹性刚度组合）。

**手册卷册与 UFC「域」**：`Analysis User’s Guide` 材料卷（如 `ANALYSIS_3.pdf` §23.3）描述**关键字与输入**；**本工单理论真值**以 **`THEORY.pdf` §4.4.2** 为准。UFC 的 **域** 仍指 `L3_MD` / `L4_PH` / `L5_RT` 下合同化模块，不与 Abaqus PDF 卷名一一对应。

---

## 2. 贯通域柱落位（甄别）

| 贯通域柱 | 本 Feature 职责 |
|----------|------------------|
| **Material** | 主：`PH_Mat_DP_*` 塑性更新；辅：`MD_Mat_DP_Desc`（L3 几何/材料描述 Populate） |
| **WriteBack** | 未在本试点实现；后续若需 `STATEV`/场输出回写，应经 **Output 域合同** 与 RT 步进钩子，不单开裸全局 |
| **Element / Contact / LoadBC / …** | 不承载本构方程；仅通过 `ctx`（应变增量等）与 `state`（应力/切线）耦合 |

---

## 3. 主/辅 TYPE 分离（四类 + Args）

| 角色 | 载体（当前仓库） | 内容 |
|------|------------------|------|
| **Desc**（只读/慢变） | `UFC/ufc_core/L3_MD/Material/Geo/MD_Geo_DruckerPrager.f90` → `MD_Mat_DP_Desc` | `E, nu, d, beta, alpha, hardening_type, G, K, tan_beta`；TBP `ValidateProps` / `InitFromProps` |
| **State**（演化历史） | `PH_Mat_DP_Core.f90` → `PH_Mat_PLM_DP_State` | `stress, ddsdde, strain_plastic, peeq, is_plastic, status, converged, iterations` |
| **Algo**（时序/数值开关） | `PH_Mat_DP_Core.f90` → `PH_Mat_PLM_DP_Algo` | `ntens, compute_tangent` |
| **Ctx**（增量上下文） | `PH_Mat_Types.f90` → `PH_Mat_Base_Ctx` | 如 `dstran` 等（试点）；雅可比/温度等扩展在域内合同卡演进 |
| **Args**（单次调用 IO bundle） | `PH_Mat_DP_Core.f90` → `PH_Mat_DP_Init_Arg` / `PH_Mat_DP_Update_Arg` | 含 `status`、`request_consistent_tangent`、`local_iters` 等；**不在 TYPE 内写 INTENT** |

**不设独立 `PH_Mat_DP_Def.f90`**：避免与 `MD_Mat_DP_Desc` / Core 内 TYPE **重复定义**；`_Def` **语义**由 **L3 Desc 模块 + Core 内 State/Algo** 共同满足（Populate 自 L3，`PH_*` 专注热路径）。

---

## 4. 文件与过程后缀（本域 + 后续推断）

| 文件 | 角色 | 说明 |
|------|------|------|
| `MD_Geo_DruckerPrager.f90` | L3 描述 + Populate | 与关键字/`props` 对齐 |
| `PH_Mat_DP_Core.f90` | `_Core` | **Init** / **Update** 五参；纯算法黑盒（无 `ALLOCATE`、无 `COMMON`） |
| `PH_Mat_DP_Proc.f90` | `_Proc` | **Init** / **Update** 网关 → 转调 Core；对外死守五参 |
| `PH_Mat_Material_Domain_Core.f90`（及同域 Router） | 域级编排 | 按域柱把本 Feature **注册**进材料求解路径（Populate + 调用顺序另见域 CONTRACT） |
| **待补（命名规范推断，非本提交强制落地）** | `_Sync` | L3 `Desc` ↔ L4 使用视图同步（若双份缓存） |
| | `_Apply_*` / Harness | SIO-01~14 单测与 RT 驱动边界 |
| | `RT_Mat_*` | 运行时层材料步进包装（若需六参 `RT_Com_Base_Ctx`） |

---

## 5. SIO 签名（必须）

```text
SUBROUTINE PH_Mat_DP_Proc_Init   (desc, state, algo, ctx, args)
SUBROUTINE PH_Mat_DP_Proc_Update (desc, state, algo, ctx, args)
SUBROUTINE PH_Mat_DP_Core_Init   (desc, state, algo, ctx, args)
SUBROUTINE PH_Mat_DP_Core_Update (desc, state, algo, ctx, args)
```

- `desc`：`TYPE(MD_Mat_DP_Desc), INTENT(IN)`  
- `state`：`TYPE(PH_Mat_PLM_DP_State), INTENT(INOUT)`  
- `algo`：`TYPE(PH_Mat_PLM_DP_Algo), INTENT(IN)`  
- `ctx`：`TYPE(PH_Mat_Base_Ctx), INTENT(IN)`  
- `args`：`TYPE(PH_Mat_DP_*_Arg), INTENT(INOUT)`  

与 `ufc-structured-io` **R-01** 一致；遗留 `inp`/`out` **不得**用于新建本 Feature 的对外 API。

---

## 6. 四链（实施与审查时自检）

| 链 | 本 Feature |
|----|------------|
| 理论链 | Abaqus Theory §4.4.2 → 式 **F = t − p tan β − d**、流动势与 **K**、硬化分解 |
| 逻辑链 | `RT/Elem` 驱动 → `PH_Mat_DP_Proc_Update` → `PH_Mat_DP_Core_Update` |
| 计算链 | 弹性预测 → 屈服判定 → 塑性乘子 → 应力与 **ddsdde** |
| 数据链 | `MD_Mat_DP_Desc` Populate → `state` 演进 → `args%status` 错误传播 |

---

## 7. 与全域推进顺序的关系

贯通域柱顺序（材料 / 单元 / …）由项目总纲与 **域柱闭环** 技能约束；本工单仅 **Material 子域 Plast/DP**。**Abaqus `UMAT`** 是产品侧接口名，UFC 侧映射为 **`PH_Mat_*` + 适配层**（见 `REPORTS/Manual_UFC_domain_subroutine_mapping_guide.md`），不得把手册 Fortran 形参表原样当作 UFC 模块边界。

---

**版本**：与仓库内 `PH_Mat_DP_Core.f90` / `PH_Mat_DP_Proc.f90` / `MD_Geo_DruckerPrager.f90` 当前实现一致时可标 `v0.1`；手册改版后需重跑 `tools/extract_manual_outlines.py` 或等价 PyMuPDF 页窗脚本更新页码锚点。
