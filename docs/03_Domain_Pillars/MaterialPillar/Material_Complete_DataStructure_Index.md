# 材料域「完整数据结构」— 仓库真源索引（可借鉴 / 勿平行造第二套）

**版本**：v1.1  
**结论（先读）**：

1. **`ufc_core/L3_MD/Material/` 完全可以、也应当作为设计与实现的借鉴真源**——11 主族目录、`Contract/MD_Mat_Def.f90`、各族 `*_Def.f90`、Populate→L4 的合同，已是「完整数据结构」的**落地形态**。  
2. **外稿第二套主卡/裸精度/ABA_PARAM 草图**仍不应不经评审整页入库；现网主卡 Fortran 名 **`MD_Mat_Desc`**（`EXTENDS(DescBase)`），与注册层 **`MD_Mat_LiteDesc`** 已分离（L3 Material 合同 v2.2）。  
3. 本页给出的是 **索引 + 边界说明 + 内部 L0–L5（材料子树）语义**；**可编译的完整定义**以 **`Contract/MD_Mat_Def.f90`** 与各 **`Material/<族>/*_Def.f90`** 为准。

---

## 1. 「完整数据结构」在仓库里对应什么？

| 概念层 | 真源位置 | 说明 |
|--------|----------|------|
| **域合同 / 四型 + Args 边界** | `ufc_core/L3_MD/Material/CONTRACT.md`、`ufc_core/L4_PH/Material/CONTRACT.md` | L3 主卡、Populate、L4 槽、`PH_Mat_*_*_Arg` |
| **L3 材料主卡（文档常写 `MD_Mat_Desc`）** | `Material/Contract/MD_Mat_Def.f90` → **`TYPE :: MD_Mat_Desc`** | 内含 **`cfg`（`MD_Mat_Cfg_Init_Desc`）**、**`pop`（`MD_Mat_Pop_Vld_Desc`）**、**`props(:)`** 等 |
| **L3 轻量注册用 Desc** | `Material/Base/MD_Mat_BaseDef.f90` → **`TYPE :: MD_Mat_LiteDesc`** | **`MD_Mat_Reg`** 用 `MD_Mat_Ctx%desc` 指针指向本类型；**不得**与合同主卡 **`MD_Mat_Desc`** 混淆。 |
| **辅 Desc / Typed 扩展** | 例：`MD_Mat_DP_Desc`、`DP_MatDesc`、`MohrCoulomb_MatDesc`、各族 `*_Def.f90` | 命名以 `ANALYSIS_3` §0 **文档规范名 ⇄ 源码** 表为准 |
| **UMAT bundle** | `MD_Mat_Def.f90` → **`MD_MAT_UMAT_Intf`**（文档 **`MD_Mat_UMAT_Intf`**） | 与 `MatCtxLegacy`、`User/` 路由一致 |
| **11 主族 × 子族目录心智** | [`Material_11Families_Subfamily_Directory.md`](Material_11Families_Subfamily_Directory.md) | 逻辑子族 vs 现网扁平 `.f90` |
| **三本手册 ↔ 类型 ↔ 关键字页** | [`Material_TripleManual_MasterCrosswalk.md`](Material_TripleManual_MasterCrosswalk.md) | CSV `manual_pages`、双列辅 Desc |

---

## 2. `L3_MD/Material/` 目录树（借鉴时从这里下钻）

```
ufc_core/L3_MD/Material/
├── CONTRACT.md                 # 域合同
├── Contract/MD_Mat_Def.f90   # 主卡 MD_Mat_Desc、UMAT、Legacy、类别常量 …
├── Base/MD_Mat_BaseDef.f90   # 轻量 MD_Mat_LiteDesc + Props 块（注册层）
├── Domain/                     # 域容器
├── Dispatch/ Registry/ Bridge/ Shared/
├── Elas/ Plast/ Geo/ HyperElas/ Viscoelas/ Creep/ Damage/ Composite/
├── Thermal/ Acoustic/ User/
└── … 各族 *Def.f90 / *Core.f90 / *Brg.f90
```

**L4 热路径**：`ufc_core/L4_PH/Material/<同族>/` — `PH_Mat_Desc` 槽、**State / Algo / Ctx / `*_Arg`** 以 L4 合同为准。

---

## 3. 材料子树「L0–L5」（UFC **内部**命名；非 Abaqus 官方标签）

与 [`Material_11Families_Subfamily_Directory.md`](Material_11Families_Subfamily_Directory.md) 中 **K0–K5** 可 **一一对应**；用于 **KEYWORD → Populate → Desc**，**不要**与「整模型」层级混淆。

| 层级 | 含义 | 典型 INP / 数据 |
|------|------|-----------------|
| **L0** | 材料定义根 | `*MATERIAL, NAME=` |
| **L1** | 主行为关键字 | `*ELASTIC`、`*PLASTIC`、`*USER MATERIAL` … |
| **L2** | 参数子选项 / 本构分支 | `TYPE=`、`HARDENING=` …（**以 KEYWORD 手册为准**，勿臆造 `*PLASTIC, TYPE=J2` 等非法词条） |
| **L3** | 模型名 / 能量形式 / 律名 | 如超弹 `MOONEY`、`OGDEN`（手册枚举） |
| **L4** | 参数组 / 表 ID | Prony 系数、硬化表引用等 |
| **L5** | 数据行 | 数值行、温度表 |

**落库映射**：L0–L4 静态 → **`MD_Mat_Desc%cfg` / `%pop` / `%props`** + **辅 Typed Desc**（多族 `*_MatDesc` 仍 **`EXTENDS(MD_Mat_Desc)`**）；L5 为数据行本体；演化进 **L4 `PH_Mat_*_State`** 等。

---

## 4. `mat_family` 1..11 → 首选 `*_Def.f90`（索引）

| `mat_family` | 目录 | 首选 Def / 合同入口（节选） |
|-------------|------|-----------------------------|
| 1 Elastic | `Elas/` | `MD_Mat_Def.f90` + `Elas/*`；线弹 Typed |
| 2 Plastic | `Plast/` | `MD_Mat_Plast_Def.f90` 等 |
| 3 Geo | `Geo/` | `MD_Mat_Geo_Def.f90`、`MD_Geo_DruckerPrager`、`MD_MatPLG_*` |
| 4 Hyper | `HyperElas/` | `MD_Mat_HyperElas_Def.f90`、`Contract/MD_MatHYP_Def.f90` |
| 5 VE | `Viscoelas/` | `MD_Mat_Visco_Def.f90` |
| 6 Creep | `Creep/` | `MD_Mat_Creep_Def.f90`、`MD_MatPorFoam_Def.f90` |
| 7 Damage | `Damage/` | `MD_Mat_Damage_Def.f90`、`Contract/MD_MatDMG_Def.f90` |
| 8 Composite | `Composite/` | `MD_Mat_Comp_Def.f90` |
| 9 Thermal | `Thermal/` | `MD_Mat_Therm_Def.f90` |
| 10 Acoustic | `Acoustic/` | `MD_Mat_Acous_Def.f90` |
| 11 User | `User/` | `MD_Mat_User_Def.f90`、`MD_MAT_UMAT_Intf`、`MD_MatSPU_Def.f90` |

枚举 **`MD_MAT_MODEL_*` / `MD_MAT_CATEGORY_*`** 在 **`MD_Mat_Def.f90`** 顶部；与 **`MD_Ana_Comp.f90`** 中 `mat_family` 对齐以 `CONTRACT.md` 为准。

---

## 5. 与外稿「映射表」的关系（可保留为 **需求表**，实现须校对 KEYWORD）

外稿中的 **「`*ELASTIC, TYPE=ISO`」「`*PLASTIC, TYPE=J2`」** 等：必须以 **Input Reference** 实际参数名为准；不少组合在 Abaqus 里是 **参数 + 数据行**，不是简单的「关键字, TYPE=子串」。**实现映射**以 **`analysis3_material_keyword_ufc_fields.csv`** + **`Material_TripleManual_MasterCrosswalk.md` §3.7** 为增量真源。

---

## 6. 三维过程（Where / When / What）

材料算核的命名与挂载以 **L4 `PH_Mat_*_Proc` / `_Core`** 与全景 **Where×When×What** 字典对齐；**不在此页**发明新的 `CALL MD_Mat_Proc_*` 清单——避免与现网过程名漂移。参见 `docs` 内 **数据四型×过程** 与 `L4_PH/Material/CONTRACT.md`。

---

## 7. 若要「生成」下一步可执行项（建议顺序）

1. **合同先行**：任何新 `EXTENDS(MD_Mat_Desc)` 的辅 Desc，先补 **`ANALYSIS_3` §0** 与 CSV `ufc_host_type` 列，再写 `.f90`。  
2. **一族一 PR**：例如仅 `*ELASTIC` 的 `TYPE=` 枚举 + Populate → 已有 `Elas/` Typed，避免 11 族同时改。  
3. **禁止**：再引入第二个「主材料四型聚合」`MD_Material` 作为 L3 唯一入口（除非合同显式迁移）。  

**自动生成索引**：见 `UFC/tools/gen_material_public_type_index.py` → `UFC/REPORTS/material_public_types_index.json`。

---

## 8. 相关链接

- [`Material_TripleManual_MasterCrosswalk.md`](Material_TripleManual_MasterCrosswalk.md)  
- [`Material_11Families_Subfamily_Directory.md`](Material_11Families_Subfamily_Directory.md)  
- [`ANALYSIS_3_Materials_PartV_Manual.md`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md)  
- [`../../../ufc_core/L3_MD/Material/CONTRACT.md`](../../../ufc_core/L3_MD/Material/CONTRACT.md)

---

*本页是**索引与纪律**，不是第二份 Fortran 真源；编译级定义请只信 `*.f90` + `CONTRACT.md`。*
