# 材料域：11 主族（一级目录）× 子族（二级目录）清单

**用途**：与 Abaqus Part V 对齐时，用 **「主族文件夹 → 子族分桶」** 做目录心智模型；**当前代码树**在 `ufc_core/L3_MD/Material/<主族>/` 与 `ufc_core/L4_PH/Material/<主族>/` 下多为 **扁平 `.f90`**，**尚无物理二级子目录**。下表 **「建议二级目录名」** 为逻辑分族（便于 Manifest、拆目录或手册 TOC 对照），括号内为 **现网已存在的模块 stem**（与 stem 一一对应，非另造型号名）。

**真源**：`mat_family` 1..11 与主族文件夹 — `ufc_core/L3_MD/Material/CONTRACT.md` §子域划分；`Material_11Families_L3L4L5_三层打通清单.md`。

---

## 手册「六级嵌套」与材料关键字：事实与 UFC 建议

### Abaqus 官方是否把材料关键字标成 L0–L5？

**不是。** Dassault 文档里**没有**名为 **L0 / L1 / … / L5** 的官方分级体系。手册侧常见的是：

- **卷 / Part / 章 / 节**（例如 Part V 第 22–26 章）；
- **Input Reference** 里每个关键字一页：**关键字行 → 参数（如 `TYPE=`）→ 数据行 / 温度表 / 依赖场**。

因此：**「手册按 L0–L5 六级嵌套」不是 Abaqus 规范表述**；若团队内部要用 **L0–L5**，应明确为 **UFC 解析器 / Populate AST 的命名约定**，并在 `ANALYSIS_3_Materials_PartV_Manual.md` 或本表注明「**非手册原文**」。

### 仅材料相关：INP 上可落地的「层级感」（建议作 UFC 内部 K 层，可与 L0–L5 自行对齐）

下面 **6 档**描述的是 **输入 deck 形态**，便于和 **主 Desc（卡级打包）+ 辅 Desc（Typed 解包）** 对齐；**层数与 TYPE 物理嵌套 ≤3 层** 是另一约束（见下节）。

| 建议层名（UFC 内部） | 含义（材料卷） | 示例 |
|----------------------|----------------|------|
| **K0** | 模型 / 截面 / 装配上下文（可选） | `*MATERIAL` 所在 `*PART`、截面引用 |
| **K1** | 材料定义块 | `*MATERIAL, NAME=…` |
| **K2** | 材料块内 **行为关键字** | `*ELASTIC`, `*PLASTIC`, `*DENSITY`, `*USER MATERIAL` … |
| **K3** | 关键字 **参数 / 子选项** | `TYPE=SHEAR`, `TYPE=ISOTROPIC`, `DEPENDENCIES=` … |
| **K4** | **数据行**（常数、表、场依赖表） | E, ν 行；硬化表；Prony 系数表 |
| **K5** | **从属 / 链式** 子块（若手册规定必须跟在某关键字后） | 某些组合下的附加关键字（以手册 *Requires* 表为准） |

**与四型的关系（摘要）**：K1–K4 的静态内容经读入 → 落入 **`MD_Mat_Desc`（主卡，`MD_Mat_Desc`）** 的 `props` / `cfg` / `behavior`；**K3 的语义**（如 `TYPE=`）在 Populate 后进入 **辅 Desc**（如 `MD_Mat_Elastic_*_Desc`、`MD_Mat_DP_Desc`）。详见 `docs/03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md` §2–§5。

### `*ELASTIC, TYPE=SHEAR` 是否体现在 `MD_Mat_Elastic_*_(Desc/Ctx/State/Algo)`？

- **Desc**：**是**。`TYPE=` 属于 **K3**，应在 **弹性辅 Desc**（或等价 Typed 结构）中用 **枚举 + 已解包常数**（如 `G`, `K`）表达；**主 Desc** 仍保留 **原始 `props` 序** 与 `cfg%matModel` 等，便于审计与回放 INP。
- **State / Algo / Ctx**：**按本构需要**——`TYPE=` 本身不「占满」四型；**State** 存演化量，**Algo** 存切线开关/子步等，**Ctx** 存本步增量上下文；与 `PH_Mat_*_*_Arg` 的 SIO 边界以 `L4_PH/Material/CONTRACT.md` 为准。
- **TYPE 嵌套 ≤3 层**：推荐 **`MD_Material`（或槽）→ 四型之一 → 子族辅 Desc`** 封顶；更深内容用 **索引 / 池 / 表句柄**，避免再套 `TYPE`。

### 附录：仓库 CSV 中的材料关键字全量（当前 32 条）

**机器真源**：`UFC/REPORTS/analysis3_material_keyword_ufc_fields.csv`（列含 `ufc_host_type`、`family_desc_anchor`）。下表为 **关键字 → 主 `mat_family`（UFC 11 族）** 的归类索引；交叉项在 `family_desc_anchor` 列写双路径。

| 关键字 | 主 `mat_family`（索引） | 备注 |
|--------|-------------------------|------|
| `*ELASTIC` | **1** Elastic | 线弹；`TYPE=` 进辅 Desc |
| `*HYPOELASTIC` | **1** Elastic | 率型模量分支 |
| `*PLASTIC` | **2** Plastic | 与金属塑、硬化表强相关 |
| `*DRUCKER PRAGER` | **3** Geo | 主卡 + `MD_Mat_DP_Desc` |
| `*MOHR COULOMB` | **3** Geo | 主卡 + Mohr–Coulomb 辅 Desc |
| `*FABRIC` | **3 / 8** | `Geo/` 与 `Composite/`（织物）交叉，以手册组合为准 |
| `*HYPERELASTIC` | **4** Hyperelastic | |
| `*HYPERFOAM` | **4** Hyperelastic | |
| `*VISCOELASTIC` | **5** Viscoelastic | |
| `*CREEP` | **6** Creep | |
| `*CONCRETE` | **7**（主）+ **2**（交叉） | 损伤/塑性与混凝土节交叉 |
| `*CONDUCTIVITY` | **9** Thermal | |
| `*SPECIFIC HEAT` | **9** Thermal | |
| `*EXPANSION` | **9** Thermal（+ 与弹耦合） | |
| `*DENSITY` | **—（跨族）** | 章 21 元数据；Populate 约束见 ANALYSIS_3 §5 |
| `*EOS` | **11** User / Special | 与 User、`MD_MAT_MODEL_USER` 路径对齐 |
| `*USER MATERIAL` | **11** User / Special | `MD_Mat_UMAT_Intf`（源码 `MD_MAT_UMAT_Intf`） |

> **说明**：CSV 为 **Priority 关键字子集**，不是 Abaqus 材料卷全部关键字的穷尽列表；扩展时改 `UFC/tools/extract_analysis3_materials_ufc_mapping.py` 内 `PRIORITY_KEYWORDS` / `KEYWORD_UFC_FIELDMAP` 并重导 CSV，再回写本表与 `ANALYSIS_3` §5。

---

## 跨主族的基础设施（非 `mat_family` 1..11）

下列为 **Material 域共用**，不宜算作某一主族「子族」：

| 一级（目录） | 说明 |
|--------------|------|
| `Contract/` | `MD_Mat_Def.f90` 等四型与全局材料合同 |
| `Domain/` | `MD_MatDomain_*` 域容器 |
| `Dispatch/` | `MD_Mat_Lib.f90` 等 legacy / 分发 |
| `Registry/` | 注册与 PLM |
| `Bridge/` | L3↔L4 冷桥 |
| `Shared/` | 跨族共享核 / 校验 / Legacy |
| `Base/` | 基底注册等 |

---

## 1 — Elastic · `mat_family = 1` · `Elas/`

**一级路径**：`ufc_core/L3_MD/Material/Elas/` · `ufc_core/L4_PH/Material/Elas/`

**Input Reference（CSV 已列）**：`*ELASTIC`，`*HYPOELASTIC`。`*ELASTIC` 的 `TYPE=`（如 `ISOTROPIC`、`ORTHOTROPIC`、`SHEAR`）落在 **辅 Desc / Typed**；主卡打包与 Populate 规则见上文「K3 + 主/辅 Desc」及 `ANALYSIS_3_Materials_PartV_Manual.md` §5。

| 建议二级目录 | 当前 stem（L3，节选） | 对齐提示 |
|--------------|------------------------|----------|
| `Isotropic/` | `MD_Ela_Iso`, `MD_Mat_Elas_Isotropic` | 各向同性线弹 |
| `Orthotropic_Transverse/` | `MD_Ela_Ortho`, `MD_Mat_Elas_Orthotropic`, `MD_Mat_Elas_TransIsotropic` | 正交 / 横观各向同性 |
| `Anisotropic/` | `MD_Ela_Aniso`, `MD_Mat_Elas_Anisotropic` | 全各向异性 |
| `Hypoelastic/` | `MD_Mat_Elas_Hypoelastic` | 率型 hypoelastic |
| `Porous_elastic_matrix/` | `MD_Mat_Elas_Porous` | 多孔弹性（与 `Geo/` 孔压耦合分工见域合同） |

---

## 2 — Plastic · `mat_family = 2` · `Plast/`

**一级路径**：`ufc_core/L3_MD/Material/Plast/` · `L4_PH/Material/Plast/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Plastic_shell/` | `MD_Mat_Plast_Def`, `MD_Mat_Plast_Core`, `MD_Mat_Plast_Brg` | 塑性域壳与通用编排 |
| `J2_Mises_line/` | `MD_Pls_J2Iso`, `MD_Mat_Plast_J2` | J2 / Mises 类 |
| `Kinematic_hardening/` | `MD_Pls_Chaboche`, `MD_Pls_ArmstrongFrederick`, `MD_Pls_KinLin`, `MD_Pls_KinComb`, `MD_Mat_Plast_Chaboche` | 随动 / 混合硬化 |
| `Anisotropic_yield/` | `MD_Pls_Hill48`, `MD_Mat_Plast_Hill`, `MD_Pls_Barlat`, `MD_Mat_Plast_Barlat` | Hill、Barlat 等 |
| `Advanced_metals/` | `MD_Pls_JohnsonCook`, `MD_Mat_Plast_JohnsonCook`, `MD_Pls_ORNL`, `MD_Mat_Plast_ORNL`, `MD_Pls_GTN`, `MD_Mat_Plast_SwiftVoce`, `MD_Mat_Plast_Temm`, `MD_Mat_Plast_Za`, `MD_Mat_Plast_CastIron`, `MD_Mat_Plast_Ceramic`, `MD_Mat_Plast_Crystal`, `MD_Mat_Plast_Deformation`, `MD_Mat_Plast_Fgm`, `MD_Mat_Plast_MixedHard`, `MD_Mat_Plast_Nano`, `MD_Mat_Plast_SmartMat` | JC、ORNL、GTN、铸造等 |
| `Rate_viscoplastic_coupling/` | `MD_Mat_Plast_RateDep`, `MD_Mat_Plast_Viscoplastic`, `MD_Mat_Plast_BiVisc`, `MD_Mat_Plast_ThermoVisc`, `MD_Mat_Plast_ViscDmgEM`, `MD_Mat_Plast_HyperElastPlast` | 率相关 / 粘塑 / 热粘 / 与损伤电磁耦合等 |

---

## 3 — Geo · `mat_family = 3` · `Geo/`

**一级路径**：`ufc_core/L3_MD/Material/Geo/` · `L4_PH/Material/Geo/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `DruckerPrager_Cap/` | `MD_Geo_DruckerPrager`, `MD_MatPLG_DruckerPrager`, `MD_MatPLG_Cap` | DP / Cap |
| `MohrCoulomb/` | `MD_Geo_MohrCoulomb`, `MD_MatPLG_MohrCoulomb` | MC |
| `CamClay_softrock_soil/` | `MD_MatPLG_CamClay`, `MD_MatPLG_SoftRock`, `MD_MatPLG_Soil`, `MD_MatPLG_Geotech` | 剑桥粘土、软岩、土 |
| `Concrete_crack_joint/` | `MD_MatPLG_ConcreteDamage`, `MD_MatPLG_BrittleCrack`, `MD_MatPLG_SmearedCrack`, `MD_MatPLG_Joint` | 混凝土损伤、裂隙、节理 |
| `Geo_shell/` | `MD_Mat_Geo_Def`, `MD_Mat_Geo_Core`, `MD_Mat_Geo_Brg` | 岩土域壳 |

---

## 4 — Hyperelastic · `mat_family = 4` · `HyperElas/`

**一级路径**：`ufc_core/L3_MD/Material/HyperElas/` · `L4_PH/Material/HyperElas/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `NeoHookean/` | `MD_Hyp_NeoHookean1`, `MD_Hyp_NeoHookean2`, `MD_Mat_HyperElas_NeoHookean` | |
| `MooneyRivlin/` | `MD_Hyp_MooneyRivlin`, `MD_Hyp_MooneyRivlin2`, `MD_Hyp_MooneyRivlin5`, `MD_Mat_HyperElas_MooneyRivlin` | |
| `Ogden/` | `MD_Hyp_Ogden2`, `MD_Hyp_Ogden3`, `MD_Mat_HyperElas_Ogden` | |
| `Yeoh_Arruda_Gent_Marlow/` | `MD_Hyp_Yeoh`, `MD_Hyp_ArrudaBoyce`, `MD_Hyp_Gent`, `MD_Hyp_Marlow`, `MD_Mat_HyperElas_Yeoh`, `MD_Mat_HyperElas_ArrudaBoyce`, `MD_Mat_HyperElas_Marlow` | |
| `VanDerWaals_Foam/` | `MD_Hyp_VanDerWaals`, `MD_Hyp_Foam` | |
| `Polynomial_reduced_softening/` | `MD_Mat_HyperElas_Polynomial`, `MD_Mat_HyperElas_ReducedPolynomial`, `MD_Mat_HyperElas_StressSoftening`, `MD_Mat_HyperElas_PermanentSet` | 多项式 / 约化多项式 / Mullins 等 |
| `Hyper_shell/` | `MD_Mat_HyperElas_Def`, `MD_Mat_HyperElas_Core`, `MD_Mat_HyperElas_Brg` | 超弹域壳 |

---

## 5 — Viscoelastic · `mat_family = 5` · `Viscoelas/`

**一级路径**：`ufc_core/L3_MD/Material/Viscoelas/` · `L4_PH/Material/Viscoelas/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Prony_Kelvin_WLF/` | `MD_Vis_PronyDev`, `MD_Vis_PronyVol`, `MD_Vis_KelvinVoigt`, `MD_Vis_WLF` | Prony、KV、WLF |
| `Linear_nonlinear_visco/` | `MD_Mat_Viscoelas_LinearVisco`, `MD_Mat_Viscoelas_NonlinearVisco` | 时域 / 频域粘弹入口 |
| `Creep_swelling_rate/` | `MD_Mat_Viscoelas_Creep`, `MD_Mat_Viscoelas_Swelling`, `MD_Mat_Viscoelas_RateDepCreep`, `MD_Mat_Viscoelas_Perzyna` | 与蠕变/膨胀/率型交叉时以手册关键字为准 |
| `VEVP_thermo/` | `MD_Mat_Viscoelas_ViscoElastPlast`, `MD_Mat_Viscoelas_ThermoVisco`, `MD_Mat_Viscoelas_ViscoBase` | 粘弹‑塑、热粘 |
| `Visco_shell/` | `MD_Mat_Visco_Def`, `MD_Mat_Visco_Core`, `MD_Mat_Visco_Brg` | 粘弹域壳 |

---

## 6 — Creep / Porous creep · `mat_family = 6` · `Creep/`

**一级路径**：`ufc_core/L3_MD/Material/Creep/` · `L4_PH/Material/Creep/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Creep_laws/` | `MD_Crp_PowerLaw`, `MD_Crp_Garofalo`, `MD_Crp_Perzyna`, `MD_Crp_Bodner`, `MD_Crp_DuvautLions`, `MD_Crp_TwoLayer`, `MD_Crp_UserDef`, `MD_Crp_Anneal` | 蠕变律族 |
| `Creep_shell/` | `MD_Mat_Creep_Def`, `MD_Mat_Creep_Core`, `MD_Mat_Creep_Brg` | 蠕变域壳 |
| `Porous_Gurson_foam/` | `MD_MatPOR_Porous`, `MD_MatPOR_Gurson`, `MD_MatPOR_CrushFoam`, `MD_MatPOR_Foam3`, `MD_MatPorFoam_Def` | Gurson / 泡沫 / 多孔（本文件夹内现网命名） |
| `Multiphysics_creep_hooks/` | `MD_Mat_Creep_BiotPoroElastic`, `MD_Mat_Creep_Diffusion`, `MD_Mat_Creep_PiezoElastic`, `MD_Mat_Creep_Piezoelectric`, `MD_Mat_Creep_PoreFlow` | 与渗流 / 扩散 / 压电等耦合描述 |

---

## 7 — Damage · `mat_family = 7` · `Damage/`

**一级路径**：`ufc_core/L3_MD/Material/Damage/` · `L4_PH/Material/Damage/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Phenomenological/` | `MD_Dmg_Ductile`, `MD_Dmg_Brittle`, `MD_Dmg_Shear`, `MD_Dmg_FLD`, `MD_Mat_Damage_DuctileDamage`, `MD_Mat_Damage_Brittle` | 延性 / 脆性 / 剪切 / FLD |
| `CDP_CZM_multiscale/` | `MD_Dmg_CDP`, `MD_Dmg_CZM`, `MD_Mat_Damage_Progressive`, `MD_Mat_Damage_Multiscale` | 混凝土损伤、内聚力、多尺度 |
| `Fatigue_dynamic_visco/` | `MD_Mat_Damage_FatigueCrack`, `MD_Mat_Damage_LowCycleFatigue`, `MD_Mat_Damage_Dynamic`, `MD_Mat_Damage_ViscoDamage` | 疲劳 / 动态 / 粘滞损伤 |
| `Damage_shell/` | `MD_Mat_Damage_Def`, `MD_Mat_Damage_Core`, `MD_Mat_Damage_Brg` | 损伤域壳 |

---

## 8 — Composite · `mat_family = 8` · `Composite/`

**一级路径**：`ufc_core/L3_MD/Material/Composite/` · `L4_PH/Material/Composite/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Laminate_delam_interface/` | `MD_Cmp_CLT`, `MD_Mat_Composite_Laminate`, `MD_Mat_Composite_Delamination`, `MD_Mat_Composite_Interface` | 层合 / 分层 / 界面 |
| `Fiber_fabric_foam/` | `MD_Mat_Composite_FiberDamage`, `MD_Mat_Composite_Fabric`, `MD_Cmp_Fabric`, `MD_Cmp_FoamVE` | 纤维、织物、粘弹泡沫 |
| `Failure_criteria/` | `MD_Cmp_Hashin`, `MD_Cmp_Jointed` | Hashin、节理类 |
| `Composite_shell/` | `MD_Mat_Comp_Def`, `MD_Mat_Comp_Core`, `MD_Mat_Comp_Brg` | 复合材料域壳 |

---

## 9 — Thermal · `mat_family = 9` · `Thermal/`

**一级路径**：`ufc_core/L3_MD/Material/Thermal/` · `L4_PH/Material/Thermal/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Conductivity_expansion/` | `MD_Thm_Iso`, `MD_Thm_Ortho`, `MD_Mat_Creep_ThermalConduction`, `MD_Mat_Creep_ThermalExpansion` | 传导 / 膨胀（命名中带 `Creep` 为历史路径，语义属热） |
| `Thermoelastic_coupling/` | `MD_Mat_Creep_ThermoElastic`, `MD_Mat_Creep_ThermoElectric`, `MD_Mat_Creep_ThermoElecElastic` | 热‑力 / 热‑电 |
| `Phase_change/` | `MD_Thm_PhaseChg` | 相变 |
| `Thermal_shell/` | `MD_Mat_Therm_Def`, `MD_Mat_Therm_Core`, `MD_Mat_Therm_Brg` | 热域壳 |

---

## 10 — Acoustic · `mat_family = 10` · `Acoustic/`

**一级路径**：`ufc_core/L3_MD/Material/Acoustic/` · `L4_PH/Material/Acoustic/`

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `Acoustic_medium/` | `MD_Aco_Linear`, `MD_Mat_AcousticProps` | 声学介质 |
| `Absorption/` | `MD_Aco_Absorb` | 吸声 |
| `Acoustic_shell/` | `MD_Mat_Acous_Def`, `MD_Mat_Acous_Core`, `MD_Mat_Acous_Brg` | 声学域壳 |
| `Legacy_cross/` | `MD_Mat_Creep_Acoustic` | 历史命名交叉项，对齐时核对是否迁移 |

---

## 11 — User / SPU / UMAT · `mat_family = 11` · `User/`

**一级路径**：`ufc_core/L3_MD/Material/User/` · `L4_PH/Material/User/`（L4 另见 `Contract/` 与 Dispatch 中的 UMAT 路由）

| 建议二级目录 | 当前 stem（节选） | 对齐提示 |
|--------------|-------------------|----------|
| `UMAT_VUMAT/` | `MD_Usr_UMAT`, `MD_Usr_VUMAT`, `MD_Mat_User_Umat`, `MD_Mat_User_*`, `MD_Usr_Ext1`, `MD_Usr_Ext2` | 用户材料 |
| `SPU_special/` | `MD_MatSPU_Connector`, `MD_MatSPU_Damping`, `MD_MatSPU_Electromagnetic`, `MD_MatSPU_Eos`, `MD_MatSPU_HydrostaticFluid`, `MD_MatSPU_MassPoint` | 连接器、阻尼、EOS、流体、质点等 |

---

## 维护约定

1. **新增本构**：优先在对应 **一级 `…/Material/<主族>/`** 下加 `.f90`；若子族清晰，可在本表增补一行 **建议二级目录**，再考虑是否真拆子文件夹。  
2. **`mat_family` 或一级目录改名**：必须同步 `MD_Ana_Comp.f90`、`L3_MD/Material/CONTRACT.md`、`L4_PH/Material/CONTRACT.md` 与本表。  
3. **手册 TOC 对齐**：仍以 `docs/03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md` + `REPORTS/analysis3_materials_ufc_mapping.json` 为机器真源。  
4. **三本 PDF 总合同（章节 ↔ KEYWORD ↔ USER ↔ 辅 Desc 双列）**：见同目录 [`Material_TripleManual_MasterCrosswalk.md`](Material_TripleManual_MasterCrosswalk.md)。  
5. **完整数据结构（仓库真源索引，避免与外稿平行冲突）**：[`Material_Complete_DataStructure_Index.md`](Material_Complete_DataStructure_Index.md)。

---

*本表由当前 `ufc_core/L3_MD/Material` 目录扫描归纳；L4 镜像目录名与一级一致，子族逻辑与 L3 对齐。*
