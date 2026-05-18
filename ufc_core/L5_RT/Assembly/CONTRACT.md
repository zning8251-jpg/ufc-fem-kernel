# Assembly 域级合同卡 (L5_RT)

- **层级**: L5_RT
- **域名**: Assembly / 全局矩阵装配与载荷施加核
- **缩写**: Asm (`RT_Asm_*`)
- **版本**: v3.1
- **更新**: 2026-05-12
- **状态**: ACTIVE

---

## 1. 域职责定义

- **核心职责（一句话）**: 将 L4 局部单元刚度/质量/阻尼/内力贡献（Ke/Me/Ce/Fe）通过 DOF 映射装配为全局系统矩阵/向量（K/M/C/F），并施加边界条件、接触约束与 MPC 约束。
- **职责边界**:
  - **做什么**: 全局矩阵组装（刚度/质量/阻尼）、全局载荷向量组装、DOF 映射构建与管理、CSR 稀疏模式构建、边界条件施加（位移/力/压力）、接触力装配、MPC/Tie/Periodic 约束嵌入、SMP 并行装配（Graph-Coloring/Atomic）、NLGeom 几何非线性求值与调度
  - **不做什么**: 不计算单元 Ke/Fe（L4_PH/Element 负责）；不求解方程组（L5_RT/Solver 或 L2_NM 负责）；不定义网格拓扑（L3_MD/Element/Mesh 负责）；不定义材料本构（L4_PH/Material 负责）
- **非职责**: 不对应 HYPLAS（装配逻辑在 HYPLAS 中分散于 GENERAL/UPDATE）

### Phase6 §3.2 — 正交分派键（Element × Section × Material）

- **模块**：[`RT_Asm_Tripartite.f90`](RT_Asm_Tripartite.f90) — `RT_Asm_TripartiteKey` + `RT_Asm_Tripartite_LinearIndex`（线性化索引，供后续装配查表接线；当前无热路径依赖）。

---

## 2. 四类 TYPE 清单

**AUTHORITY 模块**: `RT_Asm_Def.f90` (`MODULE RT_Asm_Def`)

### 2.1 Desc 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Asm_Desc` | `RT_Asm_Def` | 装配配置（冷，只读） | `assemble_mass/damping/stiffness/loads`, `elem_start/end`, `node_start/end`, `constrained_dofs(:)`, `constraint_types(:)`, `constraint_values(:)`, `is_symmetric`, `is_positive_definite` |

**TBP**: `Init`, `SetRange`, `AddConstraint`, `Finalize`

### 2.2 State 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Asm_State` | `RT_Asm_Def` | 装配进度与矩阵状态（温，频繁更新） | `current_elem`, `assembled_elements`, `total_elements`, `assembly_fraction`, `K/M/f_vector_norm`, `n_nonzero_entries`, `n_constraints_applied`, `K_global(:,:)`, `M_global(:,:)`, `C_global(:,:)`, `f_global(:)` |

**TBP**: `Reset`, `UpdateProgress`, `ComputeNorms`, `AttachMatrices`, `Detach`

### 2.3 Algo 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Asm` | `RT_Asm_Def` | 装配策略（冷，可选） | `assembly_method` (Direct/Element-wise/DomainDecomp), `sparse_format` (Dense/CSR/CSC/Skyline), `parallel_strategy` (Serial/OMP/MPI), `n_threads`, `integration_order`, `use_scaling`, `mass/stiffness_scaling_factor` |

**TBP**: `Init`, `SelectMethod`, `ConfigureParallel`

### 2.4 Ctx 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Asm_Ctx` | `RT_Asm_Def` | 单元级热路径上下文（栈空间，禁 ALLOCATABLE） | `elem_ke(24,24)`, `elem_me(24,24)`, `elem_ce(24,24)`, `elem_fe(24)`, `gp_coords(3,8)`, `gp_weights(8)`, `shape_funcs(8)`, `dndx(3,8)`, `jacobian(3,3)`, `elem_node_ids(8)`, `elem_dof_map(24)`, `stress_gp(:,:,:)`, `strain_gp(:,:,:)` |

**TBP**: `AttachToState`, `ClearElementData`, `ClearGPData`, `Detach`

**附加 Domain 类型** (`RT_Asm_Domain.f90`): `RT_Assembly_Ctx`, `RT_Assembly_State`, `RT_Assembly_Ctrl`, `RT_Assembly_Domain`

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `RT_Asm_Def.f90` | `RT_Asm_Def` | _Def | 四型定义 + TBP（Init/Reset/Finalize 等） | **AUTHORITY** |
| `RT_Asm_Core.f90` | `RT_Asm_Core` | _Core | `RT_Asm_AssemStiff`, `RT_Asm_AssemResid`, `RT_Asm_AssemMass`, `RT_Asm_AssemDamp`, `RT_Asm_AddElemStiff`, `RT_Asm_GetElemDOF`, `RT_Asm_ScatterElemToGlob` + Structured SIO 变体 | **ACTIVE** |
| `RT_Asm_Solv.f90` | `RT_Asm_Solv` | — | `RT_Asm_GlobalStiffness`, `RT_Asm_ComputeResidual`, `RT_Asm_ComputeTangent`, `RT_Asm_GlobalLoad`, `RT_Asm_ApplyBC`, `RT_Asm_ApplyContact`, `RT_Asm_ApplyL3Constraints`, `RT_Asm_Complete`, 多场耦合 (Heat/Electric/Acoustic/Transport/Piezo) | **GOLDEN-LINE** |
| `RT_Asm_DofMap.f90` | `RT_Asm_DofMap` | — | `RT_Asm_DofMap_Build`, `RT_Asm_DofMap_GetEqId`, `RT_Asm_DofMap_GetEqIdByDofType`, `RT_Asm_DofMap_Unified_Cfg/Manage` | **ACTIVE** |
| `RT_Asm_Global.f90` | `RT_Asm_Global` | — | `RT_Asm_Global_Init`, `RT_Asm_Global_ApplyBC_Sparse`, `CSR_AddEntry`, `RT_Asm_BuildGlobSys_Sparse`, `RT_Asm_AssemElems_Sparse` | **ACTIVE** |
| `RT_Asm_Impl.f90` | `RT_Asm_Impl` | _Impl | `RT_Asm_Init_Impl`, `RT_Asm_BuildPattern_Impl`, `RT_Asm_AssembleK/M/F_Impl`, `RT_Asm_ApplyConstraints_Impl`, `RT_Asm_ComputeResidual_Impl`, `RT_Asm_Finalize_Impl` | **ACTIVE** |
| `RT_Asm_Proc.f90` | `RT_Asm_Proc` | _Proc | `RT_Asm_Init`, `RT_Asm_BuildPattern`, `RT_Asm_AssembleK/M/F`, `RT_Asm_ApplyConstraints`, `RT_Asm_ComputeResidual`, `RT_Asm_Finalize` (SIO In/Out) | **ACTIVE** |
| `RT_Asm_Brg.f90` | `RT_Asm_Brg` | _Brg | L3→L5 Populate 桥接；`RT_Asm_Brg_ElemMatPtIdx`（`elem_to_mat_map`）；UMAT Bridge `Apply*Flat_IP` / `Sync*Mirror` | **ACTIVE** |
| `RT_Asm_Domain.f90` | `RT_Asm_Domain` | — | `RT_Assembly_Domain` 生命周期: Init/SyncStepIncr/BuildPattern/GetSummary/Finalize | **ACTIVE** |
| `RT_Asm_MassDamp.f90` | `RT_Asm_MassDamp` | — | 质量矩阵组装 (Consistent/Lumped)、Rayleigh 阻尼、Modal 阻尼 | **ACTIVE** |
| `RT_Asm_NLGeomDispatch.f90` | `RT_Asm_NLGeomDispatch` | — | `RT_Asm_NLGeom_Dispatch_Init`, TL/UL 调度 | **ACTIVE** |
| `RT_Asm_NLGeomEval.f90` | `RT_Asm_NLGeomEval` | _Eval | 变形梯度/Green-Lagrange应变/Almansi应变/几何刚度/应力变换 等 ~45 个计算过程 | **ACTIVE** |
| `RT_Asm_Color.f90` | `RT_Asm_Color` | — | Graph-Coloring 贪心着色、DOF-to-element 逆映射、颜色分组 | **ACTIVE** |
| `RT_Asm_Util.f90` | `RT_Asm_Util` | _Util | `RT_Asm_CSR_FromCSR/ToCSR`, `RT_Asm_GetElemCoords/Density/DOFs/Info` | **ACTIVE** |
| `RT_Asm_ShapeMechanicalField.f90` | `RT_Asm_ShapeMechanicalField` | — | `_GetNumGauss`, `_Supported`, `_Eval` | **ACTIVE** |
| `RT_Asm_ShapeShell.f90` | `RT_Asm_ShapeShell` | — | Shell 形函数求值 | **ACTIVE** |
| `RT_Asm_ShapeMembrane.f90` | `RT_Asm_ShapeMembrane` | — | Membrane 形函数求值 | **ACTIVE** |
| `RT_Asm_ShapeBeam.f90` | `RT_Asm_ShapeBeam` | — | Beam 形函数求值 | **ACTIVE** |
| `RT_Asm_ShapeMech2D.f90` | `RT_Asm_ShapeMech2D` | — | 2D 力学形函数求值 | **ACTIVE** |
| `RT_Asm_ShapeScalarField.f90` | `RT_Asm_ShapeScalarField` | — | 标量场形函数求值 | **ACTIVE** |
| `RT_ElemWS_Default.f90` | — | — | 单元工作空间默认配置 | **ACTIVE** |

**层级合规注记**: `RT_Asm_Shape*.f90` 系列文件承载形函数求值，理论上可归属 L4_PH。当前保留在 L5 因其紧耦合于装配循环；若后续 L4 Element 域需要独立复用形函数，应考虑迁移。

---

## 4. 对外接口（公开 API）

### 4.1 SIO 过程接口 (RT_Asm_Proc)

| 过程名 | In/Out TYPE | 功能 |
|--------|-------------|------|
| `RT_Asm_Init` | `RT_Asm_Init_In/Out` | 装配子系统初始化 |
| `RT_Asm_BuildPattern` | `RT_Asm_BuildPattern_In/Out` | 构建 CSR 稀疏模式 |
| `RT_Asm_AssembleK` | `RT_Asm_AssembleK_In/Out` | 全局刚度矩阵装配 |
| `RT_Asm_AssembleM` | `RT_Asm_AssembleM_In/Out` | 全局质量矩阵装配 |
| `RT_Asm_AssembleF` | `RT_Asm_AssembleF_In/Out` | 全局载荷向量装配 |
| `RT_Asm_ApplyConstraints` | `RT_Asm_ApplyConstraints_In/Out` | 约束施加 |
| `RT_Asm_ComputeResidual` | `RT_Asm_ComputeResidual_In/Out` | 残差计算 |
| `RT_Asm_Finalize` | `RT_Asm_Finalize_In/Out` | 清理释放 |

### 4.2 生产热路径接口 (RT_Asm_Solv — GOLDEN-LINE)

| 过程名 | 功能 |
|--------|------|
| `RT_Asm_GlobalStiffness` | 全局刚度矩阵组装（单元循环→L4 Ke→CSR 散射） |
| `RT_Asm_GlobalStiffness_Idx` | 索引式全局刚度组装 |
| `RT_Asm_ComputeResidual` | 全局残差 R = F_ext - F_int；可选 **`asm_config`** 与 **`RT_Asm_GlobalLoad`** 共用 **`RT_Asm_Cfg`**（`body_force_lumped_to_fext` 等） |
| `RT_Asm_ComputeResidual_Idx` | 索引式残差计算 |
| `RT_Asm_ComputeTangent` | 切线刚度计算 |
| `RT_Asm_GlobalLoad` | 全局外载荷组装 |
| `RT_Asm_ApplyBC` | 边界条件施加（位移罚方法） |
| `RT_Asm_ApplyContact` | 接触贡献装配 → 全局 K/F |
| `RT_Asm_ApplyL3Constraints` | L3 约束（MPC/Tie）嵌入 |
| `RT_Asm_Complete` | 装配完成后处理 |
| `RT_Asm_AssembleK_M_ForModal` | 模态分析 K+M 组装 |
| `RT_Asm_AssembleHeatMatrices` | 热传导矩阵组装 |
| `RT_Asm_AssembleElectricMatrices` | 电场矩阵组装 |
| `RT_Asm_AssembleAcousticMatrices` | 声学矩阵组装 |
| `RT_Asm_AssembleTransportMatrices` | 稳态传输矩阵组装 |
| `RT_Asm_AssemblePiezoCoupling` | 压电耦合组装 |

**L4 绑定（与 `L4_PH/Element/CONTRACT.md` 金线一致）**：`RT_Asm_GlobalStiffness`、`RT_Asm_ComputeResidual` 等在单元循环中调用 **`g_ufc_global%ph_layer%element%Compute_Ke`** / **`%Compute_Fe`**（`PH_Elem_Domain_Desc` TBP），实参类型为 **`PH_Element_Compute_Ke_Arg`** / **`PH_Element_Compute_Fe_Arg`**（`PH_Elem_Def.f90`）；`ke_arg` / `fe_arg` 上的错误状态字段为 **`%status`**（`ErrorStatusType`，**`%status_code`**）。

### 4.3 DOF 映射接口 (RT_Asm_DofMap)

| 过程名 | 功能 |
|--------|------|
| `RT_Asm_DofMap_Build` | 从网格构建全局 DOF 映射 |
| `RT_Asm_DofMap_GetEqId` | 节点→全局方程号查询 |
| `RT_Asm_DofMap_GetEqIdByDofType` | 按 DOF 类型查询方程号 |

---

## 5. 跨层数据流

### 5.1 上游（本域消费）

| 来源层/域 | 提供数据 | 消费方式 | 说明 |
|-----------|---------|---------|------|
| L3_MD/Element/Mesh | 网格拓扑、节点坐标、单元连接 | 经 Populate → `RT_Asm_DofMap` | 仅步初始化阶段 |
| L3_MD/Assembly | Part Instance、DOF schema | 经 Bridge → `RT_Asm_Brg` | 冷路径 |
| L4_PH/Element | 单元刚度 Ke、单元力 Fe | `PH_Element_Compute_Ke/Fe` → 热路径直调 | **核心热路径** |
| L4_PH/Material | 本构切线 C_tan | 经 Element 域间接消费 | 热路径 |
| L4_PH/Contact | 接触力贡献 Kc/Fc | `PH_Cont_*` → `RT_Asm_ApplyContact` | 热路径 |
| L4_PH/LoadBC | 载荷物理侧表示 | `PH_LoadBC_*` → `RT_Asm_ApplyBC` | 热路径 |
| L4_PH/Field | 多场耦合贡献 | `PH_Field_Cpl` → 直接消费 | 现阶段不经中转 |

### 5.2 本层输出（下游消费）

| 输出数据 | 消费者 | 载体 |
|---------|--------|------|
| 全局 K (CSR) | L5_RT/Solver | `RT_CSRMatrix` |
| 全局 F (向量) | L5_RT/Solver | `f_global(:)` |
| 全局 M/C | L5_RT/Solver (动力学) | `M_global`, `C_global` |
| DOF 映射 | L5_RT/Solver | `RT_Sol_DofMap` |
| 残差范数 | L5_RT/StepDriver (收敛判断) | 标量 |
| reanalyze 标志 | L5_RT/Solver | 布尔标志 |

### 5.3 L5 主执行流程

```
StepDriver → RT_Asm_DofMap_Build (步初始化)
         ↓
  [增量步循环]
         ↓
  RT_Asm_GlobalStiffness → 单元循环 → L4 PH_Element_Compute_Ke
         ↓
  局部→全局 DOF 映射 → Triplet_Add → CSR 散射
         ↓
  RT_Asm_GlobalLoad → F_ext（与 §5.4 load_magn_in 分工一致）
         ↓
  RT_Asm_ApplyBC (边界条件)
         ↓
  RT_Asm_ApplyContact (接触约束)
         ↓
  RT_Asm_ApplyL3Constraints (MPC/Tie)
         ↓
  全局 K/F → Solver
```

**热路径零 L3 原则**: 装配过程仅消费 Populate 后的 slot，不在热路径中直读 L3 模块。

### 5.4 全局外力 `F_ext` 与单元 `load_magn_in` / `Compute_Fe`（防双重计数）

| 载体 | 职责 |
|------|------|
| **`F_ext`** | `RT_Asm_GlobalLoad`（`_Idx` 与 Legacy）汇总 CLOAD，以及按 nset / elset / surface 已**离散到节点**的 DLOAD、BODY_FORCE、PRESSURE 等（见 `RT_Asm_GlobalLoad` 实现）。`RT_Asm_AddGeostaticGravity` 等亦直接叠加到 **`F_ext`**。 |
| **`PH_Element_Compute_Fe` → `F_int`** | 残差路径中由 **`RT_Asm_ComputeResidual`** 调用；与 **`R = F_ext - F_int`** 配套。 |
| **`PH_Element_Compute_Fe_Arg%load_magn_in`** | 仅承载 **未** 通过 `GlobalLoad` 进入 **`F_ext`**、且由单元弱式核 **`PH_Elem_Eval_Fe`** 消费的载荷量级（预留 DLOAD 全积分等）。若同一物理项已在 **`F_ext`**，此处 **必须为零**，否则 **`F_ext` 与 `Fe` 双计**。 |
| **`RT_Asm_Cfg%body_force_lumped_to_fext`** | 默认 **`.TRUE.`**：`_Idx` 路径将 `LOAD_BODY_FORCE` 与 DLOAD 等一并 lump 到 **`F_ext`**。置 **`.FALSE.`** 时：`GlobalLoad` **跳过** Domain `LOAD_BODY_FORCE` 的 lump；`RT_Asm_ComputeResidual` 向 **`load_magn_in`** 注入 **`rho_ref * gravity_z`**（与 `step%geo_ctrl` 一致，末维分量）。此时 **勿** 再调用 **`RT_Asm_AddGeostaticGravity`** 叠加同一重力。 |

**约定**: L5 在扩展体力/分布载时，二选一为主真源——**全局节点向量** 或 **单元 `load_magn_in`**——并在 Populate/步驱动文档中显式登记，避免混用。

**注**: `body_force_lumped_to_fext` 作用于 **`RT_Asm_GlobalLoad` 的 Domain `_Idx` 分支**（`LOAD_BODY_FORCE`）以及 **Legacy `step%loadDefs`** 中 **`LoadDef%loadType` 为 `LOAD_BODY_FORCE` / `LOAD_GRAVITY`** 的项（跳过对 **`F_ext`** 的分配，改由 **`RT_Asm_ComputeResidual`** 的 **`load_magn_in`** 路径承载，须与 **`RT_Asm_AddGeostaticGravity`** 互斥）。

**Legacy 接线**: （1）在解析/驱动层对 **`UF_StepDef`**（含 **`AnalysisStep`**) 调用 **`UF_Step_AttachLoadDefs(step, load_array)`**（`load_array` 为 **`TARGET`**、在步生命周期内保持分配）；卸除时 **`UF_Step_ClearLoadDefs`** 或依赖 **`step_destroy`** 中的 **`NULLIFY`**（**`MD_Step_Proc.f90`**）。（2）**自动路径**：**`RT_Asm_GlobalLoad`** 在 **`step%loadDefs`** 未关联且 **`g_ufc_global`** 就绪时，调用 **`UF_Step_BuildLegacyLoadDefs_FromLdbc(g_ufc_global%md_layer%desc%loadbc, model, step_idx, …)`**（**`MD_Step_Sync.f90`** / **`MODULE MD_Step_Sync`**）用 **`MD_LoadBC_Domain`** 当前步载荷填充本地 **`LoadDef(:)`**，再走 Legacy 分布；不写入 **`step%loadDefs`**（**`INTENT(IN)`** 的 **`AnalysisStep`** 不变）。

---

## 6. 域间契约

### 6.1 与 L5 同层其他域的协作关系

| 序号 | 关联域 | 方向 | 契约类型 | 主要接触面 | 备注 |
|------|--------|------|----------|-----------|------|
| R1 | L5_RT/StepDriver | 被调用 | S(服务) | StepDriver 调用组装 | 步/增量驱动 |
| R2 | L5_RT/Solver | 下游供给 | T(类型) | 全局 K/F/M/C → Solver | CSR 输入 |
| R3 | L5_RT/Contact | 协作 | S | 接触贡献嵌入全局矩阵 | `RT_Asm_ApplyContact` |
| R4 | L5_RT/LoadBC | 协作 | S | 载荷/BC 施加 | `RT_Asm_ApplyBC` |

### 6.2 与 L4 对应域的消费关系

| 序号 | L4 域 | 消费内容 | L5 接口 |
|------|-------|---------|---------|
| C1 | L4_PH/Element | Ke/Fe (单元贡献) | `RT_Asm_GlobalStiffness` 内单元循环 |
| C2 | L4_PH/Material | C_tan (切线模量) | 经 Element 域间接 |
| C3 | L4_PH/Contact | Kc/Fc (接触贡献) | `RT_Asm_ApplyContact` |
| C4 | L4_PH/LoadBC | 载荷贡献 | `RT_Asm_ApplyBC` |
| C5 | L4_PH/Field | 多场耦合贡献 | `RT_Asm_Solv` 多场组装接口 |

### 6.3 与 L3 的 Bridge 关系

| 序号 | L3 域 | 数据 | 载体 |
|------|-------|------|------|
| B1 | L3_MD/Element/Mesh | 拓扑/DOF | `RT_Asm_DofMap_Build` |
| B2 | L3_MD/Assembly | Part Instance | `RT_Asm_Brg` |

**跨层主链**: `StepDriver → RT_Asm_DofMap_Build → PH_Element_Compute_Ke/Fe → RT_Triplet_Add / CSR → Solver`。若约束、接触或罚项改变稀疏模式，Assembly 必须显式传播 reanalyze 标志给 Solver。

---

## 7. 验收标准

### 7.1 硬约束

| 编号 | 约束 | 说明 |
|------|------|------|
| H-HOT-01 | 热路径不回 L3 | 装配循环中禁止直读 L3 模块 |
| H-ERR-01 | 不使用 STOP | 错误通过 `ErrorStatusType` 传播 |
| H-CSR-01 | CSR 稀疏格式一致性 | K/M/C 矩阵行列索引与 DOF 映射对齐 |
| H-DEP-01 | 单向依赖 | 不可依赖 L6_AP |

### 7.2 软约束

| 编号 | 约束 | 说明 |
|------|------|------|
| S-TST-01 | 测试覆盖率 | 待建 |
| S-DOC-01 | 子程序级注释 | 新增模块须含 purpose/theory/status 头 |

### 7.3 功能验收

| 编号 | 验收项 | 判定标准 |
|------|--------|---------|
| V-ASM-01 | 线性弹性静力组装 | 简支梁: 位移误差 < 1% 解析解 |
| V-ASM-02 | 质量矩阵一致性 | Consistent/Lumped 总质量守恒 |
| V-ASM-03 | 接触力装配 | Hertz 接触力收敛于解析解 |
| V-ASM-04 | NLGeom 几何刚度 | 悬臂梁大变形屈曲载荷 < 5% 误差 |
| V-ASM-05 | SMP 并行正确性 | 并行装配结果与串行一致 (bit-wise 或 ε < 1e-14) |

---

### SMP 并行装配 (v4.0)

| 装配模式 | 枚举值 | 说明 |
|---------|--------|------|
| `RT_ASM_SERIAL` | 0 | 串行（默认） |
| `RT_ASM_OMP` | 1 | Graph-Coloring 并行 |
| `RT_ASM_ATOMIC` | 2 | ATOMIC 并行 |
| `RT_ASM_MPI` | 3 | 分布式（后续） |

### 错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| CSR 矩阵尺寸不匹配 | `IF_STATUS_INVALID` | 返回 status |
| 单元刚度奇异 | `IF_STATUS_ERROR` | 传播 L4 错误 |
| DOF 映射越界 | `IF_STATUS_INVALID` | 返回 status |

不使用 `STOP`；错误通过 `ErrorStatusType` 传播。

---

### Partial Pillar v2.0 (H3 Assembly)

**半柱分类**: H3 Assembly 是 L3+L5 半贯通柱。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Asm_Def.f90` | **AUTHORITY** — Part Instance/DOF schema | FOUR-TYPE |
| L4 | (不存在) | L4 域提供 Ke/Fe/Ce — Assembly 语义分散 | — |
| L5 | `RT_Asm_Def.f90` | **AUTHORITY** — 全局 K/F 装配四型 (本层) | ACTIVE |
| L5 | `RT_Asm_Solv.f90` | **GOLDEN-LINE** — 生产装配 hub | ACTIVE |
| L5 | `RT_Asm_Core.f90` | FACADE — 补充散射操作 | FACADE |
| L5 | `RT_Asm_Brg.f90` | ACTIVE — L3→L5 Populate | ACTIVE |

**双重 Assembly 语义**: L3 = Part Instance (几何), L5 = Global Matrix Assembly (数值)。

---

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | 有限元全局组装：K_global = Σ Ke，F_global = Σ Fe（含边界、接触、约束） |
| **逻辑链** | StepDriver → Assembly → 遍历单元(L4 Ke/Fe) → Triplet → CSR → Solver |
| **计算链** | DofMap 构建 → 单元循环 → 散射到全局 CSR → BC/Contact 惩罚施加 |
| **数据链** | `RT_Sol_DofMap`(热) + `RT_CSRMatrix`(热) 由 Assembly 创建/维护 → Solver 消费 |

---

*维护注记: 新增装配子模块时在「§3 功能模块清单」和「§4 对外接口」补一行。*
