# 第 15 件：Parallel Comm (并行通信与幽灵同步件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/05_第15件_Parallel_Comm_并行同步件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 15 件  
> **目标**：在 L5 热路径中封装和隔离所有的 MPI/OpenMP 操作，处理基于领域分解法 (DDM) 的幽灵节点 (Ghost Nodes) 数据同步。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **隐藏通信细节 (Hide Comm Topology)**：L4 的物理引擎只负责计算它所接收到的单元，它不应该知道这些单元处于哪个 MPI rank 上，也不该知道边界节点的邻居是谁。
2. **幽灵节点同步 (Ghost Node Sync)**：在局部刚度矩阵/残差组装完成后，必须通过网络与相邻的 MPI 进程交换处于分割边界上的“幽灵节点”的力与位移。

### 1.2 架构红线 (Red Lines)
- **绝对无 MPI 污染**：除了 `_Comm.f90` 这个组件以外，任何物理核心模块（`L4_PH`）和主求解器（`RT_Solv`）内，绝对不允许出现 `INCLUDE 'mpif.h'`、`USE mpi` 或任何 `MPI_Send/Recv` 语句。
- **固定同步卡点 (Sync Timeline)**：MPI 数据交换只能发生在两个固定的绝对屏障处：
  1. 求解出增量位移 $du$ 后，向幽灵节点**广播扩散 (Scatter)**。
  2. 计算完局部单元残差 $R$ 后，将幽灵节点残差力**归约合并 (Reduce/Assemble)**。

---

## 2. 核心架构时序与机制

1. **[Populate_Comm_Map]**：在 `Init` 阶段，通过 METIS/SCOTCH 网格划分结果，建立 `Parallel_Comm_Map`。识别出每个节点是属于 `Owned` (本核全权拥有) 还是 `Ghost` (被其他核拥有但本核需要读取)。
2. **[Iter: Scatter u]**：主线性求解器算出 `Owned` 节点的 $du$。调用 `Comm_Sync_Displacement`，将 $du$ 通过 MPI 发送给将其作为 `Ghost` 的相邻核。
3. **[Iter: Physics]**：L4 正常计算（它以为它拥有所有节点），产出局部残差 $R_{local}$。
4. **[Iter: Reduce R]**：调用 `Comm_Sync_Residuals`，将 `Ghost` 节点上的残差通过 `MPI_REDUCE (SUM)` 累加回它们真正的 `Owned` 节点上，形成全局正确的组装残差。

---

## 3. 伪代码模板与合同定义

### 3.1 领域通信地图 (Comm Map)
```fortran
!=============================================================================
! MODULE: RT_Comm_Def
! 描述: 并行通信映射表
!=============================================================================
MODULE RT_Comm_Def
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: RT_Comm_Map
    
    TYPE :: RT_Comm_Map
        INTEGER :: my_rank
        INTEGER :: num_ranks
        ! Owned 节点: 归属于本核的节点索引
        INTEGER, ALLOCATABLE :: owned_node_ids(:)
        ! Ghost 节点: 本核计算需要，但归属其他核的节点索引
        INTEGER, ALLOCATABLE :: ghost_node_ids(:)
        ! 记录 Ghost 节点对应的真实归属 rank
        INTEGER, ALLOCATABLE :: ghost_owner_ranks(:)
    END TYPE RT_Comm_Map

END MODULE RT_Comm_Def
```

### 3.2 幽灵同步隔离屏障 (Sync Barriers)
```fortran
!=============================================================================
! MODULE: RT_Comm_Sync
! 描述: 并行同步通信件
!=============================================================================
MODULE RT_Comm_Sync
    ! 唯一允许引用 MPI 的地方
    USE mpi
    USE RT_Comm_Def
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: Comm_Sync_Residuals
    PUBLIC :: Comm_Sync_Displacement

CONTAINS

    !> 组装阶段结束后的同步：将幽灵节点的残差(力)归约到拥有核
    SUBROUTINE Comm_Sync_Residuals(comm_map, global_residual_vector, status)
        TYPE(RT_Comm_Map), INTENT(IN) :: comm_map
        REAL*8, INTENT(INOUT) :: global_residual_vector(:)
        INTEGER, INTENT(OUT) :: status
        
        INTEGER :: ierr
        
        ! 伪代码逻辑：
        ! 1. 抽取本核 local_residual 中属于 ghost_node_ids 的切片
        ! 2. 针对每个相邻 rank 发起非阻塞发送 (MPI_Isend)
        ! 3. 针对每个相邻 rank 发起非阻塞接收 (MPI_Irecv)，接收它们算出的力
        ! 4. MPI_Waitall
        ! 5. 将收到的力累加 (SUM) 到 owned_node_ids 对应的 global_residual_vector 位置
        
        ! ... MPI 底层细节 ...
        
        status = 0
    END SUBROUTINE Comm_Sync_Residuals

    !> 求解结束后的同步：将拥有核的新位移分发给需要它们的核
    SUBROUTINE Comm_Sync_Displacement(comm_map, global_displacement, status)
        TYPE(RT_Comm_Map), INTENT(IN) :: comm_map
        REAL*8, INTENT(INOUT) :: global_displacement(:)
        INTEGER, INTENT(OUT) :: status
        
        ! 伪代码逻辑：
        ! 与 Residual 相反，这里是将 owned 的位移 Send 出去，接收端更新自己的 ghost 位移
        ! ...
        status = 0
    END SUBROUTINE Comm_Sync_Displacement

END MODULE RT_Comm_Sync
```

---

## 4. 合同检验点 (Checklist)
1. 全局代码搜索：执行 `grep -R "USE mpi" ufc_core/`，如果在除了 `_Comm.f90` 或 `L6_AP` 以外的任何文件里查找到，则 Code Review 必须拒绝。
2. 检查幽灵节点的通信序列是否严格匹配了 `Scatter-Compute-Assemble-Reduce` 模式。
3. 检查通信 Buffer 的分配是否仅在 `Init` 阶段进行了一次。热路径中的 MPI 调用只能复用预分配的连续内存，防止系统调用引发阻塞。