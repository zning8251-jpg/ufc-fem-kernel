# UFC L3/L4/L5 形式对齐 — 域级检查表（P1–P6 + H1 附录）

**版本**：1.5  
**日期**：2026-05-12  
**用途**：在不编译的前提下，按**贯通域柱**逐项核对「四型 + `*_Arg` + 过程三维命名」与合同/实现是否一致；勾选结果用于 PR 自检或 Harness 扩展规则的输入。  
**规范真源**：[`UFC/REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md`](../../REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md)（根路径为 **stub**，长文在 [`UFC/REPORTS/archive/UFC_L3L4L5_二元重构蓝图规范_v1.0.md`](../../REPORTS/archive/UFC_L3L4L5_二元重构蓝图规范_v1.0.md)；§1–§4、§8–§13）、[`UFC/rules/ufc-naming.mdc`](../../rules/ufc-naming.mdc)、各域 `ufc_core/**/CONTRACT.md`。  
**战役上下文**：[`UFC_Developer_Strategy_and_Refactor_Playbook.md`](./UFC_Developer_Strategy_and_Refactor_Playbook.md) Part A。

**执行工作流（七步·交接·防偏离）**：[`../05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md) · 任务编排 [`../../plan/workflows/L3L4L5_MASTER_PLAN.md`](../../plan/workflows/L3L4L5_MASTER_PLAN.md)

---

## 域柱垂直切片 — 「全域改造」落地法

**「全域」操作定义**：**不按层**（例如先改完整个 L3 再改 L4）横向切换；**按贯通域柱 P1–P6（及 H1 半柱）**做 **L3_MD → L4_PH → L5_RT 垂直切片**，**每柱一条金线闭合**后再扩到下一柱。

### 1. 金线首柱怎么选

| 当前产品/内核缺口侧重 | 倾向首柱 | 说明 |
|------------------------|----------|------|
| 材料本构、Populate、UMAT/族路由、L3↔L4 材料金线 | **P1 Material** | 与多物理后续柱共享「材料槽」习惯 |
| 单元族、Ke/Fe、Dispatcher、与 `RT_Asm_*` 热路径 | **P2 Element** | 与装配域强耦合 |

若 **多域几乎全缺**：仍 **只开一条柱** 做端到端样板；第二条柱须等首柱 **§2 柱内顺序** 跑通并在 PR 中留下 **G1–G6 勾选记录**，避免并行改十几个域。

### 2. 每柱内固定顺序（可拆多个小 MR，但顺序不倒）

| 顺序 | 工件 | 完成判据（本阶段不做全量编译/CTest） |
|------|------|----------------------------------------|
| ① | **CONTRACT** | 四型裁剪、文件清单、SIO 小节与跨层引用与代码一致 |
| ② | **L3 `*_Def` / `*_Mgr`**（+ 合同载明的 `*_Brg` / `*_Sync`） | G2/G3/G5 通过 |
| ③ | **L4 `*_Eval` / `*_Core`**（+ 族级子目录） | 热路径接口与 L3 Populate 叙事一致 |
| ④ | **L5 `*_Proc` / Dispatcher / 编排入口** | SIO 与生产路径分工写清 |
| ⑤ | **Harness / Guardian** | 对本柱 touched 路径跑仓库门禁（见 `AGENTS.md` / `ufc_harness/README.md`） |
| ⑥ | **最小门控** | 本柱 **G1–G6** 全勾选；**不跑**全量链接与集成/E2E 测试套件。**可选**：仅对**本柱改动**的 `.f90` 做 **`gfortran -std=f2003 -fsyntax-only`**（**不链接**、**不跑 CTest**） |

### 3. 全域推广

下一柱：在 PR 中 **复制**本文件对应 **P***（或 **H1**）节 + 空白「G1–G6」结果表，作为 **柱级验收附件**；**禁止**在无独立 PR 叙事的情况下 **并行修改 >1 条贯通柱**。

**首 PR 正文模板（材料 ∩ 单元 ∩ 装配接缝）**：[`PR01_P1_P2_材料单元装配金线.md`](./PR01_P1_P2_材料单元装配金线.md)。

---

对下列每一「检查行」，在指定文件中完成核对后打勾（✅/⏳/❌）并可选填备注（文件:行号）。

| # | 检查项 | 如何做（静态） |
|---|--------|----------------|
| G1 | **合同四型表** | 打开该域 `CONTRACT.md` 中「四类 TYPE / 四型裁剪」表；确认与蓝图角色一致。 |
| G2 | **Def 四型落地** | 打开 `*_Def.f90`（及域内 `*_Aux_Def` 若存在）：`TYPE, PUBLIC :: {Layer}_{Dom}_{Feat}_{Desc|State|Algo|Ctx}` 是否齐全或合同已声明裁剪。 |
| G3 | **Args / SIO** | 层间边界与 L5 `_Proc`：**新/改** 的对外过程应优先 `*_Arg` + `[IN]/[OUT]` 注释；热路径若保留多参，合同是否写明例外。对照 `skills/ufc-structured-io/SKILL.md` 与域 `CONTRACT` SIO 小节。 |
| G4 | **过程三维** | 对 **PUBLIC** 模块过程：是否具备 `Phase:` 注释（`ufc-naming.mdc`）；名称是否体现蓝图 **空间 / 时间 / 动作** 之一或可接受的默认压缩（见蓝图 §1.3、§4.4 域柱后缀表）。 |
| G5 | **层缀与 MODULE=文件名** | 所有 `PUBLIC` TYPE/过程/`MODULE` 是否符合 `MD_`/`PH_`/`RT_` 前缀与「MODULE = 文件名」。 |
| G6 | **遗留对偶 inp/out** | 若仍存在 `*_In`/`*_Out` 对偶：是否仅限域合同允许的遗留区，且是否有迁移到 `*_Arg` 的登记项。 |

**记录列（复制到域柱表下方使用）**

```
| 检查项 | 结果 | 证据（路径:行或说明） |
| G1–G6 |      |                       |
```

---

## P1 — Material（贯通域柱）

| 层 | 主目录 | 首要 `CONTRACT.md` |
|----|--------|---------------------|
| L3 | `ufc_core/L3_MD/Material/` | `ufc_core/L3_MD/Material/CONTRACT.md` |
| L4 | `ufc_core/L4_PH/Material/` | （族级子目录 + 域内说明；弹性/塑性等族各自 `*_Def`） |
| L5 | `ufc_core/L5_RT/Material/` | （装配调用链见 `RT_Mat_*`） |

| # | 检查行 | 建议打开的文件（示例，可按族扩展） |
|---|--------|--------------------------------------|
| P1-G1 | L3 合同四型 + 族矩阵 | `L3_MD/Material/CONTRACT.md` |
| P1-G2 | L3 塑性四型 | `L3_MD/Material/Plast/MD_Mat_Plast_Def.f90` |
| P1-G2 | L4 弹性四型 | `L4_PH/Material/Elas/PH_Mat_Elas_Def.f90` |
| P1-G2 | L4 塑性四型 + Eval_Arg | `L4_PH/Material/Plast/PH_Mat_Plast_Def.f90` |
| P1-G3 | L4 塑性 SIO 五参 | `L4_PH/Material/Plast/PH_Mat_Plast_Eval.f90` |
| P1-G4 | 塑性过程名与 Phase | 同上 + `PH_Mat_Plast_*_Core.f90` |
| P1-G5 | L5 路由 DEF | `L5_RT/Material/RT_Mat_Def.f90`、`RT_Mat_Plast_Def.f90`、`RT_Mat_Elas_Def.f90` |
| P1-G6 | 旧 inp/out | `deprecated/` 与域合同「遗留」节 |

**P1 S7 签收（2026-05-19）**：柱级 **已签收** — 详见 [`plan/workflows/P1_MATERIAL_S7_SIGNOFF.md`](../../plan/workflows/P1_MATERIAL_S7_SIGNOFF.md)。post-wave5 #7–#13；Crystal W2 #14–#16；NAME #17–#19（`guardian Plast` P2=0）。

| # | S7 结果 | 备注 |
|---|---------|------|
| P1-G1–G5 | 绿 | 合同 + 四型 + Dispatch/C2 + Plast/Crystal |
| P1-G6 | 黄 | deprecated 专项未关 |

**功能补全（与形式独立）**：见 [`docs/03_Domain_Pillars/MaterialPillar/Material_重构进展报告_20260503.md`](../03_Domain_Pillars/MaterialPillar/Material_重构进展报告_20260503.md) 及其中 **2026-05-12 勘误**；以代码与合同为准核对各材料族覆盖率。

---

## P2 — Element（贯通域柱）

| 层 | 主目录 | 首要 `CONTRACT.md` |
|----|--------|---------------------|
| L3 | `ufc_core/L3_MD/Element/`、`L3_MD/Element/Mesh/` | `L3_MD/Element/Mesh/CONTRACT.md` |
| L4 | `ufc_core/L4_PH/Element/` | `L4_PH/Element/CONTRACT.md`、`L4_PH/Element/DESIGN_Elem_FourTypes.md` |
| L5 | `ufc_core/L5_RT/Element/`、`L5_RT/Assembly/` | `L5_RT/Assembly/CONTRACT.md` |

| # | 检查行 | 建议打开的文件 |
|---|--------|----------------|
| P2-G1 | L4 单元合同 + 文件清单 | `L4_PH/Element/CONTRACT.md` §2 |
| P2-G2 | L4 统一四型 | `L4_PH/Element/PH_Elem_Def.f90`、`PH_Elem_Ctx.f90` |
| P2-G3 | 单元 Ke/Fe Arg（Harness 消费） | `PH_Elem_Def.f90` 中 `PH_Element_Compute_Ke_Arg` 等；`L5_RT/Assembly/RT_Asm_Solv.f90` 引用处 |
| P2-G4 | NLGeom / Eval 命名 | `PH_NLGeomEval.f90`、`PH_Elem_Eval.f90` |
| P2-G5 | L5 单元 Proc 骨架 vs 生产 | `L5_RT/Element/RT_Elem_Proc.f90`（**G6 重点**：`inp`/`out` 对偶与 SIO 目标态差距） |
| P2-G6 | Legacy `PH_Elem_Contm` | `CONTRACT.md` 标注为 legacy 的文件 |

**空目录 / 功能未填满（合同已列）**：`Cohesive/`、`Gasket/`、`Surface/`、`User/` 等待内核 — 勾选「功能补全」 backlog，非形式对齐单项可关闭。

---

## P3 — Contact / Interaction（贯通域柱）

**合同真源**：L3 `ufc_core/L3_MD/Interaction/CONTRACT.md`（§2 四型、**§3 功能模块清单**）；L4 `ufc_core/L4_PH/Contact/CONTRACT.md`（**§二、文件清单**）；L5 `ufc_core/L5_RT/Contact/CONTRACT.md`（**§3 功能模块清单**）。  
**勾选方法**：对下表**每一行**文件执行 §0 的 G1–G6；一行可对应多文件时拆子行记录。

### P3.A — L3_MD / Interaction（`L3_MD/Interaction/`）

摘录自 `Interaction/CONTRACT.md` §3（与合同同步维护；若合同增删行，本表跟版）。

| 文件名 | MODULE 名 | 后缀角色 | G2/G5 重点 |
|--------|-------------|----------|------------|
| `MD_Int_Def.f90` | `MD_Int_Def` | `_Def` | 四型/校验辅助 |
| `MD_Int_Types.f90` | `MD_Int_Types` | `_Types` | 基础 TYPE（合同载明 Params/命名与 Algo 对齐见 X1） |
| `MD_Int_Core.f90` | `MD_Int_Core` | `_Core` | 域 Core |
| `MD_Int_API.f90` | `MD_Int_API` | `_API` | 薄再导出；G3 抽查跨模块 Arg |
| `MD_Int_Convert.f90` | `MD_Int_Convert` | — | 几何/投影 |
| `MD_Int_Detect.f90` | `MD_Int_Detect` | — | 搜索检测 |
| `MD_Int_Enforce.f90` | `MD_Int_Enforce` | — | 施加算法入口 |
| `MD_Int_Friction.f90` | `MD_Int_Friction` | — | 摩擦 |
| `MD_Int_Stiffness.f90` | `MD_Int_Stiffness` | — | 刚度/CSR |
| `MD_Int_Query.f90` | `MD_Int_Query` | `_Query` | 查询 |
| `MD_Int_Manager.f90` | `MD_Int_Manager` | — | 表面管理 |
| `MD_Int_Mgr.f90` | `MD_IntMgr` | `_Mgr` | 管理器 |
| `MD_Cont_Mgr.f90` | `MD_Cont_Mgr` | — | 域级 CRUD / WriteBack |
| `MD_Int_Connector.f90` | `MD_Int_Connector` | — | Connector 解析 |
| `MD_Int_Ctx.f90` | 多 MODULE | `_Ctx` | G2 子模块多；核对合同索引 |
| `MD_Int_Parser.f90` | `MD_Int_Parser` | `_Parser` | 解析 |
| `MD_Int_Mapper.f90` | `MD_Int_Mapper` | `_Mapper` | 映射 |
| `MD_Int_Sync.f90` | `MD_Int_Sync` | `_Sync` | Legacy 同步 |
| `MD_Hash_Table.f90` | `MD_Hash_Table` | — | 哈希工具 |

### P3.B — L4_PH / Contact（`L4_PH/Contact/`）

摘录自 `L4_PH/Contact/CONTRACT.md` §二（18 个核心 `.f90`）。

| 子目录 | 文件 | MODULE | 合同状态 | G2/G4 提示 |
|--------|------|--------|----------|------------|
| `/` | `PH_Cont_Def.f90` | `PH_Cont_Def` | **AUTHORITY** | 四型主定义 |
| `/` | `PH_Cont_Core.f90` | `PH_Cont_Core` | **ACTIVE** | Gap/Force/Stiffness |
| `Domain/` | `PH_Cont_Domain.f90` | `PH_Cont_Domain` | **ACTIVE** | 枚举/容器 |
| `Core/` | `PH_Cont_Mgr.f90` | `PH_Cont_Mgr` | **ACTIVE** | SIO 过程 |
| `Core/` | `PH_Cont_Brg.f90` | `PH_Cont_Brg` | **ACTIVE** | L4 Bridge |
| `Core/` | `PH_Cont_CSR.f90` | `PH_Cont_CSR` | **ACTIVE** | CSR 装配 |
| `Core/` | `PH_Cont_Ctx_Def.f90` | `PH_Cont_Ctx_Def` | **ACTIVE** | Ctx |
| `Search/` | `PH_Cont_Search.f90` | `PH_Cont_Search` | **ACTIVE** | 空间维检索 |
| `Search/` | `PH_ContSearch_Adv.f90` | `PH_ContSearch_Adv` | **ACTIVE** | 高级搜索 |
| `Search/` | `PH_Cont_BVHBuilder.f90` | `PH_Cont_BVHBuilder` | **ACTIVE** | BVH 构建 |
| `Search/` | `PH_Cont_BVHQuery.f90` | `PH_Cont_BVHQuery` | **ACTIVE** | BVH 查询 |
| `Search/` | `PH_Cont_CCD.f90` | `PH_Cont_CCD` | **ACTIVE** | CCD |
| `Friction/` | `PH_Cont_Friction.f90` | `PH_Cont_Friction` | **ACTIVE** | 摩擦库 |
| `Explicit/` | `PH_Cont_Expl.f90` | `PH_Cont_Expl` | **ACTIVE** | 显式接触 |
| `Self/` | `PH_Cont_SelfContact.f90` | `PH_Cont_SelfContact` | **ACTIVE** | 自接触 |
| `Thermal/` | `PH_ThermalCont_Def.f90` | `PH_ThermalCont_Def` | **ACTIVE** | 热接触四型 |
| `Thermal/` | `PH_Cont_ThermoMech.f90` | `PH_Cont_ThermoMech` | **ACTIVE** | 热力耦合 |
| `Wear/` | `PH_Cont_WearEvolution.f90` | `PH_Cont_WearEvolution` | **ACTIVE** | 磨损 |
| `AI/` | `PH_AI_ContactLaw.f90` | `PH_AI_ContactLaw` | **ACTIVE** | AI 接触律 |

### P3.C — L5_RT / Contact（`L5_RT/Contact/`）

摘录自 `L5_RT/Contact/CONTRACT.md` §3；**注意**合同所载 **CMake 对 `Contact/*.f90` 的 EXCLUDE** — 功能补全与可链接性与 G5 无关但须在 backlog 跟踪。

| 文件名 | MODULE | 后缀角色 | 合同标记 |
|--------|--------|----------|----------|
| `RT_Cont_Def.f90` | `RT_Cont_Def` + `RT_Cont_Types_Impl` | `_Def` | **AUTHORITY** |
| `RT_Cont_Solv.f90` | `RT_Cont_Solv` | — | **GOLDEN-LINE** |
| `RT_Cont_Core.f90` | `RT_Cont_Core` | `_Core` | **ACTIVE** |
| `RT_Cont_Search.f90` | `RT_Cont_Search` | — | **ACTIVE** |
| `RT_Cont_Ctrl.f90` | `RT_Cont_Ctrl` | — | **ACTIVE** |
| `RT_Cont_Expl.f90` | `RT_Cont_Expl` | — | **ACTIVE** |
| `RT_Cont_AugLagSolv.f90` | `RT_Cont_AugLagSolv` | — | **ACTIVE** |
| `RT_Cont_Brg.f90` | `RT_Cont_Brg` | `_Brg` | **ACTIVE** |
| `RT_Contact_Def.f90` | （Re-export） | LEGACY | **LEGACY 兼容** |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（P3 域柱） |      |      |

---

## P4 — LoadBC（贯通域柱）

**合同真源**：L3 真源以 **`L3_MD/LoadBC/CONTRACT.md`** 为主；**`L3_MD/Boundary/CONTRACT.md`** 为 Phase3 前兼容入口（核心模块子弹列表见该文 §核心模块）。L4 `L4_PH/LoadBC/CONTRACT.md` **§2 文件布局**；L5 `L5_RT/LoadBC/CONTRACT.md` **§3 功能模块清单**。

### P4.A — L3_MD / LoadBC + Boundary

**LoadBC 域目录**（`LoadBC/CONTRACT.md`「核心模块」表）

| 模块文件 | 角色 |
|----------|------|
| `MD_Load_Def.f90` | 纯 Load 四型 + `MD_Load_Domain` |
| `MD_BC_Def.f90` | 纯 BC 四型 + `MD_BC_Domain` |
| `MD_LoadBC_Def.f90` | DEPRECATED（迁出引用） |
| `MD_LBC_Def.f90` | DEPRECATED（迁出引用） |

**Boundary 旧树**（`Boundary/CONTRACT.md`；与上表并行至 CMake 解除 EXCLUDE）

| 文件 | 职责摘要 |
|------|----------|
| `MD_BC_Def.f90` | BC 四型 |
| `MD_Load_Def.f90` | Load 四型 + 聚合 State/Algo/Ctx |
| `MD_LBC_Domain.f90` | 域容器、Idx、Legacy |
| `MD_LBC_Mgr.f90` | `MD_LBC_Mgr` |
| `MD_LBC_Idx.f90` | Idx 绑定 |
| `MD_LBC_Brg.f90` | L6/UF 桥 |

### P4.B — L4_PH / LoadBC（`L4_PH/LoadBC/CONTRACT.md` §2.1–2.2）

**Load 柱 — `PH_Load_*`**

| 文件 | MODULE | 角色 |
|------|--------|------|
| `PH_Load_Def.f90` | `PH_Load_Def` | `_Def` |
| `PH_Load_Core.f90` | `PH_Load_Core` | `_Core` |
| `PH_Load_Aux_Def.f90` | `PH_Load_Aux_Def` | `Aux_Def` |
| `PH_Load_NestedToFlat.f90` | `PH_Load_NestedToFlat` | `_Proc` |
| `PH_Load_Mgr.f90` | `PH_Load_Mgr` | `_Mgr` |

**BC 柱 — `PH_BC_*`**

| 文件 | MODULE | 角色 |
|------|--------|------|
| `PH_BC_Def.f90` | `PH_BC_Def` | `_Def` |
| `PH_BC_Core.f90` | `PH_BC_Core` | `_Core` |
| `PH_BC_Aux_Def.f90` | `PH_BC_Aux_Def` | `Aux_Def` |
| `PH_BC_NestedToFlat.f90` | `PH_BC_NestedToFlat` | `_Proc` |
| `PH_BC_FlatToNested.f90` | `PH_BC_FlatToNested` | `_Proc` |
| `PH_BC_Brg.f90` | `PH_BC_Brg` | `_Brg` |
| `PH_BC_Mgr.f90` | `PH_BC` | `_Mgr` |

**§4 废弃映射（勾选迁移状态）**：合同列 `PH_LoadBC_*` → Load/BC 两柱替代文件 — G6 重点。

### P4.C — L5_RT / LoadBC（`L5_RT/LoadBC/CONTRACT.md` §3）

| 文件 | MODULE | 后缀角色 | 合同状态 |
|------|--------|----------|----------|
| `RT_LoadBC_Def.f90` | `RT_LoadBC_Def` | `_Def` | **ACTIVE (AUTHORITY)** |
| `RT_LoadBC_Impl.f90` | `RT_LoadBC_Impl` | `_Impl` | **ACTIVE** |
| `RT_LoadBC_Proc.f90` | `RT_LoadBC_Proc` | `_Proc` | **ACTIVE**（G3/G6：SIO _In/_Out） |
| `RT_LoadBC_ReactionForce.f90` | `RT_LoadBC_ReactionForce` | 特化 | **ACTIVE** |
| `RT_LoadBC_Brg.f90` | `RT_LoadBC_Brg` | `_Brg` | **ACTIVE** |
| `RT_LoadBC_ConstApply.f90` | `RT_LoadBC_ConstApply` | `_Brg`（约束施加） | **ACTIVE** |
| `RT_LoadBC_Core.f90` | `RT_LoadBC_Core` | `_Core` | **LEGACY** |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（P4 域柱） |      |      |

---

## P5 — Output（贯通域柱）

**合同真源**：L3 `L3_MD/Output/CONTRACT.md` **§3 功能模块清单**；L5 `L5_RT/Output/CONTRACT.md` **§3 功能模块清单**。L4 物理输出在 **`L4_PH/Bridge/Output/`**（合同 `L4_PH/Bridge/Output/CONTRACT.md` 以 TYPE/API 为主，**无**与 Element 同构的 §2 文件矩阵）— 下表 **B** 按当前源码目录列真文件。

### P5.A — L3_MD / Output

摘录自 `L3_MD/Output/CONTRACT.md` §3。

| 文件名 | MODULE 名 | 后缀角色 | 合同状态 |
|--------|-------------|----------|----------|
| `MD_Out_API.f90` | `MD_Out_API` | Domain facade | **AUTHORITY** |
| `MD_Out_Def.f90` | `MD_Out_Def` | `_Def` | ACTIVE |
| `MD_Out_Mgr.f90` | `MD_OutMgr` | `_Mgr` | ACTIVE |
| `MD_Out_Lib.f90` | `MD_OutLib` | `_Lib` | ACTIVE |
| `MD_Out_Parse.f90` | `MD_Out_Parse` | `_Parse` | ACTIVE |
| `MD_Out_Sync.f90` | `MD_Out_Sync` | `_Sync` | ACTIVE |
| `MD_Out_VarReg.f90` | `MD_Out_VarReg` | `_VarReg` | ACTIVE |
| `MD_Out_UniFld.f90` | `MD_Out_UniFld` | — | ACTIVE |
| `MD_Out_UniFldOps.f90` | `MD_Out_UniFldOps` | `_Ops` | ACTIVE |
| `MD_Out_FieldExport.f90` | `MD_Out_FieldExport` | — | ACTIVE |
| `MD_Out_ReportPlot.f90` | `MD_Out_ReportPlot` | — | ACTIVE |
| `MD_OutDP_Brg.f90` | `MD_OutDP_Brg` | `_Brg` | SKELETON |

### P5.B — L4_PH / Bridge / Output（源码目录：`L4_PH/Bridge/Output/`）

合同描述 `PH_Output_*` API；当前仓库 **MODULE 级**文件：

| 文件 | 说明 |
|------|------|
| `PH_Out_Brg.f90` | 桥接 |
| `PH_Out_Mgr.f90` | 管理/路由 |

（若合同后续增加 §2 文件表，以合同为准扩充本行。）

### P5.C — L5_RT / Output

摘录自 `L5_RT/Output/CONTRACT.md` §3。

| 文件 | MODULE | 后缀角色 | 合同状态 |
|------|--------|----------|----------|
| `RT_Out_Aux_Def.f90` | `RT_Out_Aux_Def` | `_Aux_Def` | **ACTIVE** |
| `RT_Out_Def.f90` | `RT_Out_Def` | `_Def` | **ACTIVE (AUTHORITY)** |
| `RT_Out_Mgr.f90` | `RT_Out_Mgr` | `_Mgr` | **ACTIVE (GOLDEN-LINE)** |
| `RT_Out_Core.f90` | `RT_Out_Core` | `_Core` | **LEGACY (FACADE)** |
| `RT_Out_Proc.f90` | `RT_OutProc` | `_Proc` | **ACTIVE**（G3/G6） |
| `RT_Out_Impl.f90` | `RT_Out_Impl` | `_Impl` | **ACTIVE** |
| `RT_Out_Brg.f90` | `RT_Out_Brg` | `_Brg` | **ACTIVE** |
| `RT_Out_Restart.f90` | `RT_OutRestart` | 特化 | **ACTIVE** |
| `RT_Writer_HDF5.f90` | `RT_WriterHDF5` | Writer | **ACTIVE** |
| `RT_Writer_ODB.f90` | `RT_WriterODB` | Writer | **ACTIVE** |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（P5 域柱） |      |      |

---

## P6 — WriteBack（贯通域柱）

**合同真源**：L3 `L3_MD/WriteBack/CONTRACT.md` **§3**；L4 `L4_PH/Bridge/WriteBack/CONTRACT.md`（**§ Implementation Status / 域柱 v2.0** 与表「文件/MODULE」）；L5 `L5_RT/WriteBack/CONTRACT.md` **§3**。

### P6.A — L3_MD / WriteBack

摘录自 `L3_MD/WriteBack/CONTRACT.md` §3。

| 文件名 | MODULE 名 | 后缀角色 | 合同状态 |
|--------|-------------|----------|----------|
| `MD_WB_Def.f90` | `MD_WB_Def` | `_Def` | ACTIVE |
| `MD_WB_Core.f90` | `MD_WB_Core` | `_Core` | ACTIVE |
| `MD_WB_Domain.f90` | `MD_WBDomain` | Domain | ACTIVE |
| `MD_WB_Mgr.f90` | `MD_WBMgr` | `_Mgr` | ACTIVE |
| `MD_WB_Brg.f90` | `MD_WB_Brg` | `_Brg` | ACTIVE |

### P6.B — L4_PH / Bridge / WriteBack（`L4_PH/Bridge/WriteBack/`）

摘录自 `L4_PH/Bridge/WriteBack/CONTRACT.md` 域柱 v2.0 表（AUTHORITY / Bridge / Init）。

| 文件 | MODULE | 合同角色 |
|------|--------|----------|
| `PH_WB.f90` | `PH_WB` | **AUTHORITY**（四型 + TBP） |
| `PH_WB_Brg.f90` | `PH_WB_Brg` | Bridge API |
| `PH_WB_Init.f90` | `PH_WBInit` | 域初始化 |

> 合同「Implementation Status」尚列 `PH_WriteBack_Core.f90` 等旧名 — 以 **§ Domain Pillar v2.0** 与上表 **PH_WB\*** 为勾选真源；旧名按合同 Migration 节视为已迁移。

### P6.C — L5_RT / WriteBack

摘录自 `L5_RT/WriteBack/CONTRACT.md` §3。

| 文件 | MODULE | 后缀角色 | 合同状态 |
|------|--------|----------|----------|
| `RT_WB_Aux_Def.f90` | `RT_WB_Aux_Def` | `_Aux_Def` | **ACTIVE** |
| `RT_WB_Def.f90` | `RT_WB_Def` | `_Def` | **ACTIVE (AUTHORITY)** |
| `RT_WB_Domain.f90` | `RT_WBDomain` | Domain | **ACTIVE (GOLDEN-LINE)** |
| `RT_WB_Impl.f90` | `RT_WBImpl` | `_Impl` | **ACTIVE** |
| `RT_WB_Proc.f90` | `RT_WBProc` | `_Proc` | **ACTIVE**（G3/G6） |
| `RT_WB_Brg.f90` | `RT_WriteBack_Brg` | `_Brg` | **ACTIVE** |
| `RT_WB_Core.f90` | — | `_Core` | **LEGACY** |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（P6 域柱） |      |      |

---

## 附录 H1 — Analysis / Step / Amplitude / Solver（半贯通域柱）

**蓝图位置**：H1（L3 Analysis + L5 StepDriver / Solver；**L4 无独立 Analysis 域**）。  
**总合同**：`ufc_core/L3_MD/Analysis/CONTRACT.md`（**§二 文件清单** 按子域；**§三 四类 TYPE**；**L4 无独立域** 决策见该文 §「L4 无独立域决策」）。  
**子合同**：`Analysis/Step/CONTRACT.md`、`Analysis/Amplitude/CONTRACT.md`、`Analysis/Solver/CONTRACT.md`。  
**L5 合同**：`L5_RT/StepDriver/CONTRACT.md`、`L5_RT/Solver/CONTRACT.md`（及 `L5_RT/Solver/Coupling/CONTRACT.md` 为 Solver 子半柱）。

**说明**：`Analysis/CONTRACT.md` §二 Step 子域已于 **2026-05-12** 与 **`MD_Step_Mgr.f90` / `MODULE MD_Step_Mgr`** 对齐；勾选时以子合同细粒度表为准。

---

### H1.0 — AnalysisCompat（L3）+ 引用附录（L1）

摘录自 `L3_MD/Analysis/CONTRACT.md` §二：**实现文件**仅 **`MD_Ana_Comp` / `MD_Ana_Brg`**；**`RT_SolverType_Def`** 见同节 **「引用附录」**（不计入 L3 实现文件计数）。

**L3 实现（勾选 G1–G6）**

| 文件 | 职责 |
|------|------|
| `L3_MD/Analysis/MD_Ana_Comp.f90` | `MODULE MD_Ana_Comp`：正交兼容矩阵、`CheckTriple` / `ValidateStep` / `FullCheck` 等 |
| `L3_MD/Analysis/MD_Ana_Brg.f90` | `MODULE MD_Ana_Brg`：`InitCompat`、子域注册表 `Register` / `Lookup` / `Iterate` / `Finalize`（转发 `MD_Ana_Comp_Init`） |

**引用附录（L1，不计入「实现文件」；勾选依赖/符号真源）**

| 文件 | 职责 |
|------|------|
| `L1_IF/Base/RT_SolverType_Def.f90` | `MODULE RT_SolverType_Def`：`RT_SOLVER_*` 常量（L1 真源） |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（H1.0） |      |      |

---

### H1.A — Step（L3 + L5 StepDriver）

#### H1.A.1 — L3_MD / Analysis / Step（`L3_MD/Analysis/Step/`）

**总合同摘录**（`Analysis/CONTRACT.md` §二 Step 子域）：

| 文件（现树） | 合同职责摘要 |
|--------------|----------------|
| `MD_Step_Def.f90` | `MODULE MD_Step_Def`：`MD_Step_State` / `MD_Step_Ctx` |
| `MD_Step_Mgr.f90` | 步域 AUTHORITY：`MD_Step_Domain`、`MD_Step_Desc`、`StepAlgo`、SIO `*_Arg`、TBP（见源码头注释） |
| `MD_Step_Proc.f90` | `MODULE MD_Step_Proc`：`PROC_*`、`UF_Step*`、`ProcToSolverType` 等 |
| `MD_Step_Sync.f90` | `MODULE MD_Step_Sync`：`MD_Step_SyncFromLegacy`、`UF_Step_BuildLegacyLoadDefs_FromLdbc` |
| `Step/CONTRACT.md` | 子域合同真源 |

**子合同固定清单**（`Analysis/Step/CONTRACT.md` §「核心模块（当前树）」+ §「细粒度子程序清单」— 此处列文件级行，过程/TBP 全量以子合同为准）：

| 文件 | MODULE（以源码为准） | 备注 |
|------|----------------------|------|
| `MD_Step_Mgr.f90` | `MD_Step_Mgr` | 子合同细粒度表与 **`MODULE MD_Step_Mgr`** 一致 |
| `MD_Step_Def.f90` | `MD_Step_Def` | 子合同同 |
| `MD_Step_Proc.f90` | `MD_Step_Proc` | 多 `UF_*` / `PROC_*` TYPE |
| `MD_Step_Sync.f90` | `MD_Step_Sync` | Populate / Legacy |

#### H1.A.2 — L5_RT / StepDriver（`L5_RT/StepDriver/`）

摘录自 `L5_RT/StepDriver/CONTRACT.md` **§3 功能模块清单**。

| 文件名 | MODULE 名 | 后缀角色 | 合同状态 |
|--------|------------|----------|----------|
| `RT_Step_Def.f90` | `RT_Step_Def` | `_Def` | **AUTHORITY** |
| `RT_Step_Exec.f90` | `RT_Step_Exec` | — | **GOLDEN-LINE** |
| `RT_Step_Impl.f90` | `RT_Step_Impl` | `_Impl` | **ACTIVE** |
| `RT_Step_Core.f90` | `RT_Step_Core` | `_Core` | **ACTIVE** |
| `RT_Step_Brg.f90` | `RT_Step_Brg` | `_Brg` | **ACTIVE** |
| `RT_Step_Ctx.f90` | `RT_Step_Ctx` | — | **ACTIVE** |
| `RT_Step_WS.f90` | `RT_Step_WS` | — | **ACTIVE** |
| `RT_Step_NR_Core.f90` | `RT_Step_NR_Core` | — | **ACTIVE** |
| `RT_AI_StepCtrAlgo.f90` | `RT_AI_StepCtrAlgo` | — | **ACTIVE**（AI 插槽 PLACEHOLDER） |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（H1.A） |      |      |

---

### H1.B — Amplitude（L3；L5 编排入口见子合同）

#### H1.B.1 — L3_MD / Analysis / Amplitude（`L3_MD/Analysis/Amplitude/`）

**总合同摘录**（`Analysis/CONTRACT.md` §二 Amplitude 子域）：

| 文件 | 职责 |
|------|------|
| `MD_Amp_Def.f90` | 四型、`MD_Amp_Domain`、SIO `*_Arg` / `Apply_*`、`MD_AmpShared_*` |
| `MD_Amp_UF.f90` | `MD_Amp_Slot_*`、`MD_Amp_Ext_Desc`、`MD_Amp_FromExt*`、UAMP `MD_Amp_Eval_*` |
| `MD_Amp_Mgr.f90` | `Amp_GetFactor`、`MD_Amp_Slot_To_MD_Desc`、`MD_Amp_SyncFromLegacy`、再导出 |
| `MD_Amp_Idx.f90` | `g_ufc_global` 路径按索引 Get / EvalAtTime / WriteBack |
| `Amplitude/CONTRACT.md` | 子域合同真源 |

**子合同「模块与依赖」表**（`Amplitude/CONTRACT.md` §「模块与依赖（单向）」— 与上表一致，可逐文件勾 G2/G3）。

**子合同「细粒度子程序清单」**（同文件 §「细粒度子程序清单」— 四文件全表；此处不重复粘贴过程列，勾选时 **打开子合同 PDF/MD 原表** 对 `MD_Amp_Mgr` / `MD_Amp_Def` / `MD_Amp_Idx` / `MD_Amp_UF` 逐行）。

#### H1.B.2 — L5 编排（非 L3 模块）

`Amplitude/CONTRACT.md` 载明推荐编排入口 **`RT_Amp_FactorAt`**（路径以仓库 CMake 为准；若重命名以 `grep` 命中为准）。勾选 **G3/G4** 时核对 L5 调用是否经 **`Amp_GetFactor(..., md_layer%amplitude)`** 与 **`l3Frozen`** 策略一致。

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（H1.B） |      |      |

---

### H1.C — Solver 配置（L3）+ 运行时求解（L5）+ Coupling 子半柱

#### H1.C.1 — L3_MD / Analysis / Solver（`L3_MD/Analysis/Solver/`）

**总合同摘录**（`Analysis/CONTRACT.md` §二 Solver 子域）：

| 文件 | 职责 |
|------|------|
| `MD_Solv_Def.f90` | `MODULE MD_Solv_Def`：四型 + `MD_Solver_Desc_*` |
| `MD_Solv_Mgr.f90` | `MODULE MD_Solv_Mgr`：`MD_Solver_Domain`、SIO、`MD_Solver_Brg_GetConfigForStep*` |
| `MD_Solv_Sync.f90` | `MODULE MD_Solv_Sync`：`MD_Solver_SyncFromStep`（破环） |
| `Solver/CONTRACT.md` | 子域合同真源 |

**子合同细粒度清单**（`Solver/CONTRACT.md` §「细粒度清单（TYPE / 过程 / 绑定）」— 全表 3 行，逐文件勾 G2/G3/G5）：

| 文件 | MODULE | TYPE（PUBLIC）摘要 |
|------|--------|---------------------|
| `MD_Solv_Def.f90` | `MD_Solv_Def` | `MD_Solver_Desc` / `Algo` / `State` / `Ctx` + 桩类型 |
| `MD_Solv_Mgr.f90` | `MD_Solv_Mgr` | `MD_Solver_Domain` + SIO `MD_Solver_*_Arg` + Brg GetConfigForStep |
| `MD_Solv_Sync.f90` | `MD_Solv_Sync` | —（`MD_Solver_SyncFromStep` 等） |

#### H1.C.2 — L5_RT / Solver（`L5_RT/Solver/`）

摘录自 `L5_RT/Solver/CONTRACT.md` **§3 功能模块清单**。

| 文件名 | MODULE 名 | 后缀角色 | 合同状态 |
|--------|------------|----------|----------|
| `RT_Solv_Def.f90` | `RT_Solv_Def` | `_Def` | **AUTHORITY** |
| `RT_Solv_Mgr.f90` | `RT_Solv_Mgr` | — | **GOLDEN-LINE** |
| `RT_Solv_Nonlin.f90` | `RT_Solv_Nonlin` | — | **GOLDEN-LINE** |
| `RT_Solv_Lin.f90` | `RT_Solv_Lin` | — | **ACTIVE** |
| `RT_Solv_TimeInt.f90` | `RT_Solv_TimeInt` | — | **ACTIVE** |
| `RT_Solv_Sparse.f90` | `RT_Solv_Sparse` | — | **ACTIVE** |
| `RT_Solv_Brg.f90` | `RT_Solv_Brg` | `_Brg` | **ACTIVE** |
| `RT_Solv_Core.f90` | `RT_Solv_Core` | `_Core` | **ACTIVE** |
| `RT_Solv_Impl.f90` | `RT_Solv_Impl` | `_Impl` | **ACTIVE** |
| `RT_Solv_Proc.f90` | `RT_Solv_Proc` | `_Proc` | **ACTIVE**（G3/G6：SIO In/Out） |
| `RT_Solv_ContResidual.f90` | `RT_Solv_ContResidual` | — | **ACTIVE** |
| `RT_Solv_CoreMemPool.f90` | `RT_Solv_CoreMemPool` | — | **ACTIVE** |
| `RT_Solv_ABAQUSReg.f90` | `RT_Solv_ABAQUSReg` | — | **ACTIVE** |
| `RT_Asm_DofMapUtils.f90` | `RT_Asm_DofMapUtils` | — | **ACTIVE** |
| `RT_AI_ConvPredictAlgo.f90` | `RT_AI_ConvPredictAlgo` | — | **ACTIVE**（AI 插槽） |

**§4.1 SIO**：`RT_Solv_Init/Equilibrium/Linear/Convergence/Cutback_Interface` — **G6 重点**（`*_In`/`*_Out` 与 `*_Arg` 收敛策略）。

#### H1.C.3 — L5_RT / Solver / Coupling（子半柱）

摘录自 `L5_RT/Solver/Coupling/CONTRACT.md` **§文件清单**。

| 文件 | 说明 |
|------|------|
| `RT_MF_Def.f90` | 四型 AUTHORITY |
| `RT_MF_Coordinator.f90` | GOLDEN-LINE（合同注 PLACEHOLDER 可能） |
| `RT_MF_Brg.f90` | L3→L5 Populate Bridge |

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1–G6（H1.C） |      |      |

---

## 跨域形式对齐 — 统一待办（登记用）

| ID | 主题 | 真源/说明 | 建议 Owner |
|----|------|-----------|------------|
| X1 | `Params` → `Algo` 命名统一 | `UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md` §1附.1 | 架构 + 各域 Brg |
| X2 | L3 无层缀 TYPE（如 `Desc_Model`） | 对齐 `MD_*_Desc` 或标注 LEGACY | L3_Model |
| X3 | L5 `RT_Elem_Proc` 的 `inp`/`out` → `*_Arg` | 与 `PH_Elem_*` / Dispatcher 收敛策略 | L5_Element |
| X4 | `*_Domain_Core` vs `*_Core` 容器混用 | 蓝图 §1附、域合同「文件角色」表 | 分域逐步 |

---

## 功能补全 backlog（与形式正交）

以下项 **不** 因通过 G1–G6 而自动关闭；需单独测试/合同条目。

| ID | 说明 | 参考 |
|----|------|------|
| F1 | Element：`Cohesive`/`Gasket`/`Surface`/`User` 子目录空壳待内核 | `L4_PH/Element/CONTRACT.md` §2.2 |
| F2 | Material：多族覆盖率（超弹/蠕变/损伤等）与 L4/L5 路由一致性 | 材料进展报告 + `RT_Mat_*_Core` 分派 |
| F3 | Contact：P3 全表链上缺口（含 L5 `Contact` 目录 **CMake EXCLUDE**、实现缺失） | `L5_RT/Contact/CONTRACT.md` §3 备注 + P3.C |
| F4 | LoadBC：L3 `Boundary` 目录 **CMake EXCLUDE**、与 `LoadBC/` 双轨收敛 | `L3_MD/Boundary/CONTRACT.md` Backlog |

---

**修订（v1.5）**：**「全域推广」** 下增加首 PR 模板链接 [`PR01_P1_P2_材料单元装配金线.md`](./PR01_P1_P2_材料单元装配金线.md)（P1∩P2∩Assembly 接缝）。**v1.4** 及此前条目仍有效。
