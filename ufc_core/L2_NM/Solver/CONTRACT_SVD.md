# SVD 模块合同卡

## 1. 模块概述

| 属性 | 值 |
|------|-----|
| **模块名** | `NM_Solver_SVD_Core` |
| **文件** | `NM_Solver_SVD_Core.f90` |
| **域** | L2_NM / Solver |
| **功能** | 奇异值分解（SVD）LAPACK DGESDD 封装 |
| **理论** | Golub & Van Loan (2013), "Matrix Computations", Ch. 5.4 |
| **状态** | CORE |

## 2. 功能规格

### 2.1 SVD 分解接口

| 接口名 | 功能 | 描述 |
|--------|------|------|
| `SVD_Compute_Full` | 完全 SVD | 计算所有奇异值和左右奇异向量 |
| `SVD_Compute_Thin` | 精简 SVD | 仅计算 k = min(m,n) 个奇异向量（内存高效） |
| `SVD_Compute_Partial` | 部分 SVD | 仅计算前 k 个最大的奇异值/向量 |

### 2.2 辅助函数

| 接口名 | 功能 | 描述 |
|--------|------|------|
| `SVD_Condition_Number` | 条件数 | 计算 σ_max / σ_min |
| `SVD_Rank` | 矩阵秩 | 计算非零奇异值个数 |

## 3. 依赖关系

### 3.1 外部库

- **LAPACK**: `DGESDD` (分治法 SVD)

### 3.2 内部模块

- `IF_Precision_Params`: 精度参数定义
- `IF_Err_API`: 错误状态处理

## 4. 算法规格

### 4.1 DGESDD 接口

```
DGESDD(jobz, m, n, a, lda, s, u, ldu, vt, ldvt, work, lwork, iwork, liwork, info)

jobz: 'A' = 所有, 'S' = 精简, 'N' = 仅奇异值
m, n: 矩阵维度
a: 输入矩阵 (lda, n), 输出被覆盖
s: 奇异值 (min(m,n))
u: 左奇异向量 (ldu, m) 或 (ldu, min(m,n))
vt: 右奇异向量 (ldvt, n) 或 (ldvt, min(m,n))
```

### 4.2 奇异值排序

DGESDD 返回奇异值按**降序**排列：
```
σ₁ ≥ σ₂ ≥ ... ≥ σₖ ≥ 0
```

## 5. 错误处理

| 错误码 | 描述 |
|--------|------|
| `STATUS_OK` | 正常完成 |
| `STATUS_INVALID` | 输入参数无效 |
| `STATUS_ERROR` | LAPACK 计算失败 |

## 6. 使用示例

```fortran
USE NM_Solver_SVD_Core, ONLY: SVD_Compute_Thin, ErrorStatusType

REAL(REAL64) :: A(4,3), U(4,3), Sigma(3), VT(3,3)
TYPE(ErrorStatusType) :: status

! 计算精简 SVD
CALL SVD_Compute_Thin(A, U, Sigma, VT, status)

! 判断成功
IF (status%status_code == STATUS_OK) THEN
   PRINT *, '奇异值: ', Sigma
END IF
```

## 7. 性能特性

- **时间复杂度**: O(min(m,n)² · max(m,n))
- **空间复杂度**: O(m·n + min(m,n)·(m+n))
- **分治法优势**: 比传统 QR 迭代快 2-3 倍
