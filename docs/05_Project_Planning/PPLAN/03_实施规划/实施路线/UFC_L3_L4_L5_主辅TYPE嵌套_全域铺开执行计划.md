# UFC L3/L4/L5 主辅 TYPE 嵌套 — 全域铺开执行计划

> **状态**：EXEC | **版本**：1.0 | **日期**：2026-04-29  
> **设计母体**：[ufc-layer-l3-l4-l5-pilot.md](ufc-layer-l3-l4-l5-pilot.md)（主辅 TYPE、深度、双轨、TBP 短名、验证）  
> **域柱真源**：[UFC_DOMAIN_PILLAR_ARCHITECTURE.md](../../06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md) v3.0  
> **目录真源**：[UFC_ufc_core_目录权威分类.md](../../06_核心架构/UFC_ufc_core_目录权威分类.md)

---

## 1. 目标与硬约束

1. **语义**：主 TYPE 四型边界不变；辅 TYPE 按 **Phase×Verb×四型** 归组；外部签名不因嵌套而膨胀（见 pilot §10.4 约束1）。  
2. **性能**：**嵌套索引（读代码）** 与 **扁平域存储（`Domain`/`Slot` 数组）** 双轨；L5 Bridge 辅 TYPE **禁止 ALLOCATABLE**（pilot §3.3）。  
3. **语法**：合入主线 **F2003**；F2008 / SUBMODULE **独立 PR**（pilot §十四）。  
4. **合同**：每波次 Step4 必须更新列于下文的 **`CONTRACT.md`**，并增列「主辅 TYPE 与 `*_Arg` 对照」（pilot §十三）。  
5. **PR 粒度**：单 PR 优先 **单域柱或单半柱**；禁止 P2+P3+P4 同 PR 大杂烩（pilot §十二）。  
6. **文件级覆盖核对**：L3/L4/L5 全部 `.f90` 清单见 [`L3_L4_L5_pilot_f90任务清单.md`](L3_L4_L5_pilot_f90任务清单.md)（866 文件；可再生）；**执行顺序仍以本章 §2 波次为准**，不得以清单字母序替代。

---

## 2. 波次总览（执行顺序）

| 波次 | 覆盖范围 | 域柱类型 | 前置依赖 |
|------|----------|----------|----------|
| **W0** | 工具链、命名检查、CI、`BRIDGE_INDEX` 与 pilot 对齐 | 横切 | — |
| **W1** | **P1 Material** 贯通柱 | Full | W0 |
| **W2** | **P2 Element** 贯通柱 | Full | W1 Step3 绿（Populate+本构竖切稳定） |
| **W3** | **P3 Contact** | Full | W1；与 W2 可交错但 **禁止** 同 PR 改 Bridge 全局 + Contact 全量 |
| **W4** | **P4 LoadBC** | Full | W1 |
| **W5** | **P5 Output** | Full | W1；与 P5 消费方（Assembly/WriteBack）协调 |
| **W6** | **P6 WriteBack** | Full | W5 或并行（合同先行） |
| **W7** | **半贯通柱** H1,H2,H3,H4a,H4b,H4c,H6,H7 | Partial | W1；H7 含 **L2+L4** |
| **W8** | **层专属** S1–S6 | Layer-Only | W0；S5 与 W2 协调（Mesh 非单元部分 vs P2） |

**Bridge**：非独立域柱；**材料侧**在 W1、**单元侧**在 W2、**Output/WriteBack** 在 W5/W6 分域切入 `RT_Brg_*` / `L4_PH/Bridge/*`，每次改动保持其它域编译通过。

**编号上界与计数口径（EXEC v1.0）**：本表为 **闭合** 波次集合 — **最大编号波次 = W8**。在未 **bump 本文件版本** 且未在上表 **显式增行** 的前提下，**不使用** W9、W10 等编号。计数口径：**W0…W8** 共 **9** 个编号；其中 **W1…W8** 为业务改造波（**8** 个），**W0** 仅为横切基线。

**开展顺序与 PR 切分（治理）**：

1. **须先 W0 再 W1**；**W2** 仅在上表「前置依赖」满足后启动（含 **W1 Step3** 绿等与 pilot DoD 一致的条件）。
2. **W3–W6** 严格服从上表前置依赖列；**W7** 内按半柱 **H1…H7**（见 §5）**分行、多分 PR**，优先单半柱边界；**W8** 内按 **S1…S6**（见 §6）**分行、多分 PR**。
3. **禁止**在 Issue/PR/里程碑中使用 **未在本 §2 表登记的波次编号**（例如 invented **W9**）；若扩大范围（新增域柱行或纳入额外层），须 **修订本计划版本** 并更新上表。

---

## 3. W0 — 基线与横切

| # | 任务 | 完成判据 |
|---|------|----------|
| W0.1 | 固化 `naming_checker` / 手工脚本：LINT-TYPE-001~005（pilot §10.4） | 对当前 `*_Def.f90` 跑一次基线报告存档 |
| W0.2 | CI / 本地：`gfortran -std=f2003 -fsyntax-only` 对 **ufc_core 约定子集** 零错 | 写入 `UFC/docs` 或 harness README 一条命令 |
| W0.3 | 对照 [`ufc_core/L3_MD/Bridge/BRIDGE_INDEX.md`](../../../../ufc_core/L3_MD/Bridge/BRIDGE_INDEX.md) | Bridge 改造责任人与文件表可勾选；新增 `*_Brg` 先登记 |
| W0.4 | 本执行计划 + pilot 链入 [PPLAN/README.md](../../README.md) | 已维护 |

**W0 命令与基线存档索引**：见 [`L3_L4_L5_语义改造_导航真源.md`](L3_L4_L5_语义改造_导航真源.md) §2（含 **W0.1** 命名报告路径、**W0.2** 语法说明、**W0.3** Bridge 索引链）。

---

## 4. 贯通柱执行卡（P1–P6）

以下每根柱均重复 **Step1→4**（pilot §七）；**辅 TYPE 文件命名建议**：`PH_<Dom>_Aux_Def.f90`、`MD_<Dom>_...` 或域内已有 `*_Def.f90` 增量 —— 以 **单域内聚** 为准（pilot §10.3）。

### 4.1 W1 — P1 Material

| 层 | 权威目录（域桶） | `CONTRACT.md`（更新对象） | Step1 要点 |
|----|------------------|---------------------------|------------|
| L3 | `ufc_core/L3_MD/Material/` | `L3_MD/Material/CONTRACT.md` | `MD_Mat_*` Desc/State 辅分组；`Domain/` 扁平数组不变 |
| L4 | `ufc_core/L4_PH/Material/` | `L4_PH/Material/CONTRACT.md` | `PH_Mat_Aux_Def.f90`；主四型嵌套 |
| L5 | `ufc_core/L5_RT/Material/` | `L5_RT/Material/CONTRACT.md` | `RT_Mat_*` Bridge 辅 TYPE；禁 ALLOCATABLE |

**DoD**：pilot §9 中 **Material** 行 + 线弹性 / J2 相关用例绿；`RT_Brg_Def` 仅触及 **材料** 相关 `TYPE`。

---

### 4.2 W2 — P2 Element

| 层 | 权威目录 | `CONTRACT.md` | Step1 要点 |
|----|----------|---------------|------------|
| L3 | `ufc_core/L3_MD/Elem/`（及 `Mesh/` 根） | `L3_MD/Elem/CONTRACT.md`、`L3_MD/Mesh/CONTRACT.md` | 模型侧单元 Desc/State 辅分组；与族子目录共存 |
| L4 | `ufc_core/L4_PH/Element/` | `L4_PH/Element/CONTRACT.md` | `PH_Elem_Aux_Def.f90`；ArgHub 与 pilot §5 对齐 |
| L5 | `ufc_core/L5_RT/Element/`、`L5_RT/Element/Mesh/` | `L5_RT/Element/CONTRACT.md`、`L5_RT/Element/Mesh/CONTRACT.md` | `RT_Elem_*` Bridge |

**DoD**：至少 **C3D8 弹性** + 一条 **非线或二阶** 用例；`RT_Asm_*` 若必须同改，拆 **子 PR** 或并入 W7 H3 协调行。

---

### 4.3 W3 — P3 Contact

| 层 | 权威目录 | `CONTRACT.md` | 备注 |
|----|----------|---------------|------|
| L3 | `L3_MD/Interaction/` | `L3_MD/Interaction/CONTRACT.md` | L3 名 *Interaction* vs L4 *Contact* — 域柱文档 §3.2 |
| L4 | `L4_PH/Contact/` | `L4_PH/Contact/CONTRACT.md` | 多子域（Search/Friction/…）**按子域拆辅 TYPE 文件** 避免单文件爆炸 |
| L5 | `L5_RT/Contact/` | `L5_RT/Contact/CONTRACT.md` | |

---

### 4.4 W4 — P4 LoadBC

| 层 | 权威目录 | `CONTRACT.md` | 备注 |
|----|----------|---------------|------|
| L3 | `L3_MD/Boundary/` | `L3_MD/Boundary/CONTRACT.md` | *Boundary* vs *LoadBC* 映射见域柱文档 |
| L4 | `L4_PH/LoadBC/` | `L4_PH/LoadBC/CONTRACT.md` | |
| L5 | `L5_RT/LoadBC/` | `L5_RT/LoadBC/CONTRACT.md` | |

---

### 4.5 W5 — P5 Output

| 层 | 权威目录 | `CONTRACT.md` | 备注 |
|----|----------|---------------|------|
| L3 | `L3_MD/Output/` | `L3_MD/Output/CONTRACT.md` | |
| L4 | `L4_PH/Bridge/Output/` | `L4_PH/Bridge/Output/CONTRACT.md`、`L4_PH/Bridge/CONTRACT.md` | L4 经 Bridge；辅 TYPE 紧贴 ODB/场量写出路径 |
| L5 | `L5_RT/Output/` | `L5_RT/Output/CONTRACT.md` | |

---

### 4.6 W6 — P6 WriteBack

| 层 | 权威目录 | `CONTRACT.md` | 备注 |
|----|----------|---------------|------|
| L3 | `L3_MD/WriteBack/` | `L3_MD/WriteBack/CONTRACT.md` | |
| L4 | `L4_PH/Bridge/WriteBack/` | `L4_PH/Bridge/WriteBack/CONTRACT.md`、`L4_PH/Bridge/CONTRACT.md` | |
| L5 | `L5_RT/WriteBack/` | `L5_RT/WriteBack/CONTRACT.md` | |

---

## 5. W7 — 半贯通柱（H1–H7）

| ID | 名称 | 层 | 主要 `CONTRACT.md` / 模块 | 实施要点 |
|----|------|----|---------------------------|----------|
| **H1** | Constraint | L3+L4 | `L3_MD/Constraint/`、`L4_PH/Constraint/` | L5 融入 `RT_Asm`；辅 TYPE 冷路径为主 |
| **H2** | Field | L3+L4 | `L3_MD/Field/`、`L4_PH/Field/` | 与 P5 场输出声明对齐，避免双真源 |
| **H3** | Assembly | L3+L5 | `L3_MD/Assembly/`、`L5_RT/Assembly/` | L4 无独立域；**与 W2 RT_Asm 改动统一排期** |
| **H4a** | Step | L3+L5 | `L3_MD/Analysis/Step/`、`L5_RT/StepDriver/` | 对齐 `RT_Step_Def` 既有 Depth2 范例 |
| **H4b** | Solver | L3+L5 | `L3_MD/Analysis/Solver/`、`L5_RT/Solver/`、`L5_RT/Solver/Coupling/` | 与 **H6** 数据流文档交叉核对 |
| **H4c** | Amplitude | L3 | `L3_MD/Analysis/Amplitude/` | 仅 L3；辅 TYPE 规模通常小 |
| **H6** | Coupling | L3+L5 | `L3_MD/Analysis/Coupling/`、`L5_RT/Solver/Coupling/` | L4 分散贡献；合同优先 |
| **H7** | DiffPhys | **L2+L4** | `L2_NM/Solver/AI/`、`L4_PH/Element/`（`dRdTheta` 等） | **不进入 W1**；与伴随/可微专题同里程碑 |

**顺序建议**：H4c（小）→ H1/H2 → H4a/H4b → H3 → H6 → **最后 H7**（跨层最多）。

---

## 6. W8 — 层专属（S1–S6）

| ID | 层 | 域 | `CONTRACT.md` | 与主线的关系 |
|----|----|-----|----------------|--------------|
| S1 | L3 | KeyWord | `L3_MD/KeyWord/CONTRACT.md` | 解析冷路径；辅 TYPE 按 Populate/Cfg 分组 |
| S2 | L3 | Model | `L3_MD/Model/CONTRACT.md` | Desc+State 为主 |
| S3 | L3 | Part | `L3_MD/Part/CONTRACT.md` | |
| S4 | L3 | Section | `L3_MD/Section/CONTRACT.md` | |
| S5 | L3 | Mesh（非 P2 单元族部分） | `L3_MD/Mesh/CONTRACT.md` | **与 W2 分界**：拓扑/节点集 vs `Elem/` 族 |
| S6 | L5 | Logging | `L5_RT/Logging/CONTRACT.md` | 无 L3/L4；辅 TYPE 仅服务运行时日志 |

---

## 7. 每波次检查清单（复制到 Issue / PR 描述）

```markdown
- [ ] Step1：辅 TYPE + 主 TYPE 嵌套；F2003；深度≤3；L5 Bridge 辅 TYPE 无 ALLOCATABLE
- [ ] Step2：Init/Populate/Bridge 双写或断言（若启用）
- [ ] Step3：热路径读辅 TYPE；外部 API 签名未变
- [ ] Step4：删 DEPRECATED（满足窗口）；CONTRACT 已更新；§9 相关测例绿
- [ ] §十三：`*_Arg` 对照小节已写或已声明「无变更」
```

---

## 8. 风险与缓解

| 风险 | 缓解 |
|------|------|
| `RT_Brg_Def` 多域耦合 | 分域 PR + 编译期 `ONLY` 收紧 USE；先 `RT_Mat_*` 再 `RT_Elem_*` |
| Element 族爆炸 | 辅 TYPE **公共基底** 放 `PH_Elem_Aux_Def.f90`，族特异 **增量 TYPE** 放族目录或条件包含 |
| Output/WriteBack 双路径 | 以域柱合同 P5/P6 为真源，先合同再代码 |
| H7 与内核依赖反向 | 遵守域柱文档：AI/可微 **不得反向 USE L5** |

---

## 9. 与既有工作的衔接

若仓库中 **已部分落地** P1/P2（命名、四型、SIO 等）：  
1. 以本计划 **W1/W2 为审计单位** 对照 pilot §八表格，勾选「已做 / 缺口 / 废弃未删」。  
2. **未删 DEPRECATED** 的项优先列入 **下一 Sprint Step4**，避免与新建辅 TYPE 长期并存导致双真源。

---

## 10. 维护

- 域桶目录变更时：同步 **§4–§6 表** 与 `UFC_ufc_core_目录权威分类.md`。  
- **§2 波次编号**：闭合集合 **W0–W8**（上界 **W8**）；新增波次须 **bump 本文件版本** 并在 §2 表 **显式增行**，禁止使用未登记编号（见 §2「编号上界与计数口径」）。  
- 本计划 **版本 bump**：任一贯通柱 Step4 完成并合入主分支时，在表头追加 **修订记录** 一行（日期 + 波次 + PR 号）。

---

## 11. Kickoff 执行记录

| 日期 | 动作 | 说明 |
|------|------|------|
| 2026-04-29 | **W1 代码修复** | `PH_Mat_Domain_Core.f90`：`PH_Mat_Domain` 误用 `this%inc` / `domain%inc` 改为 `step_idx`/`incr_idx`；`PH_Mat_Apply_Init_Arg` / `PH_Mat_AllocSlot_Idx` 去重并同步 `ctx` 嵌套与 **DEPRECATED** 扁平 `step_idx`/`incr_idx`。 |
| 2026-04-29 | **W1 热路径** | `PH_Mat_Core.f90`：新增 `PH_Mat_Desc_Effective_Model`，调度/本构/切线优先 `desc%cfg%matModel` 回退 `desc%matModel`；`uarg%dt` 优先 `ctx%inc%dt` 回退 `ctx%dt`。 |
| 2026-04-29 | **W0** | 已执行 `python tools/arch_guardian.py ufc_core/L4_PH/Material --fail-on-p0`：当前目录存量 **P0:54**（非本次两行修改引入）；全量清零属独立治理任务。建议在后续 MR 中按子目录分批压 P0。 |
| 2026-04-29 | **Populate 与 S3/S4** | `PH_L4_Populate.f90`：`material_dom%inc%*` 改为 `material_dom%step_idx`/`incr_idx`；槽位 `ctx` 同步 `inc` + DEPRECATED `step_idx`/`incr_idx`。`PH_Mat_Core.f90`：`S3`/`S4` 应力与 SDV、切线优先 **`state%comp`/`state%evo`**，回退扁平字段并双写回。 |
| 2026-04-29 | **PH_Mat_State 扫描** | `L4_PH/Material` 下除四型 `PH_Mat_State` 外，其余 `state%stress`/`C_tan` 属于 `PH_J2_State`、`PH_Therm_State`、`PH_Visco_State` 等**独立 TYPE**，不改为 `comp%*`。新增 **`PH_Mat_State_DualWrite_Stress6` / `PH_Mat_State_DualWrite_Ctan66`**（`PH_Mat_Domain_Core`），`PH_Mat_Core` S3/S4 调用之；`PH_Mat_Def` re-export。 |
| 2026-04-29 | **W1 双轨写 + Bridge 同步** | `PH_Mat_State_DualWrite_StateVars`（`PH_Mat_Domain_Core`）+ `PH_Mat_Core` S3 调用；`PH_Mat_Def` re-export。`RT_Brg_Def`：`RT_Mat_Bridge_Sync_*` / `RT_Elem_Bridge_Sync_*` 扁平与 `%stp`/`%lcl` 双向同步。`L4_PH/Material/CONTRACT.md` 增补 **PH_Mat_State 辅 TYPE 与双轨写** 小节。 |
| 2026-04-29 | **Assembly / harness 挂 Sync** | `RT_Bridge_Init` 在 Mat/Elem 构造后调用 `Sync_Aux`；`RT_Bridge_*` 三过程 **PUBLIC**。`RT_Asm_Brg`：`ApplyMatBridge_Flat_IP` / `ApplyElemBridge_Flat_IP` + `Sync*Mirror`；`RT_Asm_Def` 头注释索引。`tests/L5_RT/RT_Asm_Test.f90`：`test_rt_bridge_flat_nested_mirror`。`L5_RT/Bridge/CONTRACT.md` 更新模块表与 API 表。 |
| 2026-04-29 | **W1 装配 mat_pt_idx** | `RT_Asm_Brg_ElemMatPtIdx` + `RT_Asm_GlobalStiffness` 两处 `ke_arg%mat_pt_idx` 从 `elem_to_mat_map` 解析；`L3_MD/Material/CONTRACT.md` 增补装配侧说明；L3 `MD_Mat_Desc` 全量嵌套对齐列为后续 MR。 |
