# W1（P1 Material）— MR 分批说明

> **权威子清单**：[`L3_L4_L5_pilot_f90任务清单_W1.md`](L3_L4_L5_pilot_f90任务清单_W1.md)（**Txxxx** 与总清单一致）。  
> **顺序**：**Def / Core（类型与注册）→ Bridge（L3 材料桥 + L5 `RT_Brg_Def` 材料段）→ 热路径（Dispatch / 本构核）**。  
> **禁止**：按总清单 **T0001** 字母序跨桶混改；单次 MR **不要**夹带 `RT_Asm_*` 等装配大块（见 [全域铺开执行计划](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md) §4.1 / §4.2）。

---

## 1. 每 MR 固定内功（Step1→4 摘要）

对齐 [pilot](ufc-layer-l3-l4-l5-pilot.md) §七与 [全域铺开执行计划](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md) §7：

| Step | 本批关注点 |
|------|------------|
| Step1 | 辅 TYPE + 主 TYPE 嵌套；F2003；深度 ≤3；L5 Bridge 辅 TYPE **无 ALLOCATABLE** |
| Step2 | Init / Populate / Bridge 读写 **嵌套成员**；DEPRECATED 扁平字段 **双写或同步例程** |
| Step3 | 热路径优先读 **辅 TYPE**；对外 API **不因嵌套而膨胀**（pilot §10.4） |
| Step4 | 触及域更新三层 [`Material/CONTRACT.md`](../../../../ufc_core/L3_MD/Material/CONTRACT.md) 等；删 DEPRECATED 仅出过窗口项 |

---

## 2. Populate + 本构竖切（验收闸）

**含义**：在 **L3 Desc → Populate → L4 slot → 本构求值（线弹性 + J2 为代表）** 上保持行为稳定；合并前至少满足其一：

1. **团队 CI / 工程构建**：隐式步 + 线弹性 / J2 相关目标通过（与 pilot **§9 Material**、执行计划 **§4.1 DoD** 一致）。  
2. **本地**：无 CI 时，以当前仓库约定的 **全量或增量编译** + 既有 regression / harness 为准；**禁止**仅改 Def、不编译热路径就合入大的 Dispatch 变更。

> **说明**：`PH_L4_Populate.f90` 本体在 **866 总清单**中不一定落入 W1 路径前缀；但 W1 **DoD** 仍要求 **Populate 材料段**与 **本构竖切**协同可验证。改 L3/L4 Material 栈时，应在 PR 描述中写明所触达的 Populate / slot / `PH_Mat_*` 路径。

### W1 竖切闭环快照（真源对齐）

下列条目与当前仓库 **已实现路径**一致，可作评审 **DoD** 对照；**不等价**于子清单 **全部 Txxxx** 勾选完毕。

| 链路段 | 真源 / 约定 |
|--------|-------------|
| L3 `MD_Mat_Desc` | **`cfg%*`** 为 SSOT；**`MD_Mat_Desc_SyncDeprecatedFlat`** → DEPRECATED 扁平 |
| Populate（`PH_L4_Populate_Material`） | 写 **`desc%cfg%matId`** / **`cfg%matModel`** → **`PH_Mat_Desc_SyncDeprecatedFlat`**；材料数组 **`desc%props`** |
| L4 槽只读 | **`desc%props`**（非误用的 **`ctx%props`**）；族 **`PH_MAT_*`** 用 **`PH_Mat_Desc_Effective_Model`** |
| L5 路由表 | **`RT_Mat_Brg_BuildTable_FromMaterial`**：**`PH_Mat_Domain`** + **`desc`** + **`PH_Mat_Desc_Effective_Model`** |
| L5 装配 | **`RT_Asm_Solv`**：**`slot_pool%desc%props`** |
| Element 共享 | **`PH_Elem_MaterialRoute`**：全槽拷贝 + **`PH_Mat_Desc_Effective_Model`** |
| L3 Populate 校验 | **`MD_Mat_ValidatePropsForPopulate`**：**`eff_class` / `eff_id`**（cfg→扁平回退） |
| LEGACY Dispatch | **`PH_MatEval` / `PH_MatPLMEval` / `PH_MatPLM_PlastCall`**：**`PlastModels_Desc`/UMAT** 路径保留；金线编排仍为 **`PH_Mat_Core`** + slot **`desc`** |

---

## 3. 推荐 MR 划分（依依赖：Def → Core → Bridge → 热路径）

下列 **Txxxx** 均出自 [`L3_L4_L5_pilot_f90任务清单_W1.md`](L3_L4_L5_pilot_f90任务清单_W1.md)；合并后请在子清单或总清单对应行打勾。

### MR-W1-01 — L3：Desc / Base / Domain / Registry（冷路径真源）

**目标**：先把 **类型真源、注册、状态初始化** 与 `MD_Mat_Desc` 嵌套语义对齐，再动家族模块。

| Txxxx | 路径 |
|-------|------|
| T0132 | `L3_MD/Material/Contract/MD_Mat_Def.f90` |
| T0133 | `L3_MD/Material/Contract/MD_Mat_Ids.f90` |
| T0107 | `L3_MD/Material/Base/MD_Mat_BaseDef.f90` |
| T0108 | `L3_MD/Material/Base/MD_Mat_Reg.f90` |
| T0109 | ~~`L3_MD/Material/Base/MD_Mat_StateInit.f90`~~ **已删除**（与 `MD_Mat_Reg.f90` 重复，无引用） |
| T0176 | `L3_MD/Material/Domain/MD_MatDomain_Def.f90` |
| T0177 | `L3_MD/Material/Domain/MD_Mat_Mgr.f90` |

**已落地（MR-W1-01 首批代码）**：`MD_Mat_Desc_SyncDeprecatedFlat`（`MD_Mat_Def.f90`）统一 **嵌套 cfg/pop → DEPRECATED 扁平**；`MD_Mat_Desc_Init`、`Convert_Legacy_To_MatDesc`、`Register_Material`、`Get_Material_Desc`（无效分支）已接线。**Base / Registry + L3↔L4 合同（W1 文档）**：`MD_Mat_BaseDef`、`MD_Mat_Reg` — 轻量 **`MD_Mat_Desc`** / 全局库与 **`Contract/MD_Mat_Def`** 富 **`MD_Mat_Desc`**、**Populate**→**`desc%props`** 分工。（**注**：原 **`MD_Mat_StateInit.f90`** 与 **`MD_Mat_Reg.f90`** 同源重复且无任何 `USE`，试点竖切已移除该孤立编译单元。）**`MD_Mat_Contract`** — **`MD_L3_to_L4_Contract`** 辅助校验；参数真源仍以 **`MD_Mat_Desc`** / **`PH_Mat_Desc`** 合同为准。**Domain（W1 文档）**：`MD_MatDomain_Def`、`MD_Mat_Mgr` — **`MD_Mat_Domain`** 持有 **`MD_Mat_Desc`**；**`SyncDeprecatedFlat`** / **Idx 访问** 与 **Populate→L4 `PH_Mat_Desc`** / **`desc%props`** 冷路径一致。

**可选同 MR（若变更面仍可控）**：其余 `L3_MD/Material/Contract/*_Def.f90`（T0125–T0131）中 **与本 MR 类型字段直接相关** 的子集。

### MR-W1-02 — L3：Shared Populate 映射 + 大型 Contract 分包

**已落地（首批）**：`MD_MatELA_PopulateMap.f90` — 头注释标明 **`pop%nProps` 真源在 Register/Populate**，本模块仅 **原地重排 / pad `props`**。**`MD_Mat_Lib.f90`** — **`MD_Mat_ValidatePropsForPopulate`** / **`MD_Mat_ValidatePlasticPropsForPopulate`**：**归类与模型 ID** 读 **`cfg`**，未置位时回退 **DEPRECATED 扁平 `class_id` / `id`**（与 `MD_Mat_Desc_SyncDeprecatedFlat` 对偶）。**`UF_Mat_Eval_Dispatch_FromDesc`**：按族 **band 默认** 解析 **`material_id`** 后委托 **`UF_Mat_Eval_Dispatch`**；**`UF_Elastic_Eval_Dispatch_FromDesc`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** 再导出。**`MD_MAT_USER_CORE`**：**USE** **`UF_Mat_Eval_Dispatch_FromDesc`**；**UF_UMAT_Standard** 注释指明 **`MD_Mat_Desc`** 路径优先 **FromDesc**。**弹性 Shared + Plast 门面（W1 文档）**：`MD_MatELA_ElasBase`、`MD_MatELA_Damping`、`MD_MatELA_Expansion` — **Desc/注册子块** 与 **`UF_Elastic_Eval_Dispatch_FromDesc`**、**Populate `props`** 协同。**`MD_MatPLM_PlastBase`** — **`PlastModels_Desc`** / **`UF_Plastic_*Reg`** 再导出；热路径塑性子求值见 **`MD_MatPLM_PlastCall`** / **`UF_Plastic_Eval_Dispatch_FromDesc`**。**Acoustic（W1 文档）**：`MD_Aco_Linear`、`MD_Aco_Absorb`、`MD_Mat_Acous_{Def,Core,Brg}`、`MD_Mat_AcousticProps`、`MD_Mat_Creep_Acoustic` — **`props`** / **`MD_Mat_Acous_Desc`** / **`Acoustic_MatDesc`** 与 L4 **`PH_Mat_Acoustic_Core`** / 槽 **`desc%props`**。**Composite（W1 文档）**：`MD_Cmp_{CLT,Fabric,FoamVE,Hashin,Jointed}`、`MD_Mat_Comp_{Brg,Core,Def}`、**`MD_Mat_Composite_*`**（层合/织物/纤维损伤/界面/分层等 **mat_id**）— **`MD_Mat_Desc`/`MD_Mat_Base_Desc` 叶** + **Populate**→L4 **`PH_Mat_Composite_Core`** / **`desc%props`**。**Contract 分包（W1 文档 · 头注释）**：`MD_Mat_Def`、`MD_Mat_Ids`、`MD_MatDMG_Def`、`MD_MatELA_CoupledDesc`、`MD_MatHYP_Def`、`MD_MatPLM_DescBase`、`MD_MatPlgGeotech_Def`、`MD_MatSPU_Def`、`MD_MatVSC_Def` — **`MD_Mat_Desc`** / **`mat_id` SSOT** / **InitFromProps·`props`** → **Populate** → **L4 `desc%props`**。**Creep / 多物理（W1 文档）**：`MD_Crp_*`、`MD_Mat_Creep_{Def,Core,Brg}`、`MD_MatPOR_*`、`MD_MatPorFoam_Def`、`MD_Mat_Creep_{BiotPoroElastic,Diffusion,PiezoElastic,Piezoelectric,PoreFlow}` — **`props`**、**`MD_Mat_Desc`**、**Populate**→L4 **`PH_Mat_Creep_Core`** / **`desc%props`**；**mat_id** 以 **`MD_Mat_Ids`** 与模块 **PARAMETER** 对表。**Damage（W1 文档）**：`MD_Dmg_*`、`MD_Mat_Damage_{Def,Core,Brg}`、`MD_Mat_Damage_*`（**MD_Mat_Desc** 子类）— **`props`**、**Populate**→L4 **损伤核** / **`desc%props`**；**mat_id** 见各文件头或 **`MD_MAT_ID_*`** 常量。**Elas / Geo（W1 文档）**：**Elas** — `MD_Ela_Aniso`/`Iso`/`Ortho`、`MD_Mat_Elas_*` — **`props`** / **Populate** / **`desc%props`**，**mat_id 101–106**；**Geo（塑性叶）** — `MD_Geo_DruckerPrager`、`MD_Geo_MohrCoulomb`、`MD_MatPLG_*` — **Populate**→L4 **`PH_MatGeo_*`** / **`desc%props`**（**201–222、301、303、701** 等对表）。**Geo（族级几何 Def/Core/Brg）** — `MD_Mat_Geo_{Def,Core,Brg}` — **`MD_Mat_Geo_Desc`** / **`geo_type`** / **`model_id` 路由**，与上列塑性叶分流。**HyperElas（W1 文档）**：**MD_Hyp_*（401–410）**、**MD_Mat_HyperElas_*（301–310，MD_MAT_ID_* 对表）**、**MD_Mat_HyperElas_{Def,Core,Brg}** — **Populate** / **desc%props** / **L4 PH_MatHYP_***。**Plast（W1 文档）**：**MD_Pls_*（叶描述符，约 **201–211**）**、**MD_Mat_Plast_***（**MD_Mat_Desc** / **cfg%id** / **PARAMETER**）、**MD_Mat_Plast_{Def,Core,Brg}** — **Populate** / **desc%props** / **UF_Plastic_Eval_Dispatch_FromDesc** / **L4 PH_MatPlast_***。**Registry / Shared·CORE（W1 文档）**：**MD_MatPLM_Reg/MD_MatReg_Ops** — **冷路径注册·mat_id→UMAT**；**MD_MAT_*_CORE**（**Damage/Hyper/Therm/Viscosity**）、**MD_Mat_{Composite,Creep,Geomat}_Core** — **族级共享注册/分发**；**MD_MatEval_Def** — **MatEval_Ctx**；**MD_MatPLM_TDep** — **温度依赖塑性参数**；**MD_Mat_DMG_LibBase**、**MD_Mat_{Legacy_Def,Sync,Validation}** — **损伤基元 / 遗留 State / legacy 同步 / Populate 校验**。统一真源 **MD_Mat_Desc** / **props** / **desc%props**。**Thermal（W1 文档）**：**MD_Mat_Creep_***（**601–603**/**108**/**110** 等多物理热）；**MD_Mat_Therm_{Def,Core,Brg}** — **MD_Mat_Therm_Desc**；**MD_Thm_***（**901–903**）— **Populate** / **desc%props** / **L4 热学槽**。**User / Viscoelas（W1 文档）**：**MD_MatSPU_*（702–707）**、**MD_Mat_User_*/MD_Usr_*（708·1101–1104）** — **MD_Mat_Desc** / **Populate** / **desc%props** / **MD_MAT_USER_CORE**；**MD_Mat_Visco_{Def,Core,Brg}** + **MD_Vis_*（501–504）** + **MD_Mat_Viscoelas_*（107·401–408）** — **粘弹族金线** → **L4 PH_Mat_Visco_*/PH_Mat_VSC_***。
| Txxxx | 路径 |
|-------|------|
| T0277 | `L3_MD/Material/Shared/MD_MatELA_PopulateMap.f90` |
| T0175 | `L3_MD/Material/Dispatch/MD_Mat_Lib.f90`（体量大，可再拆 **MR-W1-02a/02b** 仅改与竖切相关的分发入口） |

其余 **家族 Desc**（Acoustic/Composite/Creep/…）建议按 **家族目录** 拆后续 MR（仍优先 **Elas / Plast** 与 pilot 竖切相关族）。

### MR-W1-03 — L3：材料侧 Bridge

**已落地（首批）**：`MD_MatLibPH_Brg.f90` — `MD_PH_GetMaterialType_FromDesc` / `MD_PH_RouteToConstitutive_Idx` 增加 **DEPRECATED 扁平回退**（与 `MD_Mat_Desc_SyncDeprecatedFlat` 对偶）； Idx 路径 **`pop%nProps` / `nProps` 双轨** 拷贝 `props`。**数据链注释**已改为 **`PH_Mat_Domain` / `desc%cfg%matModel` + `desc%props`**（与 Populate 真源一致）。**`MD_Mat_Brg.f90`** — 头注释 **W1 / `cfg%*` 真源 / `MD_Mat_Desc_SyncDeprecatedFlat`**。

| Txxxx | 路径 |
|-------|------|
| T0038 | `L3_MD/Bridge/Bridge_L4/MD_MatLibPH_Brg.f90` |
| T0110 | `L3_MD/Material/Bridge/MD_MatRT_Brg.f90` |
| T0111 | `L3_MD/Material/Bridge/MD_Mat_Brg.f90` |
| … | 各家族 `*_Brg.f90`（子清单中带 `Brg` 的 L3 行） |

**登记**：新增/改名 Bridge 模块须先更新 [`BRIDGE_INDEX.md`](../../../../ufc_core/L3_MD/Bridge/BRIDGE_INDEX.md)。

### MR-W1-04 — L4：Def / Domain / 线弹性 + J2 竖切核

**目标**：**PH_Mat_Def / Domain_Core / Core + Elas + J2** 先于全量 Plast/Geo/Damage。

**已落地（首批）**：`PH_Mat_Core.f90` — **`PH_Mat_Desc_Effective_Model` PUBLIC**；`CONTRACT.md` 记 **族级模型 ID 读序**（`cfg%matModel` → 扁平 `matModel`）。**`PH_Mat_Domain_Core.f90`** — **`PH_Mat_Desc_SyncDeprecatedFlat`**；**`PH_L4_Populate.f90`** 材料填槽以 **`cfg%matId` / `cfg%matModel`** 为写入源后同步。**`PH_Mat_Def.f90`** — Execute 四步从 **`PH_Mat_Core`** 再导出（替代历史 **`PH_Mat_Execute`**），并再导出 **`PH_Mat_Desc_Effective_Model`**。**`L4_PH/Element/Shared/PH_Elem_MaterialRoute.f90`** — **`BuildElasticSlot`** 从 **`g_ufc_global%ph_layer%material`** 拷贝完整槽；路由用 **`PH_Mat_Desc_Effective_Model`** + **`desc%cfg%matId`**；**`desc%props`** 为热参数载体（不再误用不存在的 **`ctx%matModel/matId/props`**）。**Base（文档）**：`PH_Mat_BaseDefn.f90`、`PH_Mat_Dispatch.f90`、`PH_Mat_Reg.f90` — W1 头注释：**`PH_MAT_*`** / **`MAT_***`** / 槽 **`desc`** / **`desc%props`** 边界。**线弹性（文档）**：`PH_Mat_Elas_{Brg,Core,Def}.f90` — W1 竖切与 **`desc%props`** / **`PH_MAT_ELAS_*`** 协同。**J2（文档）**：`PH_Mat_J2_RadialReturn.f90`、`PH_Mat_Plast_J2.f90` — W1：`desc%props` / **Effective_Model** / **`PH_Mat_Dispatch`**。**L4 Contract/Defn（文档）**：`PH_MatConstit_Def`、`PH_Mat*_*Defn`（Creep/Dam/Geotech/Hyper/Spcl/Therm/Visc）、`PH_Mat_Aux_Def` — W1 与 **PH_Mat_Desc** / **Defn_Invoke_UMAT** 边界。**`PH_Mat_hTensor.f90`** — 张量工具与 **desc** 分离、内核消费 **props**。**L3 UMAT 核（文档+USE）**：`MD_MAT_USER_CORE` — **UF_Mat_Eval_Dispatch_FromDesc** 与 **UF_UMAT_Standard** 分工说明。**Contract·UMAT（W1 文档补登）**：`PH_Mat_Standards`、`PH_Mat_UMATIntfEnhanced`、`PH_UMAT_Def` — **Populate / desc%props** 与 **PH_UMAT_Context**。**Geo / Hyper / Therm / Visc（W1 文档）**：`PH_MatGeo_{CamClay,DruckerPrager,MohrCoulomb}`、`PH_Mat_NeoHookean`、`PH_Mat_Thermal_Core`、`PH_Mat_Visco_Core` — **`desc%props`** / **Effective_Model** 与族路由说明。

**合同**：`L4_PH/Material/CONTRACT.md`、`L3_MD/Material/CONTRACT.md`、`DESIGN_Mat_ConstitutiveKernels.md` — Populate/热路径 **`desc%props`** 口径已与 **`PH_Mat_Desc`** 对齐。

| Txxxx | 路径 |
|-------|------|
| T0737 | `L4_PH/Material/PH_Mat_Aux_Def.f90` |
| T0739 | `L4_PH/Material/PH_Mat_Def.f90` |
| T0710–T0720 | `L4_PH/Material/Contract/*`（按需分批若过大） |
| T0705–T0707 | `L4_PH/Material/Base/PH_Mat_BaseDefn.f90` 等 |
| T0740 | `L4_PH/Material/PH_Mat_Domain_Core.f90` |
| T0738 | `L4_PH/Material/PH_Mat_Core.f90` |
| T0732 | `L4_PH/Material/Elas/PH_Mat_Elas_Def.f90` |
| T0731 | `L4_PH/Material/Elas/PH_Mat_Elas_Core.f90` |
| T0730 | `L4_PH/Material/Elas/PH_Mat_Elas_Brg.f90` |
| T0746 | `L4_PH/Material/Plast/PH_Mat_Plast_J2.f90` |
| T0745 | `L4_PH/Material/Plast/PH_Mat_J2_RadialReturn.f90` |

### MR-W1-05 — L4：Dispatch + 余族热路径

**已落地（文档·Dispatch + L5 Def）**：`PH_MatEval.f90`、`PH_MatPLMEval.f90`、`PH_MatELA_ElasCall.f90`、`PH_MatPLM_PlastCall.f90` — 头注释标明 **W1 金线**（`PH_Mat_Core` + slot **`PH_Mat_Desc`/`desc%props`**）与 **LEGACY UMAT/TypeToId/PlastModels_Desc** 边界；`RT_Mat_Def.f90` — **`RT_Mat_Dispatch_Ctx%mat_type`** 与 **`PH_Mat_Desc_Effective_Model`** 对齐说明。**AI / Acoustic / Creep / Damage（W1 文档）**：`PH_AI_MatInteg`、`PH_Mat_Acoustic_Core`、`PH_Mat_Creep_Core`、`PH_MatDam_Gurson`、`PH_Mat_Lemaitre_CDM` — **`desc%props`** / **Effective_Model** 与族路由说明。**Composite / 塑性各向异性（W1 文档）**：`PH_MatComp_Castani`、`PH_Mat_Composite_Core`、`PH_MatPlast_{Barlat,Chaboche,Crystal,Hill}` — 槽 **`desc%props`**、**PH_MAT_PLASTIC** / **PH_MatPLMEval** 协同；**Barlat/Chaboche/Hill** 头 **MODULE** 行与 `MODULE` 名对齐。

| Txxxx | 路径 |
|-------|------|
| T0724–T0729 | `L4_PH/Material/Dispatch/*` |
| T0703–T0749 | 其余 `L4_PH/Material/**`（按家族拆 MR，避免单 PR 过大） |

### MR-W1-06 — L5：Material 路由 + Bridge Def（材料 TYPE 限定）

**已落地（首批）**：`RT_Mat_Brg.f90` — `RT_Mat_Brg_BuildTable_FromMaterial` 使用 **`PH_Mat_Domain`**（修正文档别名 **`PH_Mat_Domain`**）、从 **`PH_Mat_Desc`** 经 **`PH_Mat_Desc_Effective_Model`** 与 **`cfg%matId`** 填路由表（不再误读不存在的 **`ctx%matModel`**）。**`RT_Mat_Core.f90`** — W1 头注释：路由表项与 **`RT_Mat_Dispatch_Ctx`** / L4 族枚举一致；**`RT_Mat_Def.f90`** 已记 **`mat_type` 语义**。**`RT_Brg_Def.f90`** — W1 头注释：**`RT_Mat_Bridge_Ctx`** 与 **`RT_Mat_Brg`** / **`mat_type`** 金线及 **Deprecated↔Aux Sync**。**`RT_Asm_Solv.f90`**（材料号段）— 读 **`slot_pool%desc%props`**，与 **Populate** 写入的 **`PH_Mat_Desc%props`** 一致（原误用 **`ctx%props`** 已清）。

| Txxxx | 路径 |
|-------|------|
| T0819 | `L5_RT/Material/RT_Mat_Def.f90` |
| T0818 | `L5_RT/Material/RT_Mat_Core.f90` |
| T0817 | `L5_RT/Material/RT_Mat_Brg.f90` |
| T0780 | `L5_RT/Bridge/RT_Brg_Def.f90`（**仅** `RT_Mat_*` / `RT_Mat_Bridge_Ctx` 等材料相关 TYPE；非材料 Bridge 移出 W1 或另开子 PR） |

### MR-W1-07 — L3：家族模块扫尾（按目录 / 清单自上而下）

子清单 **T0100–T0328** 中尚未勾选的全部路径；建议 **每族 1 PR** 或 **每 10–20 文件 1 PR**，持续跑 **§2 竖切闸**。

---

## 4. PR 标题与描述模板

**标题**：`[W1][P1 Material][MR-W1-0x] 简述（如 L3 Contract/Base）`

**描述建议附**：

- 本子清单 **Txxxx** 列表或行号范围；  
- **Step1–4** 勾选；  
- **竖切验证**：构建 / 测例 / 手工步骤一句；  
- 是否触及 **`RT_Asm_*`**（若触及，按执行计划拆 **子 PR**）。

---

## 5. 相关入口

- [波次开展 · Issue/PR 协作说明](L3_L4_L5_波次开展_协作说明.md)  
- [W0 出口检查表](L3_L4_L5_W0_出口检查表.md)  
- [语义改造导航真源](L3_L4_L5_语义改造_导航真源.md) §3  

*最后更新：2026-04-29*
