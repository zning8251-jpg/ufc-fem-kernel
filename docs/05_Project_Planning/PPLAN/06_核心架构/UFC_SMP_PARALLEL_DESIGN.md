# UFC SMP (OpenMP) 并行计算设计

> 状态: CORE | 创建: 2026-04-26

## 概述

UFC SMP 并行计算基于 ABAQUS SMP 设计映射，贯通 OpenMP 热路径：

```
L6 配置 (nOMPThreads) -> L0 GlobalContainer (omp_set_num_threads)
                       -> L1 ThreadWS (线程工作区)
                       -> L5 单元循环 (!$OMP PARALLEL DO)
                       -> L5 装配 (ATOMIC / Graph-Coloring)
                       -> L2 求解器 (MUMPS ICNTL(16) / SuperLU)
```

## ABAQUS SMP -> UFC 映射

| ABAQUS SMP 设计 | UFC 实现 | 文件 |
|---|---|---|
| 用户指定 cpus=N | `AP_Solver_Ctrl%nOMPThreads` -> `omp_set_num_threads` | `AP_SolvDomain.f90`, `UFC_GlobalContainer_Core.f90` |
| 单元内力/刚度多线程并行 | `!$OMP PARALLEL DO PRIVATE(ctx) SCHEDULE(DYNAMIC,64)` | `RT_StepDriver_Brg.f90`, `RT_AsmSolv.f90` |
| 装配 graph-coloring | `RT_AsmColor_Build` + 逐颜色组 PARALLEL DO | `RT_AsmColor.f90` |
| 装配 atomic 保护 | `RT_Asm_AddElemStiff_Atomic` / `RT_Asm_ScatterKe_CSR_Atomic` | `RT_Asm.f90`, `RT_AsmSolv.f90` |
| 求解器多线程 | MUMPS `ICNTL(16)` / SuperLU `num_threads` | `NM_DirMUMPS_Brg.f90` |
| 接触检测多线程 | `PH_ContCSR` 已有 `!$OMP CRITICAL` | `PH_ContCSR.f90` (既有) |

## OpenMP 热路径

### 1. 线程配置入口

**单一入口原则**：所有线程数配置通过 `UFC_Global_Init(nThreads)` 或 `AP_Solver_SetOMPThreads(nOMP)` 设定。

```fortran
! L6 -> L0 -> OpenMP 全局
CALL g_ufc_global%Init(nThreads=4, workDir='.', status=st)
! 内部调用 omp_set_num_threads(4)
! 内部调用 if_layer%Init(4, ...) -> ThreadWS 分配 4 线程工作区
```

### 2. 单元循环并行化 (核心热路径)

```fortran
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP   SHARED(nElems, ...) &
!$OMP   PRIVATE(iElem, thr_asm_ctx, thr_elem_cfg, ...) &
!$OMP   SCHEDULE(DYNAMIC, 64)
DO iElem = 1, nElems
  ! 每个线程有独立的 RT_Asm_Ctx (栈变量, PRIVATE 自动处理)
  CALL thr_asm_ctx%ClearElementData()
  CALL PH_Elem_Compute(thr_elem_cfg, ...)
END DO
!$OMP END PARALLEL DO
```

**关键设计决策**：
- `SCHEDULE(DYNAMIC, 64)`：动态调度，chunk=64，兼顾负载均衡
- `RT_Asm_Ctx` 固定大小栈变量 (24x24 矩阵)，天然线程私有
- L4 `PH_Elem_Compute` 只读 Desc + 写 Ctx，无全局写入

### 3. 装配并行化 (两种模式)

#### 模式 A: ATOMIC (简单优先)

```fortran
SUBROUTINE RT_Asm_ScatterKe_CSR_Atomic(K, Ke, elem_dofs, n_dof)
  DO jj = 1, n_dof
    DO ii = 1, n_dof
      ! 查找 CSR 位置
      DO kk = K%rowPtr(row), K%rowPtr(row+1)-1
        IF (K%colInd(kk) == col) THEN
          !$OMP ATOMIC
          K%values(kk) = K%values(kk) + Ke(ii, jj)
          EXIT
        END IF
      END DO
    END DO
  END DO
END SUBROUTINE
```

#### 模式 B: Graph-Coloring (高性能)

```fortran
! 预处理：贪心着色
CALL RT_AsmColor_Build(n_elem, n_dof_per_elem, elem_dof_table, color_result, st)

! 装配：逐颜色组并行
DO ic = 1, color_result%n_colors
  !$OMP PARALLEL DO
  DO idx = color_result%color_start(ic), color_result%color_start(ic+1)-1
    ie = color_result%color_elems(idx)
    CALL RT_Asm_AddElemStiff_InPlace(K, Ke(ie), dofs(ie), n_dof)
  END DO
  !$OMP END PARALLEL DO
END DO
```

### 4. 残差计算并行化

```fortran
!$OMP PARALLEL DO REDUCTION(+:F_int) SCHEDULE(DYNAMIC, 64)
DO iElem = 1, nElems
  ! 线程私有 fe_arg
  CALL Compute_Fe(fe_arg)
  ! F_int 通过 REDUCTION 自动归约
  F_int(eq_ids) = F_int(eq_ids) + fe_arg%Fe
END DO
!$OMP END PARALLEL DO
R = F_ext - F_int
```

### 5. 求解器并行

```fortran
! 同步线程数到 MUMPS
CALL NM_DirectSolver_SyncThreads(params, nOMPThreads)
! MUMPS ICNTL(16) = nOMPThreads (多线程分解/回代)
CALL NM_MUMPS_Init(ctx, params, status)
```

## 线程安全规范

| TYPE | 并发读 | 并发写 | 说明 |
|---|---|---|---|
| `RT_Asm_Desc` | 安全 | 禁止 | 只读配置 |
| `RT_Asm_Ctx` | N/A | 安全 | PRIVATE 子句保护 |
| `RT_Asm_State.K_global` | 安全 | ATOMIC/Coloring | 全局矩阵写入需保护 |
| `RT_Asm_State.F_global` | 安全 | ATOMIC/REDUCTION | 力向量写入需保护 |
| `PH_ElemConfig` | 安全 | 禁止 | L4 只读描述 |
| `PH_ElemContext` | N/A | 安全 | PRIVATE 子句保护 |
| `ThreadWS.threads(tid)` | 安全 | 安全 | 按 thread_id 分离 |

## 性能预期

| 热路径 | 预期加速比 (8核) | 瓶颈 |
|---|---|---|
| 单元刚度计算 | ~6-7x | 近线性 (计算密集) |
| ATOMIC 装配 | ~2-3x | 内存带宽 + ATOMIC 竞争 |
| Graph-Coloring 装配 | ~4-5x | 着色分组间同步 |
| 残差 REDUCTION | ~5-6x | 近线性 (REDUCTION 高效) |
| MUMPS 求解 | ~3-4x | 依赖 MUMPS 自身并行度 |

## 文件清单

| 文件 | 变更 |
|---|---|
| `L1_IF/Base/Parallel/IF_ThreadWS_Def.f90` | Get*1D/2D stub 补全为实际实现 |
| `L1_IF/Base/Parallel/IF_ThreadWS.f90` | GetLocalArray/AggregateReal1D 实现 + RegisterArray/ResetAll |
| `L0_Global/UFC_GlobalContainer_Core.f90` | Init 中调用 omp_set_num_threads |
| `L6_AP/Solver/AP_SolvDomain.f90` | SetOMPThreads 中调用 omp_set_num_threads |
| `L5_RT/StepDriver/RT_StepDriver_Brg.f90` | 单元循环 !$OMP PARALLEL DO |
| `L5_RT/Assembly/RT_Asm.f90` | 新增 AddElemStiff_Atomic/InPlace/ScatterResid_Atomic |
| `L5_RT/Assembly/RT_AsmColor.f90` | **新文件** Graph-Coloring 算法 |
| `L5_RT/Assembly/RT_AsmSolv.f90` | Cfg.assembly_mode + OMP 化 GlobalStiffness/ComputeResidual |
| `L5_RT/Assembly/RT_AsmDomain.f90` | RT_ASM_ATOMIC 枚举 (既有) |
| `L2_NM/Bridge/NM_DirMUMPS_Brg.f90` | ICNTL(16) 线程数 + SyncThreads |

## 后续规划 (本轮不实施)

- **MPI 域分解**：空间分区 + MPI 通信层
- **GPU 加速**：单元计算 offload (OpenACC / CUDA Fortran)
- **混合并行**：节点间 MPI + 节点内 OpenMP
- **动态负载均衡**：运行时子域迁移
