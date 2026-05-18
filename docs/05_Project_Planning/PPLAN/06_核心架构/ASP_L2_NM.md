# 算法步规约：L2_NM — 数值方法层（5 域）

> **版本**: v1.0 | **日期**: 2026-04-26
>
> L2 特征：计算密集层，Compute 动词为主，被 L4/L5 热路径调用。
>
> **模式**: Base/ExternalLibs=工具域（无状态纯函数）; Matrix=数据域; Solver/TimeInt=计算域

---

## Solver（14 过程 — 计算域核心）

**核心意图**: 线性/非线性方程组求解

### 算法步序列（详细五要素）

#### Step 0: Core_Init

**设计意图**: 根据系统规模 n 分配 Krylov 工作向量 (r, p, Ap, z, du)。

**消费 [IN]**:
| 数据 | 来源 | 生产者 | 温度 |
|------|------|--------|------|
| n (系统规模) | 形参 / desc.n | L5_RT/Assembly.neq | 冷 |

**生产 [OUT]**:
| 数据 | 目标 | 消费者 | 温度 |
|------|------|--------|------|
| ctx.r(n), p(n), Ap(n), z(n) | NM_Solver_Ctx | Step 2–7 | 热 |
| state.x(n), b(n) | NM_Solver_State | Step 2–7 | 热 |
| state.converged = .FALSE. | NM_Solver_State | Step 9 | 温 |

**算法核**: `ALLOCATE(ctx.r(n), ctx.p(n), ctx.Ap(n), ctx.z(n), ...); state.converged=.FALSE.`
**前置条件**: n > 0
**后置保证**: 工作向量已分配，长度 = n
**Phase**: Config | **复杂度**: O(n)

---

#### Step 2: CG — 共轭梯度法

**设计意图**: 求解 SPD 系统 Ax=b。Krylov 子空间迭代，不存储分解——内存友好。

**消费 [IN]**:
| 数据 | 来源 | 生产者 | 温度 |
|------|------|--------|------|
| desc (n, is_spd) | desc | Populate | 冷 |
| algo (rtol, atol, maxiter) | algo | Populate | 冷 |
| matvec (callback) | 形参 | L5_RT/Solver 提供 | — |
| state.b(n) (RHS) | state | L5_RT/Assembly.F | 热 |

**生产 [OUT]**:
| 数据 | 来源 | 消费者 | 温度 |
|------|------|--------|------|
| state.x(n) (解) | state | L5_RT/StepDriver → u | 热 |
| state.niter | state | 外部日志 | 温 |
| state.rnorm | state | Step 9 (收敛检查) | 温 |

**算法核**:
```
r = b - A*x;  p = r;  rr = dot(r,r)
DO iter = 1, maxiter
  Ap = matvec(A, p)
  alpha = rr / dot(p, Ap)
  x = x + alpha * p
  r = r - alpha * Ap
  rr_new = dot(r, r)
  IF (SQRT(rr_new) < atol + rtol*rnorm0) EXIT → converged
  beta = rr_new / rr
  p = r + beta * p
  rr = rr_new
END DO
```

**前置条件**: A 是 SPD; b 已填充
**后置保证**: ||A*x - b|| < atol + rtol*||b||（若收敛）
**Phase**: Iteration (HOT_PATH) | **复杂度**: O(n × niter)

---

#### Step 3: PCG — 预条件共轭梯度法

**消费 [IN]**: 同 CG + ctx.diag(n) (预条件对角线, 来自 Step 4)
**生产 [OUT]**: 同 CG
**算法核**: CG 基础上增加 `z = M^{-1} * r` (Jacobi 预条件)
**复杂度**: O(n × niter) 但收敛更快

---

#### Step 4: Jacobi_Precond — 构造预处理

**设计意图**: 提取对角线构造 Jacobi 预条件 M = diag(A)。

**消费 [IN]**: K_global 对角线 (L5_RT/Assembly)
**生产 [OUT]**: ctx.diag(n) → Step 3 消费
**算法核**: `diag(i) = 1.0/K(i,i)`
**Phase**: Config | **复杂度**: O(n)

---

#### Step 5–7: Direct_Dense / Cholesky / Direct_Banded

**设计意图**: 直接法求解——适用于小系统或带状系统。

| Step | 方法 | 算法核 | 复杂度 |
|------|------|--------|--------|
| 5 | Dense LU | DGESV(n, K, b, x) | O(n³) |
| 6 | Cholesky | DPOTRF + DPOTRS | O(n³/6) |
| 7 | Banded | 带状 LU 分解 + 回代 | O(n × bw²) |

**消费**: K_dense/K_band, b
**生产**: x(n) 精确解
**Phase**: Iteration (HOT_PATH)

---

#### Step 8: Newton_Step — 非线性 Newton 步

**设计意图**: 执行一步 Newton 迭代：du = K⁻¹ × (-R)。不含循环，单步。

**消费 [IN]**: 残差 neg_R, 线性求解器 callback
**生产 [OUT]**: du(n), state.dunorm
**算法核**: `CALL solve_linear(K, neg_R, du); dunorm = NORM2(du)`
**Phase**: Iteration | **复杂度**: O(solve_cost)

---

#### Step 9: Check_Convergence — 收敛判断

**设计意图**: 检查残差范数和位移增量范数是否满足容差。

**消费 [IN]**: state.rnorm, state.dunorm, algo.rtol, algo.atol
**生产 [OUT]**: state.converged (LOGICAL)
**算法核**: `converged = (rnorm < atol + rtol*rnorm0) .AND. (dunorm < atol_u)`
**Phase**: Iteration | **复杂度**: O(1)

---

#### Step 10: Line_Search — 线搜索

**消费**: du(n), residual_func(callback)
**生产**: alpha(wp) 使 ||R(u + alpha*du)|| 最小化
**算法核**: Armijo/Wolfe 回溯
**Phase**: Iteration | **复杂度**: O(n × n_backtracks)

---

#### Step 11: BFGS_Update — 逆 Hessian 更新

**消费**: du, dR (增量), state.H_inv(n,n) 当前逆 Hessian
**生产**: state.H_inv(n,n) 更新后
**算法核**: `H = (I - rho*s*y^T) H (I - rho*y*s^T) + rho*s*s^T`
**Phase**: Iteration | **复杂度**: O(n²)

---

#### Step 12–13: Arc_Length_Predict / Correct

**消费**: du_bar, F_ref, ds (弧长参数)
**生产**: du_total (弧长路径上的增量)
**算法核**: 柱面/球面弧长法
**Phase**: Iteration | **复杂度**: O(n)

---

### Solver 闭合性总矩阵

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| ctx.r/p/Ap/z | Step 0 (alloc) | Step 2–3 | ✓ |
| state.x(n) | Step 2–7 | 外部 (RT_Solver) | ✓ |
| state.rnorm | Step 2–3, 8 | Step 9 | ✓ |
| state.converged | Step 9 | 外部 (RT_StepDriver) | ✓ |
| ctx.diag(n) | Step 4 | Step 3 | ✓ |
| state.H_inv | Step 11 (更新) | Step 8 (Newton with BFGS) | ✓ |

---

## Base（11 过程 — 工具域）

**核心意图**: 3×3 张量运算、Voigt 转换、范数

### 算法步模式: 纯函数，无状态

| 过程 | 消费 | 生产 | 算法核 | 复杂度 |
|------|------|------|--------|--------|
| `NM_Base_Det3x3` | A(3,3) | det(wp) | `det = a11*(a22*a33-a23*a32) - ...` | O(1) |
| `NM_Base_Inv3x3` | A(3,3) | A_inv(3,3), det | 伴随矩阵/行列式 | O(1) |
| `NM_Base_Voigt_To_Tensor` | v(6) | T(3,3) | Voigt→对称张量映射 | O(9) |
| `NM_Base_Tensor_To_Voigt` | T(3,3) | v(6) | 对称张量→Voigt 映射 | O(9) |
| `NM_Base_Outer_Product` | a(3), b(3) | C(3,3) | `C(i,j) = a(i)*b(j)` | O(9) |
| `NM_Base_Dyadic` | a(3), b(3) | C(3,3) | `C(i,j) = a(i)*b(j)` (同上别名) | O(9) |
| `NM_Base_Dev3x3` | A(3,3) | A_dev(3,3) | `A_dev = A - trace(A)/3 * I` | O(9) |
| `NM_Base_Cross3` | a(3), b(3) | c(3) | 向量叉积 | O(1) |
| `NM_Base_Trace3x3` | A(3,3) | tr(wp) | `tr = A(1,1)+A(2,2)+A(3,3)` | O(1) |

**闭合性**: 无状态纯函数，输入→输出无残留。✓

---

## Matrix（8 过程 — 数据域）

**核心意图**: CSR 稀疏矩阵生命周期

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `NM_Matrix_Core_Init` | — | matrix_desc | Config |
| 1 | `NM_Matrix_CSR_Create` | n, nnz_est | csr.row_ptr, col_idx, values | Config |
| 2 | `NM_Matrix_CSR_Insert` | row, col, val | csr 非零元 | Config |
| 3 | `NM_Matrix_CSR_SpMV` | csr, x(n) | y(n) = A*x | Iteration |
| 4 | `NM_Matrix_CSR_Apply_BC` | csr, bc_dofs, bc_vals | csr 修改行/列 | Iteration |
| 5 | `NM_Matrix_CSR_Get_Diag` | csr | diag(n) | (any) |
| 6 | `NM_Matrix_CSR_NNZ` | csr | nnz(i4) | (any) |
| 7 | `NM_Matrix_Core_Finalize` | matrix_desc | — | Config |

### 跨域消费者: L5_RT/Assembly (Create+Insert), L2_NM/Solver (SpMV)

---

## TimeInt（7 过程 — 计算域）

**核心意图**: 动力学时间积分 (Newmark/HHT-α/Central Difference)

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `NM_TimeInt_Core_Init` | n_dof, scheme | state(a,v,u 向量) | 分配状态向量 | Config |
| 1 | `NM_TimeInt_Newmark_Predict` | u_n, v_n, a_n, dt, beta, gamma | u_pred, v_pred | Newmark 预测相 | Increment |
| 2 | `NM_TimeInt_Newmark_Correct` | a_n+1, dt, beta, gamma | u_n+1, v_n+1 | Newmark 校正相 | Increment |
| 3 | `NM_TimeInt_Central_Diff` | u_n, u_n-1, M, F, dt | u_n+1 | `u_{n+1} = 2u_n - u_{n-1} + dt²M⁻¹F` | Increment |
| 4 | `NM_TimeInt_HHT_Alpha` | alpha_f, u, v, a, dt | u_eff, v_eff | HHT-α 数值阻尼 | Increment |
| 5 | `NM_TimeInt_Compute_Stable_DT` | elem_sizes, c_wave | dt_stable | `dt = h_min / c_max` (CFL) | Config |
| 6 | `NM_TimeInt_Core_Finalize` | state | — | 释放 | Config |

### 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| u_pred, v_pred | Step 1 | Step 2 (校正) | ✓ |
| u_n+1, v_n+1 | Step 2/3/4 | 下一增量 Step 1, L5_RT | ✓ |
| dt_stable | Step 5 | L5_RT/StepDriver (显式) | ✓ |

---

## ExternalLibs（7 过程 — 桥接域）

**核心意图**: BLAS/LAPACK 薄封装

### 算法步模式: 无状态透传

| 过程 | 封装对象 | 复杂度 |
|------|---------|--------|
| `NM_Ext_DGEMV` | BLAS L2 矩阵-向量 | O(n²) |
| `NM_Ext_DGEMM` | BLAS L3 矩阵-矩阵 | O(n³) |
| `NM_Ext_DGESV` | LAPACK LU 求解 | O(n³) |
| `NM_Ext_DPOTRF` | LAPACK Cholesky 分解 | O(n³/6) |
| `NM_Ext_DNRM2` | BLAS L1 范数 | O(n) |

**闭合性**: 透传层，输入→输出无状态。✓
