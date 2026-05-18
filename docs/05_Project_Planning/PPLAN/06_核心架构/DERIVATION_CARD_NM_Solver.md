# 推演卡：L2_NM / Solver

> 推演引擎 v1.0 | 2026-04-26 | 域类型：计算域（算法选择 + 迭代推演）

---

## [A] 意图推断

**域**：L2_NM / Solver

**CONTRACT 摘要**：线性/非线性方程组求解——提供 CG、PCG、直接法（LU/Cholesky）、带状法、BFGS 等算法。含收敛检查、线搜索、弧长法。

**核心意图**：
- 初始化求解器工作空间
- 执行线性方程组求解（迭代法/直接法）
- 构造预处理矩阵
- 执行非线性 Newton 步
- 检查收敛性
- 线搜索/弧长法辅助

**Verb 族分布**：Init, Compute, Evolve, Control(Check)

**Phase 分布**：Config, Iteration

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | n, half_bw, is_symmetric, is_spd | 系统配置，求解期间不变 |
| **State** | Y | x(:), b(:), niter, rnorm, dunorm, converged, H_inv | 求解状态，跨迭代演化 |
| **Algo** | Y | method, rtol, atol, maxiter, ls_alpha_init | 算法选择与容差参数 |
| **Ctx** | Y | r(:), p(:), Ap(:), z(:), du(:), neg_R(:), diag(:), K_band, alpha | Krylov 工作向量 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：计算域 → 算法分支 + 迭代流程

**算法路由**（按 Algo.method 分发）：

```
Route(method):
  CG       → CG 迭代 (SPD 矩阵)
  PCG      → 预条件 CG
  DIRECT   → LU/Cholesky 分解 + 回代
  BANDED   → 带状直接法
  GMRES    → GMRES(m) (CONTRACT 中提及，Core 待补)
  BICGSTAB → BiCGSTAB (CONTRACT 中提及，Core 待补)
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(n) | 分配工作向量，初始化 State |
| S2 | Core_Finalize | Config | Init(Finalize) | O(n) | 释放工作向量 |
| S3 | CG | Iteration | Compute(Solve) | O(n*iter) | CG 迭代求解 (callback matvec) |
| S4 | PCG | Iteration | Compute(Solve) | O(n*iter) | 预条件 CG 求解 |
| S5 | Jacobi_Precond | Config | Compute(Build) | O(n) | 构造 Jacobi 预处理对角线 |
| S6 | Direct_Dense | Iteration | Compute(Solve) | O(n^3) | 稠密 LU 分解 + 回代 |
| S7 | Cholesky | Iteration | Compute(Solve) | O(n^3) | Cholesky 分解 + 回代 |
| S8 | Direct_Banded | Iteration | Compute(Solve) | O(n*bw^2) | 带状直接法 |
| S9 | Newton_Step | Iteration | Compute | O(n) | 非线性 Newton 步：du = K^-1 * (-R) |
| S10 | Check_Convergence | Iteration | Control(Check) | O(1) | 收敛检查：rnorm/rnorm0 < tol |
| S11 | Line_Search | Iteration | Compute | O(n) | 线搜索：alpha 使 phi(alpha) 最小 |
| S12 | BFGS_Update | Iteration | Evolve(Update) | O(n^2) | BFGS 逆 Hessian 更新 |
| S13 | Arc_Length_Predict | Iteration | Compute | O(n) | 弧长法预测步 |
| S14 | Arc_Length_Correct | Iteration | Compute | O(n) | 弧长法校正步 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `NM_Solver_Core_Init` | Config | Init | (desc, state, algo, ctx, status) | COLD | _Core.f90 |
| `NM_Solver_Core_Finalize` | Config | Init(Fin) | (desc, state, ctx, status) | COLD | _Core.f90 |
| `NM_Solver_CG` | Iteration | Compute(Solve) | (desc, state, algo, ctx, matvec, status) | HOT | _Core.f90 |
| `NM_Solver_PCG` | Iteration | Compute(Solve) | (desc, state, algo, ctx, matvec, status) | HOT | _Core.f90 |
| `NM_Solver_Jacobi_Precond` | Config | Compute(Build) | (desc, ctx, status) | COLD | _Core.f90 |
| `NM_Solver_Direct_Dense` | Iteration | Compute(Solve) | (n, K_in, b_in, x_out, status) | HOT | _Core.f90 |
| `NM_Solver_Cholesky` | Iteration | Compute(Solve) | (n, K_in, b_in, x_out, status) | HOT | _Core.f90 |
| `NM_Solver_Direct_Banded` | Iteration | Compute(Solve) | (desc, state, ctx, status) | HOT | _Core.f90 |
| `NM_Solver_Newton_Step` | Iteration | Compute | (desc, state, ctx, solve_linear, status) | HOT | _Core.f90 |
| `NM_Solver_Check_Convergence` | Iteration | Control(Check) | (desc, state, algo, ctx, status) | HOT | _Core.f90 |
| `NM_Solver_Line_Search` | Iteration | Compute | (desc, state, algo, ctx, residual_func, status) | HOT | _Core.f90 |
| `NM_Solver_BFGS_Update` | Iteration | Evolve(Update) | (desc, state, ctx, status) | HOT | _Core.f90 |
| `NM_Solver_Arc_Length_Predict` | Iteration | Compute | (n, du_bar, F_ref, ds, ..., status) | HOT | _Core.f90 |
| `NM_Solver_Arc_Length_Correct` | Iteration | Compute | (n, du_total, du_t, du_bar, ..., status) | HOT | _Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| NM_Solver_Def.f90 | 83 | 四型 TYPE 定义 + 方法枚举 |
| NM_Solver_Core.f90 | ~500 | 14 个过程（全部已实现） |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 现有 14 个过程缺少标准 Phase 注释 |
| GMRES | Iteration x Compute(Solve) | P2 | CONTRACT 提及，Core 中未实现（在 LinSolv 子树中） |
| BiCGSTAB | Iteration x Compute(Solve) | P2 | CONTRACT 提及，Core 中未实现（在 LinSolv 子树中） |
| Route(Select_Method) | Config x Control(Route) | P2 | 根据 Algo.method 分发到具体求解器 |

### 评估结论

**NM_Solver 核心过程已完整（14 个），覆盖 CG/PCG/Direct/Cholesky/Banded/Newton/BFGS/ArcLength。** 待补全项为 Phase 注释标注（P1）和 GMRES/BiCGSTAB 迭代器（P2，已在子树中有独立实现）。
