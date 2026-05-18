# 八域过程算法内容漂移审计（Wave 1）

**日期**：2026-05-14  
**范围**：先审 `Element` / `Section` / `Analysis` / `LoadBC` 四域；其余四域先占位，后续补齐。  
**目的**：判断 `REPORTS` 叙事稿、`*_Domain_Inventory.md`、`ufc_core/**/CONTRACT.md`、`DomainProcedureRegistry/design/*` 之间是否已收敛到同一口径。

---

## 1. 判定口径

本审计沿用 `docs/03_Domain_Pillars/DomainProcedureRegistry/README.md` 已写明的优先级：

1. `ufc_core/**/CONTRACT.md`
2. `docs/03_Domain_Pillars/DomainProcedureRegistry/design/*`（`INTENT.md` + `manifest.json`）
3. `ufc_core/` 源码与 `generated/`
4. `REPORTS/archive/*_Procedure_Algorithm.md` 等叙事稿

**状态定义**：

- **已对齐**：结构、命名、实现边界基本一致，仅剩链接或措辞微调
- **轻度漂移**：主架构一致，但有 1-2 处明显落后项，尚未形成双 SSOT
- **显著漂移**：存在过时清单、并行真源或 machine-readable manifest 明显落后，已影响后续对账
- **待审**：本波未审

---

## 2. 八域总表

| 域 | 本波状态 | 总判定 | 主要漂移点 | 首修目标 |
|---|---|---|---|---|
| Material | 未审 | 待审 | 本波未纳入 | 后续补审 |
| Element | 已审 | **显著漂移** | L3 合同双入口并存；Inventory 仍混用旧命名；Registry 仍挂 `Mesh` 桶 | `ufc_core/L3_MD/Element/Elem/CONTRACT.md` |
| Contact | 未审 | 待审 | 本波未纳入 | 后续补审 |
| LoadBC | 已审 | **显著漂移** | `Load/BC` 新拆分已落地，但 longform / inventory / manifest 仍大量沿用混合 `LoadBC/Ldbc` 口径 | `REPORTS/archive/LoadBC_Procedure_Algorithm.md` |
| Output | 未审 | 待审 | 本波未纳入 | 后续补审 |
| WriteBack | 未审 | 待审 | 本波未纳入 | 后续补审 |
| Analysis | 已审 | **显著漂移** | 顶层子域拆分、L5 Solver 命名与 manifests 不一致 | `ufc_core/L3_MD/Analysis/CONTRACT.md` |
| Section | 已审 | **轻度漂移** | 主设计已一致，但 Inventory 与 Registry 仍落后于 L5 P3 补全 | `REPORTS/Section_Domain_Inventory.md` |

---

## 3. 已审四域明细

### 3.1 Element

**使用源**：

- `REPORTS/Element_Procedure_Algorithm.md`
- `REPORTS/archive/Element_Procedure_Algorithm.md`
- `REPORTS/Element_Domain_Inventory.md`
- `ufc_core/L3_MD/Element/CONTRACT.md`
- `ufc_core/L3_MD/Element/Elem/CONTRACT.md`
- `ufc_core/L4_PH/Element/CONTRACT.md`
- `ufc_core/L5_RT/Element/CONTRACT.md`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Mesh/{INTENT.md,manifest.json}`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L4_PH/Element/{INTENT.md,manifest.json}`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/Element/{INTENT.md,manifest.json}`

**已对齐点**：

- 根 `stub` / `archive` 关系清晰，且已明确 `CONTRACT` / 代码优先于叙事稿。
- `REPORTS` 与 `L4/L5 CONTRACT` 对 `UEL-A / UEL-B`、`RT_Elem_UEL`、M-S-E 协作的主叙事大体一致。
- `L3 -> L4 -> L5` 的职责分层没有根本冲突：L3 冷定义、L4 局部核、L5 路由与 UEL 门面。

**漂移项**：

1. **高**：`ufc_core/L3_MD/Element/CONTRACT.md` 与 `ufc_core/L3_MD/Element/Elem/CONTRACT.md` 形成并行入口。前者已切到 `MD_Elem_Desc` / 无 `Base` 口径，后者仍大段保留 `MD_Elem_Base_Desc`、旧映射与旧文件名。  
   **建议先修**：`ufc_core/L3_MD/Element/Elem/CONTRACT.md`，再决定是否把 root 合同与 `Elem/` 子合同收束为单一主入口。

2. **高**：`REPORTS/Element_Domain_Inventory.md` 仍把不少旧文件名当作 active inventory，例如 `MD_Elem_Solid3D_Def.f90`、`MD_Elem_Beam_Def.f90`、`RT_Elem_UEL_API` 这一层级表述，与当前 `ufc_core/L3_MD/Element/Elem/*.f90` / `L5_RT/Element/RT_Elem_UEL.f90` 不完全一致。  
   **建议先修**：`REPORTS/Element_Domain_Inventory.md`

3. **中**：Registry L3 设计仍挂在 `design/L3_MD/Mesh/`，而当前合同与实现已明确 `L3_MD/Element/Elem/` 为单元定义主场。现状可解释为“Mesh 桶兼容 Element 子树”，但对读者与 manifest 维护者已不够直观。  
   **建议先修**：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Mesh/INTENT.md`

4. **中**：`design/L5_RT/Element/manifest.json` 仍使用 `RT_ElemUEL.f90` / `RT_ElemSect.f90` 等旧 stem，而当前实际文件是 `RT_Elem_UEL.f90` / `RT_Elem_Sect.f90`。  
   **建议先修**：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/Element/manifest.json`

**结论**：**显著漂移**。问题核心不是 stub/archive，而是 **L3 合同双口径 + inventory / manifest 命名落后**。

### 3.2 Section

**使用源**：

- `REPORTS/Section_Procedure_Algorithm.md`
- `REPORTS/archive/Section_Procedure_Algorithm.md`
- `REPORTS/Section_Domain_Inventory.md`
- `ufc_core/L3_MD/Section/CONTRACT.md`
- `ufc_core/L5_RT/Section/CONTRACT.md`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Section/{INTENT.md,manifest.json}`

**已对齐点**：

- `Section` 为正交维、`L4` 嵌入 `Element`（方案 B）的主架构在 archive、L3 合同、L5 合同中是一致的。
- `archive/Section_Procedure_Algorithm.md` 已正确反映 `RT_Sect_Stp_Ctl_Algo` / `RT_Sec_Algo` 的 P3 补全。
- `MD_Sect_Algo%default_integration_rule` 作为 L3 最简 Algo，和源码、generated、longform 是一致的。

**漂移项**：

1. **中**：`REPORTS/Section_Domain_Inventory.md` 仍写 `L5 Sect Algo 补全 = UNDONE`，但 `REPORTS/archive/Section_Procedure_Algorithm.md` 与 `ufc_core/L5_RT/Section/CONTRACT.md` 都已按 **P3 DONE** 叙述。  
   **建议先修**：`REPORTS/Section_Domain_Inventory.md`

2. **中**：Registry 仅有 `design/L3_MD/Section/`，没有与当前 `ufc_core/L5_RT/Section/` 对应的设计入口；这会让 `RT_Sect_Aux_Def.f90` / `RT_Sect_Def.f90` 处于“generated 有、design 无”的半失配状态。  
   **建议先修**：新增 `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/Section/`

3. **低**：L3 合同局部仍用 `SectionAlgo` 这一较抽象别名，而报告 / generated / 源码均更稳定地使用 `MD_Sect_Algo`。不影响主判断，但会降低跨文档搜索一致性。  
   **建议先修**：`ufc_core/L3_MD/Section/CONTRACT.md`

**结论**：**轻度漂移**。主架构没分叉，主要是 **Inventory 未追上 + L5 registry design 缺位**。

### 3.3 Analysis

**使用源**：

- `REPORTS/Analysis_Procedure_Algorithm.md`
- `REPORTS/archive/Analysis_Procedure_Algorithm.md`
- `REPORTS/Analysis_Domain_Inventory.md`
- `ufc_core/L3_MD/Analysis/CONTRACT.md`
- `ufc_core/L3_MD/Analysis/{Step,Solver,Coupling}/CONTRACT.md`
- `ufc_core/L5_RT/{StepDriver,Solver,Solver/Coupling}/CONTRACT.md`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Analysis/{INTENT.md,manifest.json}`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/{StepDriver,Solver}/manifest.json`

**已对齐点**：

- `L3 + L5` 半贯通、`L4` 无独立 `Analysis` 域，这一点在 longform、inventory、contracts 中一致。
- `StepDriver` 持有 Step/Inc/Itr 状态机、`Solver` 承担运行时求解链，这个主叙事一致。
- 根 `stub` 与 archive 的层次关系清楚。

**漂移项**：

1. **高**：`REPORTS/archive/Analysis_Procedure_Algorithm.md` / `REPORTS/Analysis_Domain_Inventory.md` 以 `Step + Amplitude + Solver + Coupling` 为主分解；`ufc_core/L3_MD/Analysis/CONTRACT.md` 却仍把顶层写成 `Step + Amplitude + Solver + AnalysisCompat`，没有把 `Coupling` 作为同层子域明确写稳。  
   **建议先修**：`ufc_core/L3_MD/Analysis/CONTRACT.md`

2. **高**：`ufc_core/L5_RT/Solver/CONTRACT.md` 的公开类型命名落后于现实现与 inventory，仍有 `RT_Solv_Base_Desc` 一类旧说法，而运行时主类型已是 `RT_Solv_Desc`。  
   **建议先修**：`ufc_core/L5_RT/Solver/CONTRACT.md`

3. **中**：`REPORTS/Analysis_Domain_Inventory.md` 对 Coupling 与 Amplitude 的实现描述落后，仍带有旧模块名和不确定口径。  
   **建议先修**：`REPORTS/Analysis_Domain_Inventory.md`

4. **中**：Registry manifests 明显滞后，仍列 `MD_Amplitude*`、`MD_Step.f90`、`RT_StepExec.f90`、`RT_Solv.f90` 等旧 stem，和当前 `MD_Amp_*`、`MD_Step_Mgr.f90`、`RT_Step_Exec.f90`、`RT_Solv_Mgr.f90` 等口径不一致。  
   **建议先修**：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Analysis/manifest.json`、`design/L5_RT/StepDriver/manifest.json`、`design/L5_RT/Solver/manifest.json`

**结论**：**显著漂移**。核心问题是 **subdomain 分解 + manifest 命名** 仍未完全追平当前实现。

### 3.4 LoadBC

**使用源**：

- `REPORTS/LoadBC_Procedure_Algorithm.md`
- `REPORTS/archive/LoadBC_Procedure_Algorithm.md`
- `REPORTS/LoadBC_Domain_Inventory.md`
- `ufc_core/L3_MD/LoadBC/CONTRACT.md`
- `ufc_core/L3_MD/Boundary/CONTRACT.md`
- `ufc_core/L4_PH/LoadBC/CONTRACT.md`
- `ufc_core/L5_RT/LoadBC/CONTRACT.md`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Boundary/{INTENT.md,manifest.json}`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L4_PH/LoadBC/{INTENT.md,manifest.json}`
- `docs/03_Domain_Pillars/DomainProcedureRegistry/design/L5_RT/LoadBC/{INTENT.md,manifest.json}`

**已对齐点**：

- 根 `stub` 已就位，且明确 `CONTRACT` / 代码优先于报告叙事。
- 所有来源都认同 `LoadBC` 是 `L3 + L4 + L5` 的贯通柱。
- L3 冷定义、L4/L5 负责施加与运行时编排的总分工仍成立。

**漂移项**：

1. **高**：`REPORTS/archive/LoadBC_Procedure_Algorithm.md` 与 `REPORTS/LoadBC_Domain_Inventory.md` 仍以混合 `PH_LoadBC_*` / `PH_Ldbc_*` 结构为中心，而 `ufc_core/L4_PH/LoadBC/CONTRACT.md` 已将 `PH_Load_*` / `PH_BC_*` 严格拆分为 canonical。  
   **建议先修**：先改 `REPORTS/archive/LoadBC_Procedure_Algorithm.md`，再改 `REPORTS/LoadBC_Domain_Inventory.md`

2. **高**：`REPORTS/LoadBC_Domain_Inventory.md` 仍把 `MD_LoadBC_Def.f90`、`MD_LoadBCPH_Brg.f90` 等混合 L3 工件当作 active inventory，但 `ufc_core/L3_MD/LoadBC/CONTRACT.md` 已明确 `MD_Load_Def.f90 + MD_BC_Def.f90` 为 canonical。  
   **建议先修**：`REPORTS/LoadBC_Domain_Inventory.md`

3. **中**：Registry L4/L5 manifests 仍大量使用 `PH_Ldbc*`、`RT_LBC_*` 等旧 stem，未完全跟上 `PH_Load_* / PH_BC_* / RT_LoadBC_*` 口径。  
   **建议先修**：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L4_PH/LoadBC/manifest.json`、`design/L5_RT/LoadBC/manifest.json`

4. **中**：Registry L3 入口仍主要挂在 `Boundary`，而当前 `ufc_core/L3_MD/LoadBC/CONTRACT.md` 已把 `LoadBC/` 作为新 canonical，`Boundary/` 退为旧位置。  
   **建议先修**：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Boundary/INTENT.md` 与 `manifest.json`

5. **中**：`ufc_core/L5_RT/LoadBC/CONTRACT.md` 仍带有若干混合输入叙述（如 `Boundary` / `PH_LoadBC_Domain` 口径），尚未完全向新拆分体系收束。  
   **建议先修**：`ufc_core/L5_RT/LoadBC/CONTRACT.md`

**结论**：**显著漂移**。`LoadBC` 是当前四域里**最适合先修的一域**，因为 canonical split 已明确，但报告和 registry 还在旧叙事上。

---

## 4. 本波修复顺序建议

1. **LoadBC**
   先统一 `archive/LoadBC_Procedure_Algorithm.md` 与 `LoadBC_Domain_Inventory.md`，把混合 `LoadBC/Ldbc` 叙事切到 `Load` / `BC` 双柱 canonical。

2. **Analysis**
   先统一 `L3_MD/Analysis/CONTRACT.md` 与 `L5_RT/Solver/CONTRACT.md`，再刷三份 manifest。

3. **Element**
   先决定 `Element/CONTRACT.md` 与 `Element/Elem/CONTRACT.md` 的主从关系，再回写 inventory 与 registry。

4. **Section**
   先补 `Section_Domain_Inventory.md`，随后补 `design/L5_RT/Section/` 入口。

---

## 5. 下一波建议

Wave 2 建议继续审：

- `Material`
- `Contact`
- `Output`
- `WriteBack`

届时可直接沿用本表结构，把八域状态从“待审”补齐为完整矩阵。
