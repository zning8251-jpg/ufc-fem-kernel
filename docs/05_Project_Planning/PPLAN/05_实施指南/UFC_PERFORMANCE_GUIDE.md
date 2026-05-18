# UFC 性能优化指南

> **版本**: v1.0
> **创建日期**: 2026-03-06
> **最后更新**: 2026-03-06
> **适用范围**: UFC 项目性能优化（内存优化除外）
> **上级参考**: [UFC_统一内存管理体系_v3.0.md](../../archive/PLAN_History/99_归档库/01_历史版本文档/内存管理/UFC_统一内存管理体系设计_v3.0.md)（内存优化；归档演进稿见 `99_归档库/01_历史版本文档/内存管理/`）

---

## 📋 文档说明

本文档提供 UFC 项目的性能优化指南，包括：

- 性能剖析方法
- 热点识别
- 并行化策略（OpenMP）
- GPU 加速策略（CUDA）
- 算法优化技巧
- 性能基准测试结果
- 性能调优最佳实践

**注意**: 内存优化相关内容请参考 [UFC_统一内存管理体系_v3.0.md](../../archive/PLAN_History/99_归档库/01_历史版本文档/内存管理/UFC_统一内存管理体系设计_v3.0.md)。

---

## 目录

1. [性能剖析方法](#1-性能剖析方法)
2. [热点识别](#2-热点识别)
3. [并行化策略](#3-并行化策略)
4. [GPU 加速策略](#4-gpu-加速策略)
5. [算法优化技巧](#5-算法优化技巧)
6. [编译器优化](#6-编译器优化)
7. [性能基准测试](#7-性能基准测试)
8. [性能调优最佳实践](#8-性能调优最佳实践)

---

## 1. 性能剖析方法

### 1.1 使用 gprof

**编译时启用 gprof**:

```bash
gfortran -pg -O3 -o ufc_solver ufc_solver.f90
```

**运行程序**:

```bash
./ufc_solver model.inp
```

**生成报告**:

```bash
gprof ufc_solver gmon.out > profile.txt
```

**查看报告**:

```bash
less profile.txt
```

### 1.2 使用 perf (Linux)

**记录性能数据**:

```bash
perf record -g ./ufc_solver model.inp
```

**查看报告**:

```bash
perf report
```

**生成火焰图**:

```bash
perf script | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg
```

### 1.3 使用 Intel VTune

**记录性能数据**:

```bash
vtune -collect hotspots -result-dir ./vtune_result -- ./ufc_solver model.inp
```

**查看报告**:

```bash
vtune -report summary -result-dir ./vtune_result
```

### 1.4 UFC 内置性能分析

**启用性能分析**:

```bash
ufc_solver --profile --input=model.inp
```

**性能报告位置**:

- `model_profile.json`: JSON 格式
- `model_profile.txt`: 文本格式

**查看报告**:

```bash
ufc_profile --report=model_profile.json
```

---

## 2. 热点识别

### 2.1 常见性能热点

**典型热点函数**（按频率排序）:

1. **单元刚度矩阵计算** (`PH_Elem_ComputeStiffness`)

   - 占用时间: 30-50%
   - 优化重点: 向量化、并行化
2. **材料本构评估** (`PH_Mat_Evaluate`)

   - 占用时间: 15-25%
   - 优化重点: 缓存优化、SIMD
3. **矩阵-向量乘法** (`NM_SpMV`)

   - 占用时间: 10-20%
   - 优化重点: 稀疏矩阵优化、GPU 加速
4. **线性求解器** (`NM_LinearSolver_Solve`)

   - 占用时间: 10-15%
   - 优化重点: 预条件优化、并行求解
5. **装配操作** (`RT_Solver_Assemble`)

   - 占用时间: 5-10%
   - 优化重点: 并行装配、内存访问优化

### 2.2 热点分析工具

**使用 UFC 内置工具**:

```bash
ufc_hotspot --input=model.inp --threshold=5.0
```

**输出示例**:

```
Hotspot Analysis Report:
========================

Function                              Time (%)    Calls    Avg Time (ms)
------------------------------------------------------------------------
PH_Elem_ComputeStiffness              42.3%       1000000  0.423
PH_Mat_Evaluate                       18.7%       5000000  0.037
NM_SpMV                               12.5%       10000    1.250
NM_LinearSolver_Solve                11.2%       1000     11.200
RT_Solver_Assemble                    8.3%        1000     8.300
...
```

### 2.3 性能瓶颈诊断

**CPU 瓶颈**:

- 症状: CPU 使用率接近 100%
- 优化: 并行化、向量化、算法优化

**内存瓶颈**:

- 症状: 内存带宽饱和、缓存未命中率高
- 优化: 内存访问优化、缓存友好算法

**I/O 瓶颈**:

- 症状: 磁盘 I/O 等待时间长
- 优化: 异步 I/O、数据压缩、SSD

---

## 3. 并行化策略

### 3.1 OpenMP 并行化

#### 单元循环并行化

**原始代码**:

```fortran
DO i_elem = 1, n_elements
  CALL PH_Elem_ComputeStiffness(elem_type, coords(i_elem), &
                                material, Ke(i_elem), status)
END DO
```

**并行化代码**:

```fortran
!$OMP PARALLEL DO PRIVATE(i_elem, status) SHARED(coords, material, Ke)
DO i_elem = 1, n_elements
  CALL PH_Elem_ComputeStiffness(elem_type, coords(i_elem), &
                                material, Ke(i_elem), status)
END DO
!$OMP END PARALLEL DO
```

#### 线程数优化

**自动线程数**:

```bash
export OMP_NUM_THREADS=0  # 0 = 自动（CPU 核心数）
```

**手动设置**:

```bash
export OMP_NUM_THREADS=8
```

**NUMA 感知**:

```bash
export OMP_PROC_BIND=close
export OMP_PLACES=cores
```

#### 并行效率测试

**测试并行效率**:

```bash
ufc_benchmark --parallel-efficiency --max-threads=16
```

**输出示例**:

```
Parallel Efficiency Test:
==========================

Threads  Time (s)  Speedup  Efficiency
----------------------------------------
1        100.0     1.00     100.0%
2        52.5      1.90     95.0%
4        27.8      3.60     90.0%
8        15.2      6.58     82.3%
16       9.5       10.53    65.8%

Best efficiency: 95.0% (2 threads)
```

### 3.2 MPI 并行化

**MPI 并行化**（适用于大规模问题）:

```fortran
CALL MPI_INIT(ierr)
CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
CALL MPI_COMM_SIZE(MPI_COMM_WORLD, nprocs, ierr)

! 域分解
CALL DomainDecompose(n_elements, nprocs, rank, local_elements)

! 并行计算
DO i_elem = local_start, local_end
  CALL PH_Elem_ComputeStiffness(...)
END DO

! 通信（边界数据交换）
CALL MPI_Allreduce(local_Ke, global_Ke, ...)

CALL MPI_FINALIZE(ierr)
```

**运行 MPI 程序**:

```bash
mpirun -np 8 ufc_solver_mpi model.inp
```

### 3.3 混合并行（OpenMP + MPI）

**混合并行**:

```bash
# 4 MPI 进程，每个进程 4 OpenMP 线程
export OMP_NUM_THREADS=4
mpirun -np 4 ufc_solver_hybrid model.inp
```

**总并行度**: 4 MPI × 4 OpenMP = 16 线程

---

## 4. GPU 加速策略

### 4.1 CUDA 加速

#### 单元刚度矩阵 GPU 加速

**CPU 版本**:

```fortran
DO i_elem = 1, n_elements
  CALL PH_Elem_ComputeStiffness(...)
END DO
```

**GPU 版本**（CUDA Fortran）:

```fortran
! 数据传输到 GPU
!$cuf kernel do <<<(*,*)>>>
DO i_elem = 1, n_elements
  CALL PH_Elem_ComputeStiffness_GPU(...)
END DO
!$cuf end kernel do

! 数据传输回 CPU
```

**性能提升**: 10-50x（取决于问题规模）

#### 稀疏矩阵-向量乘法 GPU 加速

**使用 cuSPARSE**:

```fortran
USE cusparse

! 创建 cuSPARSE 句柄
CALL cusparseCreate(handle)

! 执行 SpMV
CALL cusparseDcsrmv(handle, CUSPARSE_OPERATION_NON_TRANSPOSE, &
                     n_rows, n_cols, nnz, alpha, descr, &
                     d_val, d_row_ptr, d_col_idx, d_x, beta, d_y)
```

**性能提升**: 5-20x

### 4.2 OpenACC 加速

**OpenACC 并行化**:

```fortran
!$acc parallel loop
DO i_elem = 1, n_elements
  CALL PH_Elem_ComputeStiffness(...)
END DO
!$acc end parallel loop
```

**编译**:

```bash
pgfortran -acc -ta=tesla:cc70 ufc_solver.f90
```

### 4.3 GPU 性能优化技巧

**优化数据传输**:

- 最小化 CPU-GPU 数据传输
- 使用异步传输（`cudaMemcpyAsync`）
- 使用固定内存（`cudaMallocHost`）

**优化内存访问**:

- 合并内存访问（Coalesced Access）
- 使用共享内存（Shared Memory）
- 避免 bank conflicts

**优化计算**:

- 使用 Tensor Cores（V100+）
- 优化线程块大小（Block Size）
- 使用 warp shuffle

---

## 5. 算法优化技巧

### 5.1 单元刚度矩阵优化

#### 向量化优化

**原始代码**:

```fortran
DO i = 1, 6
  DO j = 1, 6
    Ke(i, j) = Ke(i, j) + B(i, k) * D(k, l) * B(l, j) * w * detJ
  END DO
END DO
```

**向量化代码**:

```fortran
! 使用 BLAS 矩阵乘法
CALL DGEMM('N', 'N', 6, 6, 6, 1.0_wp, B, 6, D, 6, 0.0_wp, temp, 6)
CALL DGEMM('N', 'T', 6, 6, 6, w*detJ, temp, 6, B, 6, 1.0_wp, Ke, 6)
```

**性能提升**: 2-5x

#### 缓存优化

**原始代码**（缓存不友好）:

```fortran
DO i_elem = 1, n_elements
  DO i_gp = 1, n_gp
    CALL ComputeBMatrix(coords(i_elem, :, :), gp_coords(i_gp, :), B)
    ...
  END DO
END DO
```

**优化代码**（缓存友好）:

```fortran
! 重新组织循环顺序
DO i_gp = 1, n_gp
  DO i_elem = 1, n_elements
    CALL ComputeBMatrix(coords(i_elem, :, :), gp_coords(i_gp, :), B)
    ...
  END DO
END DO
```

### 5.2 线性求解器优化

#### 预条件优化

**ILU 预条件**:

```fortran
CALL NM_ILU_Factorize(A, L, U, status)
CALL NM_LinearSolver_Solve_Preconditioned(A, b, x, L, U, status)
```

**性能提升**: 2-10x（取决于问题）

#### 多网格预条件

**多网格预条件**:

```fortran
CALL NM_Multigrid_Setup(A, mg_hierarchy, status)
CALL NM_LinearSolver_Solve_Multigrid(A, b, x, mg_hierarchy, status)
```

**性能提升**: 10-100x（大规模问题）

### 5.3 稀疏矩阵优化

#### CSR 格式优化

**CSR 格式**（行优先）:

- 适合行访问（SpMV）
- 内存占用: `O(nnz + n_rows)`

**CSC 格式**（列优先）:

- 适合列访问（SpMV^T）
- 内存占用: `O(nnz + n_cols)`

**选择原则**:

- SpMV: 使用 CSR
- SpMV^T: 使用 CSC
- 两者都需要: 存储两种格式或转换

---

## 6. 编译器优化

### 6.1 gfortran 优化选项

**基本优化**:

```bash
gfortran -O3 -march=native -mtune=native
```

**高级优化**:

```bash
gfortran -O3 -march=native -mtune=native \
         -ffast-math -funroll-loops -flto
```

**向量化**:

```bash
gfortran -O3 -march=native -ftree-vectorize -fopt-info-vec
```

### 6.2 ifort 优化选项

**基本优化**:

```bash
ifort -O3 -xHost -qopenmp
```

**高级优化**:

```bash
ifort -O3 -xHost -qopenmp -ipo -fast
```

**向量化**:

```bash
ifort -O3 -xHost -qopt-report=5 -qopt-report-phase=vec
```

### 6.3 链接时优化（LTO）

**启用 LTO**:

```bash
gfortran -O3 -flto -o ufc_solver *.o
```

**性能提升**: 5-15%

---

## 7. 性能基准测试

### 7.1 标准基准测试

**运行基准测试**:

```bash
ufc_benchmark --test=all --output=benchmark.json
```

**测试问题**:

- Patch Test（单元精度）
- Cantilever Beam（弯曲问题）
- Cook's Membrane（弯曲+剪切）
- 大规模问题（100万自由度）

### 7.2 性能对比

**对比 ABAQUS**:

```bash
ufc_benchmark --compare=abaqus --abaqus-result=abaqus.dat
```

**对比历史性能**:

```bash
ufc_benchmark --compare=baseline --baseline=baseline.json
```

### 7.3 性能报告

**生成性能报告**:

```bash
ufc_benchmark --report=benchmark.json --format=html
```

**报告内容**:

- 求解时间对比
- 内存使用对比
- 并行效率
- 性能趋势

---

## 8. 性能调优最佳实践

### 8.1 性能调优流程

**步骤 1: 性能剖析**

```bash
ufc_solver --profile model.inp
```

**步骤 2: 识别热点**

```bash
ufc_hotspot --threshold=5.0
```

**步骤 3: 优化热点**

- 并行化
- 向量化
- 算法优化

**步骤 4: 验证优化**

```bash
ufc_benchmark --compare-baseline
```

**步骤 5: 迭代优化**

- 重复步骤 1-4
- 直到性能满足要求

### 8.2 性能优化检查清单

**编译优化**:

- [ ] 启用 `-O3` 优化
- [ ] 启用 `-march=native`
- [ ] 启用向量化
- [ ] 启用 LTO（如适用）

**并行优化**:

- [ ] 单元循环并行化
- [ ] 优化线程数（`OMP_NUM_THREADS`）
- [ ] NUMA 感知（如适用）
- [ ] MPI 并行化（大规模问题）

**算法优化**:

- [ ] 使用 BLAS/LAPACK
- [ ] 优化内存访问模式
- [ ] 使用高效预条件
- [ ] 优化稀疏矩阵格式

**GPU 优化**（如适用）:

- [ ] 最小化数据传输
- [ ] 优化 GPU 内核
- [ ] 使用 cuBLAS/cuSPARSE

### 8.3 性能目标

**典型性能目标**:

| 指标                 | 目标值                 |
| -------------------- | ---------------------- |
| **求解时间**   | < 60 秒（100万自由度） |
| **并行效率**   | > 70%（8 线程）        |
| **内存使用**   | < 8 GB（100万自由度）  |
| **GPU 加速比** | > 10x（大规模问题）    |

---

## 附录

### A.1 性能优化工具速查

| 工具                  | 用途             | 平台          |
| --------------------- | ---------------- | ------------- |
| **gprof**       | 函数级性能分析   | Linux         |
| **perf**        | 系统级性能分析   | Linux         |
| **Intel VTune** | 详细性能分析     | Linux/Windows |
| **UFC Profile** | UFC 内置性能分析 | 全平台        |
| **Valgrind**    | 内存分析         | Linux         |
| **nvprof**      | GPU 性能分析     | Linux         |

### A.2 相关文档

- [UFC_统一内存管理体系_v3.0.md](../../archive/PLAN_History/99_归档库/01_历史版本文档/内存管理/UFC_统一内存管理体系设计_v3.0.md) - 内存优化
- `UFC_OPERATIONS_MANUAL.md` - 运维手册
- `UFC_BENCHMARK_SUITE.md` - 标准测试问题库

---

**文档状态**: Draft v1.0
**最后更新**: 2026-03-06
**维护者**: UFC 开发团队
