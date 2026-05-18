# UFC 子程序模板库 — 索引与使用指南

> **版本**: post-audit v1.0 (2026-04)
> **模板总数**: 112 个 `.f90` 文件
> **标准**: UFC 命名规范 v3.2, Principle #14 (SIO), Phase × Verb 标注

**真源与门禁**：实现与命名以 `ufc_core/`、`rules/ufc-fortran-syntax.mdc`、`rules/ufc-naming.mdc`、域 `CONTRACT.md` 为准。本目录与同指南其余 Markdown、`docs/03_Domain_Pillars/` 中带 Fortran 围栏的文档由 `tools/scan_code_templates_ssot.py` 自动对账（报告 `REPORTS/code_templates_ssot_scan.md`；Harness：`run_harness.py code-templates-ssot`，已并入 `plan-checks`）。

---

## 1. 模板分类索引

### 1.1 Skeleton 三件套（架构核心）

| 文件 | 用途 | SIO | Phase\|Verb |
|------|------|-----|-------------|
| `UFC_Skeleton_Def.f90` | 四型 TYPE 定义骨架 (Desc/State/Algo/Ctx) | N/A | N/A |
| `UFC_Skeleton_Core.f90` | 域核心过程骨架 (Init/Compute/Query/Finalize) | N/A | ✓ |
| `UFC_Skeleton_Brg.f90` | 跨层 Bridge 骨架 (Populate/WriteBack) | N/A | ✓ |

**使用方法**: 复制三件套到 `{Layer}_{Domain}/{Feature}/`, 替换 `{Layer}`, `{Domain}`, `{Feature}` 占位符。

### 1.2 L5_RT — Runtime Proc 模板 (12 个)

| 文件 | 域 | SIO 变体 | Phase\|Verb |
|------|-----|----------|-------------|
| `RT_XXX_StepDriver_Proc.f90` | Step Driver | 6-tuple + RT_Com_Ctx | Orchestrate \| Apply \| COLD |
| `RT_XXX_Elem_Proc.f90` | Element | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_Mat_Proc.f90` | Material | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_Output_Proc.f90` | Output | 6-tuple + RT_Com_Ctx | Output \| Apply \| COLD |
| `RT_XXX_Load_Proc.f90` | Load | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_BC_Proc.f90` | BC | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_Contact_Proc.f90` | Contact | 6-tuple + RT_Com_Ctx | Compute \| Eval \| HOT |
| `RT_XXX_Constraint_Proc.f90` | Constraint | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_Field_Proc.f90` | Field | 6-tuple + RT_Com_Ctx | Compute \| Apply \| HOT |
| `RT_XXX_Assembly_Proc.f90` | Assembly | 5-tuple (无 RT_Com_Ctx) | Compute \| Apply \| HOT |
| `RT_XXX_WriteBack_Proc.f90` | WriteBack | 5-tuple (无 RT_Com_Ctx) | WriteBack \| Apply \| COLD |
| `RT_XXX_Solver_Proc.f90` | Solver | 5-tuple-dual-ctx | Compute \| Apply \| HOT |

#### SIO 变体说明

- **6-tuple**: `(Desc, State, Algo, Ctx, RT_Com_Ctx, args)` — 标准形式，用于需要运行时上下文的域
- **5-tuple**: `(Desc, State, Algo, Ctx, args)` — Assembly/WriteBack 不需要 RT_Com_Ctx
- **5-tuple-dual-ctx**: `(Algo, State, Conv_Ctx, Lin_Ctx, args)` — Solver 使用收敛+线性两个上下文

### 1.3 L5_RT — Runtime Types 模板

| 文件 | 域 |
|------|-----|
| `RT_XXX_StepDriver_Types.f90` | Step Driver |
| `RT_XXX_Constraint_Types.f90` | Constraint |
| `RT_XXX_Field_Types.f90` | Field |
| `RT_Global_Types.f90` | Global |
| `RT_Assembly_Types.f90` | Assembly |
| `RT_Com_Types.f90` | Common |
| `RT_Bridge_Types.f90` | Bridge |
| `RT_Checkpoint_Types.f90` | Checkpoint |
| `RT_Contact_Types.f90` | Contact |
| `RT_Domain_Types.f90` | Domain |
| `RT_Error_Types.f90` | Error |
| `RT_LoadBC_Types.f90` | Load/BC |
| `RT_Monitor_Types.f90` | Monitor |
| `RT_Output_Types.f90` | Output |
| `RT_Parallel_Types.f90` | Parallel |
| `RT_Schedule_Types.f90` | Schedule |
| `RT_Solver_Types.f90` | Solver |
| `RT_State_Types.f90` | State |
| `RT_WriteBack_Types.f90` | WriteBack |

### 1.4 L4_PH — Physics Layer 模板

| 文件 | 域 | Phase\|Verb |
|------|-----|-------------|
| `PH_XXX_Elem.f90` | Element | Compute \| Compute \| HOT |
| `PH_Elem_XXX.f90` | Element (specific) | — |
| `PH_XXX_Mat.f90` | Material | Compute \| Apply \| HOT |
| `PH_XXX_UMAT.f90` | Material (UMAT) | Compute \| Apply \| HOT |
| `PH_XXX_VUMAT.f90` | Material (VUMAT) | Compute \| Apply \| HOT |
| `PH_XXX_UMAT_ULTRA_COMPACT.f90` | Material (UMAT compact) | — |
| `PH_XXX_UEL.f90` | User Element | Compute \| Apply \| HOT |
| `PH_XXX_BC.f90` | BC | Compute \| Apply \| HOT |
| `PH_XXX_Load.f90` | Load | Compute \| Apply \| HOT |
| `PH_XXX_Contact.f90` | Contact | Compute \| Apply \| HOT |
| `PH_XXX_Constraint.f90` | Constraint | Compute \| Apply \| HOT |
| `PH_XXX_Field.f90` | Field | Compute \| Apply \| HOT |
| `PH_XXX_Solver.f90` | Solver | Compute \| Iterate \| HOT |
| `PH_XXX_CFD_BC.f90` | CFD BC | — |
| `PH_Thm_Flux.f90` | Thermal flux | — |
| `PH_Thm_Film.f90` | Thermal film | — |
| `PH_Thm_HeatGen.f90` | Heat generation | — |
| `PH_PLM_J2_UMAT_INTERFACE.f90` | J2 plasticity (UMAT) | — |
| `PH_PLM_J2_UEL_INTERFACE.f90` | J2 plasticity (UEL) | — |
| `PH_Analysis_Group_Router.f90` | Analysis routing | — |
| `RT_AnalysisGroup_Validator.f90` | Analysis group validation | — |

#### PH Types 模板

| 文件 | 域 |
|------|-----|
| `PH_Elem_Types.f90` | Element |
| `PH_Mat_Types.f90` | Material |
| `PH_BC_Types.f90` | BC |
| `PH_Load_Types.f90` | Load |
| `PH_Contact_Types.f90` | Contact |
| `PH_Constraint_Types.f90` | Constraint |
| `PH_Field_Def.f90` | Field |
| `PH_Solver_Types.f90` | Solver |
| `PH_Friction_Types.f90` | Friction |
| `PH_Thermal_Types.f90` | Thermal |
| `PH_Fluid_Types.f90` | Fluid |
| `PH_CFD_Types.f90` | CFD |
| `PH_Explicit_Types.f90` | Explicit |
| `PH_Special_Types.f90` | Special |
| `PH_Misc_Types.f90` | Misc |
| `PH_Analysis_Types.f90` | Analysis |

### 1.5 L3_MD — Model Description 模板

| 文件 | 域 |
|------|-----|
| `MD_Analysis_Types.f90` | Analysis |
| `MD_XXX_Analysis_Types.f90` | Analysis (domain-specific) |
| `MD_Analysis_GroupAware_Desc.f90` | Analysis Group |
| `MD_Amplitude_Types.f90` | Amplitude |
| `MD_BC_Types.f90` | BC |
| `MD_Constraint_Types.f90` | Constraint |
| `MD_Contact_Types.f90` | Contact |
| `MD_Damping_Types.f90` | Damping |
| `MD_DOF_Types.f90` | DOF |
| `MD_Elem_Types.f90` | Element |
| `MD_Field_Types.f90` | Field |
| `MD_Friction_Types.f90` | Friction |
| `MD_Interaction_Types.f90` | Interaction |
| `MD_Load_Types.f90` | Load |
| `MD_Mat_Types.f90` | Material |
| `MD_Material_Types.f90` | Material (extended) |
| `MD_Mat_XXX.f90` | Material (specific model) |
| `MD_Mesh_Types.f90` | Mesh |
| `MD_Model_Types.f90` | Model |
| `MD_Orientation_Types.f90` | Orientation |
| `MD_Output_Types.f90` | Output |
| `MD_Sect_Types.f90` | Section |
| `MD_Solver_Types.f90` | Solver |
| `MD_Step_Types.f90` | Step |
| `MD_XXX_BC.f90` | BC (domain) |
| `MD_XXX_Constraint.f90` | Constraint (domain) |
| `MD_XXX_Contact.f90` | Contact (domain) |
| `MD_XXX_Domain_Types.f90` | Domain (generic) |
| `MD_XXX_Elem.f90` | Element (domain) |
| `MD_XXX_Field.f90` | Field (domain) |
| `MD_XXX_Load.f90` | Load (domain) |
| `MD_XXX_Output.f90` | Output (domain) |
| `MD_XXX_Solver.f90` | Solver (domain) |

### 1.6 L2_NM & Cross-Layer 模板

| 文件 | 域 | 说明 |
|------|-----|------|
| `NM_Matrix_Domain_Template.f90` | Matrix | Domain 容器参考实现 |
| `RT_Material_Domain_Template.f90` | Material | Domain 容器参考实现 |
| `RT_Solver_Domain_Template.f90` | Solver | Domain 容器参考实现 |
| `UFC_Memory_Strategy.f90` | Common | 内存生命周期策略 |
| `UFC_Populate_Template.f90` | Common | Populate 阶段参考模板 |
| `UFC_Abaqus_TYPE_Matrix.f90` | Common | ABAQUS TYPE 映射矩阵 |

### 1.7 LEGACY 文件（仅供参考）

| 文件 | 说明 |
|------|------|
| `ElemLib.f90` | 单元库参考实现，**不符合** UFC v3 命名（小写 module/type 无层前缀） |
| `ElemGaussInt.f90` | 高斯积分参考实现，**不符合** UFC v3 命名 |

---

## 2. 使用指南: Copy-Rename Checklist

### 2.1 新建域模板 (Skeleton 三件套)

1. 复制 `UFC_Skeleton_Def.f90` → `{L}_{Domain}_Def.f90`
2. 复制 `UFC_Skeleton_Core.f90` → `{L}_{Domain}_Core.f90`
3. 复制 `UFC_Skeleton_Brg.f90` → `{L}_{Domain}_Brg.f90`
4. 全局替换:
   - `{Layer}` → 实际层缀 (如 `MD`, `PH`, `RT`)
   - `{Domain}` → 域缩写 (如 `Mat`, `Elem`, `Load`)
   - `{Feature}` → 功能集 (如 `J2`, `C3D8`)
5. 验证: `MODULE` 名 = 文件名 stem

### 2.2 新建 RT_Proc

1. 选择最接近的 RT_XXX_*_Proc.f90 模板
2. 确认 SIO 变体 (6-tuple / 5-tuple / 5-tuple-dual-ctx)
3. 替换 `XXX` 为实际域名
4. 填充 Phase|Verb 标注

### 2.3 新建 PH 物理层实现

1. 从 `PH_XXX_UMAT.f90` (Standard) 或 `PH_XXX_VUMAT.f90` (Explicit) 开始
2. 替换 `XXX` 为材料族 + 模型名
3. 实现 `_Impl` 中的本构算法
4. 补充 `USE MD_Mat_XXX, ONLY: ...` 引用

---

## 3. 约束与规范

- **MODULE = Filename stem**: 每个 `.f90` 文件的 `MODULE` 声明必须等于文件名去掉 `.f90`
- **精度**: `USE IF_Prec_Core, ONLY: wp, i4` — 禁止 `ISO_FORTRAN_ENV` 或自定义 KIND
- **常量**: TYPE 字段默认值必须使用全限定 PARAMETER 名 (如 `MD_MAT_ELAS_ISOTROPIC`)
- **层级前缀**: MD 模块只用 `MD_*` 常量，PH 模块只用 `PH_*` 常量
- **SIO**: 层间边界和 L5 `_Proc` 必须标注 `!>>> SIO_VARIANT`
- **Phase|Verb**: 公开过程必须标注 `! Phase: ... | Verb: ... | COLD_PATH|HOT_PATH`
