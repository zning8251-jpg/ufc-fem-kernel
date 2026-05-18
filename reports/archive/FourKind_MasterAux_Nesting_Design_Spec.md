# 四型主/辅 · 总分 · 并列/嵌套 — 设计规格书

**路径（冷归档全文）**：`UFC/REPORTS/archive/FourKind_MasterAux_Nesting_Design_Spec.md` · **入口 stub（外链锚点）**：`UFC/REPORTS/FourKind_MasterAux_Nesting_Design_Spec.md`
**性质**：基于八合订文档（Material/Element/Section/Contact/LoadBC/Output/WriteBack/OnePager）的**合规审查 + 统一设计规格**；不替代各域 `CONTRACT.md`，供跨域评审与命名统一时引用。
**报告 ID**：`REP-FOURKIND-SPEC`
**版本**：v1.0（2026-05-04）

---

## 1. 合规审查结论（四文档 vs 总纲 vs 命名规范 v2.0）— 状态闭环

| # | 差距 | 严重度 | 来源文档 | 修正建议 | 状态 (2026-05-05) |
|---|------|--------|---------|---------|-------------------|
| G1 | `Base` 后缀仅 Element/Section 有，Material 无 | 高 | Element/Section | 去 `Base`，见 §2.1 | 🔄 **Phase 4**：Element L3 从 Mesh 剥离时执行 |
| G2 | 截面域缩混用 `Sect` / `Section` | 高 | Section | 统一为 `Sect`，见 §2.2 | 🔄 **Phase 8**：Section 命名统一时执行 |
| G3 | `Mirror` 文档术语不直观 | 中 | Material/Element | 改为 `ABI_Flat`，见 §3 | ✅ **已定**：`L4_Gap_Domain_Decisions.md` §1.3 及 
各域合订本中采用 `ABI_Flat` 术语；代码 TYPE 名不变 |
| G4 | OnePager 缺 Contact/LoadBC/Constraint 填槽行 | 中 | OnePager | §6 补全 | ✅ **已补全**：`OnePager_FourKind_MasterAux_Nesting.md` §3.2–§3.4 已有 Contact/LoadBC/Analysis 填槽行 |
| G5 | 截面 L4 主挂载决策未写入合同 | 中 | Section §5 | 方案 B 写死，见 §5 | ✅ **已写入**：`L4_Gap_Domain_Decisions.md` §4（Section 方案 B
锁定）；剩余步骤见 Phase 8 |
| G6 | `PH_UEL_Def.f90` 仍为设计名，无实装 | 高 | Element | 见 §7 U1–U4 | ❌ **待实现**：代码库 `PH_UEL_Def.f90` 存在但为骨架/UEL-A 薄适配；需按 Element 合订本 §14.4/U0 完整实装 |
| G7 | Props 布局无机器可读表 | 中 | Material | 见 §7 Phase 4 | ❌ **待实现**：材料 `props` 布局（`nprops`/`nstatv` 等）尚未生成机器可读的 JSON/CSV 表 |
| G8 | L4 Element State 过轻，RHS/AMATRX 落位未定 | 低 | Element | 合同闭环后再填 | 🔄 **待合同闭环**：`L4_PH/Element/CONTRACT.md` 已标记 U0，Phase 4 合并时同步填写 |
| G9 | 截面 L3 有 `MD_SectDesc` 与 `MD_Sect_Desc` 两套 | 高 | Section | 合并，见 §2.3 | ✅ **代码中已合并**：当前 `MD_Sect_Def.f90` 仅保留 `MD_Sect_Desc`（有 TBP），`MD_SectDesc`/`MD_Sect_Desc` 已移除或标记为 `! DEPRECATED` |
| G10 | R-08 截面横切规则未在合同闭环 | 中 | OnePager | 合同 bump 时标注 | 🔄 **Phase 8**：Section L4 主挂载锁定 + 命名统一时写入合同 |

**状态图例**：✅ = 已闭合 / 🔄 = 实施中（已分配阶段） / ❌ = 待实施（未分配阶段或等待依赖）

### 1.1 验收标准引用

| 硬规则 | 验收条件 | 对应阶段 |
|--------|---------|---------|
| **R-09（去 `Base`）** | L3/L4 基类 Desc/State/Algo/Ctx 不带 `Base` 后缀 | Phase 4（Element 主战场）+ 全域扫尾 |
| **R-10（域缩统一）** | Section→`Sect`、Contact→`Cont`、Constraint→`Constr`、LoadBC→`LoadBC` | Phase 2（Contact）+ Phase 8（Section）+ 全域扫尾 |
| **R-11（截面单类型）** | L3 截面域只保留一套基类 Desc（`MD_Sect_Desc`） | ✅ 代码已合并；文档确认见 Phase 8 |

---

## 2. 命名统一

### 2.1 去 `Base` 后缀 — 与材料域对齐

**原则**：`{层}_{域缩}_{四型}` 为基类命名；族扩展加族缩。`Base` 不出现在命名公式中。

| 域 | 现名 | → 目标名 | 族扩展示例 |
|----|------|----------|-----------|
| 材料 | `MD_Mat_Desc` ✅ | — | `MD_Mat_Elas_Desc` |
| 单元 | `MD_Elem_Desc` ❌ | **`MD_Elem_Desc`** | `MD_Elem_Solid3D_Desc` |
| 单元 | `MD_Elem_Algo` ❌ | **`MD_Elem_Algo`** | — |
| 截面 | `MD_Sect_Desc` ❌ | **`MD_Sect_Desc`** | — |

**L4 侧同步**：

| 现名 | → 目标名 | 说明 |
|------|----------|------|
| `PH_Elem_Desc` | **`PH_Elem_Desc`** | 已在 PH_Elem_Def.f90 完成 |
| `PH_Elem_State` | **`PH_Elem_State`** | 已完成 |
| `PH_Elem_Ctx` | **`PH_Elem_Ctx`** | 已完成 |
| `PH_Elem_Algo` | **`PH_Elem_Algo`** | 已完成 |

**L3 迁移影响**：

- `MD_Elem_Desc`：7+ 文件引用（Spring/Sld3D/Sld2D/Shell/Mass/Truss/Surface）
- `MD_Sect_Desc`：3+ 文件引用，含 TBP（CONTAINS）

**迁移策略**：L3 保留旧名作为 `! DEPRECATED` 别名过渡，新代码一律使用无 `Base` 名。

### 2.2 截面域缩统一为 `Sect`

**总纲域缩表**（命名规范 v2.0 §2.2）规定：Section → `Sect`。

| 现名 | → 目标名 | 类型 |
|------|----------|------|
| `MD_Section_Domain` | **`MD_Sect_Domain`** | TYPE/模块 |
| `MD_Section_Catalog_Desc` | **`MD_Sect_Catalog_Desc`** | TYPE |
| `MD_Section_State` | **`MD_Sect_State`** | TYPE |
| `MD_Section_Ctx` | **`MD_Sect_Ctx`** | TYPE |
| `MD_SectDesc` | **`MD_Sect_Desc`** | TYPE（加下划线） |
| `SectionAlgo` | **`MD_Sect_Algo`**（L3） | TYPE（加层缀+域缩） |

### 2.3 截面 L3 双类型合并

**现状**：仓库中同时存在：

- `MD_SectDesc`（平面存储，无 TBP）— `MD_Sect_Def.f90`
- `MD_Sect_Desc`（有 TBP：InitBasic/Validate/AssociateMat/Nullify）— `MD_Sect_Def.f90`

**目标**：合并为单一 **`MD_Sect_Desc`**（有 TBP，作为 L3 唯一截面基类 Desc）。

**合并步骤**：
1. 将 `MD_SectDesc` 的平面字段吸收进 `MD_Sect_Desc` 的字段集
2. 保留 TBP（InitBasic/Validate/AssociateMat/Nullify）
3. 重命名为 `MD_Sect_Desc`
4. 旧名 `MD_SectDesc` / `MD_Sect_Desc` 标记 `! DEPRECATED`

---

## 3. Mirror → ABI_Flat 术语统一

### 3.1 问题根源

四型之一名为 **`Ctx`**（如 `PH_Mat_Ctx`、`PH_Elem_Ctx`）。
UMAT/UEL 的扁参工作区也以 **`Context`** 结尾（`PH_UMAT_Context`、`PH_UEL_Context`）。
口语说「Context」时无法区分二者。

### 3.2 Mirror 含义与替代

| 文档术语 | 语义 | 问题 |
|---------|------|------|
| Mirror（镜像） | "照着 Abaqus 参数表抄一遍" | 隐喻不够直白 |
| Frame（调用帧） | "函数调用一次的数据快照" | 偏编译原理，工程人员不熟悉 |
| **ABI_Flat（ABI 扁参包）** | "对齐外部 ABI 的扁平参数打包" | 直白、无歧义 |

**推荐**：文档/评审中统一使用 **ABI_Flat** 替代 Mirror。

| 对象 | 代码 TYPE（不改） | 文档名（改） |
|------|-------------------|-------------|
| UMAT 扁参工作区 | `PH_UMAT_Context` | **`PH_UMAT_Context`（ABI_Flat）** |
| UEL 扁参工作区 | `PH_UEL_Context` | **`PH_UEL_Context`（ABI_Flat）** |
| 四型之一 Ctx | `PH_Mat_Ctx` / `PH_Elem_Ctx` | 保留 `Ctx` |

### 3.3 三轨并列图

```
四型轨（域内真源）          ABI_Flat轨（外部ABI对齐）      Arg轨（层间边界束）
─────────────          ─────────────────         ──────────────────
Desc ← Populate ──┐    PH_UMAT_Context(ABI_Flat)   PH_Mat_Update_Arg
Ctx  ← 步内写入 ──┼──→ PH_UEL_Context(ABI_Flat)   PH_Element_Compute_*_Arg
State ← 热路径 ───┘    仅调用期视图                 MD_Sect_Add_Arg
Algo ← 控制
```

---

## 4. 主/辅四型并列·嵌套·总分 — 统一规格

### 4.1 并列（硬规则 R-01）

Slot 内四主型并列，**不设第五根主柱**：

```
TYPE :: {Layer}_{Domain}_Slot
  TYPE({Layer}_{Domain}_Desc)  :: desc
  TYPE({Layer}_{Domain}_Ctx)   :: ctx
  TYPE({Layer}_{Domain}_State) :: state
  TYPE({Layer}_{Domain}_Algo)  :: algo
  LOGICAL :: active = .FALSE.
END TYPE
```

### 4.2 嵌套（辅TYPE，Depth≤2 cap）

**辅TYPE命名公式**：`{Layer}_{Domain}_{Phase}_{Verb}_{FourKind}`

| Phase | Verb | 含义 | 材料示例 | 单元示例 |
|-------|------|------|---------|---------|
| Cfg | Init | 配置初始化 | `PH_Mat_Cfg_Init_Desc` | `PH_Elem_Cfg_Init_Desc` |
| Pop | Vld | Populate 校验 | `PH_Mat_Pop_Vld_Desc` | `PH_Elem_Pop_Vld_Desc` |
| Inc | Evo | 增量演化 | `PH_Mat_Inc_Evo_Ctx` | `PH_Elem_Inc_Evo_Ctx` |
| Itr | Asm | 迭代组装 | — | `PH_Elem_Itr_Asm_Ctx` |
| Lcl | Comp | 局部计算 | `PH_Mat_Lcl_Comp_Ctx` | `PH_Elem_Lcl_Comp_Ctx` |
| Lcl | Evo | 局部演化 | `PH_Mat_Lcl_Evo_State` | `PH_Elem_Lcl_Evo_Ctx` |
| Stp | Ctl | 步控制 | `PH_Mat_Stp_Ctl_Algo` | `PH_Elem_Stp_Ctl_Algo` |

### 4.3 总分三模式

| 模式 | 方法 | 适用场景 | 深度 |
|------|------|---------|------|
| A | `ASSOCIATE(s=>slot_pool(idx))` | 冷路径 Populate（同槽写≥5处） | 4→2 |
| B | S1 FetchState 局部拷贝+末步写回 | 热路径 Execute（读→算→写回） | 4→1 |
| C | Accessor API（`PH_Mat_GetCtx_Idx`） | 域外消费（单元/L5） | 4→2 |

### 4.4 三域四型字段对照

| 主型 | 辅型 | 材料 `PH_Mat_*` | 单元 `PH_Elem_*` | 截面 `MD_Sect_*` |
|------|------|-----------------|------------------|------------------|
| Desc | cfg | Cfg_Init_Desc: matId, matModel | Cfg_Init_Desc: elem_type_id, family_id, ndim | — |
| | pop | Pop_Vld_Desc: mat_model_id | Pop_Vld_Desc: n_nodes, n_dof, n_integration | — |
| | props | props(:) 线性参数 | — | thickness, offset, mat_id |
| Ctx | inc | Inc_Evo_Ctx: step_idx, incr_idx, dt | Inc_Evo_Ctx: step_idx, incr_idx | current_section_idx |
| | lcl | Lcl_Comp_Ctx: temperature, strain_rate, dstrain(6) | Itr_Asm_Ctx: current_ip, det_J, weight | — |
| | — | — | Lcl_Comp_Ctx: u_elem, du_elem, dN_dX, J_mat | — |
| | — | — | Lcl_Evo_Ctx: Ke, Ke_geo, R_int | — |
| State | comp | Lcl_Comp_State: stress(:), C_tan(:,:) | 轻量标志: initialized, stiffness_built | active_sections |
| | evo | Lcl_Evo_State: stateVars(:), stateVars_n(:) | — | — |
| Algo | stp | Stp_Ctl_Algo: tol_yield, max_iter | Stp_Ctl_Algo: integration_order, hourglass, nlgeom | 默认积分规则 |
| | dyn | — | Stp_Ctl_Dyn_Algo: reduced_integ, mass_type, rayleigh | — |
| | ptr | constitutive 过程指针 | integrator 过程指针 | — |

---

## 5. 截面 L4 主挂载决策闭合

**现状**：Section §5 列出方案 A（独立 `PH_Sect_*`）与方案 B（嵌入 `PH_Elem_*`），标注"现阶段推荐 B"但未写入合同。

**闭合结论**：

| 决策项 | 结论 | 合同落位点 |
|--------|------|-----------|
| 截面 L4 主挂载 | **方案 B：嵌入 `PH_Elem_*`** | `L4_PH/Element/CONTRACT.md` §M-S-E |
| 截面冷真源 | **L3 `MD_Sect_Desc`（合并后）唯一 SSOT** | `L3_MD/Section/CONTRACT.md` §2 |
| 截面 Populate 消费 | 经 `PH_L4_Populate_Element` 灌入单元缓存 | Element CONTRACT Populate 列 |
| 截面热路径 | **只读** Populate 派生量（厚度/取向/ntens） | R-05/R-08 执行 |
| 方案 A 触发条件 | 跨单元型大量重复截面中间结果时开 Phase | 合同附录备注 |

---

## 6. OnePager 填槽扩展 — Contact/LoadBC/Constraint

### 6.1 Contact 填槽行

| 填槽项 | Contact（接触） |
|--------|----------------|
| 总枢纽 TYPE / 容器 | **`PH_Contact_Domain`**；`ufc_core/L4_PH/Contact/CONTRACT.md` |
| desc 主 + 典型辅 | **`PH_Cont_Desc`** + 辅（接触类型、摩擦系数、法向刚度等）；L3 **`MD_Cont_Desc`** |
| ctx 主 + 典型辅 | **`PH_Cont_Ctx`** + 辅（当前从面节点、间隙、滑移增量等） |
| state 主 + 典型辅 | **`PH_Cont_State`** + 辅（接触力、接触状态标志、磨损量等） |
| algo 主 + 典型辅 | **`PH_Cont_Algo`** + 辅（`PH_Cont_Stp_Ctl_Algo`：惩罚/增广Lagrange/单纯法等） |
| ABI_Flat | 无（无 UMAT/UEL 级 ABI_Flat） |
| 代表 *_Arg | **`PH_Cont_Detect_Arg`**、**`PH_Cont_Enforce_Arg`** |
| Populate 主入口 | **`PH_L4_Populate_Contact`** |
| Dispatch / Execute | **`RT_Cont_Dispatch`** + **`PH_Contact_Execute`** |
| 步内主写入面 | 接触力/接触状态写 `PH_Cont_State` |
| 联合键 / 交界 | `contact_id`、`master_surface_id`、`slave_surface_id` |
| 本域特异禁止 | L5 无接触力/刚度主源；L4 无双套 `PH_Cont_*` 与 `MD_Interaction_*` 并列真源 |

### 6.2 LoadBC 填槽行

| 填槽项 | LoadBC（载荷/边界条件） |
|--------|------------------------|
| 总枢纽 TYPE / 容器 | **`PH_LoadBC_Domain`**；`ufc_core/L4_PH/LoadBC/CONTRACT.md` |
| desc 主 + 典型辅 | **`PH_Ldbc_Desc`** + 辅（BC类型、DOF、幅值引用等）；L3 **`MD_Ldbc_Desc`** |
| ctx 主 + 典型辅 | **`PH_Ldbc_Ctx`** + 辅（当前时间/增量、幅值插值结果等） |
| state 主 + 典型辅 | **`PH_Ldbc_State`**（施加载荷向量、约束反应力等） |
| algo 主 + 典型辅 | **`PH_Ldbc_Algo`** + 辅（施加方法：直接/惩罚/增广等） |
| ABI_Flat | 无 |
| 代表 *_Arg | **`PH_Ldbc_Apply_Arg`** |
| Populate 主入口 | **`PH_L4_Populate_LoadBC`** |
| Dispatch / Execute | **`RT_Ldbc_Apply`** |
| 步内主写入面 | 载荷/BC 施加结果写 `PH_Ldbc_State` |
| 联合键 / 交界 | `bc_id`、`node_set_id` / `elem_set_id`、`amplitude_id` |
| 本域特异禁止 | L3 `MD_Boundary_*` 与 L4 `PH_LoadBC_*` 不得并列为双主源 |

### 6.3 Constraint 填槽行

| 填槽项 | Constraint（约束） |
|--------|-------------------|
| 总枢纽 TYPE / 容器 | **`PH_Constr_Domain`**；`ufc_core/L4_PH/Constraint/CONTRACT.md` |
| desc 主 + 典型辅 | **`PH_Constr_Desc`**（MPC类型、约束方程等）；L3 **`MD_Constr_Desc`** |
| ctx 主 + 典型辅 | **`PH_Constr_Ctx`**（当前约束雅可比等） |
| state 主 + 典型辅 | **`PH_Constr_State`**（Lagrange乘子、约束力、违反度等） |
| algo 主 + 典型辅 | **`PH_Constr_Algo`**（容差、权重、施加方法等） |
| ABI_Flat | 无 |
| 代表 *_Arg | **`PH_Constr_Enforce_Arg`** |
| Populate 主入口 | **`PH_L4_Populate_Constraint`** |
| Dispatch / Execute | **`RT_Constr_Enforce`** |
| 步内主写入面 | 约束力/乘子写 `PH_Constr_State` |
| 联合键 / 交界 | `constraint_id`、`dependent_node_id`、`reference_node_ids` |
| 本域特异禁止 | L3 `MD_Constraint_*` 与 L4 `PH_Constr_*` 不得并列为双主源 |

---

## 7. 分阶段补全路线

| 阶段 | 交付 | 优先级 | 依赖 |
|------|------|--------|------|
| P0 | 本规格书落盘 + 合规审查闭合 | 必须 | — |
| P1 | L3 去 `Base` + 截面域缩统一 + 双类型合并 | 高 | P0 |
| P2 | 截面 L4 主挂载方案 B 写入 Element CONTRACT | 高 | P0 |
| P3 | `PH_UEL_Def.f90` 实装（U1–U4，见 Element 合订 §14.4） | 高 | P2 |
| P4 | Props 布局合同机器可读表（JSON/CSV） | 中 | P0 |
| P5 | Contact/LoadBC/Constraint OnePager 填槽 + 域合同 | 中 | P0 |
| P6 | ABI_Flat 术语统一（更新 Material/Element 合订本附录 G.0/C.0） | 中 | P0 |
| P7 | L5 族级 Stub 按需填充 | 低 | P3 |

---

## 8. 硬规则汇总（评审一票否决项）

| ID | 规则 | 来源 |
|----|------|------|
| R-01 | 主四型只认一套顶层 `desc/ctx/state/algo` 并列；**禁止**辅块升格为第五顶层 | OnePager |
| R-02 | 辅只嵌套；新语义优先落入已有主柱下辅 TYPE | OnePager |
| R-03 | 热边界优先 `枢纽+索引`；禁止 L4/L5 长期展开 30+ 扁参列表 | OnePager |
| R-04 | ABI_Flat ≠ 四型 Ctx；口语须区分 | 本规格书 §3 |
| R-05 | L5 不持步内大数组主源 | OnePager |
| R-06 | 禁止双主源 | OnePager |
| R-07 | SIO：跨边界用 `*_Arg`；避免薄 Arg | OnePager |
| R-08 | 截面主挂载二选一写死于合同 | OnePager + 本规格书 §5 |
| R-09 | **去 `Base`**：L3/L4 基类 Desc/State/Algo/Ctx 不带 `Base` 后缀 | 本规格书 §2.1 |
| R-10 | **域缩统一**：Section→`Sect`、Contact→`Cont`、Constraint→`Constr`、LoadBC→`LoadBC` | 命名规范 v2.0 |
| R-11 | **截面单类型**：L3 截面域只保留一套基类 Desc（合并 `MD_SectDesc` + `MD_Sect_Desc` → `MD_Sect_Desc`） | 本规格书 §2.3 |
| R-12 | **Algo TYPE 双重语义**：`Algo` 除结构化四型槽外，**也是过程/算法的策略容器**（步控参数、Procedure Pointer、算法选择枚举）；跨域评审应同时对照四型合订（§3.5）和 `*_Procedure_Algorithm.md`（§2 Algo TYPE） | 本规格书 + `Procedure_Algorithm_L3L4L5_synthesis.md` §A、§E |
| R-13 | **Procedure Pointer 显式声明**：预计通过 `PROCEDURE()` PTR 实现算法可替换的域，须在 `*_Procedure_Algorithm.md` §3 定义抽象接口+具体绑定。**不强制**已声明「枚举驱动」的域（Section/Analysis/LoadBC/Output/WriteBack）改用 PTR | `Abaqus_UserSubroutine_UFC_Map.md` §5 对偶表 + `*_Procedure_Algorithm.md` §3 |

---

*冷归档全文：`UFC/REPORTS/archive/FourKind_MasterAux_Nesting_Design_Spec.md`。入口 stub：`UFC/REPORTS/FourKind_MasterAux_Nesting_Design_Spec.md`。对齐文档（根 stub）：`Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`、`Element_L3L4L5_four_type_UEL_discussion_synthesis.md`、`Section_L3L4L5_four_type_synthesis.md`、`Contact_L3L4L5_four_type_synthesis.md`、`LoadBC_L3L4L5_four_type_synthesis.md`、`Output_L3L4L5_four_type_synthesis.md`、`WriteBack_L3L4L5_four_type_synthesis.md`、`Analysis_L3L4L5_four_type_synthesis.md`、`OnePager_FourKind_MasterAux_Nesting.md`。**Procedure/Algorithm**：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）+ 八份域级 `*_Procedure_Algorithm.md`（**均为根 stub**，长文 `archive/` 同名）、`Abaqus_UserSubroutine_UFC_Map.md`。Registry 对账见 `docs/03_Domain_Pillars/DomainProcedureRegistry/README.md`。*

