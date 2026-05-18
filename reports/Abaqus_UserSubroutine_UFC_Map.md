# Abaqus 用户子程序 ↔ UFC 域柱映射（对照表）

**路径**：`UFC/REPORTS/Abaqus_UserSubroutine_UFC_Map.md`  
**性质**：把 **Abaqus User Subroutines** 按 **Standard / Explicit / CFD** 分列，映射到 UFC **贯通域柱（P1–P6）** 及若干 **横切关切**（约束、热、孔隙/固结、求解器替换、步级钩子等）。用于 **命名对齐、ABI 路由、缺口盘点**。

**非目标**：**不**收录完整 **Fortran 参数签名**（版权与版本漂移）；**接口真源** 以持证 **`D:\TEST7\Manual\USER.pdf`**（及贵司许可的更新版 *User Subroutines Reference Guide*）为准。UFC **字段与行为真源** 仍为各层 **`CONTRACT.md` + 代码**。

**相关**：**`REPORT_Naming_Quad_OnePager_FiveScenes.md`** §1（报告 ID）、§3（**S0–S4**）、§6（本地 PDF 与 **`temp_pdf_extractor.py`**）；**`Pillar_L3L4L5_CrossLayer_Design_Template.md`**；**`user_subroutine_keyword_pages_ABAQUS_USER_6_14.json`**（关键词→页码机读索引，**6.14** 抽检）。

**版本说明**：下列 **子程序清单** 与 **Abaqus 2025 文档体系** 常见口径对齐（Std **34** + Exp **18** + CFD **3**）；若你方 PDF 为 **6.14** 等旧版，以 **实际手册目录** 核对 **增减与签名**，本表仅作 **内部域柱归类**。

---

## 1. 列约定

| 列 | 含义 |
|----|------|
| **子程序** | Abaqus 入口名（Fortran SUBROUTINE） |
| **求解器** | **Std** / **Exp** / **CFD** |
| **UFC 域柱 / 关切** | 主要落点：**Material / Element / Section / Contact / LoadBC / Output / WriteBack**；加 **Constraint**、**Thermal**、**Coupled**（孔隙/固结/质量流等）、**Runtime·Step**、**Solver** 等横切标签 |
| **与 UFC 合订 / 合同** | 优先指向 **REPORTS** 合订文件名或层内 **CONTRACT.md**（不替代真源） |

---

## 2. Abaqus/Standard（34）

**求解器**：本节均为 **Standard**。

| 子程序 | UFC 域柱 / 关切 | 与 UFC 合订 / 合同（入口） |
|--------|-----------------|---------------------------|
| **CREEP** | Material | `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`；蠕变/粘塑 |
| **DFLOW** | Coupled | 固结/孔隙流 |
| **DFLUX** | Thermal · LoadBC | `LoadBC_L3L4L5_four_type_synthesis.md` |
| **DISP** | LoadBC | `LoadBC_L3L4L5_four_type_synthesis.md` |
| **DLOAD** | LoadBC | `LoadBC_L3L4L5_four_type_synthesis.md` |
| **FILM** | Thermal · LoadBC | `LoadBC_L3L4L5_four_type_synthesis.md` |
| **FLOW** | Coupled | 渗透系数（固结相关） |
| **FRIC** | Contact | `Contact_L3L4L5_four_type_synthesis.md` |
| **GAPCON** | Contact · Thermal | `Contact_L3L4L5_four_type_synthesis.md` |
| **GAPELECTR** | Contact | 间隙电导 |
| **HARDINI** | Material | 初始硬化/背应力 |
| **HETVAL** | Thermal · Material | 体积热源 |
| **MPC** | Constraint | 与 **LoadBC** 分界见 LoadBC 合订 §1、`KEYWORD.pdf` |
| **UAMP** | LoadBC | `LoadBC_L3L4L5_four_type_synthesis.md` |
| **UANALYSIS** | Runtime · Step | 步级分析逻辑；对齐 StepDriver / 作业编排（非单一域柱） |
| **UEL** | Element | `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` |
| **UEXPAN** | Material · Thermal | 热膨胀 |
| **UGENS** | Section · Material | `Section_L3L4L5_four_type_synthesis.md` + Material |
| **UHARD** | Material | 硬化曲线 |
| **UMASFL** | Coupled · Thermal | 质量流 |
| **UMAT** | Material | `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` |
| **UMATHT** | Thermal · Material | 热本构 |
| **UMOTION** | LoadBC | 刚体运动学边界 |
| **UPILE** | Contact | 桩–土相互作用 |
| **URDFIL** | WriteBack · I/O | `WriteBack_L3L4L5_four_type_synthesis.md` |
| **USDFLD** | Material · Field | 场变量/状态传递 |
| **USOLVE** | Solver | 自定义线性求解器 |
| **USPRING** | Element · Contact | 弹簧/阻尼（以建模为准） |
| **USTATEV** | Material | SDV 初始化 |
| **UTEMP** | Thermal · LoadBC | 温度边界 |
| **UTRAC** | LoadBC | 面力/牵引 |
| **UVARM** | Output | `Output_L3L4L5_four_type_synthesis.md` |
| **UVEOL** | Coupled | 孔隙体积变化 |
| **UEXTERNALDB** | WriteBack · Runtime | `WriteBack_L3L4L5_four_type_synthesis.md` |

---

## 3. Abaqus/Explicit（18）

**求解器**：本节均为 **Explicit**。

| 子程序 | UFC 域柱 / 关切 | 与 UFC 合订 / 合同（入口） |
|--------|-----------------|---------------------------|
| **VDLOAD** | LoadBC | 与 **DLOAD** 对偶 |
| **VDISP** | LoadBC | 与 **DISP** 对偶 |
| **VFRIC** | Contact | 与 **FRIC** 对偶 |
| **VUAMP** | LoadBC | 与 **UAMP** 对偶 |
| **VUEL** | Element | 与 **UEL** 对偶 |
| **VUMAT** | Material | 与 **UMAT** 对偶 |
| **VUSDFLD** | Material · Field | 与 **USDFLD** 对偶 |
| **VUHARD** | Material | 与 **UHARD** 对偶 |
| **VUINTER** | Contact | 接触本构/交互 |
| **VUINTERACTION** | Contact | 表面交互 |
| **VUMATHT** | Thermal · Material | 与 **UMATHT** 对偶 |
| **VUFIELD** | Material · Field | 预定义场 |
| **VUFLUIDEXCH** | Coupled | 流体交换 |
| **VUFLUIDEXCHEFFAREA** | Coupled | 有效交换面积 |
| **VUGENS** | Section · Material | 与 **UGENS** 对偶 |
| **VUMULLINS** | Material | 损伤/Mullins |
| **VURDFIL** | WriteBack · I/O | 与 **URDFIL** 对偶 |
| **VUEXTERNALDB** | WriteBack · Runtime | 与 **UEXTERNALDB** 对偶 |

---

## 4. Abaqus/CFD（3）

| 子程序 | UFC 域柱 / 关切 | 备注 |
|--------|-----------------|------|
| **CFDUBOUND** | CFD | 边界 |
| **CFDUPHYS** | CFD | 物理模型 |
| **CFDUSOLVER** | CFD · Solver | 与 **RT_SolverType** 中 CFD 路径对偶思考 |

---

## 5. Std ↔ Exp 对偶（速查）

| Standard | Explicit |
|----------|----------|
| UMAT | VUMAT |
| UEL | VUEL |
| UGENS | VUGENS |
| DLOAD | VDLOAD |
| DISP | VDISP |
| UAMP | VUAMP |
| USDFLD | VUSDFLD |
| UHARD | VUHARD |
| UMATHT | VUMATHT |
| FRIC | VFRIC |
| URDFIL | VURDFIL |
| UEXTERNALDB | VUEXTERNALDB |

---

## 6. 维护

- **手册换版**：只核对 **子程序增减与章节位移**；**签名** 以 PDF 为准，**不**在本文件追抄长接口块。  
- **UFC 合同变更**：域柱职责或 **UMAT/VUMAT** 路由变化时，同步检查本表 **「关切」** 列是否仍成立。  
- **页码检索**：增补关键词后重跑 **`UFC/temp_pdf_extractor.py`**，更新 **`REPORTS/user_subroutine_keyword_pages_ABAQUS_USER_6_14.json`**（文件名可随手册版本改名）。

---

*主路径：`UFC/REPORTS/Abaqus_UserSubroutine_UFC_Map.md`。*
