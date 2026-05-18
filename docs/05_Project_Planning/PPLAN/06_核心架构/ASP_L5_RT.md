# 算法步规约：L5_RT — 运行时层（10 域）

> **版本**: v1.0 | **日期**: 2026-04-26
>
> L5 特征：求解器编排层，Phase 覆盖 Step–Local，HOT_PATH 密集。
>
> **详细黄金样板**: [ASP_GOLDEN_RT_StepDriver.md](ASP_GOLDEN_RT_StepDriver.md)

---

## StepDriver（13 过程 — 编排域核心）

> 详见 [ASP_GOLDEN_RT_StepDriver.md](ASP_GOLDEN_RT_StepDriver.md) — 完整 14 步 + 闭合性矩阵 + 状态机视图

**概要数据链**:
```
Populate → Begin_Step → {Begin_Inc → NR_Increment → End_Inc}* → End_Step
```

---

## Assembly（13 过程 — 编排域）

**核心意图**: 全局刚度阵/力向量/质量阵装配、BC 施加、残差计算

### 算法步序列（详细五要素）

#### Step 0: Core_Init

**消费 [IN]**: n_dof (from MD_Assembly.NEQ)
**生产 [OUT]**: K_global(CSR 空壳), F_global(n), dof_map
**算法核**: `ALLOCATE(K.values(nnz), F(n_dof)); F=0; K.values=0`
**Phase**: Config | **复杂度**: O(n_dof)

#### Step 1: Build_DofMap

**消费 [IN]**: L3_MD/Mesh.conn, elem_n_dof_per_node
**生产 [OUT]**: dof_map(n_elem) — 每单元局部 DOF→全局 DOF 映射

**算法核**:
```
DO e = 1, n_elem
  DO n = 1, n_nodes_e
    global_node = conn(n, e)
    DO d = 1, n_dof_per_node
      dof_map(e)%idx(local) = (global_node-1)*n_dof_per_node + d
    END DO
  END DO
END DO
```

**Phase**: Config | **复杂度**: O(n_nodes)

#### Step 2: Zero_System — 清零

**消费 [IN]**: K_global, F_global
**生产 [OUT]**: K.values=0, F=0
**Phase**: Iteration (每次迭代开始清零) | **复杂度**: O(nnz)

#### Step 3: Scatter_Ke — 单元刚度散射

**消费 [IN]**: Ke(ndof_e, ndof_e) from L4_PH/Element, dof_map(e)
**生产 [OUT]**: K_global 对应位置 += Ke

**算法核**:
```
DO i = 1, ndof_e
  DO j = 1, ndof_e
    ig = dof_map(e)%idx(i); jg = dof_map(e)%idx(j)
    K_global(ig, jg) = K_global(ig, jg) + Ke(i, j)
  END DO
END DO
```

**Phase**: Iteration (HOT_PATH) | **复杂度**: O(ndof_e²)

#### Step 4: Scatter_Fe — 单元力散射

**消费**: Fe(ndof_e), dof_map(e)
**生产**: F_global(ig) += Fe(i)
**Phase**: Iteration | **复杂度**: O(ndof_e)

#### Step 5: Scatter_Me — 质量散射（同 Scatter_Ke 结构）

#### Step 6: Apply_BC — Dirichlet BC 施加

**消费 [IN]**: bc_list (from L4_PH/LoadBC), K_global, F_global
**生产 [OUT]**: K_global, F_global 修改后（消元法）
**算法核**: 同 L4_PH/LoadBC.Apply_Dirichlet
**Phase**: Iteration | **复杂度**: O(n_bc)

#### Step 7: Compute_Residual — 残差计算

**消费 [IN]**: F_ext(n), Fint(n) (from 单元内力装配)
**生产 [OUT]**: R(n) = F_ext - Fint → L2_NM/Solver.b / L5_RT/Solver.Check_Convergence

**算法核**: `R(1:n) = F_ext(1:n) - Fint(1:n)`
**Phase**: Iteration (HOT_PATH) | **复杂度**: O(n_dof)

#### Step 8–10: Assemble_K / Assemble_F / Assemble_M — 完整装配循环

**设计意图**: 顶层单元循环编排——遍历所有单元，调用 L4 计算 Ke/Fe/Me，再 Scatter。

**算法核**:
```
CALL Zero_System
DO e = 1, n_elem
  CALL PH_Elem_Core_Compute_Ke(elem(e), ..., Ke, status)   ! L4 调用
  CALL Scatter_Ke(Ke, dof_map(e), K_global)
END DO
```

**Phase**: Iteration | **复杂度**: O(n_elem × Compute_Ke_cost)

#### Step 11: Apply_Constraints

**消费**: T_mpc (from L4_PH/Constraint), K_global, F_global
**生产**: K_modified, F_modified
**Phase**: Iteration | **复杂度**: O(n_constr)

### Assembly 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| dof_map | Step 1 | Step 3,4,5 | ✓ |
| K_global | Step 2→3→6→11 | RT_Solver.Solve_Linear | ✓ |
| F_global | Step 2→4→6→11 | RT_Solver.Solve_Linear | ✓ |
| R (residual) | Step 7 | RT_Solver.Check_Convergence | ✓ |
| Ke | L4_PH/Element | Step 3 | ✓ |
| Fe | L4_PH/Element | Step 4 | ✓ |

---

## Solver（7 过程 — 编排域）

**核心意图**: L5 级求解编排——调用 L2_NM/Solver，管理收敛/切回

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase | 复杂度 |
|------|------|------|------|-------|--------|
| 0 | `RT_Solv_Core_Init` | solver_config | solver_state | Config | O(1) |
| 1 | `RT_Solv_Core_Solve_Linear` | K, b | x(解) via L2_NM | Iteration | O(nnz) |
| 2 | `RT_Solv_Core_Solve_Nonlinear` | callbacks | u(收敛解) | Iteration | O(n_iter×nnz) |
| 3 | `RT_Solv_Core_Check_Convergence` | R_norm, du_norm | converged(LOGICAL) | Iteration | O(n_dof) |
| 4 | `RT_Solv_Core_Apply_Increment` | du, u | u += du | Increment | O(n_dof) |
| 5 | `RT_Solv_Core_Cutback` | — | dt_reduced | Increment | O(1) |

**数据流**: K,F (Assembly) → Solve_Linear (via L2) → du → StepDriver → u_updated

---

## Element（9 过程 — 编排域）

**核心意图**: 运行时单元循环——调用 L4_PH/Element 计算，非自身做计算

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `RT_Element_Core_Init` | elem_desc array | RT_elem_state | Config |
| 1 | `RT_Element_Loop_Ke` | u, elem(:) | Ke(:) → Assembly | Iteration |
| 2 | `RT_Element_Loop_Fe` | u, elem(:) | Fe(:) → Assembly | Iteration |
| 3 | `RT_Element_Loop_Mass` | elem(:) | Me(:) → Assembly | Iteration |
| 4 | `RT_Element_Loop_Stress` | u, elem(:) | stress(:,:) per elem | Local |
| 5 | `RT_Element_Loop_Internal_Force` | stress, elem(:) | Fint(:) → Assembly | Iteration |
| 6 | `RT_Element_Get_DOF_Map` | elem(e) | dof_indices | (any) |

**Loop_Ke 算法核**:
```
DO e = 1, n_elem
  CALL PH_Elem_Core_Compute_Ke(elem(e)%desc, ..., Ke, status)
  CALL RT_Asm_Core_Scatter_Ke(Ke, dof_map(e), K_global)
END DO
```

---

## Material（7 过程 — 编排域）

**核心意图**: 运行时材料编排——状态保存/恢复

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `RT_Material_Core_Init` | n_mat, mat_desc(:) | RT_mat_slots | Config |
| 1 | `RT_Material_Update_Stress` | strain, slot | stress via L4/Material | Local |
| 2 | `RT_Material_Compute_Tangent` | slot | tangent via L4/Material | Local |
| 3 | `RT_Material_Init_SDV` | slot | sdv=0 via L4/Material | Config |
| 4 | `RT_Material_Save_State` | slot.state | slot.state_n = state | Increment |
| 5 | `RT_Material_Restore_State` | slot.state_n | slot.state = state_n | Increment |

**Save/Restore 算法核**:
```
Save:    state_n.stress = state.stress; state_n.sdv = state.sdv   ! commit
Restore: state.stress = state_n.stress; state.sdv = state_n.sdv   ! revert
```

**闭合性**: Save 生产的 state_n 被 Restore 消费（切回时）或被下一增量 Save 覆盖。✓

---

## LoadBC（7 过程 — 编排域）

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `RT_LoadBC_Core_Init` | bc_config | RT_loadbc_state | Config |
| 1 | `RT_LoadBC_Assemble_Loads` | load_cache | F_ext via L4/LoadBC | Iteration |
| 2 | `RT_LoadBC_Apply_BCs` | bc_cache, K, F | K,F modified | Iteration |
| 3 | `RT_LoadBC_Eval_Amplitude` | ampl_id, time | factor(wp) via L3/Analysis | Iteration |
| 4 | `RT_LoadBC_Get_Prescribed_Disps` | bc_cache | u_prescribed(:) | Iteration |
| 5 | `RT_LoadBC_Compute_Incremental` | u_prescribed, u_current | du_bc(:) | Increment |

**数据流**: L3/Boundary → Populate → RT_LoadBC → Assemble_Loads → F_ext → Assembly

---

## Contact（7 过程 — 编排域）

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `RT_Contact_Core_Init` | contact_config | RT_contact_state | Config |
| 1 | `RT_Contact_Search` | x_current(:) | active_pairs via BVH | Iteration |
| 2 | `RT_Contact_Evaluate_Pairs` | active_pairs | gap, F_n, F_t via L4/Contact | Iteration |
| 3 | `RT_Contact_Assemble_K` | K_c from L4 | K_global += K_c | Iteration |
| 4 | `RT_Contact_Assemble_F` | F_c from L4 | F_global += F_c | Iteration |
| 5 | `RT_Contact_Update_Status` | gap, slip_flag | contact_state.status(:) | Iteration |

**数据链**: Search → Evaluate → Assemble_K/F → Assembly → Solve

---

## Output（8 过程 — 编排域）

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `RT_Output_Core_Init` | — | output_desc | Config |
| 1 | `RT_Output_Open_File` | filename | file_handle | Config |
| 2 | `RT_Output_Write_Frame` | u, stress, sdv | → ODB 帧 | Step |
| 3 | `RT_Output_Write_Field` | field_values, nodes | → ODB 场 | Step |
| 4 | `RT_Output_Write_History` | history_values | → ODB 历史 | Step |
| 5 | `RT_Output_Check_Frequency` | inc_num, freq_setting | write_now(LOGICAL) | Step |
| 6 | `RT_Output_Close_File` | file_handle | — | Config |

---

## WriteBack（7 过程 — 桥接域）

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 1 | `RT_WriteBack_Displacements` | u(n_dof) | → L3_MD/Field | Step |
| 2 | `RT_WriteBack_Stresses` | stress(6,n_gp,n_elem) | → L3_MD/Field | Step |
| 3 | `RT_WriteBack_SDVs` | sdv(n_sdv,n_mat) | → L3_MD/Material.state | Step |
| 4 | `RT_WriteBack_Reactions` | R(n_bc) | → L3_MD/Boundary.reaction | Step |
| 5 | `RT_WriteBack_Execute_All` | 全部回写项 | → L3_MD | Step |

**Execute_All 算法核**:
```
CALL RT_WriteBack_Displacements(u, l3_field, status)
CALL RT_WriteBack_Stresses(stress, l3_field, status)
CALL RT_WriteBack_SDVs(sdv, l3_material, status)
CALL RT_WriteBack_Reactions(reaction, l3_boundary, status)
```

---

## Logging（8 过程 — 观测域）

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 1 | `RT_Logging_Step_Header` | step_id, time_start/end | → stdout/file | Step |
| 2 | `RT_Logging_Inc_Summary` | inc_num, dt, n_iters, converged | → stdout | Increment |
| 3 | `RT_Logging_Iteration_Info` | iter_num, rnorm, dunorm | → stdout | Iteration |
| 4 | `RT_Logging_Convergence` | converged, rnorm | → stdout | Iteration |
| 5 | `RT_Logging_Error_Message` | error_status | → stderr | (any) |
| 6 | `RT_Logging_Cutback_Info` | n_cutbacks, old_dt, new_dt | → stdout | Increment |

**数据流模式**: 纯输出型（观测不影响求解）。✓ 全闭合。
