# L2_NM CSR稀疏矩阵核心

> **文档位置**：`六层架构拆分/04-六层架构拆解/L2_NM-数值层/L2-05-CSR稀疏矩阵.md`  
> **来源章节**：原文档第二十一章  
> **最后更新**：2026-02-17  
> **相关文档**：[数值层总览](L2-01-数值层总览.md)、[线性求解器](L2-02-线性求解器.md)

---

## 概述

> **核心原则**：UFC 内核以 CSR（Compressed Sparse Row）一维稀疏行压缩存储和求解为主，这是整个架构的矩阵存储和计算基础。

## CSR 存储格式理论基础

### CSR 格式数学定义

**CSR 格式结构**（参考 Saad, Iterative Methods for Sparse Linear Systems, 2003）：

对于稀疏矩阵 A ∈ ℝⁿˣⁿ，CSR 格式使用三个一维数组存储：

```
┌─────────────────────────────────────────────────────────────┐
│  CSR 格式定义                                                │
│                                                              │
│  A = [a_ij]  (n×n 矩阵)                                      │
│                                                              │
│  存储结构:                                                   │
│    val[k]     : 非零元素值 (k = 0, ..., nnz-1)              │
│    col_ind[k] : 列索引 (对应 val[k] 的列号)                 │
│    row_ptr[i] : 行指针 (第 i 行的起始位置)                  │
│                                                              │
│  关系:                                                       │
│    row_ptr[i] ≤ k < row_ptr[i+1]  →  val[k] = a_{i, col_ind[k]}│
└─────────────────────────────────────────────────────────────┘
```

**内存占用**：

- **密集矩阵**：n² × sizeof(real) 字节
- **CSR 格式**：(nnz × sizeof(real) + nnz × sizeof(int) + (n+1) × sizeof(int)) 字节
- **压缩比**：当稀疏度 < 10% 时，CSR 显著节省内存

### CSR 格式优势分析

**CSR 格式优势**（针对有限元问题）：

1. **内存效率**：
   - 有限元刚度矩阵通常稀疏度 < 5%
   - CSR 内存占用 ≈ nnz × (sizeof(real) + sizeof(int)) + (n+1) × sizeof(int)
   - 相比密集矩阵节省 95%+ 内存

2. **访问模式**：
   - **行访问高效**：row_ptr[i] 到 row_ptr[i+1] 连续访问
   - **矩阵向量乘法（SpMV）高效**：按行遍历，缓存友好
   - **行提取高效**：O(nnz_row) 时间复杂度

3. **并行友好**：
   - **行级并行**：不同行可并行处理
   - **SIMD 友好**：行内元素连续存储，适合向量化
   - **GPU 友好**：适合 CUDA 的 CSR SpMV 内核

4. **求解器兼容**：
   - **直接求解器**：LDLT、Cholesky 分解支持 CSR
   - **迭代求解器**：CG、GMRES、BiCGStab 等主要操作是 SpMV
   - **预条件器**：ILU、AMG 等基于 CSR 格式

## CSR 矩阵数据结构设计

### 核心 CSR 类型定义

**L2_NM 层 CSR 类型**（核心数据结构）：

```fortran
! L2_NM/Sparse/NM_Sparse_Matrix_CSR.f90
module NM_Sparse_Matrix_CSR
  use IF_GlobalParams, only: wp, i4
  implicit none
  private
  
  !=============================================================================
  ! CSR 矩阵核心类型（UFC 标准格式）
  !=============================================================================
  type, public :: NM_CSR_Type
    ! 矩阵维度
    integer(i4) :: n = 0_i4              ! 行数
    integer(i4) :: m = 0_i4              ! 列数（通常 n == m）
    integer(i4) :: nnz = 0_i4            ! 非零元素个数
    
    ! CSR 三数组
    integer(i4), allocatable :: row_ptr(:)  ! 行指针 (n+1)
    integer(i4), allocatable :: col_ind(:)  ! 列索引 (nnz)
    real(wp), allocatable :: val(:)         ! 非零值 (nnz)
    
    ! 矩阵属性
    logical :: is_symmetric = .false.       ! 对称矩阵标志
    logical :: is_positive_definite = .false.  ! 正定矩阵标志
    logical :: is_allocated = .false.       ! 分配标志
    
  contains
    ! 基础操作
    procedure :: init => csr_init
    procedure :: destroy => csr_destroy
    procedure :: allocate => csr_allocate
    procedure :: deallocate => csr_deallocate
    
    ! 矩阵操作
    procedure :: matvec => csr_matvec              ! y = A·x
    procedure :: matvec_trans => csr_matvec_trans  ! y = A^T·x
    procedure :: matvec_sym => csr_matvec_sym      ! y = A·x (对称矩阵优化)
  end type NM_CSR_Type
  
end module NM_Sparse_Matrix_CSR
```

## CSR 矩阵组装策略

### 两阶段组装法（Two-Phase Assembly）

**阶段1：COO 格式临时存储**：

- 使用COO（Coordinate）格式临时存储单元贡献
- 支持并行组装（每个线程一个COO列表）

**阶段2：COO 转 CSR**：

- 按 (row, col) 排序
- 合并相同 (row, col) 的元素
- 构建 row_ptr、col_ind、val 数组

### 直接 CSR 组装法（Direct CSR Assembly）

**直接 CSR 组装**（适用于已知稀疏结构）：

- 预分配稀疏矩阵结构
- 直接组装到CSR格式
- 适用于固定网格结构

## 基于 CSR 的求解器算法

### CSR SpMV 优化算法

**SIMD 向量化 SpMV**：

- 利用SIMD指令加速行内计算
- 提高缓存命中率

**GPU CSR SpMV**：

- CUDA内核实现
- 适合大规模稀疏矩阵

### 基于 CSR 的迭代求解器

**CG 求解器（CSR 格式）**：

- 主要操作是SpMV
- 利用CSR格式的高效访问模式

**GMRES 求解器（CSR 格式）**：

- Krylov子空间方法
- 基于CSR SpMV

### 基于 CSR 的直接求解器

**LDLT 分解（CSR 格式）**：

- 符号分解 + 数值分解
- 支持稀疏矩阵分解

---

## 相关文档

- [数值层总览](L2-01-数值层总览.md)
- [线性求解器](L2-02-线性求解器.md)
- [非线性求解器](L2-03-非线性求解器.md)
