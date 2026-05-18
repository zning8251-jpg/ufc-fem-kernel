# 关键词参数目录 (Keyword Parameter Catalog)

**路径**: UFC/REPORTS/Keyword_Parameter_Catalog.md
**版本**: v1.1 | **日期**: 2026-05-05
**来源**: Abaqus 2016 Keywords Reference Manual (Manual/KEYWORD.pdf)
**性质**: 77 个关键字的参数、数据行、UFC 映射目录
**互链**: 命名规范见 REPORT_Naming_Unified_Spec.md | 域级 Inventory 见 Master_Domain_Inventory_Index.md

---

## 1. 优先等级

| 等级 | 数量 | 说明 |
|------|------|------|
| P0 (必选) | 8 | 核心关键字，必须支持注册+解析 |
| P1 (重要) | 52 | 工程常用关键字，需逐域覆盖 |
| P2 (按需) | 17 | 试验数据/特殊关键字 |

## 2. P0 关键字

| 关键字 | 类别 | 参数 | 参数名 | UFC 映射 |
|--------|------|------|--------|----------|
| *RIGID BODY | Model | 9 | REF NODE, ANALYTICAL SURFACE, POSITION, CENTER OF MASS, ISOTHERMAL | MD_Cont_Rigid_Desc |
| *INITIAL CONDITIONS | Model | 20 | TYPE, VALUES, NODE, ELEMENT, FILE, SIZE, UNSYMM, OP, NSTEP | MD_Initc_Def |
| *CONNECTOR MOTION | Interaction | 5 | COMPONENT, TYPE, LENGTH, AMPLITUDE | MD_Connector_Desc |
| *CONNECTOR LOAD | Interaction | 6 | COMPONENT, TYPE, AMPLITUDE, OPERATION | MD_Connector_Desc |
| *CONNECTOR STOP | Interaction | 4 | COMPONENT, TYPE, MAGNITUDE | MD_Connector_Desc |
| *AMPLITUDE | Model/Step | 12 | NAME, TIME, VALUE, DEFINITION, INPUT | MD_Amp_Desc (11 类型) |
| *STEP | Procedure | 0 | NAME, NLGEOM, INC, UNSYMM | MD_Step_Mgr |
| *END STEP | Procedure | 0 | — | MD_Step_Mgr |

## 3. P1 关键字

| 域分类 | 数量 | 代表关键字 |
|--------|------|-----------|
| 材料本构(11) | 11 | *DRUCKER PRAGER, *MOHR COULOMM, *CRUSHABLE FOAM, *CONCRETE, *LOW DENSITY FOAM, *HONEYCOMB, *ELASTIC, *PLASTIC, *HYPERELASTIC, *USER MATERIAL, *RATE DEPENDENT |
| 热传导(4) | 4 | *HEAT TRANSFER, *SPECIFIC HEAT, *CONDUCTIVITY, *GAP CONDUCTANCE |
| 截面(4) | 4 | *SHELL GENERAL SECTION, *SOLID SECTION, *SHELL SECTION, *BEAM SECTION |
| 载荷(5) | 5 | *CLOAD, *DLOAD, *DSLOAD, *DECHARGE, *GRAVITY |
| 边界(2) | 2 | *BOUNDARY, *TEMPERATURE |
| 约束(2) | 2 | *EQUATION, *MPC |
| 接触(5) | 5 | *CONTACT PAIR, *SURFACE DEFINITION, *SURFACE INTERACTION, *CONTACT CONTROLS, *GAP |
| 步类型(4) | 4 | *STATIC, *DYNAMIC EXPLICIT, *COUPLED TEMPERATURE-DISPLACEMENT, *VISCO |
| 输出(5) | 5 | *OUTPUT, *NODE OUTPUT, *ELEMENT OUTPUT, *CONTACT OUTPUT, *RESTART |
| 网格(4) | 4 | *NODE, *ELEMENT, *NCOPY, *NMAP |
| 特殊(6) | 6 | *RIGID BODY, *PRE-TENSION SECTION, *BOLT LOAD, *CAVITY DEFINITION, *CONTROL, *SENSOR |

## 4. P2 关键字

| 域分类 | 数量 | 代表关键字 |
|--------|------|-----------|
| 试验数据(5) | 5 | *UNIAXIAL TEST DATA, *BIAXIAL TEST DATA, *PLANAR TEST DATA, *VOLUMETRIC TEST DATA, *SHEAR TEST DATA |
| 特殊(6) | 6 | *CONTOUR INTEGRAL, *NOTCH, *DUCTILE DAMAGE INITIATION, *CONSTITUTIVE MASS SCALING, *ADAPTIVE MESH, *CO-SIMULATION |
| 环境(3) | 3 | *INITIAL CONDITIONS (field), *PRE-FIELD, *TEMPERATURE (initial) |
| 幅值(3) | 3 | *AMPLITUDE (PSD/DECAY/SMOOTH STEP) |

## 5. 数据行格式

| 关键字 | 数据行 | 每行列数 | 说明 |
|--------|--------|---------|------|
| *RIGID BODY | ref_node, surf_name | 2 | 参考节点+解析面 |
| *INITIAL CONDITIONS | set, value1, value2, ... | 可变 | TYPE 决定列数 |
| *CONNECTOR MOTION | comp, type, value, amp | 4 | 运动分量定义 |
| *ELASTIC | E, nu, temp | 3 | 各向同性/工程常数 |
| *PLASTIC | yield, strain | 2 | 屈服应力 vs. 塑性应变 |

## 6. 状态与交付

| 交付项 | 状态 | 路径 |
|--------|------|------|
| MD_KW_Reg_Ext.f90 | DONE | L3_MD/KeyWord/ |
| MD_KW_Abaqus.f90 集成 | DONE | L3_MD/KeyWord/ |
| CONTRACT.md v3.2 | DONE | L3_MD/KeyWord/ |
| 关键词参数目录 | THIS DOC | REPORTS/ |
| Word 版目录 | DONE | REPORTS/Keyword_Parameter_Catalog.docx |

---

> **END** — Keyword Parameter Catalog v1.1
