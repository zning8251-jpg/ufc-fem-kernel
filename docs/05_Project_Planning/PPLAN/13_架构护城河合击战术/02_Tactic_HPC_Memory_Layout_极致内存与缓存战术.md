# 战术二：HPC极致内存布局与SoA缓存战术 (内功)

> **文档位置**：`docs/05_Project_Planning/PPLAN/13_架构护城河合击战术/02_Tactic_HPC_Memory_Layout_极致内存与缓存战术.md`

## 1. 战术意图

由于我们将业务拆解为了极其碎片的“十件套”（尤其是分离出了 `_Desc` 静态描述和 `_State` 动态状态），如果我们不进行精确的内存编排，将导致缓存一致性（Cache Coherence）灾难和极高的 Cache Miss 率。本战术被视为底层计算的“内功”。

## 2. 核心武器一：AoS vs SoA 的战略切分

在单元积分（L4）和材料演化（L3）的高频热路径中，必须对 `_State` 和 `_Desc` 采用不同的内存布局。

- **`_Desc` 采用 AoS (Array of Structures)**：
  因为这些配置属性（比如单元的 8 个节点坐标、材料的 E/nu 等）是在装配前就固定的。在单个单元积分的生命周期内，一次性把这一个单元的所有 Desc 取入 CPU L1 Cache 最有效率。
  
- **`_State` 采用 SoA (Structure of Arrays)**：
  状态量（比如塑性应变矩阵）必须连片分配。
  *错误示范*：`TYPE(ElemState) :: all_states(100000)`
  *正确战术*：
  ```fortran
  TYPE :: Global_State_Pool
      REAL(DP), ALLOCATABLE :: plastic_strain(:,:) ! (6, num_elems)
      REAL(DP), ALLOCATABLE :: stress(:,:)         ! (6, num_elems)
  END TYPE
  ```
  **原因**：这使得当我们启用 `!$OMP SIMD` 时，CPU 能够通过连续的内存预取（Prefetching）实现最极致的向量化加速。

## 3. 核心武器二：64字节对齐与假共享(False Sharing)防范

- 在多线程（如 `RT_Assembly` 组装 CSR 矩阵）中，各个线程更新状态极易写到同一条 Cache Line 上，引发总线锁风暴（False Sharing）。
- **要求**：由 `IF_Memory` 分配的大数组，起始指针必须向 64 字节（Cache Line 大小）对齐。
- 在 `_Ctx` 传递时，将每个线程的临时工作区（Work-space）彻底物理隔离，绝不在全局数据区进行原子加锁的局部计算。

## 4. 落地路径

1. 所有底层 `L2_NM` 和 `L3_MD_Algo` 必须去除内部隐藏的临时分配（如隐式的返回数组）。
2. 在 `IF_Memory` 层实现 `memalign` 等 C 标准库的对接，接管所有百万级网格数组的内存分配。