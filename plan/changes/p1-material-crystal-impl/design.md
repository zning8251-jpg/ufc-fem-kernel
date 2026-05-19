# Design: p1-material-crystal-impl

> **Status**: W1a implementing（2026-05-19）— #7–#10 merged；W1b Schmid 后续 PR。

## 1. 现状（as-is）

| 组件 | 状态 |
|------|------|
| `PH_Mat_Plast_Crystal_Core.f90` | `UF_CrystalPlasticity_UMAT_Arg` + stub → `STATUS_UNSUPPORTED` |
| `PH_MatPLMEval.f90` CASE `266` | Arg 打包/回写（wave5 #6） |
| `CrystalPlast_MatDesc` | `props(50)` 占位；**未**与 Populate 金线贯通 |
| L3 `MD_Mat_Plast_Reg` | mat_id 266 注册为 stub，`nprops` 1..99 |
| L3 专用 `MD_MatPLMCrystal` | **不存在**（仅 Registry 字符串） |

参考实现模式：**`PH_Mat_Plast_J2_UMAT_Core`**（弹性 D、试应力、径向返回、`statev` 合同）。

## 2. 目标（W1 — 本 change 默认交付）

**W1 = “可跑通增量 + 合同闭合”**，非工业级多滑移 CPFEM。

### 2.1 本构简化（建议默认）

采用 **单晶率无关 J2 回退 + 滑移阻力标量** 作为 W1 占位，接口保持 Crystal 语义：

1. 从 `arg%props` 解析：`E`, `nu`, `tau_c`（临界分切应力），可选 `H`（各向同性硬化模量）。  
2. 弹性试应力：`sigma_trial = sigma_n + D^e : dstran`（`Construct_Elastic_D` / 与 J2 同工具）。  
3. 等效 Mises 驱动 + **单滑移系统** 塑性修正（或显式文档化的 “iso-surrogate” 分支）。  
4. 输出 `ddsdde`、`statev(1)`=累积滑移/等效塑性度量，`IF_STATUS_OK`。  
5. `nprops`/`nstatev` 不足 → `IF_STATUS_INVALID` + message（**禁止** silent unsupported）。

> **已决策（2026-05-19）**：分两阶段交付 — **W1a iso-surrogate**（当前 PR）→ **W1b 1-slip Schmid**（后续 PR，替换 W1a 本构核，保留 Arg/`statev` 布局）。

### 2.2 `props[]` 合同（草案索引）

| Index | 符号 | 含义 |
|-------|------|------|
| 1 | `E` | Young's modulus |
| 2 | `nu` | Poisson ratio |
| 3 | `tau_c0` | Initial critical resolved shear stress |
| 4 | `H` | Hardening modulus on slip resistance (optional, 0 = perfect plasticity) |
| 5–9 | `s`, `m` | **W1b only** — slip direction / plane normal |

**W1a** `nprops_min = 4`（`E, nu, tau_c0, H`）。**W1b** 扩展 5–9。

### 2.3 `statev` 布局（草案）

| Index | 内容 |
|-------|------|
| 1 | `gamma` — 累积滑移（或等效 peeq） |
| 2–7 | 塑性应变 `eps_p`（Voigt 6，与 J2 iso 对齐） |
| 8+ | 预留：各滑移系 `gamma_i`（W2） |

`nstatev_min = 7`（与 `PH_MAT_NSTATV_PLM_J2_ISO` 对齐，降低 PLM 宿主分配复杂度）。

### 2.4 模块切分（建议）

| 模块 | 职责 |
|------|------|
| `PH_Mat_Plast_Crystal_Core.f90` | 保留 `UF_CrystalPlasticity_UMAT` 公开 API + `CrystalPlast_MatDesc` |
| `PH_Mat_Plast_Crystal_Kernel.f90`（新建，可选） | 内部：`ValidateProps`、`UpdateIncrement`、Schmid 算子 |

若 W1 行数 &lt; ~200，可暂不拆 Kernel（与 J2 早期一致）。

### 2.5 金线

- **W1 文案**：`desc%props` / `CrystalPlast_MatDesc` 与 UMAT `arg%props` 一致（`PH_Mat_Plast_Crystal_Core` 模块头已注明）。  
- **禁止** L4 `USE` L5_RT（DEP-001）。  
- **禁止** 写 L3 `MD_Mat_Desc` SSOT（wave5 spec Scenario B）。

## 3. W2（显式 out of scope）

- 多滑移系（N&gt;1）、潜硬化矩阵  
- 旋率更新 / 大变形  
- 纹理 ODF、单晶–多晶 homogenization  
- L3 `MD_MatPLMCrystal` Desc 类型与 MatPoint 专用 API  

## 4. 测试与 harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90 --rules INTF-001,MOD-001
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90
python ufc_harness/run_harness.py change-package validate --change-id p1-material-crystal-impl --strict
```

可选：最小 Fortran 驱动或 harness 单点增量（若 repo 已有 Plast 测试 harness 模式则复用）。

## 5. 风险

| 风险 | 缓解 |
|------|------|
| Registry `nprops` 过宽导致脏输入 | W1 内 `ValidateProps` 严格检查 |
| 与 J2 行为重复 | CONTRACT 标明 W1 surrogate；W2 换真多滑移 |
| #10 未合入时改 Core | **实施 PR 仅基于 post-C2 `main`** |
