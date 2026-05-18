# L2_NM/BVH - Bounding Volume Hierarchy 域

## 域职责

**BVH (Bounding Volume Hierarchy)** 提供空间加速结构，用于加速碰撞检测、射线查询、最近邻搜索等几何查询操作。

### 核心功能

1. **空间加速结构**
   - 层次化包围盒树
   - 支持多种分裂策略（Median, SAH, Equal Area）
   - 自适应重建策略

2. **查询操作**
   - 射线-包围盒求交（Ray-Box Intersection）
   - 最近邻搜索（Nearest Neighbor）
   - 范围查询（Range Query）

3. **性能特征**
   - 构建复杂度：O(n log n)（Median）或 O(n log² n)（SAH）
   - 查询复杂度：O(log n) 平均情况

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 架构位置

```
L2_NM (数值方法层)
├── Matrix/      - 矩阵运算
├── Solver/      - 求解器
├── TimeInt/     - 时间积分
└── BVH/         - 空间加速 ← 当前域
    ├── NM_BVH_Types.f90   - 类型定义
    ├── NM_BVH_Core.f90    - 核心算法
    └── NM_BVH_API.f90     - 薄适配器 API
```

### 依赖关系

```fortran
USE IF_Prec_Core, ONLY: wp, i4              ! 精度定义
USE IF_Err_API, ONLY: ErrorStatusType  ! 错误处理
```

**铁律**：L2_NM 不依赖 L3-L6，确保数值算法的独立性。

---

## 公共 API

### 1. 创建和销毁

#### BVH_Create / NM_BVH_Create
```fortran
SUBROUTINE NM_BVH_Create(bvh, n_objects, max_depth, min_leaf_size, &
                        split_strategy, status)
  !! 创建并初始化 BVH 树
  TYPE(BVH_Tree), INTENT(OUT) :: bvh
  INTEGER(i4), INTENT(IN) :: n_objects     ! 对象数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: max_depth       ! 最大深度
  INTEGER(i4), INTENT(IN), OPTIONAL :: min_leaf_size    ! 最小叶节点大小
  INTEGER(i4), INTENT(IN), OPTIONAL :: split_strategy  ! 分裂策略
  INTEGER(i4), INTENT(OUT) :: status
```

**使用示例**：
```fortran
TYPE(BVH_Tree) :: tree
INTEGER(i4) :: status

CALL BVH_Create(tree, n_objects=10000, max_depth=20, &
                min_leaf_size=4, split_strategy=BVH_MEDIAN, status=status)
IF (status /= 0) STOP "Create failed"
```

#### BVH_Destroy / NM_BVH_Destroy
```fortran
SUBROUTINE NM_BVH_Destroy(bvh)
  !! 销毁 BVH 树并释放内存
  TYPE(BVH_Tree), INTENT(INOUT) :: bvh
```

---

### 2. 构建

#### BVH_Build / NM_BVH_Build
```fortran
SUBROUTINE NM_BVH_Build(bvh, object_boxes, split_strategy, status)
  !! 使用指定策略构建 BVH 树
  TYPE(BVH_Tree), INTENT(INOUT) :: bvh
  REAL(wp), INTENT(IN) :: object_boxes(:,:)  ! (n_objects, 6) 或 (2, 3, n_objects)
  INTEGER(i4), INTENT(IN), OPTIONAL :: split_strategy
  INTEGER(i4), INTENT(OUT) :: status
```

**输入格式**：
- `object_boxes(n, 6)`: [xmin, ymin, zmin, xmax, ymax, zmax]
- `object_boxes(2, 3, n)`: [min/max, xyz, object]

**分裂策略**：
- `BVH_MEDIAN`（默认）：沿最长轴的中点分裂，构建最快
- `BVH_SAH`：表面积启发式，分裂质量最高
- `BVH_EQUAL_AREA`：等面积分裂

**使用示例**：
```fortran
REAL(wp) :: boxes(10000, 6)
! 填充 boxes...

! 使用 Median 分裂策略
CALL BVH_Build(tree, boxes, strategy='MEDIAN', status=status)

! 或使用 SAH（更优质量）
CALL BVH_Build(tree, boxes, strategy='SAH', status=status)
```

---

### 3. 查询

#### BVH_RayCast / NM_BVH_RayCast
```fortran
SUBROUTINE NM_BVH_QueryRay(bvh, ray_origin, ray_direction, max_distance, &
                           hit_objects, n_hits, status)
  !! 查询射线穿过的对象
  TYPE(BVH_Tree), INTENT(IN) :: bvh
  REAL(wp), INTENT(IN) :: ray_origin(3)     ! 射线起点
  REAL(wp), INTENT(IN) :: ray_direction(3) ! 射线方向
  REAL(wp), INTENT(IN) :: max_distance      ! 最大查询距离
  INTEGER(i4), INTENT(OUT) :: hit_objects(:)   ! 碰撞对象列表
  INTEGER(i4), INTENT(OUT) :: n_hits            ! 碰撞数量
  INTEGER(i4), INTENT(OUT) :: status
```

**使用示例**：
```fortran
REAL(wp) :: origin(3) = [0.0_wp, 0.0_wp, 0.0_wp]
REAL(wp) :: direction(3) = [1.0_wp, 0.0_wp, 0.0_wp]
INTEGER(i4) :: hits(100), n_hits, status

CALL BVH_RayCast(tree, origin, direction, max_distance=1000.0_wp, &
                 hit_objects=hits, n_hits=n_hits, status=status)
```

#### BVH_FindNearest / NM_BVH_FindNearest
```fortran
SUBROUTINE NM_BVH_QueryNearest(bvh, point, nearest_object, distance, status)
  !! 查找最近邻对象
  TYPE(BVH_Tree), INTENT(IN) :: bvh
  REAL(wp), INTENT(IN) :: point(3)          ! 查询点
  INTEGER(i4), INTENT(OUT) :: nearest_object ! 最近对象索引
  REAL(wp), INTENT(OUT) :: distance         ! 最近距离
  INTEGER(i4), INTENT(OUT) :: status
```

**使用示例**：
```fortran
REAL(wp) :: query_point(3) = [5.0_wp, 3.0_wp, 7.0_wp]
INTEGER(i4) :: nearest
REAL(wp) :: dist
INTEGER(i4) :: status

CALL BVH_FindNearest(tree, point=query_point, &
                     nearest_object=nearest, distance=dist, status=status)
```

---

### 4. 重建

#### BVH_Rebuild / NM_BVH_Rebuild
```fortran
SUBROUTINE NM_BVH_Rebuild(bvh, new_object_boxes, status)
  !! 使用新几何数据重建 BVH
  TYPE(BVH_Tree), INTENT(INOUT) :: bvh
  REAL(wp), INTENT(IN) :: new_object_boxes(:,:)
  INTEGER(i4), INTENT(OUT) :: status
```

**使用场景**：
- 几何形状发生显著变化时
- 自适应重建触发条件：
  - 节点变形超过阈值
  - 接触对数量变化超过 50%
  - 每 N 个增量步强制重建

---

## 数据结构

### BVH_Node
```fortran
TYPE, PUBLIC :: BVH_Node
  REAL(wp) :: bounding_box(2, 3)    ! [min,max] × [x,y,z]
  INTEGER(i4) :: left_child          ! 左子树索引（0 表示叶节点）
  INTEGER(i4) :: right_child         ! 右子树索引
  INTEGER(i4) :: parent             ! 父节点索引
  INTEGER(i4) :: object_index       ! 叶节点第一个对象索引
  INTEGER(i4) :: n_objects          ! 叶节点对象数量
  LOGICAL :: is_leaf                ! 是否为叶节点
END TYPE
```

### BVH_Tree
```fortran
TYPE, PUBLIC :: BVH_Tree
  TYPE(BVH_Node), ALLOCATABLE :: nodes(:)  ! 节点数组
  INTEGER(i4) :: n_nodes                    ! 节点总数
  INTEGER(i4) :: n_objects                  ! 对象总数
  INTEGER(i4) :: split_strategy             ! 分裂策略
  INTEGER(i4) :: max_depth                  ! 最大深度
  INTEGER(i4) :: min_leaf_size              ! 最小叶节点大小
  LOGICAL :: built                          ! 构建状态
  
  ! 统计信息
  INTEGER(i4) :: n_leaves
  INTEGER(i4) :: max_leaf_size
  REAL(wp) :: avg_leaf_size
END TYPE
```

---

## 算法细节

### 分裂策略

#### Median Split（默认）
```
1. 计算所有对象在每个轴的质心
2. 选择最长轴作为分裂轴
3. 按该轴质心排序
4. 中点分割为两个子集
```

**优点**：构建速度快 O(n log n)
**缺点**：树质量一般

#### Surface Area Heuristic (SAH)
```
1. 对每个可能的分裂位置计算代价：
   cost = N_left × SA_left + N_right × SA_right
2. 选择代价最小的分裂
3. 递归重复
```

**优点**：最优查询性能
**缺点**：构建较慢 O(n log² n)

### 查询算法

#### 射线求交（使用 Slab Method）
```
1. 从根节点开始遍历
2. 对每个节点：
   a. 计算射线与包围盒的交点 [t_near, t_far]
   b. 如果无交点，跳过该子树
   c. 如果是叶节点，报告所有对象
   d. 如果是内部节点，递归遍历子节点
3. 使用显式栈避免递归深度问题
```

---

## 使用示例：Contact 搜索

```fortran
MODULE PH_Cont_BVH_Search
  USE NM_BVH_API
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
CONTAINS
  
  SUBROUTINE PH_Cont_GlobalSearch(n_elements, elem_boxes, contact_pairs, &
                                   n_pairs, status)
    INTEGER(i4), INTENT(IN) :: n_elements
    REAL(wp), INTENT(IN) :: elem_boxes(n_elements, 6)
    INTEGER(i4), INTENT(OUT) :: contact_pairs(2, n_elements)
    INTEGER(i4), INTENT(OUT) :: n_pair
    INTEGER(i4), INTENT(OUT) :: status
    
    TYPE(BVH_Tree) :: tree
    INTEGER(i4) :: i, j, hits(100), n_hits
    
    status = 0
    n_pair = 0
    
    ! Build BVH for all element bounding boxes
    CALL BVH_Create(tree, n_objects=n_elements, status=status)
    CALL BVH_Build(tree, elem_boxes, strategy='MEDIAN', status=status)
    
    ! For each element, find potential contacts
    DO i = 1, n_elements
      ! Query elements that might intersect with element i's bounding box
      CALL BVH_RayCast(tree, &
                       ray_origin=elem_boxes(i, 1:3), &
                       ray_direction=[1.0_wp, 0.0_wp, 0.0_wp], &
                       max_distance=elem_boxes(i, 4) - elem_boxes(i, 1), &
                       hit_objects=hits, n_hits=n_hits, status=status)
      
      ! Process hits (simplified - real implementation would use box overlap)
      DO j = 1, n_hits
        IF (hits(j) /= i) THEN  ! Exclude self
          n_pair = n_pair + 1
          contact_pairs(1, n_pair) = i
          contact_pairs(2, n_pair) = hits(j)
        END IF
      END DO
    END DO
    
    CALL BVH_Destroy(tree)
    
  END SUBROUTINE PH_Cont_GlobalSearch
  
END MODULE PH_Cont_BVH_Search
```

---

## 性能优化建议

### 1. 分裂策略选择

| 场景 | 推荐策略 | 理由 |
|------|----------|------|
| 静态几何 | SAH | 一次构建，多次查询 |
| 动态几何 | MEDIAN | 频繁重建，快速构建 |
| 实时渲染 | EQUAL_AREA | 平衡质量和速度 |

### 2. 深度控制

```fortran
! 推荐设置
max_depth = 20    ! 10K 对象约需 14 层
min_leaf_size = 4 ! 叶节点最小对象数
```

### 3. 自适应重建

```fortran
! 触发条件
IF (max_displacement > 0.1_wp * element_size .OR. &
    ABS(n_contacts - old_n_contacts) > 0.5_wp * n_contacts) THEN
  CALL BVH_Rebuild(tree, new_boxes, status)
END IF
```

---

## 架构合规性验证

### 依赖检查

```bash
# 检查 L2_NM/BVH 是否只依赖 L1/L2 内部模块
grep -E "^USE (L[3-6]|RT_|PH_|MD_)" UFC/ufc_core/L2_NM/BVH/*.f90
# 预期：无输出
```

### 编译验证

```bash
gfortran -std=f2003 -fsyntax-only UFC/ufc_core/L2_NM/BVH/*.f90
```

---

## 测试计划

### 单元测试

1. **构建测试**
   - 不同对象数量（1, 10, 100, 10K, 100K）
   - 不同分裂策略
   - 边界条件（空输入、单对象）

2. **查询测试**
   - 射线求交正确性
   - 最近邻正确性
   - 空结果处理

3. **性能测试**
   - 构建时间基准
   - 查询时间基准
   - 内存使用

### 集成测试

1. **Contact 搜索集成**
2. **并行 BVH 构建**（结合 ThreadWS）

---

## 交付清单

- [x] `NM_BVH_Types.f90` (+296 行) - 类型定义
- [x] `NM_BVH_Core.f90` (+502 行) - 核心算法
- [x] `NM_BVH_API.f90` (+213 行) - 薄适配器 API
- [ ] `CONTRACT.md` (+350 行) - 域合同文档（本文档）
- [ ] 验证脚本（待创建）

**总代码量**：~1,011 行

---

## Phase 3 完成度

| 任务 | 状态 | 代码量 | 工时 |
|------|------|--------|------|
| A: BVH 构建算法 | 🟡 进行中 | ~1,011 行 | ~1.5h |
| B: 查询接口 | ⏳ 待启动 | - | ~1.0h |
| C: 自适应重建 | ⏳ 待启动 | - | ~0.5h |

**Phase 3 总计**: 1/3 完成

---

## 历史决策记录

### 为什么选择在 L2_NM 而非 L4_PH 实现 BVH？

**问题**：BVH 是空间加速结构，可被多个域（Contact、Mesh、RayTracing）复用

**解决方案**：在 L2_NM（数值方法层）实现，作为通用基础设施工具

**收益**：
- ✅ 架构复用性提升
- ✅ 与具体物理域解耦
- ✅ Contact/Mesh/其他域均可调用


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_BVH.f90` | `NM_BVH` | — | `NM_BVH_Build` (SUB,PUB,Populate); `NM_BVH_BuildMedian` (SUB,PUB,Populate); `NM_BVH_BuildSAH` (SUB,PUB,Populate); `NM_BVH_QueryRay` (SUB,PUB,Query); `NM_BVH_QueryNearest` (SUB,PUB,Query); `NM_BVH_Rebuild` (SUB,PUB,—); `NM_BVH_UpdateStats` (SUB,PUB,Compute) |
| `NM_BVH_Brg.f90` | `NM_BVH_Brg` | — | `NM_BVH_Create` (SUB,PUB,Init); `BVH_Create_Simple` (SUB,PRV,Init); `NM_BVH_Destroy` (SUB,PUB,Finalize); `BVH_Build_Str` (SUB,PRV,Populate); `BVH_RayCast_Simple` (SUB,PRV,—); `BVH_FindNearest_Simple` (SUB,PRV,Query); `NM_BVH_IsBuilt` (FN,PUB,Query) |
| `NM_BVH_Def.f90` | `NM_BVH_Def` | `BVH_Node` | `ComputeVolume` (TBP,PRV,—); `ComputeSurfaceArea` (TBP,PRV,—); `Overlaps` (TBP,PRV,—); `ContainsPoint` (TBP,PRV,—); `BVH_Node_ComputeVolume` (FN,PRV,Compute); `BVH_Node_ComputeSurfaceArea` (FN,PRV,Compute); `BVH_Node_Overlaps` (FN,PRV,—); `BVH_Node_ContainsPoint` (FN,PRV,—); `BVH_Tree_Initialize` (SUB,PRV,Init); `BVH_Tree_Destroy` (SUB,PRV,Finalize); `BVH_Tree_GetBoundingBox` (SUB,PRV,Query); `BVH_Tree_IsBuilt` (FN,PRV,Query); `BVH_Stack_Initialize` (SUB,PRV,Init); `BVH_Stack_Push` (SUB,PRV,—); `BVH_Stack_Pop` (SUB,PRV,—); `BVH_Stack_IsEmpty` (FN,PRV,Query); `BVH_Stack_Destroy` (SUB,PRV,Finalize) |
