# 算法步规约：L4_PH — 物理层（7 域）

> **版本**: v1.0 | **日期**: 2026-04-26
>
> L4 特征：FEM 核心计算层，Compute 密集，HOT_PATH 集中地。
>
> **详细黄金样板**: [ASP_GOLDEN_PH_Mat_Elas.md](ASP_GOLDEN_PH_Mat_Elas.md)

---

## Element（9 过程 — 计算域核心）

**核心意图**: 形函数→Jacobian→B阵→高斯积分→Ke/Fe/Fint/Mass

### 算法步序列（详细五要素）

#### Step 0: Populate (Bridge)

**消费 [IN]**: L3_MD/Mesh.coords, Section.thickness, Section.int_order
**生产 [OUT]**: elem_desc (n_nodes, n_dof_per_node, n_int_points, coords_cache)
**Phase**: Populate

---

#### Step 1: Compute_Ke — 单元刚度阵（金线）

**设计意图**: 高斯积分核心——构造单元刚度矩阵 Ke = ∫ B^T C_tan B dΩ。FEM 的计算瓶颈。

**消费 [IN]**:
| 数据 | 来源 | 生产者 | 温度 |
|------|------|--------|------|
| desc (n_nodes, coords) | elem_desc | Step 0 (Populate) | 冷 |
| algo (integration_order) | elem_algo | Populate | 冷 |
| tangent(6,6) 或 callback | PH_Material | PH_Mat_*.Compute_Tangent | 热 |

**生产 [OUT]**:
| 数据 | 来源 | 消费者 | 温度 |
|------|------|--------|------|
| Ke(ndof,ndof) | ctx.Ke_local | L5_RT/Assembly.Scatter_Ke | 热 |

**算法核**:
```
Ke = 0
DO gp = 1, n_gp
  ! 形函数及其导数
  CALL Shape_Functions(xi(gp), N, dNdxi)
  ! Jacobian
  J = dNdxi * coords;  detJ = Det3x3(J);  Jinv = Inv3x3(J)
  ! B-矩阵 (应变-位移关系)
  dNdx = Jinv * dNdxi
  B = Strain_Displacement_Matrix(dNdx)
  ! 刚度积分
  Ke = Ke + w(gp) * MATMUL(TRANSPOSE(B), MATMUL(C_tan, B)) * detJ
END DO
```

**前置条件**: coords 有效 (detJ > 0 at all GP), C_tan SPD
**后置保证**: Ke 对称 (Ke(i,j)=Ke(j,i)), Ke 半正定
**Phase**: Local (HOT_PATH) | **复杂度**: O(n_gp × ndof²)

---

#### Step 2: Compute_Fe — 单元力向量

**消费 [IN]**: B-matrix (同 Step 1), stress(6) from Material
**生产 [OUT]**: Fe(ndof) → L5_RT/Assembly.Scatter_Fe

**算法核**:
```
Fe = 0
DO gp = 1, n_gp
  B = (from cache or recompute)
  Fe = Fe + w(gp) * MATMUL(TRANSPOSE(B), stress(:,gp)) * detJ(gp)
END DO
```

**Phase**: Local (HOT_PATH) | **复杂度**: O(n_gp × ndof)

---

#### Step 3: Compute_Fint — 单元内力

**消费 [IN]**: 同 Step 2
**生产 [OUT]**: Fint(ndof) → L5_RT/Assembly.Assemble_F (减法: R = Fext - Fint)

**算法核**: 与 Fe 相同结构，符号对应 Fint = ∫ B^T σ dΩ
**Phase**: Local (HOT_PATH)

---

#### Step 4: Compute_Mass — 单元质量阵

**消费 [IN]**: N (形函数), rho (密度 from Material.Desc)
**生产 [OUT]**: Me(ndof,ndof) → L5_RT/Assembly.Scatter_Me

**算法核**:
```
Me = 0
DO gp = 1, n_gp
  Me = Me + w(gp) * rho * MATMUL(TRANSPOSE(N), N) * detJ(gp)
END DO
```

**Phase**: Local (HOT_PATH) | **复杂度**: O(n_gp × ndof²)

---

#### 查询步 (Get_NDof, Get_NNodes)

**算法核**: `result = desc.n_nodes * desc.n_dof_per_node`
**Phase**: (any) | **复杂度**: O(1)

### Element 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| desc (coords, n_nodes) | Populate | Step 1–4 | ✓ |
| C_tan(6,6) | PH_Material.Compute_Tangent | Step 1 | ✓ |
| stress(6) | PH_Material.Compute_Stress | Step 2, 3 | ✓ |
| Ke(ndof,ndof) | Step 1 | RT_Assembly.Scatter_Ke | ✓ |
| Fe(ndof) | Step 2 | RT_Assembly.Scatter_Fe | ✓ |
| Fint(ndof) | Step 3 | RT_Assembly (residual) | ✓ |
| Me(ndof,ndof) | Step 4 | RT_Assembly.Scatter_Me | ✓ |

---

## Material 域级（6 过程 — 分发域）

**核心意图**: 注册路由 + 族内核分发

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 |
|------|------|-----------|-----------|--------|
| 0 | `PH_Mat_Core_Init` | n_mat_slots | domain(空slot池) | 分配 slot 数组 |
| 1 | `PH_Mat_Core_Update_Stress` | slot.desc, strain_inc | slot.state.stress | `SELECT CASE(matModel)` → 族内核 |
| 2 | `PH_Mat_Core_Compute_Tangent` | slot.desc, slot.state | tangent(6,6) | `SELECT CASE(matModel)` → 族内核 |
| 3 | `PH_Mat_Core_Init_SDV` | slot.desc | slot.state.stateVars | 族内核 Init_SDV |
| 4 | `PH_Mat_Core_Get_NSDV` | slot.desc | nsdv(i4) | 查询状态变量数 |
| 5 | `PH_Mat_Core_Finalize` | domain | — | 释放所有 slot |

**Route 算法核（Step 1 详细）**:
```
SELECT CASE (slot%desc%matModel)
  CASE (MAT_ELASTIC)
    CALL PH_Mat_Elas_Compute_Stress(slot%elas_ctx, strain, stress, status)
  CASE (MAT_J2_PLASTIC)
    CALL PH_MatPlast_J2_Compute_Stress(slot%plast_ctx, strain_inc, stress, status)
  CASE (MAT_HYPERELASTIC)
    CALL PH_MatHyper_Compute_Stress(slot%hyper_ctx, F_def, stress, status)
  CASE (MAT_UMAT)
    CALL PH_UserSub_UMAT(slot%umat_ctx, strain_inc, stress, sdv, status)
  ...
END SELECT
```

### Material/Elas 子域

> 详见 [ASP_GOLDEN_PH_Mat_Elas.md](ASP_GOLDEN_PH_Mat_Elas.md) — 完整 7 步 + 闭合性矩阵

---

## LoadBC（9 过程 — 混合域）

**核心意图**: 载荷向量组装 + Dirichlet BC 施加

### 算法步序列（详细五要素）

#### Step 0: Populate (Bridge)

**消费**: L3_MD/Boundary.bc_list, amplitude_funcs
**生产**: PH_LoadBC_Desc (load_cache, bc_cache)

---

#### Step 1: Concentrated_Force — 集中力

**消费 [IN]**:
| 数据 | 来源 | 温度 |
|------|------|------|
| load_cache.concentrated(:) | Desc (Populate) | 冷 |
| amplitude_factor | L3_MD/Analysis.Eval_Amplitude | 温 |
| time_current | L5_RT/StepDriver.Get_Current_Time | 温 |

**生产 [OUT]**:
| 数据 | 消费者 | 温度 |
|------|--------|------|
| F_ext(dof_idx) += factor * value | L5_RT/Assembly.Assemble_F | 热 |

**算法核**: `DO i_load, F_ext(dof) = F_ext(dof) + ampl(time) * load_value`
**Phase**: Iteration | **复杂度**: O(n_loads)

---

#### Step 2–5: Distributed / Pressure / Body / Gravity / Thermal

| Step | 过程 | 算法核 | 复杂度 |
|------|------|--------|--------|
| 2 | Distributed_Load | 面/线积分: `∫ N^T q dS` | O(n_face × n_gp) |
| 3 | Pressure_Load | 法向压力: `∫ N^T p·n dS` | O(n_face × n_gp) |
| 4 | Body_Force | 体积力: `∫ N^T b dΩ` | O(n_elem × n_gp) |
| 5 | Gravity_Load | 简化体力: `f_g = rho * g * V_e` | O(n_elem) |
| 6 | Thermal_Load | 热应变力: `∫ B^T D α ΔT dΩ` | O(n_elem × n_gp) |

**共同消费**: 形函数 N, B, detJ (来自 Element), 幅值 (来自 Analysis)
**共同生产**: F_ext 向量各分量 → L5_RT/Assembly

---

#### Step 7: Apply_Dirichlet — BC 施加

**消费 [IN]**: bc_cache.dirichlet(:), K_global, F_global
**生产 [OUT]**: 修改后的 K_global, F_global

**算法核（消元法）**:
```
DO i_bc = 1, n_bc
  dof = bc(i_bc)%dof_global
  val = bc(i_bc)%value * ampl_factor
  F = F - K(:,dof) * val       ! 右端修正
  K(dof,:) = 0; K(:,dof) = 0   ! 行/列清零
  K(dof,dof) = 1; F(dof) = val ! 对角线置 1
END DO
```

**Phase**: Iteration | **复杂度**: O(n_bc)

### LoadBC 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| load_cache | Populate | Step 1–6 | ✓ |
| F_ext(各分量) | Step 1–6 | RT_Assembly.Assemble_F | ✓ |
| K_modified | Step 7 | RT_Solver.Solve_Linear | ✓ |
| ampl_factor | L3/Analysis.Eval_Amplitude | Step 1–7 | ✓ |

---

## Constraint（7 过程 — 计算域）

**核心意图**: MPC/Tie/Periodic 约束的数值形式

### 算法步序列

#### Step 1: Build_MPC_Transform — 变换矩阵

**消费 [IN]**: constraint_desc (master, slaves, coeffs)
**生产 [OUT]**: T_mpc(n_eq, n_eq) 变换矩阵
**算法核**: 构造 u_slave = T_s * u_master 的稀疏变换矩阵
**Phase**: Iteration | **复杂度**: O(n_mpc × n_dof)

#### Step 2: Apply_Penalty — 罚函数施加

**消费 [IN]**: constraint_desc, K_global, F_global, alpha(罚因子)
**生产 [OUT]**: K_global += alpha·C^T·C; F_global += alpha·C^T·g
**Phase**: Iteration | **复杂度**: O(n_constr)

#### Step 3: Build_Lagrange — 拉格朗日扩充

**消费 [IN]**: constraint_desc
**生产 [OUT]**: K_aug, F_aug (扩充方程组)
**算法核**: `[K C^T; C 0] [u; λ]^T = [F; g]`
**Phase**: Iteration | **复杂度**: O(n_constr)

#### Step 4: Compute_Reaction — 约束反力

**消费 [IN]**: u(solved), constraint_desc
**生产 [OUT]**: reaction(:) → L5_RT/WriteBack
**Phase**: Iteration | **复杂度**: O(n_constr)

#### Step 5: Check_Violation — 违规检查

**消费 [IN]**: u(current), constraint_desc
**生产 [OUT]**: max_violation(wp), violation_count(i4)
**算法核**: `viol(i) = |C(i,:)*u - g(i)|; max_viol = MAXVAL(viol)`
**Phase**: Iteration | **复杂度**: O(n_constr)

---

## Contact（8 过程 — 计算域）

**核心意图**: 接触间隙→法向力→摩擦力→接触刚度

### 算法步序列

| Step | 过程 | 消费 | 生产 | 算法核 | Phase | 复杂度 |
|------|------|------|------|--------|-------|--------|
| 0 | Populate | L3/Interaction | desc (pairs, friction) | Bridge | Populate | O(1) |
| 1 | `Penalty_Param` | desc, elem_size | epsilon_n, epsilon_t | `eps = alpha * E * h` | Config | O(1) |
| 2 | `Compute_Gap` | x_slave, x_master, normal | g_n(:) | `g_n = (x_s - x_m) · n` | Iteration | O(n_pairs) |
| 3 | `Compute_Normal_Force` | g_n, epsilon_n | F_n(:) | `F_n = eps_n * <-g_n>_+` | Iteration | O(n_active) |
| 4 | `Compute_Friction_Force` | F_n, v_tangent, mu | F_t(:) | `F_t = mu * F_n * t` (Coulomb) | Iteration | O(n_active) |
| 5 | `Compute_Stiffness` | F_n, F_t, dg/du | K_c(:,:) | 一致切线 dF/du | Iteration | O(n_active) |
| 6 | `Check_Status` | g_n | active/inactive/slip/stick | 状态判断 | Iteration | O(n_pairs) |

### Contact 数据链

```
x_slave, x_master (Element coords)
  → Compute_Gap → g_n
    → Compute_Normal_Force → F_n
      → Compute_Friction_Force → F_t
        → Compute_Stiffness → K_c
          → RT_Assembly.Scatter (装配)
```

**闭合性**: 链式依赖，每步生产恰被下一步消费。✓

---

## Field（7 过程 — 计算域）

**核心意图**: 场变量插值/外推/梯度

### 算法步序列

| Step | 过程 | 消费 | 生产 | 算法核 | 复杂度 |
|------|------|------|------|--------|--------|
| 1 | `Interpolate_To_IP` | nodal_values, N(shape_funcs) | ip_value | `v_ip = N^T * v_nodal` | O(n_nodes) |
| 2 | `Extrapolate_To_Nodes` | ip_values(:,n_gp) | nodal_values | 最小二乘外推 | O(n_gp) |
| 3 | `Average_At_Nodes` | elem_nodal(:,:) | averaged_nodal | 补丁恢复平均 | O(n_elem) |
| 4 | `Gradient_At_IP` | nodal_values, dNdx | grad(ndim) | `∇v = dNdx^T * v_nodal` | O(n_nodes×ndim) |
| 5 | `Compute_Invariants` | stress(6) | p, q, J3 | `p=I1/3; q=√(3J2); J3=det(s)` | O(1) |

**跨域消费者**: L5_RT/Output (外推到节点用于可视化); L4_PH/Material (梯度用于大变形)
