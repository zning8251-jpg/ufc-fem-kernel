# Mesh域四链贯通设计文档

**层**: L3_MD  
**域**: Mesh (网格域)  
**子域**: DOF / Node  
**状态**: v5.1 Release  
**日期**: 2026-04-13  

---

## 1. 概述

Mesh域是UFC架构的**拓扑真相源（Single Source of Truth）**，为所有物理计算提供离散空间基础。本设计通过**四链贯通**实现从网格离散化理论到运行时查询的端到端闭环。

---

## 2. 四链定义

### 2.1 理论链 (Theory Chain)

**路径**: ABAQUS网格离散化 → UFC拓扑定义 → Fortran实现

| 理论概念 | UFC映射 | 实现文件 |
|---------|---------|---------|
| 节点位置 X ∈ R^(3×n_n) | MeshNodeDesc%coords(3) | MD_Mesh_Node.f90 |
| 单元连接 conn ∈ Z^(max_npe×n_e) | MeshElemDesc%connectivity(:) | MD_Mesh_Elem.f90 |
| 形函数 N(ξ,η,ζ) | L4_PH Element域 | (不在L3) |
| 雅可比 J = dX/dξ | L4_PH计算 | (不在L3) |
| DOF映射 L→G | MeshGlobalNum%nodeMap(:) | MD_Mesh_GlobalNum.f90 |

**贯通逻辑**:
```
ABAQUS *NODE/*ELEMENT
  → MD_Mesh_Domain_Init(nNodes, nElems, spatialDim)
    → MeshData%Init() 分配存储
      → GlobalNum_BuildFromFlat() 构建DOF映射
        → [l3Frozen = .TRUE.] 冻结Desc
```

### 2.2 逻辑链 (Logic Chain)

**路径**: L6解析 → 初始化 → DOF编号 → 冻结 → L4/L5查询 → 大变形回写

```
L6_AP 解析阶段
  ├─ 解析 *NODE 卡片
  │   └─ MeshData%AddNode(coords, global_id)
  ├─ 解析 *ELEMENT 卡片
  │   └─ MeshData%AddElement(connect, elem_type, section_ref)
  └─ 解析 *NSET/*ELSET 卡片
      └─ 节点集/单元集注册
          ↓
MD_Mesh_Domain_Init(nNodes, nElems, spatialDim)
  ├─ ALLOCATE node_desc(nNodes)
  ├─ ALLOCATE elem_desc(nElems)
  ├─ ALLOCATE node_state(nNodes)
  └─ ALLOCATE elem_state(nElems)
      ↓
GlobalNum_BuildFromFlat(nNodes, nElems, conn, nDofPerNode)
  ├─ 分配 nodeMap(nNodes)
  ├─ 分配 elemMap(nElems)
  ├─ 节点映射: dofStartIndex = nDofPerNode*(i-1)+1
  ├─ 单元映射: connGlobalNodes 从connectivity提取
  └─ nTotalEq = nDofPerNode * nNodes
      ↓
[l3Frozen = .TRUE.]  ← 冻结Desc (不可修改)
      ↓
求解阶段 (只读查询)
  ├─ 步边界 (Step Boundary)
  │   └─ L4_PH: MD_Mesh_Domain_GetElemConnect()  ← 获取单元连接
  ├─ 增量循环 (Increment Loop)
  │   ├─ L4_PH: MD_Mesh_Domain_GetNodeCoords()   ← 获取节点坐标
  │   └─ L5_RT: MD_Mesh_Domain_GetDofMap()       ← 获取DOF映射
  └─ 大变形分析 (Large Deform)
      └─ L5_RT: MD_Mesh_WriteBack_NodePos()      ← 回写更新坐标
          ↓
MD_Mesh_Domain_Finalize()
  └─ DEALLOCATE 所有数组
```

### 2.3 计算链 (Computation Chain)

**路径**: 初始化 → O(1)查询 → 可选回写

| 操作 | 算法 | 复杂度 | 实现 |
|------|------|--------|------|
| Init | 数组分配+初始化 | O(nNodes+nElems) | MD_Mesh_Domain_Init |
| GetNodeCoords | 直接索引 `node_coords(:,id)` | **O(1)** | MeshData%GetNodeCoords |
| GetElemConnect | 直接索引 `element_connect(:,id)` | **O(1)** | MeshData%GetElementConnectivity |
| GetDofMap | 查表 `nodeMap(id)%dofStartIndex` | **O(1)** | MeshGlobalNum查询 |
| GetSurfaceByName | 线性搜索 | O(nSurfaces) | ⚠️ 可优化为哈希表 |
| WriteBack_NodePos | 数组赋值 `node_state(id)%currentCoords = new` | **O(1)** | 白名单校验后直接赋值 |
| Finalize | 数组释放 | O(nNodes+nElems) | MD_Mesh_Domain_Finalize |

**性能优化策略**:
```fortran
! 推荐：SoA (Structure of Arrays) 布局 - 利于向量化
REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! (3, nNodes)
INTEGER(i4), ALLOCATABLE :: element_connect(:,:)  ! (maxNPE, nElems)

! 替代：AoS (Array of Structures) - 不利于向量化
TYPE(MeshNodeDesc), ALLOCATABLE :: nodes(:)  ! 当前部分实现
```

### 2.4 数据链 (Data Chain)

**路径**: Desc(只读) → State(可回写) → Algo(求解参数) → Ctx(瞬态)

```
L3_MD 域容器 (MD_Mesh_Domain)
  │
  ├── Desc (Write-Once, Read-Many) ← 冻结后不可修改
  │   ├── desc             → mesh_id/name/nNodes/nElems/spatial_dim/elem_family
  │   ├── node_desc(:)     → global_node_id/coords(3)  [分析级冻结]
  │   ├── elem_desc(:)     → elem_type/connectivity(:) [分析级冻结]
  │   └── global_num       → dof_sys (GlobalNum_Build后冻结)
  │
  ├── State (WriteBack Whitelist) ← 仅允许白名单API修改
  │   ├── state            → isActive/nAssembled
  │   ├── node_state(:)    → currentCoords(3)/disp(3)/vel(3)/acc(3)
  │   └── elem_state(:)    → ipStates(:)/nIntPoints  [积分点状态缓存]
  │
  ├── Algo (Solve-Phase Read-Only) ← 求解期只读
  │   └── algo             → integration_order/elem_formulation/nlgeom/large_strain
  │
  └── Ctx (Transient, Not in Container) ← 瞬态，不驻留容器
      └── MeshCtx          → mesh_id/assembly_id/instance_id (L6创建，解析后释放)
```

---

## 3. WriteBack白名单机制

### 3.1 允许的WriteBack路径

| API | 修改目标 | 调用方 | 触发条件 |
|-----|---------|--------|---------|
| **MD_Mesh_WriteBack_NodePos** | `node_state(i)%currentCoords` | L5_RT | 大变形分析 |
| **MD_Mesh_WriteBack_NodeDisp** | `node_state(i)%disp` | L5_RT | 位移输出 |
| **MD_Mesh_WriteBack_NodeVel** | `node_state(i)%vel` | L5_RT | 动力学分析 |
| **MD_Mesh_WriteBack_NodeAcc** | `node_state(i)%acc` | L5_RT | 动力学分析 |
| **MD_Mesh_WriteBack_ElemStress** | `elem_state(i)%ipStates(j)%sigma` | L4_PH | 应力输出 |
| **MD_Mesh_WriteBack_State** | `state%nAssembled` | L5_RT | 装配完成标记 |

### 3.2 禁止修改的字段

```fortran
! ❌ 永久冻结 (Write-Once After Parse)
desc%nNodes           ! 节点总数
desc%nElems           ! 单元总数
global_num            ! DOF映射表
elem_desc(:)          ! 单元连接
node_desc(:)%coords   ! 节点初始坐标

! ✅ 允许回写 (Whitelist Only)
node_state(:)%currentCoords  ! 大变形更新坐标
node_state(:)%disp           ! 位移场
node_state(:)%vel            ! 速度场
node_state(:)%acc            ! 加速度场
elem_state(:)%ipStates       ! 积分点状态
state%nAssembled             ! 装配标记
```

---

## 4. 跨域依赖关系

### 4.1 域间调用矩阵

| 调用方 | 调用接口 | 用途 | 调用时机 |
|--------|---------|------|---------|
| **L6_AP** | MD_Mesh_Domain_Init | 初始化网格 | 解析*NODE/*ELEMENT后 |
| **L6_AP** | MeshData%AddNode | 添加节点 | 解析*NODE卡片 |
| **L6_AP** | MeshData%AddElement | 添加单元 | 解析*ELEMENT卡片 |
| **L4_PH Element** | MD_Mesh_Domain_GetElemConnect | 获取单元连接 | 步边界 |
| **L4_PH Element** | MD_Mesh_Domain_GetNodeCoords | 获取节点坐标 | 增量循环 |
| **L5_RT Assembly** | MD_Mesh_Domain_GetDofMap | 获取DOF映射 | 增量循环 |
| **L5_RT Assembly** | MD_Mesh_WriteBack_NodePos | 回写坐标 | 大变形牛顿迭代后 |
| **Interaction** | MD_Mesh_Domain_GetSurfaceByName | 获取表面 | 接触初始化 |
| **LoadBC** | MD_Mesh_GetNumNodes | 获取节点数 | 边界条件施加 |
| **Constraint** | MD_Mesh_Domain_GetDofMap | 获取DOF映射 | 约束方程构建 |

### 4.2 依赖图

```
L6_AP (解析层)
  ↓ 解析*NODE/*ELEMENT
Mesh域 (L3_MD)
  ├─ MD_Mesh_Domain_Init
  ├─ GlobalNum_Build
  └─ [l3Frozen = .TRUE.]
      ↓ 只读查询
  ┌─────────────┬──────────────┐
  ↓             ↓              ↓
L4_PH        L5_RT        Interaction
(Element)   (Assembly)   (Contact)
  ↓             ↓              ↓
GetElemConnect  GetDofMap    GetSurfaceByName
GetNodeCoords   WriteBack    (校验表面节点)
```

---

## 5. 关键接口设计

### 5.1 域容器接口

```fortran
TYPE :: MD_Mesh_Domain
  !--- Desc (Write-Once) ---
  TYPE(MeshDesc)                       :: desc
  TYPE(MeshNodeDesc), ALLOCATABLE      :: node_desc(:)
  TYPE(MeshElemDesc), ALLOCATABLE      :: elem_desc(:)
  TYPE(MeshGlobalNum)                  :: global_num
  
  !--- State (WriteBack Target) ---
  TYPE(MeshState)                      :: state
  TYPE(MeshNodeState), ALLOCATABLE     :: node_state(:)
  TYPE(MeshElemState), ALLOCATABLE     :: elem_state(:)
  
  !--- Algo (Read-Only) ---
  TYPE(MeshAlgo)                       :: algo
  
  !--- Raw Data ---
  TYPE(MeshData)                       :: raw_data
  
  !--- Control ---
  LOGICAL                              :: initialized = .FALSE.

CONTAINS
  PROCEDURE :: Init           => MD_Mesh_Domain_Init
  PROCEDURE :: Finalize       => MD_Mesh_Domain_Finalize
  PROCEDURE :: GetNodeCoords  => MD_Mesh_Domain_GetNodeCoords
  PROCEDURE :: GetElemConnect => MD_Mesh_Domain_GetElemConnect
  PROCEDURE :: GetElemSection => MD_Mesh_Domain_GetElemSection
  PROCEDURE :: GetDofMap      => MD_Mesh_Domain_GetDofMap
  PROCEDURE :: GetSurfaceByName => MD_Mesh_Domain_GetSurfaceByName
  PROCEDURE :: GetNodeByName  => MD_Mesh_Domain_GetNodeByName
  PROCEDURE :: WriteBack_NodePos => MD_Mesh_WriteBack_NodePos
  PROCEDURE :: WriteBack_NodeDisp => MD_Mesh_WriteBack_NodeDisp
  PROCEDURE :: WriteBack_NodeVel => MD_Mesh_WriteBack_NodeVel
  PROCEDURE :: WriteBack_NodeAcc => MD_Mesh_WriteBack_NodeAcc
  PROCEDURE :: WriteBack_ElemStress => MD_Mesh_WriteBack_ElemStress
  PROCEDURE :: WriteBack_State   => MD_Mesh_WriteBack_State
END TYPE
```

### 5.2 Arg参数容器 (Phase 2)

```fortran
! 节点坐标查询
TYPE :: MD_Mesh_GetNodeCoords_Arg
  REAL(wp) :: coords(3) = 0.0_wp
END TYPE

! 单元连接查询
TYPE :: MD_Mesh_GetElemConnect_Arg
  INTEGER(i8) :: connect(MD_MESH_MAX_NODES_PER_ELEM) = 0_i8
  INTEGER(i4) :: npe = 0_i4
END TYPE

! DOF映射查询
TYPE :: MD_Mesh_GetDofMap_Arg
  INTEGER(i4) :: global_dof_start = 0_i4
  INTEGER(i4) :: n_dof = 0_i4
END TYPE

! 节点坐标回写
TYPE :: MD_Mesh_WriteBack_NodePos_Arg
  REAL(wp) :: new_coords(3) = 0.0_wp
END TYPE
```

---

## 6. DOF子域设计

### 6.1 DOF标签体系

| 标签常量 | 值 | 物理含义 | 适用单元族 |
|---------|----|---------|-----------|
| MD_MESH_DOF_LBL_U1 | 1 | X方向位移 | Solid/Shell/Beam |
| MD_MESH_DOF_LBL_U2 | 2 | Y方向位移 | Solid/Shell/Beam |
| MD_MESH_DOF_LBL_U3 | 3 | Z方向位移 | Solid/Shell/Beam |
| MD_MESH_DOF_LBL_U4 | 4 | X方向转动 | Shell/Beam |
| MD_MESH_DOF_LBL_U5 | 5 | Y方向转动 | Shell/Beam |
| MD_MESH_DOF_LBL_U6 | 6 | Z方向转动 | Shell/Beam |
| MD_MESH_DOF_LBL_T1 | 7 | 温度 | 热-固耦合 |
| MD_MESH_DOF_LBL_P1 | 8 | 压力 | 流-固耦合 |

### 6.2 DOF状态枚举

| 状态常量 | 值 | 含义 | 方程编号 |
|---------|----|------|---------|
| MD_MESH_DOF_INACTIVE | 0 | 未激活 | 无 |
| MD_MESH_DOF_FREE | 1 | 自由DOF | 连续编号 |
| MD_MESH_DOF_FIXED | 2 | 固定边界 | 无 |
| MD_MESH_DOF_PRESCRIBED | 3 | 指定位移 | 无 |
| MD_MESH_DOF_SLAVE | 4 | 从属DOF (约束) | 无 |
| MD_MESH_DOF_LAGRANGE | 5 | 拉格朗日乘子 | 连续编号 |

### 6.3 DOF映射算法

```fortran
! GlobalNum_BuildFromFlat 核心逻辑
DO i = 1, nNodes
  nodeMap(i)%globalNodeId  = i
  nodeMap(i)%partIndex     = 0
  nodeMap(i)%instanceIndex = 1
  nodeMap(i)%localNodeId   = i
  nodeMap(i)%nDof          = nDofPerNode
  nodeMap(i)%dofStartIndex = nDofPerNode * (i - 1) + 1
END DO

nTotalEq = nDofPerNode * nNodes  ! 总方程数
```

---

## 7. Node子域设计

### 7.1 节点TYPE定义

```fortran
TYPE, EXTENDS(DescBase) :: MD_Node_Type
  ! 基本标识
  INTEGER(i4) :: id = 0
  CHARACTER(LEN=80) :: name = ""
  
  ! 空间坐标
  REAL(wp) :: coords(3) = 0.0_wp
  INTEGER(i4) :: spatial_dim = 3
  
  ! DOF信息
  INTEGER(i4) :: nDof = 0
  INTEGER(i4) :: dof_map(16) = 0
  INTEGER(i4) :: dof_offset = 0
  
  ! 边界条件与载荷
  LOGICAL :: bc_applied(16) = .FALSE.
  REAL(wp) :: bc_values(16) = 0.0_wp
  REAL(wp) :: load_values(16) = 0.0_wp
  
  ! 节点属性
  REAL(wp) :: mass = 0.0_wp
  REAL(wp) :: temperature = 0.0_wp
  REAL(wp) :: pressure = 0.0_wp
  
  ! 连接信息
  INTEGER(i4) :: nElems = 0
  INTEGER(i4), ALLOCATABLE :: element_list(:)
  INTEGER(i4), ALLOCATABLE :: tags(:)
END TYPE
```

### 7.2 节点操作接口

| 接口 | 功能 | 复杂度 |
|------|------|--------|
| MD_Node_Create | 创建节点 | O(1) |
| MD_Node_Destroy | 销毁节点 | O(nElems) |
| MD_Node_SetCoords | 设置坐标 | O(1) |
| MD_Node_GetCoords | 获取坐标 | O(1) |
| MD_Node_SetDOF | 设置DOF | O(nDof) |
| MD_Node_GetDOF | 获取DOF | O(1) |
| MD_Node_Transform | 坐标变换 | O(1) |
| MD_Node_GetDistance | 节点距离 | O(1) |
| MD_Node_GetStatistics | 统计信息 | O(nElems) |
| MD_Node_Valid | 有效性校验 | O(1) |

---

## 8. 内存管理策略

### 8.1 数组分配策略

| 数组 | 分配时机 | 大小 | 释放时机 |
|------|---------|------|---------|
| node_coords | MD_Mesh_Domain_Init | (3, nNodes) | Finalize |
| element_connect | MD_Mesh_Domain_Init | (maxNPE, nElems) | Finalize |
| element_types | MD_Mesh_Domain_Init | (nElems) | Finalize |
| nodeMap | GlobalNum_Build | (nNodes) | Finalize |
| elemMap | GlobalNum_Build | (nElems) | Finalize |
| node_desc | MD_Mesh_Domain_Init | (nNodes) | Finalize |
| elem_desc | MD_Mesh_Domain_Init | (nElems) | Finalize |
| node_state | MD_Mesh_Domain_Init | (nNodes) | Finalize |
| elem_state | MD_Mesh_Domain_Init | (nElems) | Finalize |

### 8.2 内存池集成 (Phase 3)

```fortran
! 当前：直接ALLOCATE
ALLOCATE(this%node_desc(nNodes))

! Phase 3：内存池分配
CALL UF_Mem_AllocStructArray(MEM_DOMAIN_MESH, MEM_DOMAIN_LAYER, &
     nNodes, 'node_desc', this%node_desc, pid, mem_status)
```

---

## 9. 错误处理

### 9.1 错误类型

| 错误场景 | 错误码 | 处理策略 |
|---------|--------|---------|
| 未初始化查询 | IF_STATUS_INVALID | 返回错误，不崩溃 |
| 索引越界 | IF_STATUS_INVALID | 边界检查拦截 |
| DOF映射未构建 | IF_STATUS_INVALID | 提示先调用GlobalNum_Build |
| WriteBack越权 | IF_STATUS_INVALID | 白名单校验拦截 |

### 9.2 边界检查示例

```fortran
SUBROUTINE MD_Mesh_Domain_GetNodeCoords(this, local_id, coords, status)
  CALL init_error_status(status)
  
  ! 初始化检查
  IF (.NOT. this%initialized) THEN
    status%status_code = IF_STATUS_INVALID
    status%message = "Mesh domain not initialized"
    RETURN
  END IF
  
  ! 边界检查
  IF (local_id < 1 .OR. local_id > this%desc%nNodes) THEN
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,I0,A,I0)') &
         "node_id out of range: ", local_id, " / ", this%desc%nNodes
    RETURN
  END IF
  
  ! 安全查询
  CALL this%raw_data%GetNodeCoords(local_id, coords, status)
END SUBROUTINE
```

---

## 10. 性能优化

### 10.1 查询性能

| 操作 | 当前实现 | 优化建议 | 预期提升 |
|------|---------|---------|---------|
| GetNodeCoords | O(1) 数组索引 | ✅ 已最优 | - |
| GetElemConnect | O(1) 数组索引 | ✅ 已最优 | - |
| GetDofMap | O(1) 查表 | ✅ 已最优 | - |
| GetSurfaceByName | O(n) 线性搜索 | 哈希表 | 10-100x |

### 10.2 内存布局优化

```fortran
! 当前：部分AoS
TYPE(MeshNodeDesc), ALLOCATABLE :: node_desc(:)

! 优化：SoA (利于SIMD向量化)
REAL(wp), ALLOCATABLE :: node_x(:), node_y(:), node_z(:)
INTEGER(i4), ALLOCATABLE :: node_global_id(:)
```

---

## 11. 验证策略

### 11.1 功能验证

| 测试项 | 验证内容 | 预期结果 |
|--------|---------|---------|
| Init/Finalize | 成对调用 | 无内存泄漏 |
| GetNodeCoords | 返回正确坐标 | 与输入一致 |
| GetElemConnect | 返回正确连接 | 与输入一致 |
| GetDofMap | O(1) DOF查找 | dofStartIndex = nDof*(id-1)+1 |
| WriteBack | 仅更新白名单字段 | Desc保持冻结 |

### 11.2 性能验证

| 测试场景 | 规模 | 指标 |
|---------|------|------|
| 网格初始化 | 100万元素 | < 1秒 |
| GetDofMap | 100万次查询 | < 0.1秒 |
| WriteBack_NodePos | 10万次更新 | < 0.05秒 |

---

## 12. 文件清单

### L3_MD/Mesh 域 (12文件 + 2子域)

```
L3_MD/Mesh/
├── MD_Mesh_Domain_Core.f90      # 域容器总控 (909行)
├── MD_Mesh_Core.f90             # 向后兼容层 (4346行)
├── MD_Mesh_API.f90              # 只读API (192行)
├── MD_Mesh_Data.f90             # 数据存储 (~500行)
├── MD_Mesh_Elem.f90             # 单元网格 (~300行)
├── MD_Mesh_Node.f90             # 节点网格 (~200行)
├── MD_Mesh_Mgr.f90              # 管理器 (~100行)
├── MD_Mesh_Sync.f90             # 跨域同步 (~200行)
├── MD_Mesh_GlobalNum.f90        # 全局编号 (~500行)
├── MD_Mesh_Types.f90            # 类型定义 (~60行)
├── DOF/
│   ├── MD_DOF_Core.f90          # DOF核心 (1928行)
│   ├── MD_DOF_Mgr.f90           # DOF管理器 (14.4KB)
│   └── MD_DOF_API.f90           # DOF API (待创建)
└── Node/
    └── MD_Node.f90              # 节点操作 (713行)
```

---

## 13. 附录

### 13.1 符号约定

| 符号 | 含义 | 单位/类型 |
|------|------|----------|
| nNodes | 节点总数 | INTEGER(i8) |
| nElems | 单元总数 | INTEGER(i8) |
| nDofPerNode | 每节点DOF数 | INTEGER(i4), 默认3 |
| maxNPE | 每单元最大节点数 | INTEGER(i4), 27 (C3D27) |
| nTotalEq | 总方程数 | INTEGER(i4) |
| dofStartIndex | DOF起始索引 | INTEGER(i4), 1-based |

### 13.2 阶段演进

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 1 | 域容器设计+四链定义 | ✅ 完成 |
| Phase 2 | Arg参数容器+索引API | ✅ 完成 |
| Phase 3 | 内存池集成+SoA优化 | ⏳ 规划中 |
| Phase C | 清理MD_Mesh_Core遗留代码 | ⏳ 规划中 |

---

**文档维护**: 随L3_MD/Mesh代码同步更新  
**下次审查**: Phase 3内存池集成后更新状态  
**相关文档**: 
- `L3_MD_Mesh_域级设计文档_v1.0.md`
- `L3_MD_Mesh_域级审查报告.md`
- `Mesh/CONTRACT.md`
