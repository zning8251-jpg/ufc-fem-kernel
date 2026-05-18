# 推演卡补充：L4_PH — Contact & Field

> 推演引擎 v1.0 | 2026-04-26 | Element/Material/LoadBC/Constraint 见独立卡

---

## Contact

**域**：L4_PH / Contact | **域类型**：计算域 | **四型**：Desc(Y) State(Y) Algo(Y) Ctx(Y)

**核心意图**：接触间隙计算、法向力/摩擦力、接触刚度、罚参数、接触状态检查

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `PH_Contact_Core_Init` | Config | Init | COLD | O(1) |
| `PH_Contact_Core_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `PH_Contact_Compute_Gap` | Iteration | Compute | HOT | O(n_pairs) |
| `PH_Contact_Compute_Normal_Force` | Iteration | Compute | HOT | O(n_active) |
| `PH_Contact_Compute_Friction_Force` | Iteration | Compute | HOT | O(n_active) |
| `PH_Contact_Compute_Stiffness` | Iteration | Compute(Build) | HOT | O(n_active) |
| `PH_Contact_Penalty_Param` | Config | Compute | COLD | O(1) |
| `PH_Contact_Check_Status` | Iteration | Control(Check) | HOT | O(n_pairs) |

**子域**：`Search/`（PH_ContSearch, BVH, CCD）、`Friction/`、`Explicit/`、`Self/`、`Thermal/`、`Wear/`、`AI/`

**算法锚定**：

```
Gap → 法向力 → 摩擦力 → 接触刚度 → 状态检查 → 装配
g_n = x_slave - x_master · n
F_n = epsilon_n * <-g_n>_+  (罚法)
F_t = mu * F_n * t           (Coulomb 摩擦)
K_c = d(F)/d(u)              (一致切线)
```

---

## Field

**域**：L4_PH / Field | **域类型**：计算域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：场变量插值/外推/梯度、不变量计算（多物理场贡献）

| 过程名 | Phase | Verb | 热/冷 | 复杂度 |
|--------|-------|------|-------|--------|
| `PH_Field_Ops_Init` | Config | Init | COLD | O(1) |
| `PH_Field_Ops_Finalize` | Config | Init(Fin) | COLD | O(1) |
| `PH_Field_Interpolate_To_IP` | Local | Compute(Interpolate) | HOT | O(n_nodes) |
| `PH_Field_Extrapolate_To_Nodes` | Local | Compute | HOT | O(n_gp) |
| `PH_Field_Average_At_Nodes` | Local | Compute | HOT | O(n_elem) |
| `PH_Field_Gradient_At_IP` | Local | Compute | HOT | O(n_nodes*ndim) |
| `PH_Field_Compute_Invariants` | Local | Compute | HOT | O(1) |

**关联模块**：`PH_Field_ComputeTemp`（温度场）、`PH_Field_ComputePore`（孔压场）、`PH_Field_ComputeConc`（浓度场）、`PH_Field_Cpl`（多物理耦合贡献）。
