# UFC 链式落地顺序：材料 → 单元 → 载荷边界 → 接触

**版本**: 1.4.1  
**日期**: 2026-03-19  
**范围**: `ufc_core` 内 **L3_MD / L4_PH / L5_RT** 四条垂直链（核心锚点、桥接路径、Data chain 契约摘要）。

**执行任务分解（WBS）**：`docs/plans/README.md`（当前工作区未收录）— **材料·单元**、**载荷边界**、**接触** 三链的 **主计划**、**`_WBS_detail`**、多文件 **`R2-*` round2** 与 **交叉依赖矩阵**（与本文 §一～§四 对照执行）。

---

## 执行顺序（冻结）

1. **材料链**（L3 Mat → L4 Mat → RT Mat/Asm 中与材料相关的装配入口）  
2. **单元链**（L3 Mesh/Elem → L4 Element → RT Element/Asm）  
3. **载荷边界链**（L3 LoadBC/LoadBC → L4 LoadBC → RT LoadBC/Asm）  
4. **接触链**（L3 Interaction/Cont → L4 Contact → RT Contact/Asm）

---

## 一、材料链（优先）

### 1.1 层间锚点（按数据流）

| 层 | 角色 | 核心模块（入口） |
|----|------|------------------|
| **L3_MD** | 材料库、描述、同步到 L4 侧可消费形态 | `MD_Mat_API.f90`, `MD_Mat_Core.f90`, `MD_Mat_Lib.f90`, `MD_Mat_Reg.f90`, `MD_Mat_Sync.f90`, `MD_Mat_*_Core.f90`（弹/塑/粘/损伤等）, `MD_Mat_Domain_Types*.f90` |
| **Bridge L3→L4** | L3 本构描述 → L4 路由 | `L3_MD/Bridge/Bridge_L4/MD_MatLib_PH_Brg.f90` |
| **L4_PH** | 本构计算、注册表、UMAT 桥 | `PH_Mat_Domain_Core.f90`, `PH_Mat_Reg_Core.f90`, `PH_Mat_Eval.f90`, `PH_Mat_Integ_Core.f90`, `PH_Mat_Standards.f90`, `Shared/PH_Mat_ParamMapping.f90`, `Shared/PH_Mat_Defn_UMAT_Bridge.f90`, `UMAT/*`, 各 `*Core.f90` |
| **L5_RT** | 运行时调 L4 本构、与装配上下文对接 | `Physics/Material/RT_Mat_Core.f90`, `Bridge/PH/RT_Brg_PH_Mat.f90` |
| **L5_RT（装配侧）** | 单元积分中取材料切线/应力 | `Physics/Assembly/RT_Assembly_Domain_Core.f90`, `RT_Asm_Solv.f90`, `RT_Asm_NLMat_Eval.f90`, `RT_Asm_Global.f90`（与材料路径交叉处打锚点） |

### 1.2 建议动作（与现有设计稿对齐）

| 优先级 | 动作 | 依据 |
|--------|------|------|
| P0 | 落实 `Material_Constitutive_Unified_Design.md` **Phase 1**：扩展 `PH_Mat_Reg_Entry`（category / integration_family / impl_status）并在注册初始化中填报 | 元数据先于大重构 |
| P0 | 在 **`MD_MatLib_PH_Brg`** 与 **`RT_Brg_PH_Mat`** 模块头增加 **Data chain** 注释：`MatProperties` / `mat_id` / `props` / `statev` 与 L4 `PH_Mat_*` 的对应字段 | 减少 L3/L4/L5 口头约定 |
| P1 | 清理 **`PH_Mat_ParamMapping.f90`** 中残余乱码 `!! Theory`（按本构块分批改为短英文 + 指向材料手册/卡片） | 可读性与审查 |
| P1 | `props`/`statev` **长度校验**：在 L4 `Build_UMAT_Context` 或 Reg 查询之后统一检查（设计稿 Phase 2） | 防止静默越界 |
| P2 | 共享子程序抽取（`Construct_Elastic_D`、`Consistent_Tangent_Plastic` 等，设计稿 Phase 3） | 降重复、统一 bug 修复面 |
| P2 | **验证**：至少一条路径 **J2 + 单单元** + **一种超弹/蠕变** 的回归（NAFEMS/自编） | 材料链改动的安全网 |

---

## 二、单元链（第二）

### 2.1 层间锚点

| 层 | 角色 | 核心模块 |
|----|------|----------|
| **L3_MD** | 网格与单元数据、单元库元数据 | `L3_MD/Mesh/MD_Mesh_*`, `L3_MD/Element/MD_Elem_Core.f90`, `MD_Elem_Family.f90`, `MD_Elem_UEL.f90`, `MD_Mesh_Domain_Core.f90` |
| **Bridge L3→L4** | 单元/几何计算转发至 L4 | `L3_MD/Bridge/Bridge_L4/MD_Elem_PH_Brg.f90`, `L3_MD/Bridge/Bridge_L4/MD_Geom_PH_Brg.f90` |
| **Bridge L3→L5** | 单元侧与 RT 装配/本构衔接（若经 L3 调度） | `L3_MD/Bridge/Bridge_L5/MD_Elem_RT_Brg.f90` |
| **L4_PH** | 单元族内核、注册、形状函数与 B 矩阵 | `L4_PH/Element/PH_Element_Domain_Core.f90`, `PH_Elem_Reg_Core.f90`, `PH_Elem_Ctx.f90`, `Element/Shared/*`, 各族 `PH_Elem_*_Core.f90` |
| **L5_RT** | 单元驱动、装配、与求解器对接 | `L5_RT/Physics/Element/RT_Element_Domain_Core.f90`, `RT_Elem_Core.f90`, `RT_UEL_API.f90`, `Physics/Assembly/RT_Asm_*`, `Physics/Element/RT_Contm_Struct_Mat.f90`（连续介质材料点） |

### 2.2 Data chain 契约（Element，P0 文档锚点）

| 字段 / 概念 | 典型来源 | 消费侧 | 说明 |
|-------------|----------|--------|------|
| `UF_ElemType` / `UF_ElemFormul` | L3 单元库 / 网格 | `MD_Elem_PH_Brg` → `PH_Elem_*` | 决定族与公式；与 `PH_Elem_Reg_Core` 注册 id 应对齐 |
| `UF_ElemCtx` / 积分点坐标、雅可比 | L3+几何桥 | L4 形函数 / B 矩阵 | `MD_Geom_PH_Brg` 与单元桥配合 |
| `matModels(:)` / 材料 id | L3 Mat | L4 本构 + L5 装配 | 与材料链 `mat_id` / `props` 一致 |
| `state_in` / `state_out` | RT 迭代 | L4 单元内核 | 热/孔压/THM 等扩展自由度随族而定 |

### 2.3 建议动作

| 优先级 | 动作 |
|--------|------|
| P0 | 在 **`PH_Element_Domain_Core`** / **`RT_Element_Domain_Core`** 中明确 **elem_type → PH 注册表 → RT 调度** — **已扩展** `Compute_Ke`/`Compute_Fe`：**C3D4、C3D10、CPS4（elem_type 150–171）/CPE4、C3D8**（见模块头四链说明） |
| P0 | 核对 **`MD_Elem_PH_Brg`** 与 **`PH_Elem_Reg_InitAll`** 的 elem 集合 — **见 §2.4**；头注释已加 **elem_type ID contract** |
| P1 | **B-bar / 减缩积分 / 沙漏** 等策略在 **同一 Element 族** 内用 `! Theory:` 指向同一内部说明，避免复制漂移 |
| P1 | **UEL/UMAT 并行路径**：`MD_Elem_UEL` + `RT_UEL_API` + `PH_Elem_UEL_Core` 的字段对齐检查 |
| P2 | **Patch test** 覆盖：C3D8（或主实体单元）+ 一种壳/梁作为单元链验收 |

### 2.4 `MD_Elem_PH_Brg` 与 `PH_Elem_Reg_InitAll` 核对（2026-03-19）

| 检查项 | 结果 |
|--------|------|
| **`MD_Elem_Core.f90` 中 `PARAMETER, PUBLIC :: ELEM_*`** | **192** 个（含 `ELEM_USER`） |
| **`PH_Elem_Reg_InitAll` 中 `CALL PH_Elem_Reg_Add`** | **191** 次 |
| **差值** | **`ELEM_USER = 0`** 不在 `InitAll` 中静态注册，供运行时用户单元 `PH_Elem_Reg_Add` 使用 → **与设计一致** |
| **`MD_Elem_PH_Brg`** | **无独立 elem 列表**；经 `UF_ElemType` / `ElemType%elem_type_id` 传递，须与 `ELEM_*` 及网格 `element_types` 一致 |
| **编译耦合** | `PH_Elem_Reg_Core` 的 `USE MD_Elem_Core, ONLY: ELEM_...` 与 `InitAll` 首参同步；若在 MD 增加新型号而未改 L4 注册，会出现 **编译失败或遗漏注册** |
| **可选 CI** | `python scripts/check_elem_reg_vs_md_core.py`：`MD_Elem_Core` 中除 `ELEM_USER` 外每个 `ELEM_*` 与 `PH_Elem_Reg_InitAll` 中 `PH_Elem_Reg_Add` 首参集合一致 |

模块头已补充：`MD_Elem_PH_Brg.f90` 内 **elem_type ID contract** 段落。

---

## 三、载荷边界链（第三）

### 3.1 层间锚点

| 层 | 角色 | 核心模块 |
|----|------|----------|
| **L3_MD** | 载荷与边界条件描述、解析、同步 | `L3_MD/Boundary/MD_LoadBC_Idx.f90`, `MD_LoadBC_DomainTypes.f90`, `MD_LoadBC_*`, `MD_LoadBC_Parse.f90`, `MD_LoadBC_Kinematic_Parse.f90` |
| **Bridge L3→L4** | Desc → PH 侧缓存（BC/Load） | `L3_MD/Bridge/Bridge_L4/MD_LoadBC_PH_Brg.f90` |
| **Bridge L3→L5** | 与 RT 步进/方程号/装配桥接 | `L3_MD/Bridge/Bridge_L5/MD_LoadBC_RT_Brg.f90` |
| **L4_PH** | 物理侧载荷模型（稳态、地应力等） | `L4_PH/LoadBC/PH_Ldbc_Core.f90`, `PH_LoadBC_Steady.f90`, `LoadBC/Geostatic/*`, `PH_Load_Types.f90`, `PH_BC_Types`（经 `MD_LoadBC_PH_Brg`） |
| **L5_RT** | 施加到整体方程、与步进一致 | `L5_RT/Physics/LoadBC/RT_Ldbc_Apply_Core.f90`, `RT_Ldbc_ConstApply.f90`, `RT_Ldbc_InitApply.f90`, `RT_Ldbc_Mgr.f90`, `Phys_LoadBC.f90`, `Physics/Assembly/RT_Asm_Ldbc_Apply.f90` |

### 3.2 Data chain 契约（LoadBC，P0 文档锚点）

| 字段 / 概念 | 典型来源 | 消费侧 | 说明 |
|-------------|----------|--------|------|
| `MD_BC` / `MD_Load` / step 索引 | `MD_LoadBC_Core`, `MD_LoadBC_Idx` | `MD_LoadBC_PH_Brg` | `BuildStepBCs` / `BuildStepLoads` |
| `PH_BC_Cache_Type` / `PH_Load_Cache_Type` | `MD_LoadBC_PH_Brg` | L4 `PH_*`、RT 施加 | 与振幅、时间曲线在 Brg 层组合 |
| 方程号 / DOF 类型 | `RT_DofMapUtils` | `MD_LoadBC_RT_Brg` | 与 `MD_Cont_RT_Brg` 共用 `UF_GetEqId` 族 |
| 固定 / 分布载荷 / 体载 | L3 解析结果 | `RT_Ldbc_*` + `RT_Asm_Ldbc_Apply` | 建议在 L3 枚举与 RT 施加阶段表做一页对照 |

### 3.3 建议动作

| 优先级 | 动作 |
|--------|------|
| P0 | 建立 **LoadBC 类型枚举 / 施加阶段**（step、increment）在 L3→L4→L5 的 **同名字段或映射表** — 见 [UFC_Ldbc_Layer_Map.md](../../07_设计文档/UFC_Ldbc_Layer_Map.md) |
| P0 | 在 **`MD_LoadBC_PH_Brg`** 模块头补充 **Data chain**（`MD_BC_Desc`/`MD_Load_Desc` → `PH_*_Cache_Type`）— **已写入**；`BuildStep*FromDomain` 振幅分支 **已修复**（完整 `IF/ELSE/END IF`） |
| P1 | 对 **`MD_LoadBC_Parse`** 等高 TODO 文件做 **TODO 清单**（区分解析完成度与占位） |
| P2 | **最小验证**：固定端 + 均布载荷一条静力算例贯穿三层 |

---

## 四、接触链（第四）

### 4.1 层间锚点

| 层 | 角色 | 核心模块 |
|----|------|----------|
| **L3_MD** | 接触对、交互定义 | `L3_MD/Interaction/MD_Cont_Core.f90`，及与接触配对的约束/面数据（见 `Interaction/`、`Constraint/` 相关类型） |
| **Bridge L3→L5** | L3 接触装配数据 → RT 三元组与方程映射 | `L3_MD/Bridge/Bridge_L5/MD_Cont_RT_Brg.f90`（`RT_Triplet_Add`、`RT_GetEqId`） |
| **L4_PH** | 接触本构/罚函数、间隙、摩擦等物理核 | `L4_PH/Contact/PH_Cont_Domain.f90`, `PH_Cont_Core.f90`, `PH_Cont_Ctx.f90`, `PH_Cont_API.f90`, `PH_Cont_Types.f90` |
| **L5_RT** | 接触求解调度、搜索、与装配耦合 | `L5_RT/Contact/RT_Contact_Domain_Core.f90`, `Physics/Assembly/RT_Asm_Solv.f90`（`RT_Asm_ApplyContact`）、`Physics/Contact/*`、`PH_Cont_*` API |

> **说明**：**`L3_MD/Bridge/Bridge_L4/MD_Cont_PH_Brg.f90`** 已提供 `MD_Cont_PH_FillParams_FromMD`（`MD_ContactProperty_Type` 或 `MD_ContactProperty` + `MD_ContactPairDef` → `PH_Contact_Params`），由 `RT_Asm_ApplyContact` 在装配阶段调用。

### 4.2 Data chain 契约（Contact，P0 文档锚点）

| 字段 / 概念 | 典型来源 | 消费侧 | 说明 |
|-------------|----------|--------|------|
| 接触对 master/slave 面、法向 | `MD_Cont_Core` | `RT_Cont_Search_Core` | 与网格拓扑、面集合 id 一致 |
| 罚刚度 `k_n`、摩擦系数 `mu` | L3 交互属性 | `PH_Cont_*` / `RT_Cont_Friction_Core` | **小滑移/有限滑移** 标志应在 L3 Desc 与 PH 实现中共用同一枚举或整型码 |
| `(row,col,val)` 三元组 | `MD_Cont_RT_Brg` | `RT_Asm_*` / 求解器 | 与总体 K、F 装配顺序一致 |
| 方程号 | `RT_GetEqId` | `MD_Cont_RT_Brg` | 与 LoadBC 链共用 DOF 映射 |
| CSR 接触回写 | `RT_Asm_ApplyContact` | `RT_CSRMatrix` | 默认按稀疏 **模式内** 覆盖；`RT_Asm_Cfg%contact_csr_delta_merge` 时用 `RT_CSR_AddToValue` 做模式内增量；模式外填项需 **triplet 合并 / 重分析** |
| 搜索 | `PH_Cont_SearchPairs_API` | `RT_Asm_ApplyContact`（可选） | `RT_Asm_Cfg%contact_try_ph_search` + 节点坐标/位移指针接线后启用 |

### 4.3 建议动作

| 优先级 | 动作 |
|--------|------|
| P0 | 明确 **小滑移 / 有限滑移**、**法向罚因子** 在 MD 描述与 PH 实现之间的 **字段契约** — 见 [UFC_Contact_Field_Contract.md](../../07_设计文档/UFC_Contact_Field_Contract.md) |
| P1 | **`RT_Contact_Domain_Core`** 与 **`PH_Cont_Domain`** 的 **调用序**（Runner → Init ctx → Asm）— **已在两模块头补充锚点**；后续随代码接线细化子程序名 |
| P2 | **验证**：赫兹接触或简化块-块算例 + 与参考解对比 |

---

## 五、横向检查（每条链做完都做）

- **语法**: `gfortran -std=f2003 -fsyntax-only`（或当前工程）对改动层编译通过。  
- **命名**: 新代码统一 **`PH_Brg_*` / `MD_*_Brg`**，避免再引入 `PH_Bridge_*`。  
- **可观测**: 材料/装配热路径预留计时或计数钩子（与 observability 规范一致，可选）。

---

## 六、相关文档

- [UFC_L3_L4_L5_FourChain_MasterPlan.md](UFC_L3_L4_L5_FourChain_MasterPlan.md) — **四条链总目标 × 四链 × 入口文件**  
- `Material_Constitutive_Unified_Design.md`（历史计划稿，当前工作区未收录）— 材料本构元数据与积分路线
- [PH_Mat_Phase4_Dispatch.md](../../10_材料专项/PH_Mat_Phase4_Dispatch.md) — Phase 4 调度与性能说明  
- [UFC_UMAT_Props_Statev_Layout.md](../../06_核心架构/UFC_UMAT_Props_Statev_Layout.md) — props/statev 布局；维护说明与 `scripts/check_mat_props_schema.py`
- [UFC_Ldbc_Layer_Map.md](../../07_设计文档/UFC_Ldbc_Layer_Map.md) — LoadBC 枚举与 L3→L5 施加阶段锚点
- [UFC_LoadBC_Enum_Mapping.md](../../07_设计文档/UFC_LoadBC_Enum_Mapping.md) — `MD_LoadBC_Core` vs `MD_LoadBC_DomainTypes` 载荷枚举对照
- `MD_LoadBC_Load_Parse_TODO.md`（历史 TODO，当前工作区未收录）— 载荷解析模块 TODO 清单
- [UFC_Contact_Field_Contract.md](../../07_设计文档/UFC_Contact_Field_Contract.md) — 接触契约 + `MD_Cont_PH_Brg`
- `载荷边界全面对齐.plan.md`、`UFC_LoadBC_Coverage_Matrix.md`（当前工作区未收录）— 载荷边界链历史规划与覆盖矩阵
- `接触全面对齐.plan.md`、`UFC_Contact_Coverage_Matrix.md`（当前工作区未收录）— 接触链历史规划与覆盖矩阵
- `UFC_Verification_Backlog.md`、`UFC_PatchTest_Procedure.md`（当前工作区未收录）— 验证 backlog 与 Patch test 步骤
- `tests/harness/README.md`（当前工作区未收录）— 验证 harness 与脚本
- 六层依赖图: `docs/diagrams/layer_dependency.mmd`

### 六.1 可选 CI 脚本（`ufc_core/scripts/`）

| 脚本 | 作用 |
|------|------|
| `check_mat_props_schema.py` | `PH_Mat_Reg_Add` 的 `props_schema` 分段数 vs `num_props`（跳过占位关键字） |
| `check_elem_reg_vs_md_core.py` | `MD_Elem_Core` 的 `ELEM_*`（除 `ELEM_USER`）与 `PH_Elem_Reg_InitAll` 一致 |
| `check_loadbc_ldbc_map.py` | `MD_LoadBC_Map.f90` 与 MD/DomainTypes 载荷枚举数值一致 |
