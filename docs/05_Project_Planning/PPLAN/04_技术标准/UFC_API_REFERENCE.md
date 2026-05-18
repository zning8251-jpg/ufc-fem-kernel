# UFC API 参考手册

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 全栈 API 参考  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档提供 UFC 全栈所有 PUBLIC 接口的完整参考，包括：

- 接口签名（参数类型、含义、取值范围）
- 返回值说明
- 错误码说明
- 使用示例
- 版本兼容性说明

**命名规范**: 所有接口遵循 UFC 四段式命名：`Layer_Domain_Function_Suffix`

---

## 目录

1. [L1_IF API（基础设施层）](#l1_if-api基础设施层)
2. [L2_NM API（数值计算层）](#l2_nm-api数值计算层)
3. [L3_MD API（模型数据层）](#l3_md-api模型数据层)
4. [L4_PH API（物理层）](#l4_ph-api物理层)
5. [L5_RT API（运行时层）](#l5_rt-api运行时层)
6. [L6_AP API（应用层）](#l6_ap-api应用层)
7. [全局容器 API](#全局容器-api)
8. [错误码参考](#错误码参考)
9. [版本兼容性](#版本兼容性)

---

## L1_IF API（基础设施层）

### IF_Prec（精度类型）

**模块**: `IF_Prec`  
**文件**: `L1_IF/Precision/IF_Prec.f90`  
**职责**: 定义全局精度参数（全栈唯一来源）

#### 类型定义

```fortran
! 精度类型（全栈统一）
INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)  ! 工作精度（默认双精度）
INTEGER, PARAMETER :: sp = SELECTED_REAL_KIND(6, 37)    ! 单精度
INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15, 307)  ! 双精度
INTEGER, PARAMETER :: qp = SELECTED_REAL_KIND(33, 4931) ! 四精度

! 整数类型
INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)         ! 32位整数
INTEGER, PARAMETER :: i8 = SELECTED_INT_KIND(18)       ! 64位整数
```

**使用示例**:

```fortran
USE IF_Prec, ONLY: wp, i4, i8

REAL(wp) :: stress
INTEGER(i4) :: n_nodes
INTEGER(i8) :: total_memory
```

---

### IF_Err_API（错误处理）

**模块**: `IF_Err_API`  
**文件**: `L1_IF/Error/IF_Err_API.f90`  
**职责**: 定义错误状态类型（全栈唯一错误类型）

#### 类型定义

```fortran
TYPE, PUBLIC :: ErrorStatusType
  INTEGER(i4) :: status_code = STATUS_OK
  CHARACTER(len=256) :: error_message = ''
  CHARACTER(len=128) :: module_name = ''
  INTEGER(i4) :: line_number = 0
  INTEGER(i8) :: timestamp = 0_i8
END TYPE ErrorStatusType
```

#### 常量定义

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: STATUS_OK = 0
INTEGER(i4), PARAMETER, PUBLIC :: STATUS_ERROR = 1
INTEGER(i4), PARAMETER, PUBLIC :: STATUS_WARNING = 2
```

#### 核心过程

##### `UFC_Error_Raise`

```fortran
SUBROUTINE UFC_Error_Raise(status, error_code, error_message)
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
  INTEGER(i4), INTENT(IN) :: error_code
  CHARACTER(len=*), INTENT(IN) :: error_message
```

**功能**: 设置错误状态

**参数**:

- `status`: 错误状态对象（INOUT）
- `error_code`: 错误码（见错误码参考）
- `error_message`: 错误消息（字符串）

**使用示例**:

```fortran
USE IF_Err_API, ONLY: ErrorStatusType, UFC_Error_Raise, STATUS_ERROR

TYPE(ErrorStatusType) :: status

IF (n_nodes <= 0) THEN
  CALL UFC_Error_Raise(status, STATUS_ERROR, '节点数量必须大于0')
  RETURN
END IF
```

---

### IF_Mem_PoolMgr（内存管理）

**模块**: `IF_Mem_PoolMgr`  
**文件**: `L1_IF/Memory/IF_Mem_PoolMgr.f90`  
**职责**: 统一内存池管理器（6池架构，P0+P1+P2优化）

#### 类型定义

```fortran
TYPE, PUBLIC :: IF_Mem_PoolMgr_Type
  TYPE(IF_Mem_HotPool_Type) :: hot_pool      ! 热数据池（30%，SIMD优化）
  TYPE(IF_Mem_WarmPool_Type) :: warm_pool    ! 温数据池（45%，Real/Int分立）
  TYPE(IF_Mem_ColdPool_Type) :: cold_pool    ! 冷数据池（5%）
  TYPE(IF_Mem_TempPool_Type) :: temp_pool    ! 临时池（10%，SLAB）
  TYPE(IF_Mem_PtrPool_Type) :: ptr_pool      ! 指针池（10%，防泄漏）
  TYPE(IF_Mem_PathMapper_Type) :: path_mapper ! 路径映射器
  
  ! L1_IF 集成（复用）
  TYPE(IF_SymbolTableManager), POINTER :: sym_table => NULL()
  TYPE(IF_StructMetaData), POINTER :: struct_meta => NULL()
  TYPE(IF_DeviceManager), POINTER :: device_mgr => NULL()
  TYPE(IF_StructFileManager), POINTER :: file_mgr => NULL()
  TYPE(IF_BackupManager), POINTER :: backup_mgr => NULL()
  
  INTEGER(i8) :: totalMemory = 0_i8
  LOGICAL :: initialized = .FALSE.
  
CONTAINS
  PROCEDURE :: Init => IF_Mem_PoolMgr_Init
  PROCEDURE :: AllocByPath => IF_Mem_PoolMgr_AllocByPath
  PROCEDURE :: AllocHot => IF_Mem_PoolMgr_AllocHot
  PROCEDURE :: AllocWarm => IF_Mem_PoolMgr_AllocWarm
  PROCEDURE :: AllocTemp => IF_Mem_PoolMgr_AllocTemp
  PROCEDURE :: RegPtr => IF_Mem_PoolMgr_RegPtr
  PROCEDURE :: FindByPath => IF_Mem_PoolMgr_FindByPath
  PROCEDURE :: GetStats => IF_Mem_PoolMgr_GetStats
  PROCEDURE :: Finalize => IF_Mem_PoolMgr_Finalize
END TYPE IF_Mem_PoolMgr_Type
```

#### 核心过程

##### `IF_Mem_PoolMgr_Init`

```fortran
SUBROUTINE IF_Mem_PoolMgr_Init(this, totalMemory, status)
  CLASS(IF_Mem_PoolMgr_Type), INTENT(INOUT) :: this
  INTEGER(i8), INTENT(IN) :: totalMemory
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 初始化内存池管理器

**参数**:

- `this`: 内存池管理器对象（INOUT）
- `totalMemory`: 总内存大小（字节，i8）
- `status`: 错误状态（INOUT）

**内存分配比例**:

- Hot Pool: 30%
- Warm Pool: 45%
- Cold Pool: 5%
- Temp Pool: 10%
- Ptr Pool: 10%

**使用示例**:

```fortran
USE IF_Mem_PoolMgr, ONLY: IF_Mem_PoolMgr_Type
USE IF_Err_API, ONLY: ErrorStatusType

TYPE(IF_Mem_PoolMgr_Type) :: pool_mgr
TYPE(ErrorStatusType) :: status

! 初始化 16GB 内存
CALL pool_mgr%Init(16_i8*1024_i8*1024_i8*1024_i8, status)
IF (status%status_code /= STATUS_OK) THEN
  WRITE(*,'(A)') '初始化失败: '//TRIM(status%error_message)
  STOP
END IF
```

##### `IF_Mem_PoolMgr_AllocByPath`

```fortran
FUNCTION IF_Mem_PoolMgr_AllocByPath(this, abaqusPath, varName, dims, dtype, status) &
    RESULT(ptr)
  CLASS(IF_Mem_PoolMgr_Type), INTENT(INOUT) :: this
  CHARACTER(len=*), INTENT(IN) :: abaqusPath
  CHARACTER(len=*), INTENT(IN) :: varName
  INTEGER(i4), INTENT(IN) :: dims(:)
  INTEGER(i4), INTENT(IN) :: dtype
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
  TYPE(C_PTR) :: ptr
```

**功能**: 通过 ABAQUS 路径分配内存（自动选择池类型）

**参数**:

- `this`: 内存池管理器对象（INOUT）
- `abaqusPath`: ABAQUS 路径（如 `"mdb.models['Model-1'].parts['Part-1'].mesh.nodes"`）
- `varName`: 变量名（如 `"coordinates"`）
- `dims`: 数组维度（一维数组，i4）
- `dtype`: 数据类型（`DATA_TYPE_DP` 或 `DATA_TYPE_INT`）
- `status`: 错误状态（INOUT）

**返回值**: `TYPE(C_PTR)` - 分配的内存指针

**数据类型常量**:

```fortran
INTEGER(i4), PARAMETER :: DATA_TYPE_DP = 1   ! 双精度实数
INTEGER(i4), PARAMETER :: DATA_TYPE_INT = 2  ! 整数
```

**使用示例**:

```fortran
USE IF_Mem_PoolMgr, ONLY: IF_Mem_PoolMgr_Type, DATA_TYPE_DP
USE IF_Err_API, ONLY: ErrorStatusType

TYPE(IF_Mem_PoolMgr_Type) :: pool_mgr
TYPE(ErrorStatusType) :: status
TYPE(C_PTR) :: ptr
REAL(wp), POINTER :: coords(:,:)

! 分配节点坐标数组（温数据，自动选择 WarmPool）
ptr = pool_mgr%AllocByPath( &
    abaqusPath="mdb.models['Model-1'].parts['Part-1'].mesh.nodes", &
    varName="coordinates", &
    dims=[nNodes, 3], &
    dtype=DATA_TYPE_DP, &
    status=status)

IF (C_ASSOCIATED(ptr)) THEN
  CALL C_F_POINTER(ptr, coords, [nNodes, 3])
END IF
```

##### `IF_Mem_PoolMgr_FindByPath`

```fortran
FUNCTION IF_Mem_PoolMgr_FindByPath(this, fullPath, status) RESULT(ptr)
  CLASS(IF_Mem_PoolMgr_Type), INTENT(IN) :: this
  CHARACTER(len=*), INTENT(IN) :: fullPath
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
  TYPE(C_PTR) :: ptr
```

**功能**: 通过 ABAQUS 路径查找已分配的内存

**参数**:

- `this`: 内存池管理器对象（IN）
- `fullPath`: 完整路径（如 `"mdb.models['Model-1'].parts['Part-1'].mesh.nodes.coordinates"`）
- `status`: 错误状态（INOUT）

**返回值**: `TYPE(C_PTR)` - 找到的内存指针，未找到返回 `C_NULL_PTR`

**使用示例**:

```fortran
ptr = pool_mgr%FindByPath( &
    "mdb.models['Model-1'].parts['Part-1'].mesh.nodes.coordinates", &
    status)

IF (C_ASSOCIATED(ptr)) THEN
  CALL C_F_POINTER(ptr, coords, [nNodes, 3])
END IF
```

---

### IF_Log（日志系统）

**模块**: `IF_Log`  
**文件**: `L1_IF/Log/IF_Log.f90`  
**职责**: 分级日志系统

#### 类型定义

```fortran
TYPE, PUBLIC :: LogEntry_Type
  INTEGER(i4) :: level = LOG_LEVEL_INFO
  CHARACTER(len=256) :: message = ''
  CHARACTER(len=128) :: module_name = ''
  INTEGER(i4) :: line_number = 0
  INTEGER(i8) :: timestamp = 0_i8
END TYPE LogEntry_Type

TYPE, PUBLIC :: Logger_Type
  INTEGER(i4) :: min_level = LOG_LEVEL_INFO
  LOGICAL :: enabled = .TRUE.
  TYPE(LogEntry_Type), ALLOCATABLE :: buffer(:)
  INTEGER(i4) :: nEntries = 0_i4
CONTAINS
  PROCEDURE :: Log => Logger_Log
  PROCEDURE :: Flush => Logger_Flush
END TYPE Logger_Type
```

#### 日志级别常量

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: LOG_LEVEL_DEBUG = 0
INTEGER(i4), PARAMETER, PUBLIC :: LOG_LEVEL_INFO = 1
INTEGER(i4), PARAMETER, PUBLIC :: LOG_LEVEL_WARN = 2
INTEGER(i4), PARAMETER, PUBLIC :: LOG_LEVEL_ERROR = 3
```

#### 核心过程

##### `Logger_Log`

```fortran
SUBROUTINE Logger_Log(this, level, message, module_name, line_number)
  CLASS(Logger_Type), INTENT(INOUT) :: this
  INTEGER(i4), INTENT(IN) :: level
  CHARACTER(len=*), INTENT(IN) :: message
  CHARACTER(len=*), INTENT(IN), OPTIONAL :: module_name
  INTEGER(i4), INTENT(IN), OPTIONAL :: line_number
```

**功能**: 记录日志

**使用示例**:

```fortran
USE IF_Log, ONLY: Logger_Type, LOG_LEVEL_INFO

TYPE(Logger_Type) :: logger

CALL logger%Log(LOG_LEVEL_INFO, '初始化完成', 'MyModule', 123)
```

---

## L2_NM API（数值计算层）

### NM_LinearSolver（线性求解器）

**模块**: `NM_LinearSolver`  
**文件**: `L2_NM/Solver/NM_LinearSolver.f90`  
**职责**: 线性方程组求解

#### 类型定义

```fortran
TYPE, PUBLIC :: NM_LinearSolver_Type
  INTEGER(i4) :: solver_type = SOLVER_LU
  TYPE(NM_CSRMatrix_Type) :: A
  REAL(wp), ALLOCATABLE :: x(:), b(:)
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => NM_LinearSolver_Init
  PROCEDURE :: Solve => NM_LinearSolver_Solve
  PROCEDURE :: Finalize => NM_LinearSolver_Finalize
END TYPE NM_LinearSolver_Type
```

#### 求解器类型常量

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: SOLVER_LU = 1
INTEGER(i4), PARAMETER, PUBLIC :: SOLVER_CHOLESKY = 2
INTEGER(i4), PARAMETER, PUBLIC :: SOLVER_GMRES = 3
INTEGER(i4), PARAMETER, PUBLIC :: SOLVER_CG = 4
```

#### 核心过程

##### `NM_LinearSolver_Solve`

```fortran
SUBROUTINE NM_LinearSolver_Solve(this, A, b, x, status)
  CLASS(NM_LinearSolver_Type), INTENT(INOUT) :: this
  TYPE(NM_CSRMatrix_Type), INTENT(IN) :: A
  REAL(wp), INTENT(IN) :: b(:)
  REAL(wp), INTENT(OUT) :: x(:)
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 求解线性方程组 `A·x = b`

**参数**:

- `this`: 求解器对象（INOUT）
- `A`: 系数矩阵（CSR格式，IN）
- `b`: 右端向量（IN）
- `x`: 解向量（OUT）
- `status`: 错误状态（INOUT）

**使用示例**:

```fortran
USE NM_LinearSolver, ONLY: NM_LinearSolver_Type, SOLVER_LU

TYPE(NM_LinearSolver_Type) :: solver
TYPE(NM_CSRMatrix_Type) :: A
REAL(wp) :: b(n_dof), x(n_dof)

CALL solver%Init(SOLVER_LU, status)
CALL solver%Solve(A, b, x, status)
```

---

### NM_TimeIntegration（时间积分）

**模块**: `NM_TimeIntegration`  
**文件**: `L2_NM/TimeInt/NM_TimeIntegration.f90`  
**职责**: 时间积分算法（Newmark, HHT-α）

#### 类型定义

```fortran
TYPE, PUBLIC :: NM_TimeIntegration_Type
  INTEGER(i4) :: method = METHOD_NEWMARK
  REAL(wp) :: beta = 0.25_wp
  REAL(wp) :: gamma = 0.5_wp
  REAL(wp) :: alpha = 0.0_wp  ! HHT-α 参数
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => NM_TimeIntegration_Init
  PROCEDURE :: Step => NM_TimeIntegration_Step
  PROCEDURE :: Finalize => NM_TimeIntegration_Finalize
END TYPE NM_TimeIntegration_Type
```

#### 方法类型常量

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: METHOD_NEWMARK = 1
INTEGER(i4), PARAMETER, PUBLIC :: METHOD_HHT_ALPHA = 2
INTEGER(i4), PARAMETER, PUBLIC :: METHOD_GENERALIZED_ALPHA = 3
```

#### 核心过程

##### `NM_TimeIntegration_Step`

```fortran
SUBROUTINE NM_TimeIntegration_Step(this, dt, u, v, a, u_new, v_new, a_new, status)
  CLASS(NM_TimeIntegration_Type), INTENT(IN) :: this
  REAL(wp), INTENT(IN) :: dt
  REAL(wp), INTENT(IN) :: u(:), v(:), a(:)
  REAL(wp), INTENT(OUT) :: u_new(:), v_new(:), a_new(:)
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 执行一个时间积分步

**参数**:

- `this`: 时间积分器对象（IN）
- `dt`: 时间步长（IN）
- `u`, `v`, `a`: 当前时刻的位移、速度、加速度（IN）
- `u_new`, `v_new`, `a_new`: 新时刻的位移、速度、加速度（OUT）
- `status`: 错误状态（INOUT）

---

## L3_MD API（模型数据层）

### MD_Material（材料定义）

**模块**: `MD_Material`  
**文件**: `L3_MD/Material/MD_Material.f90`  
**职责**: 材料定义（Desc类型）

#### 类型定义

```fortran
TYPE, PUBLIC :: MD_Material_Desc_Type
  CHARACTER(len=64) :: name = ''
  INTEGER(i4) :: material_type = MAT_TYPE_ELASTIC
  REAL(wp) :: young_modulus = 0.0_wp
  REAL(wp) :: poisson_ratio = 0.0_wp
  REAL(wp) :: density = 0.0_wp
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => MD_Material_Desc_Init
  PROCEDURE :: Validate => MD_Material_Desc_Validate
  PROCEDURE :: Clone => MD_Material_Desc_Clone
  PROCEDURE :: Serialize => MD_Material_Desc_Serialize
  PROCEDURE :: Finalize => MD_Material_Desc_Finalize
END TYPE MD_Material_Desc_Type
```

#### 材料类型常量

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_ELASTIC = 1
INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_PLASTIC = 2
INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_HYPERELASTIC = 3
```

#### 核心过程

##### `MD_Material_Desc_Init`

```fortran
SUBROUTINE MD_Material_Desc_Init(this, name, material_type, young_modulus, &
                                 poisson_ratio, density, status)
  CLASS(MD_Material_Desc_Type), INTENT(INOUT) :: this
  CHARACTER(len=*), INTENT(IN) :: name
  INTEGER(i4), INTENT(IN) :: material_type
  REAL(wp), INTENT(IN) :: young_modulus, poisson_ratio, density
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 初始化材料定义

**使用示例**:

```fortran
USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC

TYPE(MD_Material_Desc_Type) :: material

CALL material%Init('Steel', MAT_TYPE_ELASTIC, &
                   200.0e9_wp, 0.3_wp, 7850.0_wp, status)
```

---

### MD_Mesh（网格管理）

**模块**: `MD_Mesh`  
**文件**: `L3_MD/Mesh/MD_Mesh.f90`  
**职责**: 网格数据管理

#### 类型定义

```fortran
TYPE, PUBLIC :: MD_Mesh_Desc_Type
  INTEGER(i4) :: nNodes = 0_i4
  INTEGER(i4) :: nElements = 0_i4
  REAL(wp), ALLOCATABLE :: coordinates(:,:)  ! [nNodes, 3]
  INTEGER(i4), ALLOCATABLE :: connectivity(:,:)  ! [nElements, nNodesPerElem]
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => MD_Mesh_Desc_Init
  PROCEDURE :: AddNode => MD_Mesh_Desc_AddNode
  PROCEDURE :: AddElement => MD_Mesh_Desc_AddElement
  PROCEDURE :: Finalize => MD_Mesh_Desc_Finalize
END TYPE MD_Mesh_Desc_Type
```

---

## L4_PH API（物理层）

### PH_Elem（单元计算）

**模块**: `PH_Elem`  
**文件**: `L4_PH/Elem/PH_Elem.f90`  
**职责**: 单元刚度矩阵计算

#### 核心过程

##### `PH_Elem_ComputeStiffness`

```fortran
SUBROUTINE PH_Elem_ComputeStiffness(elem_type, coords, material, Ke, status)
  INTEGER(i4), INTENT(IN) :: elem_type
  REAL(wp), INTENT(IN) :: coords(:,:)
  TYPE(MD_Material_Desc_Type), INTENT(IN) :: material
  REAL(wp), INTENT(OUT) :: Ke(:,:)
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 计算单元刚度矩阵

**参数**:

- `elem_type`: 单元类型（C3D8, C3D20, S4等）
- `coords`: 节点坐标（[nNodes, 3]）
- `material`: 材料定义（IN）
- `Ke`: 单元刚度矩阵（OUT）
- `status`: 错误状态（INOUT）

---

### PH_Mat（材料本构）

**模块**: `PH_Mat`  
**文件**: `L4_PH/Mat/PH_Mat.f90`  
**职责**: 材料本构积分

#### 核心过程

##### `PH_Mat_Evaluate`

```fortran
SUBROUTINE PH_Mat_Evaluate(material_desc, strain, stress, ddsdde, state, status)
  TYPE(MD_Material_Desc_Type), INTENT(IN) :: material_desc
  REAL(wp), INTENT(IN) :: strain(6)
  REAL(wp), INTENT(OUT) :: stress(6)
  REAL(wp), INTENT(OUT) :: ddsdde(6,6)
  TYPE(PH_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 评估材料本构关系（应力-应变）

**参数**:

- `material_desc`: 材料定义（IN）
- `strain`: 应变向量（6×1，IN）
- `stress`: 应力向量（6×1，OUT）
- `ddsdde`: 切线刚度矩阵（6×6，OUT）
- `state`: 材料状态（INOUT）
- `status`: 错误状态（INOUT）

---

## L5_RT API（运行时层）

### RT_Solver（求解器调度）

**模块**: `RT_Solver`  
**文件**: `L5_RT/Solver/RT_Solver.f90`  
**职责**: 求解器调度与状态管理

#### 类型定义

```fortran
TYPE, PUBLIC :: RT_Solver_Type
  TYPE(RT_GlobalState_Type) :: global_state
  TYPE(NM_LinearSolver_Type) :: linear_solver
  TYPE(NM_TimeIntegration_Type) :: time_integrator
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => RT_Solver_Init
  PROCEDURE :: SolveStep => RT_Solver_SolveStep
  PROCEDURE :: SolveIncrement => RT_Solver_SolveIncrement
  PROCEDURE :: Finalize => RT_Solver_Finalize
END TYPE RT_Solver_Type
```

#### 核心过程

##### `RT_Solver_SolveStep`

```fortran
SUBROUTINE RT_Solver_SolveStep(this, step_desc, model_ctx, status)
  CLASS(RT_Solver_Type), INTENT(INOUT) :: this
  TYPE(RT_Step_Desc_Type), INTENT(IN) :: step_desc
  TYPE(MD_Model_Ctx_Type), INTENT(IN) :: model_ctx
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
```

**功能**: 求解一个分析步

**参数**:

- `this`: 求解器对象（INOUT）
- `step_desc`: 分析步定义（IN）
- `model_ctx`: 模型上下文（IN）
- `status`: 错误状态（INOUT）

---

## L6_AP API（应用层）

### AP_Cmd（命令解析）

**模块**: `AP_Cmd`  
**文件**: `L6_AP/Input/AP_Cmd.f90`  
**职责**: 命令解析与执行

#### 类型定义

```fortran
TYPE, PUBLIC :: AP_Cmd_Desc_Type
  CHARACTER(len=64) :: cmd_name = ''
  CHARACTER(len=256) :: cmd_args = ''
  INTEGER(i4) :: cmd_type = CMD_TYPE_STEP
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => AP_Cmd_Desc_Init
  PROCEDURE :: Execute => AP_Cmd_Desc_Execute
END TYPE AP_Cmd_Desc_Type
```

#### 命令类型常量

```fortran
INTEGER(i4), PARAMETER, PUBLIC :: CMD_TYPE_STEP = 1
INTEGER(i4), PARAMETER, PUBLIC :: CMD_TYPE_MATERIAL = 2
INTEGER(i4), PARAMETER, PUBLIC :: CMD_TYPE_SECTION = 3
```

---

## 全局容器 API

### UFC_GlobalContainer（全局容器）

**模块**: `UF_GlobalContainer_Core`  
**文件**: `L1_IF/Base/UF_GlobalContainer_Core.f90`  
**职责**: 全局统一数据容器（三级嵌套）

#### 类型定义

```fortran
TYPE, PUBLIC :: UFC_GlobalContainer_Type
  TYPE(L1_IF_LayerContainer_Type) :: l1_if
  TYPE(L2_NM_LayerContainer_Type) :: l2_nm
  TYPE(L3_MD_LayerContainer_Type) :: l3_md
  TYPE(L4_PH_LayerContainer_Type) :: l4_ph
  TYPE(L5_RT_LayerContainer_Type) :: l5_rt
  TYPE(L6_AP_LayerContainer_Type) :: l6_ap
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => UFC_GlobalContainer_Init
  PROCEDURE :: Finalize => UFC_GlobalContainer_Finalize
END TYPE UFC_GlobalContainer_Type
```

#### 全局实例

```fortran
TYPE(UFC_GlobalContainer_Type), SAVE, TARGET :: g_ufc_global
```

**使用示例**:

```fortran
USE UF_GlobalContainer_Core, ONLY: g_ufc_global

! 初始化全局容器
CALL g_ufc_global%Init(status)

! 访问 L3_MD 材料域
CALL g_ufc_global%l3_md%material%Register(material_desc, status)
```

---

## 错误码参考

### L1_IF 错误码（1000-1999）


| 错误码  | 常量名                            | 说明       |
| ---- | ------------------------------ | -------- |
| 1001 | `UFC_ERR_LOCK_CONTENTION`      | 锁竞争      |
| 1002 | `UFC_ERR_THREAD_SAFE_NOT_INIT` | 线程安全未初始化 |
| 2001 | `UFC_ERR_PATH_TOO_LONG`        | 路径过长     |
| 2002 | `UFC_ERR_PATH_TOO_DEEP`        | 路径深度超限   |
| 3001 | `UFC_ERR_CORRUPTED_BLOCK`      | 内存块损坏    |
| 3002 | `UFC_ERR_BUFFER_OVERFLOW`      | 缓冲区溢出    |
| 3003 | `UFC_ERR_DOUBLE_FREE`          | 双重释放     |
| 4001 | `UFC_ERR_SLAB_EXHAUSTED`       | SLAB 耗尽  |


### L2_NM 错误码（2000-2999）


| 错误码  | 常量名                      | 说明    |
| ---- | ------------------------ | ----- |
| 2001 | `NM_ERR_SOLVER_FAILED`   | 求解器失败 |
| 2002 | `NM_ERR_MATRIX_SINGULAR` | 矩阵奇异  |


### L3_MD 错误码（3000-3999）


| 错误码  | 常量名                         | 说明    |
| ---- | --------------------------- | ----- |
| 3001 | `MD_ERR_MATERIAL_NOT_FOUND` | 材料未找到 |
| 3002 | `MD_ERR_MESH_INVALID`       | 网格无效  |


---

## 版本兼容性

### 版本号规则

采用语义化版本：`主版本号.次版本号.修订号`

- **主版本号**: 不兼容的 API 变更
- **次版本号**: 向后兼容的功能新增
- **修订号**: 向后兼容的问题修复

### 向后兼容性保证

- v2.0 必须能读取 v1.x 的 .inp 文件
- 不兼容的变更必须通过格式转换工具迁移
- 至少支持 2 个大版本的向后兼容

---

## 附录

### A.1 常用类型别名

```fortran
USE IF_Prec, ONLY: wp => wp, i4 => i4, i8 => i8
USE IF_Err_API, ONLY: ErrorStatusType
```

### A.2 命名规范速查

- **类型**: `Layer_Domain_Function_Suffix`
- **过程**: `Layer_Domain_Function_Suffix`
- **常量**: `Layer_Domain_CONSTANT_NAME`
- **模块**: `Layer_Domain_Core` 或 `Layer_Domain_API`

### A.3 相关文档

- UFC_架构设计总纲_六层四类四链三步三级两图一体.md
- UFC_DEVELOPER_GUIDE.md（开发者指南）
- UFC_TEST_STRATEGY.md（测试策略）

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队