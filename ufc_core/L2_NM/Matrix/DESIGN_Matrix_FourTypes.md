# 四大功能集详细设计文档 — Matrix 域

> **文档位置**: `L2_NM/Matrix/DESIGN_Matrix_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L2_NM/Matrix 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：稠密矩阵、稀疏矩阵（CSR/CSC）、矩阵分解、矩阵乘法、SpMV

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `matrix_type` | INTEGER(i4) | 矩阵类型：1=Dense, 2=CSR, 3=CSC, 4=Symmetric | NM_Matrix_Desc |
| `nrows` | INTEGER(i4) | 行数 | NM_Matrix_Desc |
| `ncols` | INTEGER(i4) | 列数 | NM_Matrix_Desc |
| `storage_format` | INTEGER(i4) | 存储格式：1=Row-Major, 2=Col-Major | NM_Matrix_Desc |
| `is_symmetric` | LOGICAL | 对称矩阵标志 | NM_Matrix_Desc |

**生命周期**：
- **写入阶段**：矩阵分配时
- **读取阶段**：矩阵操作全过程
- **释放时机**：矩阵销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 矩阵级生命周期

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `nnz` | INTEGER(i8) | 非零元个数（稀疏矩阵） | NM_Matrix_State |
| `is_allocated` | LOGICAL | 分配标志 | NM_Matrix_State |
| `norm_fro` | REAL(wp) | Frobenius 范数缓存 | NM_Matrix_State |
| `cond_number` | REAL(wp) | 条件数（计算） | NM_Matrix_State |
| `eigenvalues(:)` | REAL(wp), ALLOCATABLE | 特征值缓存 | NM_Matrix_State |

**生命周期**：
- **写入阶段**：矩阵操作后更新
- **读取阶段**：迭代内复用
- **释放时机**：矩阵重置

**内存策略**：
- 温数据，按需 ALLOCATE
- 缓存优化

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `factorization_type` | INTEGER(i4) | 分解类型：LU/Cholesky/QR | NM_Matrix_Factor_Algo |
| `pivot_strategy` | INTEGER(i4) | 主元策略：Partial/Full/None | NM_Matrix_Factor_Algo |
| `transpose_enabled` | LOGICAL | 转置开关 | NM_Matrix_Algo |
| `block_size` | INTEGER(i4) | 分块大小（BLAS 优化） | NM_Matrix_Algo |

**生命周期**：
- **写入阶段**：矩阵初始化
- **读取阶段**：矩阵操作全过程
- **释放时机**：矩阵销毁

**内存策略**：
- 冷数据，可 ALLOCATE
- 跨矩阵复用

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `alpha` | REAL(wp) | 标量系数（SpMV: y = A*x + alpha*y） | NM_Matrix_MatMul_Ctx |
| `beta` | REAL(wp) | 输出系数 | NM_Matrix_MatMul_Ctx |
| `transpose_flag` | LOGICAL | 转置标志 | NM_Matrix_MatMul_Ctx |
| `work_array(:)` | REAL(wp), ALLOCATABLE | 工作数组 | NM_Matrix_Ctx |

**生命周期**：
- **写入阶段**：每次矩阵操作入口
- **读取阶段**：单次操作内
- **释放时机**：操作返回

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配

---

## 3. 矩阵存储格式

### 3.1 DenseMatrix（稠密矩阵）

| 字段 | 类型 | 说明 |
|------|------|------|
| `data(:,:)` | REAL(wp), ALLOCATABLE | 二维数组（列主序） |
| `nrows` | INTEGER(i4) | 行数 |
| `ncols` | INTEGER(i4) | 列数 |

### 3.2 SparseMatrix_CSR（稀疏矩阵 CSR）

| 字段 | 类型 | 说明 |
|------|------|------|
| `values(:)` | REAL(wp), ALLOCATABLE | 非零元值 |
| `col_idx(:)` | INTEGER(i4), ALLOCATABLE | 列索引 |
| `row_ptr(:)` | INTEGER(i4), ALLOCATABLE | 行指针 |
| `nnz` | INTEGER(i8) | 非零元个数 |

### 3.3 SparseMatrix_CSC（稀疏矩阵 CSC）

| 字段 | 类型 | 说明 |
|------|------|------|
| `values(:)` | REAL(wp), ALLOCATABLE | 非零元值 |
| `row_idx(:)` | INTEGER(i4), ALLOCATABLE | 行索引 |
| `col_ptr(:)` | INTEGER(i4), ALLOCATABLE | 列指针 |

---

## 4. 核心算法模块

| 模块 | 文件 | 说明 |
|------|------|------|
| 稠密核心 | `NM_LinAlg_Dense_Core.f90` | BLAS 封装 |
| 稀疏核心 | `NM_Sparse_Matrix_Core.f90` | CSR SpMV |
| 矩阵乘法 | `NM_Matrix_MatMul.f90` | 矩阵-矩阵乘法 |
| 稀疏装配 | `NM_Assem_Sparse.f90` | CSR 装配 |
| 矩阵分解 | `NM_Matrix_Factorization.f90` | LU/Cholesky/QR |
| 矩阵求逆 | `NM_Matrix_Inversion.f90` | 矩阵求逆 |
| LAPACK 封装 | `NM_LAPACK_Wrappers.f90` | DSYEV/DGESVD/DGETRF/DGETRI |

---

## 5. 依赖关系

```
NM_Matrix_Desc (L2) → NM_Matrix_State (L2) → NM_Matrix_Ctx (L2)
NM_Matrix_Algo (L2) → NM_Matrix_Ctx (L2)
RT_Solver (L5) → NM_Matrix (L2)
RT_Element (L5) → NM_Matrix (L2)
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含矩阵配置 | ✅ | 行列/格式/对称 |
| State 含缓存 | ✅ | Frobenius 范数 |
| Algo 含分解参数 | ✅ | LU/Cholesky/QR |
| Ctx 零 ALLOCATE | ✅ | SpMV 入口 |
| CSR/CSC 支持 | ✅ | 两种稀疏格式 |
| LAPACK 封装 | ✅ | 四大接口 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本