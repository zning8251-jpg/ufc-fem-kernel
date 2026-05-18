# 推演卡综合：L5_RT — 运行时层（非 StepDriver 域）

> 推演引擎 v1.0 | 2026-04-26 | 9 域（StepDriver 见独立卡）
>
> L5 特征：求解器编排层，Phase 覆盖 Step–Local 全范围，HOT_PATH 密集。

---

## Assembly

**域**：L5_RT / Assembly | **域类型**：编排域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：全局刚度阵/力向量/质量阵装配、DOF 映射、BC/约束施加、残差计算

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Asm_Core_Init` | Config | Init | COLD | O(n_dof) |
| `RT_Asm_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Asm_Core_Zero_System` | Iteration | Init(Reset) | HOT | O(nnz) |
| `RT_Asm_Core_Scatter_Ke` | Iteration | Assemble | HOT | O(ndof_e^2) |
| `RT_Asm_Core_Scatter_Fe` | Iteration | Assemble | HOT | O(ndof_e) |
| `RT_Asm_Core_Scatter_Me` | Iteration | Assemble | HOT | O(ndof_e^2) |
| `RT_Asm_Core_Apply_BC` | Iteration | Assemble(Apply) | HOT | O(n_bc) |
| `RT_Asm_Core_Compute_Residual` | Iteration | Compute | HOT | O(n_dof) |
| `RT_Asm_Core_Build_DofMap` | Config | Compute(Build) | COLD | O(n_nodes) |
| `RT_Asm_Core_Assemble_K` | Iteration | Assemble | HOT | O(n_elem) |
| `RT_Asm_Core_Assemble_F` | Iteration | Assemble | HOT | O(n_elem) |
| `RT_Asm_Core_Assemble_M` | Iteration | Assemble | HOT | O(n_elem) |
| `RT_Asm_Core_Apply_Constraints` | Iteration | Assemble(Apply) | HOT | O(n_constr) |

---

## Solver

**域**：L5_RT / Solver | **域类型**：编排域 | **四型**：Desc(Y) State(Y) Algo(Y) Ctx(Y)

**核心意图**：线性/非线性求解编排、收敛判断、增量施加、切回

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Solv_Core_Init` | Config | Init | COLD | O(1) |
| `RT_Solv_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Solv_Core_Solve_Linear` | Iteration | Compute(Solve) | HOT | O(nnz) |
| `RT_Solv_Core_Solve_Nonlinear` | Iteration | Control(Loop) | HOT | O(n_iter*nnz) |
| `RT_Solv_Core_Check_Convergence` | Iteration | Control(Check) | HOT | O(n_dof) |
| `RT_Solv_Core_Apply_Increment` | Increment | Evolve(Advance) | HOT | O(n_dof) |
| `RT_Solv_Core_Cutback` | Increment | Control(Route) | HOT | O(1) |

**关联模块**：`RT_SolvLin`、`RT_SolvNonlin`、`RT_SolvTimeInt`、`RT_SolvSparse`、`Coupling/RT_MFCoordinator`

---

## Element

**域**：L5_RT / Element | **域类型**：编排域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：单元循环编排——调用 L4 `PH_Elem_*` 计算 Ke/Fe/Mass/Stress/内力

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Element_Core_Init` | Config | Init | COLD | O(1) |
| `RT_Element_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Element_Loop_Ke` | Iteration | Control(Loop) | HOT | O(n_elem) |
| `RT_Element_Loop_Fe` | Iteration | Control(Loop) | HOT | O(n_elem) |
| `RT_Element_Loop_Mass` | Iteration | Control(Loop) | HOT | O(n_elem) |
| `RT_Element_Loop_Stress` | Local | Control(Loop) | HOT | O(n_elem*n_gp) |
| `RT_Element_Loop_Internal_Force` | Iteration | Control(Loop) | HOT | O(n_elem) |
| `RT_Element_Get_DOF_Map` | (any) | Access(Get) | COLD | O(1) |

**子域**：`Mesh/`（RT_Mesh* 运行时网格系统）

---

## Material

**域**：L5_RT / Material | **域类型**：编排域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(N)

**核心意图**：运行时材料编排——调用 L4 `PH_Mat_*`、管理状态保存/恢复

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Material_Core_Init` | Config | Init | COLD | O(n_mat) |
| `RT_Material_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Material_Update_Stress` | Local | Compute | HOT | O(1) |
| `RT_Material_Compute_Tangent` | Local | Compute | HOT | O(1) |
| `RT_Material_Init_SDV` | Config | Init | COLD | O(n_sdv) |
| `RT_Material_Save_State` | Increment | Evolve(Commit) | HOT | O(n_sdv) |
| `RT_Material_Restore_State` | Increment | Evolve(Revert) | HOT | O(n_sdv) |

---

## LoadBC

**域**：L5_RT / LoadBC | **域类型**：编排域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：运行时载荷/BC 编排——调用 L4 `PH_LoadBC_*`、幅值求值、增量计算

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_LoadBC_Core_Init` | Config | Init | COLD | O(1) |
| `RT_LoadBC_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_LoadBC_Assemble_Loads` | Iteration | Assemble | HOT | O(n_loads) |
| `RT_LoadBC_Apply_BCs` | Iteration | Assemble(Apply) | HOT | O(n_bc) |
| `RT_LoadBC_Eval_Amplitude` | Iteration | Compute(Evaluate) | HOT | O(1) |
| `RT_LoadBC_Get_Prescribed_Disps` | Iteration | Access(Get) | HOT | O(n_bc) |
| `RT_LoadBC_Compute_Incremental` | Increment | Compute | HOT | O(n_dof) |

---

## Contact

**域**：L5_RT / Contact | **域类型**：编排域 | **四型**：Desc(Y) State(Y) Algo(Y) Ctx(Y)

**核心意图**：运行时接触编排——搜索、评估、装配、状态更新

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Contact_Core_Init` | Config | Init | COLD | O(1) |
| `RT_Contact_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Contact_Search` | Iteration | Compute | HOT | O(n_slave*log(n)) |
| `RT_Contact_Evaluate_Pairs` | Iteration | Compute | HOT | O(n_active) |
| `RT_Contact_Assemble_K` | Iteration | Assemble | HOT | O(n_active) |
| `RT_Contact_Assemble_F` | Iteration | Assemble | HOT | O(n_active) |
| `RT_Contact_Update_Status` | Iteration | Evolve(Update) | HOT | O(n_pairs) |

---

## Output

**域**：L5_RT / Output | **域类型**：编排域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：运行时输出——ODB/HDF5 文件管理、帧写入、频率控制

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Output_Core_Init` | Config | Init | COLD | O(1) |
| `RT_Output_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Output_Open_File` | Config | Init | COLD | O(1) |
| `RT_Output_Close_File` | Config | Init(Fin) | COLD | O(1) |
| `RT_Output_Write_Frame` | Step | Bridge(WriteBack) | COLD | O(n_dof) |
| `RT_Output_Write_Field` | Step | Bridge(WriteBack) | COLD | O(n_nodes) |
| `RT_Output_Write_History` | Step | Bridge(WriteBack) | COLD | O(n_hist) |
| `RT_Output_Check_Frequency` | Step | Control(Check) | COLD | O(1) |

---

## WriteBack

**域**：L5_RT / WriteBack | **域类型**：桥接域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：将位移/应力/SDV/反力等写回 L3 模型侧

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_WriteBack_Core_Init` | Config | Init | COLD | O(1) |
| `RT_WriteBack_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_WriteBack_Displacements` | Step | Bridge(WriteBack) | COLD | O(n_nodes) |
| `RT_WriteBack_Stresses` | Step | Bridge(WriteBack) | COLD | O(n_elem*n_gp) |
| `RT_WriteBack_SDVs` | Step | Bridge(WriteBack) | COLD | O(n_mat*n_sdv) |
| `RT_WriteBack_Reactions` | Step | Bridge(WriteBack) | COLD | O(n_bc) |
| `RT_WriteBack_Execute_All` | Step | Control(Loop) | COLD | O(all) |

---

## Logging

**域**：L5_RT / Logging | **域类型**：观测域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：运行时日志——步头、增量摘要、迭代信息、收敛/切回记录

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `RT_Logging_Core_Init` | Config | Init | COLD | O(1) |
| `RT_Logging_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `RT_Logging_Step_Header` | Step | Access(Log) | COLD | O(1) |
| `RT_Logging_Inc_Summary` | Increment | Access(Log) | COLD | O(1) |
| `RT_Logging_Iteration_Info` | Iteration | Access(Log) | COLD | O(1) |
| `RT_Logging_Convergence` | Iteration | Access(Log) | COLD | O(1) |
| `RT_Logging_Error_Message` | (any) | Access(Log) | COLD | O(1) |
| `RT_Logging_Cutback_Info` | Increment | Access(Log) | COLD | O(1) |
