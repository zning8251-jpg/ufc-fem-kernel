# Assembly域四链贯通设计文档

**层**: L3_MD  
**域**: Assembly (装配域)  
**子域**: Instance (已融合)  
**状态**: v5.1 Release  
**日期**: 2026-04-13  

---

## 1. 概述

Assembly域是L3_MD层的**根装配真相源（Root Assembly Single Source of Truth）**，负责管理Part实例、节点集/单元集、表面定义和约束定义。本设计通过**四链贯通**实现从装配理论到运行时查询的端到端闭环。

**关键特性**:
- ✅ 纯静态定义（**无WriteBack**）
- ✅ part_ref跨域校验（Part域索引）
- ✅ 约束主从面校验（存在于assembly%surfaces）
- ✅ Rodrigues旋转矩阵变换
- ✅ 全局编号偏移计算

---

## 2. 四链定义

### 2.1 理论链 (Theory Chain)

**路径**: ABAQUS装配理论 → UFC实例变换 → Fortran实现

| 理论概念 | UFC映射 | 实现文件 |
|---------|---------|---------|
| 实例变换 x_global = R·x_local + t | UF_InstanceDef%translation/rotation_matrix | MD_Instance_Algo.f90 |
| Rodrigues旋转公式 | R = cos(θ)I + sin(θ)[k]× + (1-cos(θ))k⊗k | instance_set_rotation |
| 全局编号 | node_offset/elem_offset/dof_offset | UF_InstanceDef |
| 集合定义 | MD_SetDef%members(:) | MD_Assem_Algo.f90 |
| 表面定义 | MD_SurfaceDef%elem_ids/face_ids | MD_Assem_Algo.f90 |
| 约束定义 | MD_ConstraintDef%master_surface/slave_surface | MD_Assem_Algo.f90 |

**贯通逻辑**:
```
ABAQUS *INSTANCE/*NSET/*ELSET/*SURFACE/*TIE
  → MD_Assembly_Domain_Init()
    → AddInstance(part_ref/translation/rotation)
    → AddNodeSet(name/members)
    → AddSurface(name/elem_ids/face_ids)
    → AddTieConstraint(master/slave/tolerance)
      → ValidateAllRefs() 跨域校验
        → [l3Frozen = .TRUE.] 冻结Desc
```

### 2.2 逻辑链 (Logic Chain)

**路径**: L6解析 → Add*填充 → Validate校验 → 冻结 → L5查询

```
L6_AP 解析阶段
  ├─ 解析 *INSTANCE 卡片
  │   └─ MD_Assembly_Domain_AddInstance(desc)
  │       ├─ part_ref (Part域索引)
  │       ├─ translation(3)
  │       └─ rotation(3,3)  ← Rodrigues公式
  ├─ 解析 *NSET 卡片
  │   └─ MD_Assembly_Domain_AddNodeSet(def)
  ├─ 解析 *ELSET 卡片
  │   └─ MD_Assembly_Domain_AddElemSet(def)
  ├─ 解析 *SURFACE 卡片
  │   └─ MD_Assembly_Domain_AddSurface(def)
  └─ 解析 *TIE/*MPC/*COUPLING/*RIGID 卡片
      └─ MD_Assembly_Domain_Add*Constraint(def)
          ↓
ValidateAllRefs()  ← 跨域引用校验
  ├─ instance%part_ref ∈ [1, part%n_parts]
  ├─ constraint%master_surface ∈ assembly%surfaces
  └─ constraint%slave_surface ∈ assembly%surfaces
      ↓
[l3Frozen = .TRUE.]  ← 冻结Desc (不可修改)
      ↓
求解阶段 (只读查询)
  ├─ L5_RT Assembly: GetInstance/GetNodeSet/GetElemSet
  ├─ L5_RT Assembly: GetSurface (接触查询)
  ├─ LoadBC域: GetNodeSetByName (边界条件施加)
  └─ Interaction域: GetSurfaceByName (接触对定义)
      ↓
MD_Assembly_Domain_Finalize()
  └─ DEALLOCATE 所有数组
```

### 2.3 计算链 (Computation Chain)

**路径**: 初始化 → O(1)索引查询 → O(n)名称查询

| 操作 | 算法 | 复杂度 | 实现 |
|------|------|--------|------|
| Init | 数组分配+初始化 | O(1) | MD_Assembly_Domain_Init |
| AddInstance | 动态数组扩容(×2) | O(1)均摊 | MOVE_ALLOC |
| AddNodeSet | 动态数组扩容(×2) | O(1)均摊 | MOVE_ALLOC |
| GetInstance(idx) | 直接索引 | **O(1)** | instances(idx) |
| GetNodeSet(idx) | 直接索引 | **O(1)** | node_sets(idx) |
| GetNodeSetByName(name) | 线性搜索 | O(n_sets) | TRIM(name)==TRIM(target) |
| GetSurfaceByName(name) | 线性搜索 | O(n_surfaces) | 同上 |
| instance_transform_point | 矩阵乘法 | **O(1)** | R·(x-p)+p+t |
| instance_get_global_node_id | 加法 | **O(1)** | local_id + node_offset |
| Finalize | 数组释放 | O(n_instances+n_sets) | DEALLOCATE |

**性能优化策略**:
```fortran
! 动态数组扩容策略（Add*子程序）
IF (.NOT. ALLOCATED(this%instances)) THEN
  ALLOCATE(this%instances(16))  ! 初始容量16
ELSE IF (this%n_instances > SIZE(this%instances)) THEN
  ALLOCATE(tmp(this%n_instances * 2))  ! 扩容×2
  tmp(1:this%n_instances-1) = this%instances(1:this%n_instances-1)
  CALL MOVE_ALLOC(tmp, this%instances)  ! 零拷贝移动
END IF
```

### 2.4 数据链 (Data Chain)

**路径**: Desc(只读冻结) → State(运行监控) → Algo(求解参数) → Ctx(瞬态缓存)

```
L3_MD 域容器 (MD_Assembly_Domain)
  │
  ├── Desc (Write-Once, Read-Many) ← 冻结后不可修改
  │   ├── instances(:)       → MD_Instance_Desc数组(part_ref/translation/rotation)
  │   ├── node_sets(:)       → MD_SetDef数组(name/members(:))
  │   ├── elem_sets(:)       → MD_SetDef数组(name/members(:))
  │   ├── surfaces(:)        → MD_SurfaceDef数组(name/elem_ids/face_ids)
  │   └── constraints(:)     → MD_ConstraintDef数组(master_surface/slave_surface)
  │
  ├── State (Runtime Monitoring) ← 求解期监控约束状态
  │   ├── active_constraints         → 激活约束数
  │   ├── active_contact_pairs       → 激活接触对数
  │   ├── total_constraint_violations→ 总违反次数
  │   ├── max_constraint_error       → 最大约束误差
  │   ├── tie_satisfied/pc_satisfied → Tie/MPC满足标志
  │   └── failed_constraints         → 失败约束数
  │
  ├── Algo (Solve-Phase Read-Only) ← 求解期只读
  │   ├── default_tie_tolerance      → 默认Tie容差(0.01)
  │   ├── mpc_penalty_factor         → MPC惩罚因子(1.0E+8)
  │   ├── auto_adjust                → 自动调整(.TRUE.)
  │   ├── max_constraint_iters       → 最大迭代数(100)
  │   ├── small_sliding_default      → 默认小滑移(.FALSE.)
  │   └── rigid_auto_ref             → 刚体自动参考(.TRUE.)
  │
  └── Ctx (Transient Cache) ← 瞬态缓存
      ├── current_inst_id            → 当前实例ID
      ├── transform_cached           → 变换缓存标志
      ├── cached_translation(3)      → 缓存平移
      ├── cached_rotation(3,3)       → 缓存旋转
      ├── current_constraint_idx     → 当前约束索引
      └── constraint_cache_valid     → 约束缓存有效标志
```

---

## 3. 关键特性：无WriteBack设计

### 3.1 与Mesh域对比

| 特性 | Assembly域 | Mesh域 |
|------|-----------|--------|
| **WriteBack** | ❌ **无**（纯静态） | ✅ 6个白名单API |
| **可变字段** | 无 | node_state%currentCoords等 |
| **冻结时机** | ValidateAllRefs后 | GlobalNum_Build后 |
| **运行时修改** | 不允许 | 大变形允许回写 |
| **设计原因** | 装配关系不随求解变化 | 大变形需更新坐标 |

### 3.2 纯静态定义的优势

```fortran
! ✅ Assembly域：Desc永久冻结
TYPE :: MD_Assembly_Domain
  TYPE(MD_Instance_Desc), ALLOCATABLE :: instances(:)  ! Write-Once
  TYPE(MD_SetDef), ALLOCATABLE :: node_sets(:)         ! Write-Once
  TYPE(MD_SurfaceDef), ALLOCATABLE :: surfaces(:)      ! Write-Once
  TYPE(MD_ConstraintDef), ALLOCATABLE :: constraints(:)! Write-Once
END TYPE

! 求解期只能Get*，不能Add*或修改
CALL assembly%GetInstance(idx, desc, status)  ! ✅ 只读
CALL assembly%AddInstance(desc, status)        ! ❌ 求解期禁止
```

---

## 4. 跨域依赖关系

### 4.1 域间调用矩阵

| 调用方 | 调用接口 | 用途 | 调用时机 |
|--------|---------|------|---------|
| **L6_AP** | MD_Assembly_Domain_AddInstance | 添加实例 | 解析*INSTANCE |
| **L6_AP** | MD_Assembly_Domain_AddNodeSet | 添加节点集 | 解析*NSET |
| **L6_AP** | MD_Assembly_Domain_AddSurface | 添加表面 | 解析*SURFACE |
| **L6_AP** | MD_Assembly_Domain_AddTieConstraint | 添加Tie约束 | 解析*TIE |
| **L5_RT Assembly** | MD_Assembly_Domain_GetInstance | 获取实例 | 装配全局K/F |
| **L5_RT Assembly** | MD_Assembly_Domain_GetNodeSet | 获取节点集 | 载荷施加 |
| **L5_RT Assembly** | MD_Assembly_Domain_GetSurface | 获取表面 | 接触查找 |
| **LoadBC域** | MD_Assembly_Domain_GetNodeSetByName | 按名查节点集 | 边界条件 |
| **Interaction域** | MD_Assembly_Domain_GetSurfaceByName | 按名查表面 | 接触对定义 |
| **Constraint域** | MD_Assembly_Domain_GetConstraint | 获取约束 | 约束方程 |

### 4.2 跨域引用校验

```fortran
! MD_L3_ValidateAssemblyRefs()
SUBROUTINE MD_L3_ValidateAssemblyRefs(assembly, part, status)
  ! 校验1: instance%part_ref 有效性
  DO i = 1, assembly%n_instances
    IF (assembly%instances(i)%part_ref < 1 .OR. &
        assembly%instances(i)%part_ref > part%n_parts) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') &
           "Invalid part_ref: ", assembly%instances(i)%part_ref, &
           " / ", part%n_parts
      RETURN
    END IF
  END DO
  
  ! 校验2: constraint%master_surface/slave_surface 存在性
  DO i = 1, assembly%n_constraints
    master_found = .FALSE.
    slave_found = .FALSE.
    DO j = 1, assembly%n_surfaces
      IF (TRIM(assembly%constraints(i)%master_surface) == &
          TRIM(assembly%surfaces(j)%name)) master_found = .TRUE.
      IF (TRIM(assembly%constraints(i)%slave_surface) == &
          TRIM(assembly%surfaces(j)%name)) slave_found = .TRUE.
    END DO
    IF (.NOT. master_found .OR. .NOT. slave_found) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint surface not found"
      RETURN
    END IF
  END DO
END SUBROUTINE
```

### 4.3 依赖图

```
L6_AP (解析层)
  ↓ 解析*INSTANCE/*NSET/*ELSET/*SURFACE/*TIE
Assembly域 (L3_MD)
  ├─ MD_Assembly_Domain_Init
  ├─ AddInstance/AddNodeSet/AddSurface/AddConstraint
  ├─ ValidateAllRefs (part_ref/surface校验)
  └─ [l3Frozen = .TRUE.]
      ↓ 只读查询
  ┌──────────────┬───────────────┬────────────────┐
  ↓              ↓               ↓                ↓
L5_RT         LoadBC        Interaction      Constraint
(Assembly)    (边界条件)     (接触)           (约束)
  ↓              ↓               ↓                ↓
GetInstance   GetNodeSet     GetSurface        GetConstraint
GetNodeSet    ByName         ByName
GetSurface
```

---

## 5. 关键接口设计

### 5.1 域容器接口

```fortran
TYPE :: MD_Assembly_Domain
  !--- Desc (Write-Once) ---
  TYPE(MD_Instance_Desc),   ALLOCATABLE :: instances(:)
  TYPE(MD_SetDef),          ALLOCATABLE :: node_sets(:)
  TYPE(MD_SetDef),          ALLOCATABLE :: elem_sets(:)
  TYPE(MD_SurfaceDef),      ALLOCATABLE :: surfaces(:)
  TYPE(MD_ConstraintDef),   ALLOCATABLE :: constraints(:)
  
  !--- Union Types ---
  TYPE(MD_ConstraintUnion)              :: constraint_union
  TYPE(MD_InteractionUnion)             :: interaction_union
  
  !--- Counters ---
  INTEGER(i4) :: n_instances   = 0
  INTEGER(i4) :: n_node_sets   = 0
  INTEGER(i4) :: n_elem_sets   = 0
  INTEGER(i4) :: n_surfaces    = 0
  INTEGER(i4) :: n_constraints = 0
  
  !--- Algo/State/Ctx ---
  TYPE(AssemblyAlgo)  :: algo
  TYPE(AssemblyState) :: state
  TYPE(AssemblyCtx)   :: ctx
  
  !--- Control ---
  LOGICAL :: initialized = .FALSE.

CONTAINS
  PROCEDURE :: Init          => MD_Assembly_Domain_Init
  PROCEDURE :: Finalize      => MD_Assembly_Domain_Finalize
  PROCEDURE :: AddInstance   => MD_Assembly_Domain_AddInstance
  PROCEDURE :: AddNodeSet    => MD_Assembly_Domain_AddNodeSet
  PROCEDURE :: AddElemSet    => MD_Assembly_Domain_AddElemSet
  PROCEDURE :: AddSurface    => MD_Assembly_Domain_AddSurface
  PROCEDURE :: AddConstraint => MD_Assembly_Domain_AddConstraint
  PROCEDURE :: AddTieConstraint    => MD_Assembly_Domain_AddTieConstraint
  PROCEDURE :: AddMPCConstraint    => MD_Assembly_Domain_AddMPCConstraint
  PROCEDURE :: AddCouplingConstraint => MD_Assembly_Domain_AddCouplingConstraint
  PROCEDURE :: AddRigidConstraint  => MD_Assembly_Domain_AddRigidConstraint
  PROCEDURE :: GetInstance      => MD_Assembly_Domain_GetInstance
  PROCEDURE :: GetNodeSet       => MD_Assembly_Domain_GetNodeSet
  PROCEDURE :: GetNodeSetByName => MD_Assembly_Domain_GetNodeSetByName
  PROCEDURE :: GetElemSet       => MD_Assembly_Domain_GetElemSet
  PROCEDURE :: GetSurface       => MD_Assembly_Domain_GetSurface
  PROCEDURE :: GetSurfaceByName => MD_Assembly_Domain_GetSurfaceByName
  PROCEDURE :: GetConstraint    => MD_Assembly_Domain_GetConstraint
  PROCEDURE :: ReleaseConstraintUnion   => MD_Assembly_Domain_ReleaseConstraintUnion
  PROCEDURE :: ReleaseInteractionUnion  => MD_Assembly_Domain_ReleaseInteractionUnion
END TYPE
```

### 5.2 实例变换接口

```fortran
TYPE :: UF_InstanceDef
  CHARACTER(LEN=80) :: name = ""
  INTEGER(i4) :: id = 0
  INTEGER(i4) :: part_id = 0           ! Part域索引
  
  ! 变换参数
  REAL(wp) :: translation(3) = 0.0_wp
  REAL(wp) :: rotation_matrix(3,3)     ! Rodrigues公式构建
  REAL(wp) :: rotation_axis(3)         ! 旋转轴
  REAL(wp) :: rotation_angle           ! 旋转角度(度)
  REAL(wp) :: rotation_point(3)        ! 旋转轴上点
  
  ! 全局编号偏移
  INTEGER(i4) :: node_offset = 0
  INTEGER(i4) :: elem_offset = 0
  INTEGER(i4) :: dof_offset = 0
  
  ! 状态标志
  LOGICAL :: is_dependent = .FALSE.
  LOGICAL :: is_suppressed = .FALSE.

CONTAINS
  PROCEDURE :: init => instance_init
  PROCEDURE :: bind_part => instance_bind_part
  PROCEDURE :: set_translation => instance_set_translation
  PROCEDURE :: set_rotation => instance_set_rotation
  PROCEDURE :: set_rotation_from_points => instance_set_rotation_from_points
  PROCEDURE :: transform_point => instance_transform_point
  PROCEDURE :: get_global_node_id => instance_get_global_node_id
  PROCEDURE :: get_global_elem_id => instance_get_global_elem_id
END TYPE
```

---

## 6. 实例变换算法

### 6.1 Rodrigues旋转公式

```fortran
! 输入: axis(3), angle(度), point(3)
! 输出: rotation_matrix(3,3)

SUBROUTINE instance_set_rotation(this, point, axis, angle)
  ! 1. 角度转弧度
  theta = angle * PI / 180.0_wp
  
  ! 2. 归一化旋转轴
  norm = SQRT(axis(1)**2 + axis(2)**2 + axis(3)**2)
  k = axis / norm
  
  ! 3. Rodrigues公式
  c = COS(theta)
  s = SIN(theta)
  t = 1.0_wp - c
  
  ! 4. 构建旋转矩阵
  R(1,1) = t*k(1)*k(1) + c
  R(1,2) = t*k(1)*k(2) - s*k(3)
  R(1,3) = t*k(1)*k(3) + s*k(2)
  
  R(2,1) = t*k(1)*k(2) + s*k(3)
  R(2,2) = t*k(2)*k(2) + c
  R(2,3) = t*k(2)*k(3) - s*k(1)
  
  R(3,1) = t*k(1)*k(3) - s*k(2)
  R(3,2) = t*k(2)*k(3) + s*k(1)
  R(3,3) = t*k(3)*k(3) + c
END SUBROUTINE
```

### 6.2 坐标变换

```fortran
! 局部坐标 → 全局坐标
FUNCTION instance_transform_point(this, local_coords) RESULT(global_coords)
  ! x_global = R·(x_local - p) + p + t
  temp = local_coords - this%rotation_point
  global_coords = MATMUL(this%rotation_matrix, temp)
  global_coords = global_coords + this%rotation_point + this%translation
END FUNCTION
```

### 6.3 全局编号计算

```fortran
! 局部节点ID → 全局节点ID
FUNCTION instance_get_global_node_id(this, local_id) RESULT(global_id)
  global_id = local_id + this%node_offset
END FUNCTION

! 局部单元ID → 全局单元ID
FUNCTION instance_get_global_elem_id(this, local_id) RESULT(global_id)
  global_id = local_id + this%elem_offset
END FUNCTION
```

---

## 7. 约束类型体系

### 7.1 约束枚举

| 约束类型 | 常量值 | 物理含义 | 适用场景 |
|---------|--------|---------|---------|
| CONSTRAINT_TIE | 1 | Tie绑定(主从面绑定) | 接触面绑定 |
| CONSTRAINT_COUPLING | 2 | 耦合约束 | 载荷分布 |
| CONSTRAINT_MPC | 3 | 多点约束方程 | 刚性连接 |
| CONSTRAINT_RIGID_BODY | 4 | 刚体约束 | 刚体运动 |
| CONSTRAINT_EMBEDDED | 5 | 嵌入约束 | 钢筋混凝土 |
| CONSTRAINT_TRANSFORM | 6 | 变换约束 | 坐标系变换 |
| CONSTRAINT_CLEARANCE | 7 | 间隙约束 | 接触间隙 |
| CONSTRAINT_SHELL_SOLID_COUPLING | 8 | 壳-固耦合 | 混合单元 |
| CONSTRAINT_CYCLIC_SYMMETRY | 9 | 循环对称 | 旋转机械 |

### 7.2 约束定义TYPE

```fortran
TYPE :: MD_ConstraintDef
  CHARACTER(LEN=64) :: name = ""
  INTEGER(i4) :: constraint_id = 0
  INTEGER(i4) :: constraint_type = CONSTRAINT_TIE
  
  ! Tie约束字段
  CHARACTER(LEN=64) :: master_surface = ""
  CHARACTER(LEN=64) :: slave_surface = ""
  REAL(wp) :: tolerance = 0.0_wp
  LOGICAL :: adjust = .TRUE.
  
  ! MPC约束字段 (扩展)
  INTEGER(i4) :: num_terms = 0
  INTEGER(i4), ALLOCATABLE :: mpc_nodes(:)
  INTEGER(i4), ALLOCATABLE :: mpc_dofs(:)
  REAL(wp), ALLOCATABLE :: mpc_coeffs(:)
END TYPE
```

---

## 8. 内存管理策略

### 8.1 数组分配策略

| 数组 | 分配时机 | 初始容量 | 扩容策略 | 释放时机 |
|------|---------|---------|---------|---------|
| instances(:) | AddInstance首次调用 | 16 | ×2 (MOVE_ALLOC) | Finalize |
| node_sets(:) | AddNodeSet首次调用 | 16 | ×2 (MOVE_ALLOC) | Finalize |
| elem_sets(:) | AddElemSet首次调用 | 16 | ×2 (MOVE_ALLOC) | Finalize |
| surfaces(:) | AddSurface首次调用 | 16 | ×2 (MOVE_ALLOC) | Finalize |
| constraints(:) | AddConstraint首次调用 | 16 | ×2 (MOVE_ALLOC) | Finalize |
| constraint_union | 按需分配 | - | - | ReleaseConstraintUnion |
| interaction_union | 按需分配 | - | - | ReleaseInteractionUnion |

### 8.2 动态扩容实现

```fortran
SUBROUTINE MD_Assembly_Domain_AddInstance(this, desc, status)
  TYPE(MD_Instance_Desc), ALLOCATABLE :: tmp(:)
  
  this%n_instances = this%n_instances + 1
  
  IF (.NOT. ALLOCATED(this%instances)) THEN
    ALLOCATE(this%instances(16))  ! 初始容量
  ELSE IF (this%n_instances > SIZE(this%instances)) THEN
    ALLOCATE(tmp(this%n_instances * 2))  ! 扩容×2
    tmp(1:this%n_instances-1) = this%instances(1:this%n_instances-1)
    CALL MOVE_ALLOC(tmp, this%instances)  ! 零拷贝移动
  END IF
  
  this%instances(this%n_instances) = desc
END SUBROUTINE
```

---

## 9. 错误处理

### 9.1 错误类型

| 错误场景 | 错误码 | 处理策略 |
|---------|--------|---------|
| 未初始化查询 | IF_STATUS_INVALID | 返回错误 |
| 索引越界 | IF_STATUS_INVALID | 边界检查拦截 |
| part_ref无效 | IF_STATUS_INVALID | ValidateAllRefs校验 |
| 约束表面不存在 | IF_STATUS_INVALID | 表面名校验 |
| 重复名称 | IF_STATUS_INVALID | 名称唯一性检查 |

### 9.2 边界检查示例

```fortran
SUBROUTINE MD_Assembly_Domain_GetInstance(this, idx, desc, status)
  CALL init_error_status(status)
  
  ! 初始化检查
  IF (.NOT. this%initialized) THEN
    status%status_code = IF_STATUS_INVALID
    RETURN
  END IF
  
  ! 边界检查
  IF (idx < 1 .OR. idx > this%n_instances) THEN
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,I0,A,I0)') &
         "Instance index out of range: ", idx, " / ", this%n_instances
    RETURN
  END IF
  
  ! 安全查询
  desc = this%instances(idx)
  status%status_code = IF_STATUS_OK
END SUBROUTINE
```

---

## 10. 验证策略

### 10.1 功能验证

| 测试项 | 验证内容 | 预期结果 |
|--------|---------|---------|
| Init/Finalize | 成对调用 | 无内存泄漏 |
| AddInstance | 添加实例 | n_instances+1 |
| AddNodeSet | 添加节点集 | n_node_sets+1 |
| GetInstance(idx) | O(1)查询 | 返回正确实例 |
| GetNodeSetByName | O(n)查询 | 返回正确集合 |
| ValidateAllRefs | part_ref校验 | 全部通过 |
| 无WriteBack | 求解期修改 | 编译错误 |

### 10.2 性能验证

| 测试场景 | 规模 | 指标 |
|---------|------|------|
| 装配初始化 | 100实例 | < 0.5秒 |
| GetInstance | 10万次查询 | < 0.05秒 |
| GetNodeSetByName | 1000集合 | < 0.1秒 |

---

## 11. 文件清单

### L3_MD/Assembly 域（当前 .f90 与合同/设计）

```
L3_MD/Assembly/
├── MD_Assem_Algo.f90              # 域容器：MD_Assembly_Domain、Idx API、全局委托
├── MD_Assem_Domain.f90            # 薄门面：再导出（兼容 USE MD_Assem_Domain）
├── MD_Assem_Legacy.f90            # Legacy UF + SyncFromLegacy / MirrorUFConstraint
├── MD_Instance_Algo.f90           # UF 实例 / legacy 实例子程序
├── CONTRACT.md
└── DESIGN_Assembly_FourTypes.md
```

**已删除文件**（精简优化）:
- ~~MD_Assem_Mgr.f90~~ (3088行，零调用)
- ~~MD_Assembly_API.f90~~ (123行，简单转发)
- ~~MD_Instance_API.f90~~ (80行，零调用)
- ~~MD_Assem_Types.f90~~、~~MD_Assem_Types_Impl.f90~~、~~MD_Assem_Core.f90~~、~~MD_Assem_Lib.f90~~、~~MD_Assem_Sync.f90~~（已收敛至 **MD_Assem_Algo** / **MD_Assem_Legacy**）

---

## 12. 附录

### 12.1 符号约定

| 符号 | 含义 | 单位/类型 |
|------|------|----------|
| n_instances | 实例总数 | INTEGER(i4) |
| n_node_sets | 节点集总数 | INTEGER(i4) |
| n_surfaces | 表面总数 | INTEGER(i4) |
| n_constraints | 约束总数 | INTEGER(i4) |
| part_ref | Part域索引 | INTEGER(i4), 1-based |
| node_offset | 节点编号偏移 | INTEGER(i4) |
| elem_offset | 单元编号偏移 | INTEGER(i4) |

### 12.2 阶段演进

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 1 | 域容器设计+四链定义 | ✅ 完成 |
| Phase 2 | Arg参数容器+索引API | ✅ 完成 |
| Phase B | 精简优化(删除5个文件) | ✅ 完成 |
| Phase C | Legacy代码清理 | ⏳ 规划中 |

---

**文档维护**: 随L3_MD/Assembly代码同步更新  
**下次审查**: Phase C Legacy清理后更新状态  
**相关文档**: 
- `L3_MD_Assembly_域级建模文档.md`
- `DESIGN_Assembly_FourTypes.md`
- `Assembly/CONTRACT.md`
