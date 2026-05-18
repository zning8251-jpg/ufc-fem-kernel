# Abaqus 6.14 材料卷 · 叶类型主表（固定 41 行）

**路径（仓库固定）**：`UFC/docs/03_Domain_Pillars/MaterialPillar/Abaqus614_Material_Leaf41.md`  
**版本**：v1.0  
**日期**：2026-05-02  
**策略**：**严格 41 行** — 新增叶类型须走 **改版本表（v1.1+）** 或 **显式替换/废弃某行**；禁止出现第 42 行「未登记」叶类型。  
**手册锚点**：以 *Abaqus Analysis User’s Guide 6.14 — Materials* 卷为语义主参考；本表为 **UFC 项目内可执行枚举**（与 `mat_family` 1..11 对齐），**不等价**于手册任意附录的逐字编号。  
**与 11 主族关系**：`mat_family` 真源见 `ufc_core/L3_MD/Analysis/MD_Ana_Comp.f90`、`ufc_core/L3_MD/Material/CONTRACT.md`。  
**UFC 映射列**：填「主 L3 目录 / Contract 片段 / 代表 `PH_MAT_*`」等 **指针**；实现以代码与 `CONTRACT.md` 为准，本表为 **门禁与对照入口**。

---

## 行数合并说明（为严格 41）

| 合并项 | 主表行号 | 说明 |
|--------|----------|------|
| 声学 | **40** | `*ACOUSTIC MEDIUM` 与吸声相关选项合并为 **单一叶类型**「声学介质/吸声（选项互斥）」 |
| 复合材料 | **35–36** | 「层合板」与「织物」合并为 **一行**（**35**）；**Hashin** 单独 **36** |
| User | **41** | `*USER MATERIAL` / UMAT / VUMAT / UEL 作为 **一条叶类型**（接口 bundle，不拆成 3 行） |

---

## 主表（41 行）

| ID | `mat_family` | 主族（CONTRACT） | 叶类型（中文） | 典型关键字 / TYPE= | UFC 映射提示（可迭代补全） |
|----|----------------|------------------|----------------|----------------------|------------------------------|
| 1 | 1 | Elastic | 各向同性线弹 | `*ELASTIC, TYPE=ISOTROPIC` | `L3_MD/Material/Elas/` · `PH_MAT_ELASTIC` |
| 2 | 1 | Elastic | 正交各向异性 | `*ELASTIC, TYPE=ORTHOTROPIC` | 同上 |
| 3 | 1 | Elastic | 横观各向同性 | `*ELASTIC, TYPE=TRAVERSE`（或手册等价写法） | 同上 |
| 4 | 1 | Elastic | 全各向异性 | `*ELASTIC, TYPE=ANISOTROPIC` | 同上 |
| 5 | 1 | Elastic | 率型（亚弹性） | `*ELASTIC, TYPE=HYPOELASTIC` | 同上 |
| 6 | 1 | Elastic | 多孔弹性 | `*ELASTIC, TYPE=POROUS` | 同上 |
| 7 | 2 | Plastic | J2 / Mises（各向同性/随动硬化） | `*PLASTIC` + Mises 支路 | `L3_MD/Material/Plast/` · `PH_MAT_ELASTO_PLASTIC` |
| 8 | 2 | Plastic | Chaboche 混合硬化 | `*PLASTIC` + Chaboche | 同上 |
| 9 | 2 | Plastic | Hill48 各向异性屈服 | `*PLASTIC` + Hill | 同上 |
| 10 | 2 | Plastic | Barlat 各向异性 | `*PLASTIC` + Barlat | 同上 |
| 11 | 2 | Plastic | Johnson-Cook | `*PLASTIC` + JC | 同上 |
| 12 | 2 | Plastic | GTN 多孔韧性 | `*PLASTIC` + Gurson-type | 同上 |
| 13 | 2 | Plastic | 率相关塑性 | `*PLASTIC` + rate-dependent | 同上；与族 6 边界见 `CONTRACT.md` |
| 14 | 3 | Geo | Drucker-Prager | `*DRUCKER PRAGER` | `L3_MD/Material/Geo/` · `PH_MAT_GEOTECH` |
| 15 | 3 | Geo | Mohr-Coulomb | `*MOHR COULOMB` | 同上 |
| 16 | 3 | Geo | Cam-Clay | `*CLAY PLASTICITY` 等 | 同上 |
| 17 | 3 | Geo | 混凝土损伤塑性（CDP） | `*CONCRETE DAMAGED PLASTICITY` | 同上；与族 7 CDP 损伤叙述边界在 MR 中显式 |
| 18 | 4 | Hyperelastic | Neo-Hookean | `*HYPERELASTIC, TYPE=NEO HOOKE` | `Contract/MD_MatHYP_Def.f90` · `HyperElas/` · `PH_MAT_HYPERELASTIC` |
| 19 | 4 | Hyperelastic | Mooney-Rivlin | `*HYPERELASTIC, TYPE=MOONEY` | 同上 |
| 20 | 4 | Hyperelastic | Ogden | `*HYPERELASTIC, TYPE=OGDEN` | 同上 |
| 21 | 4 | Hyperelastic | Yeoh | `*HYPERELASTIC, TYPE=YEOH` | 同上 |
| 22 | 4 | Hyperelastic | Arruda-Boyce | `*HYPERELASTIC, TYPE=ARRUDA BOYCE` | 同上 |
| 23 | 4 | Hyperelastic | 超弹性泡沫（Foam） | `*HYPERELASTIC, TYPE=FOAM`（或手册等价） | 同上 |
| 24 | 5 | Viscoelastic | Prony 级数 | `*VISCOELASTIC, TIME=PRONY` 等 | `Contract/MD_MatVSC_Def.f90` · `Viscoelas/` · `PH_MAT_VISCOELASTIC` |
| 25 | 5 | Viscoelastic | Kelvin-Voigt | `*VISCOELASTIC` 等效 KV 支路 | 同上 |
| 26 | 5 | Viscoelastic | 蠕变粘性（粘弹侧） | `*VISCOELASTIC` 与蠕变耦合叙述 | 同上；**数值主归属**与族 6 以合同为准 |
| 27 | 5 | Viscoelastic | 粘弹塑性（VEVP） | `*VISCOELASTIC` + 塑性耦合支路 | 同上 |
| 28 | 6 | Creep / VP | 幂律蠕变 | `*CREEP, LAW=POWER` 等 | `L3_MD/Material/Creep/` · `PH_MAT_CREEP` |
| 29 | 6 | Creep / VP | Garofalo 蠕变 | `*CREEP, LAW=GAROFALO` 等 | 同上 |
| 30 | 6 | Creep / VP | Gurson 型多孔蠕变/扩展 | `*CREEP` + 多孔支路 | 同上；与族 2 GTN 边界在 MR 中显式 |
| 31 | 7 | Damage | 延性损伤 | `*DAMAGE INITIATION, TYPE=DUCTILE` 等 | `Contract/MD_MatDMG_Def.f90` · `Damage/` · `PH_MAT_DAMAGE` |
| 32 | 7 | Damage | 脆性损伤 | `*DAMAGE INITIATION, TYPE=BRITTLE` 等 | 同上 |
| 33 | 7 | Damage | 混凝土 CDP 损伤演化 | CDP 损伤子选项 | 同上；与族 17 Geo-CDP 本构边界显式 |
| 34 | 7 | Damage | 疲劳损伤 | `*DAMAGE INITIATION` 疲劳支路 | 同上 |
| 35 | 8 | Composite | 层合 / 织物（合并叶） | `*SHELL GENERAL SECTION` / 层合 + 织物关键字族 | `L3_MD/Material/Composite/` · `PH_MAT_COMPOSITE` |
| 36 | 8 | Composite | Hashin 失效 | Hashin 准则关键字族 | 同上 |
| 37 | 9 | Thermal | 热传导 | `*CONDUCTIVITY` | `L3_MD/Material/Thermal/` · 热标量 / `GROUP_MAT_COMPAT` 第 9 列 |
| 38 | 9 | Thermal | 热膨胀 | `*EXPANSION` | 同上 |
| 39 | 9 | Thermal | 相变 / 潜热 | `*LATENT HEAT` / `*PHASE CHANGE` 等 | 同上 |
| 40 | 10 | Acoustic | 声学介质 + 吸声（合并叶） | `*ACOUSTIC MEDIUM` / `*ACOUSTIC ABSORPTION`（选项互斥） | `L3_MD/Material/Acoustic/` · `PH_MAT_ACOUSTIC` |
| 41 | 11 | User / SPU | UMAT / VUMAT / UEL（bundle） | `*USER MATERIAL` / UMAT / VUMAT / UEL | `User/` · `Contract/MD_MatSPU_Def.f90` · `MD_MAT_UMAT_*` in `Contract/MD_Mat_Def.f90` · `PH_MAT_USER_*` |

---

## 修订流程（保持 41）

1. **不改行数**：只改表中「关键字 / UFC 映射 / 备注」文字 → **PATCH** 本文件版本号第三位。  
2. **替换叶类型**：用 **DEPRECATED** 行注释 + 新语义写在同行「备注」**或** 发 v2.0 仍保持 41 行（替换定义）。  
3. **扩充到 42+**：**禁止**在本文件追加行；须发 **v2.0 新主表**（新文件名或明确版本废弃 v1.0），并同步 `CONTRACT.md` 与 `Material_11Families_Sequential_Rollout.md`。

---

## 交叉引用

- **Multitask 子任务 backlog**：[`Material_Leaf41_Multitask_Backlog.md`](./Material_Leaf41_Multitask_Backlog.md)  
- **Leaf41 ↔ UFC 对照表（MT-0.1，可填）**：[`Leaf41_UFC_Crosswalk.csv`](./Leaf41_UFC_Crosswalk.csv)  
- 11 主族执行顺序：[`Material_11Families_Sequential_Rollout.md`](./Material_11Families_Sequential_Rollout.md)  
- 族 MR 工单：[`Material_Family_WorkOrder_Template.md`](./Material_Family_WorkOrder_Template.md)  
- 手册 Part II 总册：[`../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md)  
- L3 合同：[`../../../ufc_core/L3_MD/Material/CONTRACT.md`](../../../ufc_core/L3_MD/Material/CONTRACT.md)  

---

## 与「Marlow」等手册独有项

6.14 树中常见 **Marlow** 等未单独占行时，**不增加第 42 行**：在 **v1.0** 中并入 **行 18–23** 之一（建议 **行 19 Mooney-Rivlin** 备注「Marlow 为独立 TYPE= 时替换本行语义」）或于 **v1.1** 通过「替换行定义」消化。**严格 41** 下禁止并行增加未登记叶类型。
