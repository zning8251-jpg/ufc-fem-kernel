# L2_NM 数值算法层 — 完整域级拆解 v1.0

> **层级**: L2_NM (Numerical Method Layer)  
> **版本**: v1.0  
> **层级职责**: 线性代数、矩阵求解、非线性求解、时间积分  
> **域级总数**: 5 个  
> **子域总数**: 10 个  
> **功能模块总数**: 42 个  
> **命名前缀**: `NM_` (Numerical Method)

---

## 📋 L2_NM 层拓扑结构

```
L2_NM (数值算法层)
│
├─ Base — 基础数学工具
├─ Matrix — 矩阵存储与运算（Dense/Sparse）
├─ Solver — 求解器（Linear/Nonlinear/Eigenvalue）
├─ TimeInt — 时间积分（Implicit/Explicit/Adaptive）
└─ Bridge — 与 L3_MD 连接
```

---

## 🎯 一、五个域级完整拆解

### 1.1 域级 1: **Base** — 基础数值工具

**职责**: 向量/矩阵基础操作、范数计算、线性代数工具库

**子域**: 无

**功能模块** (6 个):
```
NM_Base_Desc.f90          — 基本数学常数与参数
NM_Base_Vector.f90        — 向量操作 (DGEMV等)
NM_Base_Matrix.f90        — 矩阵基础操作
NM_Base_Norm.f90          — 范数与收敛判据
NM_Base_Precond.f90       — 预条件子基础
NM_Base_Ctx.f90           — 数值上下文
```

### 1.2 域级 2: **Matrix** — 矩阵管理体系

**职责**: 密集/稀疏矩阵存储、转换、装配

**子域** (2 个):
- **Dense** — 密集矩阵 (CSR, Full)
- **Sparse** — 稀疏矩阵 (COO, CSR, CSC)

**功能模块** (12 个):
```
NM_Mat_Desc.f90           — 矩阵元数据
NM_Mat_Assemble.f90       — 矩阵装配逻辑
NM_Mat_Dense_Desc.f90     — Dense TYPE 定义
NM_Mat_Dense_Convert.f90  — Dense 格式转换
NM_Mat_Sparse_Desc.f90    — Sparse TYPE 定义
NM_Mat_Sparse_COO.f90     — COO 格式实现
NM_Mat_Sparse_CSR.f90     — CSR 格式实现
NM_Mat_Sparse_CSC.f90     — CSC 格式实现
NM_Mat_SpMV.f90           — 稀疏矩阵向量乘
NM_Mat_Permute.f90        — 矩阵重排序
NM_Mat_Scale.f90          — 矩阵缩放
NM_Mat_Ctx.f90            — 矩阵上下文
```

### 1.3 域级 3: **Solver** — 求解器框架

**职责**: 线性/非线性/特征值求解器

**子域** (4 个):
- **Linear** — 直接求解器 (LU/Cholesky/QR)
- **Nonlinear** — 迭代求解器 (Newton-Raphson/Line Search)
- **Eigenvalue** — 特征值求解 (Lanczos/Jacobi)
- **Iterative** — 迭代求解 (GMRES/BICG)

**功能模块** (14 个):
```
NM_Solv_Desc.f90          — 求解器配置
NM_Solv_Lin_Direct.f90    — 直接求解 (LU)
NM_Solv_Lin_Chol.f90      — Cholesky 分解
NM_Solv_Lin_QR.f90        — QR 分解
NM_Solv_NL_NR.f90         — Newton-Raphson
NM_Solv_NL_LineSearch.f90 — 线搜索
NM_Solv_NL_Trust.f90      — 信任域方法
NM_Solv_EV_Lanczos.f90    — Lanczos 迭代
NM_Solv_EV_Jacobi.f90     — Jacobi 旋转
NM_Solv_IT_GMRES.f90      — GMRES 迭代
NM_Solv_IT_BICG.f90       — BiCG 迭代
NM_Solv_State.f90         — 求解器状态
NM_Solv_Algo.f90          — 求解算法选择
NM_Solv_Ctx.f90           — 求解器上下文
```

### 1.4 域级 4: **TimeInt** — 时间积分体系

**职责**: 隐式/显式/自适应时间步长

**子域** (3 个):
- **Implicit** — 隐式格式 (Newmark/HHT/中点)
- **Explicit** — 显式格式 (中心差分/RK4)
- **Adaptive** — 自适应步长 (Runge-Kutta 错误控制)

**功能模块** (8 个):
```
NM_Time_Desc.f90          — 时间参数
NM_Time_Imp_Newmark.f90   — Newmark 格式
NM_Time_Imp_HHT.f90       — HHT-α 格式
NM_Time_Imp_MidPoint.f90  — 中点格式
NM_Time_Exp_Leapfrog.f90  — Leapfrog 格式
NM_Time_Exp_RK2.f90       — Runge-Kutta 2 阶
NM_Time_Exp_RK4.f90       — Runge-Kutta 4 阶
NM_Time_Adapt.f90         — 自适应步长 & Ctx
```

### 1.5 域级 5: **Bridge** — 与上层连接

**职责**: L2_NM ↔ L3_MD 的接口适配

**子域**: 无

**功能模块** (2 个):
```
NM_Bridge_L3.f90          — L2→L3 数据转换
NM_Bridge_Ctx.f90         — 桥接上下文
```

---

## 📊 二、L2_NM 层模块统计

| 序号 | 域级 | 子域数 | 模块数 | 关键功能 | 优先级 |
|------|------|--------|--------|----------|--------|
| 1 | Base | 0 | 6 | 向量/矩阵/范数 | ⭐⭐⭐ |
| 2 | Matrix | 2 | 12 | 矩阵存储/转换 | ⭐⭐⭐ |
| 3 | Solver | 4 | 14 | 直接/迭代求解 | ⭐⭐⭐ |
| 4 | TimeInt | 3 | 8 | 隐式/显式时间积分 | ⭐⭐⭐ |
| 5 | Bridge | 0 | 2 | 层间连接 | ⭐⭐ |
| **合计** | | **10** | **42** | | |

---

## 🔗 三、命名规范

**层前缀**: `NM_`

**子域前缀**:
- Base → NM_Base_*
- Matrix → NM_Mat_* (Dense/Sparse 不单独前缀)
- Solver → NM_Solv_* (Linear/Nonlinear/Eigenvalue 不单独前缀)
- TimeInt → NM_Time_*
- Bridge → NM_Bridge_*

**约束**: 所有四型必须贯通，Solver 和 TimeInt 域级涉及复杂算法，应严格设计 Desc/State/Algo/Ctx

---

## ✅ 交付清单

- ✅ 5 个域级、10 个子域、42 个模块的完整设计
- ✅ 命名规范统一
- ✅ 四型规范贯通
- ✅ 与 L1_IF、L3_MD 的接口定义

**下一步**: 阶段 2.3 — L3_MD 层完整拆解
