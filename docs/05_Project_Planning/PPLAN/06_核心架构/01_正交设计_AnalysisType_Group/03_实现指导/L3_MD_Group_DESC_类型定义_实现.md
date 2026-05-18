# L3_MD Layer - Group_DESC类型定义与实现

**版本**: v1.0  
**日期**: 2026-04-04  
**状态**: 实现指导文档  
**作者**: UFC架构设计组  

---

## 📋 目录

1. [L3_MD层架构](#l3_md层架构)
2. [MD_Analysis_Group_DESC类型定义](#md_analysis_group_desc类型定义)
3. [1-based vs 0-based转换](#1-based-vs-0-based转换)
4. [约束矩阵初始化](#约束矩阵初始化)
5. [Group路由逻辑](#group路由逻辑)
6. [特殊场景处理](#特殊场景处理)

---

## L3_MD层架构

### 职责定义

L3_MD层(Metadata Definition)负责：

1. **数据定义** - 定义分析类型的三维坐标结构
2. **PROC映射** - 将ABAQUS PROC编号映射到Group_ID
3. **约束记录** - 记录该分析类型支持的Coupling和单元/材料约束
4. **多求解器标记** - 标识是否需要辅助求解器

### 设计流程

```
User Input (PROC编号)
    ↓
PROC_TO_GROUP_3D映射表
    ↓
MD_Analysis_Group_DESC (1-based外部编号)
    ↓
L4_PH路由层
    ├─ 检查约束矩阵
    ├─ 识别多求解器需求
    └─ 启用相应处理器
    ↓
L5_RT执行层 (转换为0-based内部索引)
    ↓
Harness主循环
```

---

## MD_Analysis_Group_DESC类型定义

### 完整Fortran定义

```fortran
! UFC\ufc_core\L3_MD\L3_MD_Analysis_Group_Module.f90

MODULE L3_MD_Analysis_Group_Module
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: MD_Analysis_Group_DESC
  PUBLIC :: PROC_TO_GROUP_3D_MAP
  PUBLIC :: group_from_proc_id
  PUBLIC :: validate_group_combination
  PUBLIC :: get_auxiliary_solver_info
  
  ! ============================================================================
  ! TYPE: MD_Analysis_Group_DESC - 分析类型完整描述
  ! ============================================================================
  TYPE :: MD_Analysis_Group_DESC
    !
    ! ◆ 外部API编号 (1-based，用户可见)
    !
    INTEGER :: solver_1based           ! 1-5: Standard/Explicit/Acoustic/EM/CFD
    INTEGER :: coupling_1based         ! 1-4: OneShot/OneWay/Weak/Strong
    INTEGER :: physics_1based          ! 1-12: Structure/Thermal/.../Special
    
    !
    ! ◆ 内部实现索引 (0-based，用于矩阵访问)
    !
    INTEGER :: solver_idx              ! 0-4
    INTEGER :: coupling_idx            ! 0-3
    INTEGER :: physics_idx             ! 0-11
    
    !
    ! ◆ 衍生编码 (便利字段)
    !
    INTEGER :: group_id_3d             ! = solver_1based*100 + coupling_1based*10 + physics_1based
    INTEGER :: proc_id_origin          ! 原始PROC编号(1-91)，用于追溯
    
    !
    ! ◆ 约束信息
    !
    INTEGER :: n_compatible_coupling   ! 允许的Coupling策略数(1-4)
    INTEGER :: compatible_couplings(1:4)  ! 支持的Coupling(1-based)
    
    !
    ! ◆ 单元与材料约束
    !
    INTEGER :: allowed_materials(1:20)
    INTEGER :: n_allowed_materials
    INTEGER :: allowed_elements(1:30)
    INTEGER :: n_allowed_elements
    
    !
    ! ◆ 多求解器耦合标记
    !
    LOGICAL :: requires_auxiliary_solver
    INTEGER :: auxiliary_solver_id     ! 当requires_auxiliary_solver=.TRUE.时有效
    
    !
    ! ◆ 描述与验证信息
    !
    CHARACTER(len=256) :: description
    CHARACTER(len=64)  :: solver_name
    CHARACTER(len=64)  :: coupling_name
    CHARACTER(len=64)  :: physics_name
    
  END TYPE MD_Analysis_Group_DESC
  
  ! ============================================================================
  ! PARAMETERS
  ! ============================================================================
  
  INTEGER, PARAMETER :: SOLVER_STANDARD = 1
  INTEGER, PARAMETER :: SOLVER_EXPLICIT = 2
  INTEGER, PARAMETER :: SOLVER_ACOUSTIC = 3
  INTEGER, PARAMETER :: SOLVER_EM = 4
  INTEGER, PARAMETER :: SOLVER_CFD = 5
  
  INTEGER, PARAMETER :: COUPLING_ONESHOT = 1
  INTEGER, PARAMETER :: COUPLING_ONEWAY = 2
  INTEGER, PARAMETER :: COUPLING_WEAK = 3
  INTEGER, PARAMETER :: COUPLING_STRONG = 4
  
  ! Physics (1-based)
  INTEGER, PARAMETER :: PHYSICS_STRUCTURE = 1
  INTEGER, PARAMETER :: PHYSICS_THERMAL = 2
  INTEGER, PARAMETER :: PHYSICS_FREQUENCY = 3
  INTEGER, PARAMETER :: PHYSICS_ACOUSTIC = 4
  INTEGER, PARAMETER :: PHYSICS_EM = 5
  INTEGER, PARAMETER :: PHYSICS_FLUID = 6
  INTEGER, PARAMETER :: PHYSICS_THERMALSTRUCT = 7
  INTEGER, PARAMETER :: PHYSICS_ELECTROSTRUCT = 8
  INTEGER, PARAMETER :: PHYSICS_FLUIDSTRUCT = 9
  INTEGER, PARAMETER :: PHYSICS_FLUIDTHERMAL = 10
  INTEGER, PARAMETER :: PHYSICS_MULTIFIELD = 11
  INTEGER, PARAMETER :: PHYSICS_SPECIAL = 12
  
CONTAINS

  ! ============================================================================
  ! FUNCTION: group_from_proc_id
  ! 描述: 根据PROC编号创建Group_DESC
  ! ============================================================================
  FUNCTION group_from_proc_id(proc_id) RESULT(group)
    INTEGER, INTENT(IN) :: proc_id
    TYPE(MD_Analysis_Group_DESC) :: group
    
    ! Step 1: 使用映射表获取1-based编码
    group%solver_1based = PROC_TO_GROUP_3D_MAP(proc_id)%solver
    group%coupling_1based = PROC_TO_GROUP_3D_MAP(proc_id)%coupling
    group%physics_1based = PROC_TO_GROUP_3D_MAP(proc_id)%physics
    
    ! Step 2: 自动计算0-based索引
    group%solver_idx = group%solver_1based - 1
    group%coupling_idx = group%coupling_1based - 1
    group%physics_idx = group%physics_1based - 1
    
    ! Step 3: 计算3D编码
    group%group_id_3d = group%solver_1based * 100 + &
                        group%coupling_1based * 10 + &
                        group%physics_1based
    
    ! Step 4: 记录原始PROC
    group%proc_id_origin = proc_id
    
    ! Step 5: 加载约束信息
    CALL load_group_constraints(group)
    
  END FUNCTION group_from_proc_id

  ! ============================================================================
  ! SUBROUTINE: load_group_constraints
  ! 描述: 加载该Group的所有约束信息
  ! ============================================================================
  SUBROUTINE load_group_constraints(group)
    TYPE(MD_Analysis_Group_DESC), INTENT(INOUT) :: group
    
    ! 设置名称
    group%solver_name = get_solver_name(group%solver_1based)
    group%coupling_name = get_coupling_name(group%coupling_1based)
    group%physics_name = get_physics_name(group%physics_1based)
    
    ! 加载Coupling约束
    CALL load_compatible_couplings(group)
    
    ! 加载单元/材料约束
    CALL load_element_material_constraints(group)
    
    ! 检查多求解器需求
    CALL check_auxiliary_solver_requirement(group)
    
    ! 构建描述
    WRITE(group%description, '(A)') TRIM(group%solver_name) // &
      ' + ' // TRIM(group%coupling_name) // ' + ' // TRIM(group%physics_name)
    
  END SUBROUTINE load_group_constraints

  ! ============================================================================
  ! SUBROUTINE: validate_group_combination
  ! 描述: 验证Group组合的合法性（外部API，1-based）
  ! ============================================================================
  SUBROUTINE validate_group_combination(solver, coupling, physics, is_valid)
    INTEGER, INTENT(IN) :: solver, coupling, physics
    LOGICAL, INTENT(OUT) :: is_valid
    INTEGER :: solver_idx, coupling_idx, physics_idx
    INTEGER :: compat_matrix(0:4, 0:3, 0:11)
    
    ! 转换为0-based索引
    solver_idx = solver - 1
    coupling_idx = coupling - 1
    physics_idx = physics - 1
    
    ! 边界检查
    IF (solver_idx < 0 .OR. solver_idx > 4) THEN
      is_valid = .FALSE.
      RETURN
    END IF
    IF (coupling_idx < 0 .OR. coupling_idx > 3) THEN
      is_valid = .FALSE.
      RETURN
    END IF
    IF (physics_idx < 0 .OR. physics_idx > 11) THEN
      is_valid = .FALSE.
      RETURN
    END IF
    
    ! 查询约束矩阵
    CALL get_compatibility_matrix(compat_matrix)
    is_valid = (compat_matrix(solver_idx, coupling_idx, physics_idx) == 1)
    
  END SUBROUTINE validate_group_combination

  ! ============================================================================
  ! SUBROUTINE: get_compatibility_matrix
  ! 描述: 返回约束矩阵（0-based索引）
  ! ============================================================================
  SUBROUTINE get_compatibility_matrix(matrix)
    INTEGER, INTENT(OUT) :: matrix(0:4, 0:3, 0:11)
    
    ! Standard (Solver=0)
    matrix(0, 0, :) = [1,1,1,0,0,0,0,0,0,0,1,1]  ! OneShot
    matrix(0, 1, :) = [1,0,0,0,0,0,0,0,0,0,0,0]  ! OneWay
    matrix(0, 2, :) = [1,1,0,0,0,0,1,1,0,0,1,1]  ! Weak
    matrix(0, 3, :) = [1,0,0,0,0,0,1,1,0,0,1,1]  ! Strong
    
    ! Explicit (Solver=1)
    matrix(1, 0, :) = [1,0,0,0,0,0,0,0,0,0,0,0]  ! OneShot only
    matrix(1, 1:3, :) = 0  ! 无OneWay/Weak/Strong
    
    ! Acoustic (Solver=2)
    matrix(2, 0, :) = [0,0,0,1,0,0,0,0,0,0,0,0]  ! OneShot only
    matrix(2, 1:3, :) = 0
    
    ! EM (Solver=3)
    matrix(3, 0, :) = [0,0,0,0,1,0,0,0,0,0,0,0]  ! OneShot only
    matrix(3, 1:3, :) = 0
    
    ! CFD (Solver=4)
    matrix(4, 0, :) = [0,0,0,0,0,1,0,0,0,0,0,1]  ! OneShot: Fluid+Special
    matrix(4, 1, :) = 0  ! 无OneWay
    matrix(4, 2, :) = [0,0,0,0,0,1,0,0,0,1,0,0]  ! Weak: Fluid+FluidThermal
    matrix(4, 3, :) = [0,0,0,0,0,1,0,0,1,0,0,0]  ! Strong: Fluid+FluidStruct
    
  END SUBROUTINE get_compatibility_matrix

  ! ============================================================================
  ! FUNCTION: get_solver_name
  ! ============================================================================
  FUNCTION get_solver_name(solver_1based) RESULT(name)
    INTEGER, INTENT(IN) :: solver_1based
    CHARACTER(len=64) :: name
    
    SELECT CASE (solver_1based)
      CASE (1)
        name = 'Standard'
      CASE (2)
        name = 'Explicit'
      CASE (3)
        name = 'Acoustic'
      CASE (4)
        name = 'Electromagnetic'
      CASE (5)
        name = 'CFD'
      CASE DEFAULT
        name = 'Unknown'
    END SELECT
  END FUNCTION get_solver_name

  ! ============================================================================
  ! 其他辅助函数...
  ! ============================================================================
  
  ! get_coupling_name(coupling_1based) ...
  ! get_physics_name(physics_1based) ...
  ! load_compatible_couplings(group) ...
  ! load_element_material_constraints(group) ...
  ! check_auxiliary_solver_requirement(group) ...
  ! get_auxiliary_solver_info(group) ...

END MODULE L3_MD_Analysis_Group_Module
```

---

## 1-based vs 0-based转换

### 转换规则

```fortran
! 外部API（用户层） → 内部实现（矩阵/数组索引）
internal_index = external_1based - 1

! 示例
! [1][1][1] (1-based) → [0][0][0] (0-based，用于矩阵访问)
! [5][4][9] (1-based) → [4][3][8] (0-based)
```

### 转换位置

**转换发生在L3_MD层的group_from_proc_id函数中**：

```fortran
! Step 1: 从映射表获取1-based编码（用户API）
group%solver_1based = 1    ! Standard
group%coupling_1based = 3  ! Weak
group%physics_1based = 7   ! ThermalStruct

! Step 2: 自动计算0-based索引（内部实现）
group%solver_idx = group%solver_1based - 1      ! 0
group%coupling_idx = group%coupling_1based - 1  ! 2
group%physics_idx = group%physics_1based - 1    ! 6

! 后续在L4_PH和L5_RT中使用0-based索引访问矩阵和数组
IF (compat_matrix(solver_idx, coupling_idx, physics_idx) == 1) THEN
  ! 有效组合
END IF
```

### 双向转换示例

```fortran
! 根据用户输入的1-based编号创建Group
group%solver_1based = 5
group%physics_1based = 9  ! FluidStruct

! 计算内部索引
group%solver_idx = 4        ! 用于矩阵compat_matrix(4, ...)
group%physics_idx = 8       ! 用于矩阵(..., 8)

! 获取辅助求解器信息
IF (group%physics_idx == 8) THEN  ! FluidStruct
  auxiliary_solver = SOLVER_STANDARD
END IF
```

---

## 约束矩阵初始化

### 矩阵定义（L4_PH层）

```fortran
! UFC\ufc_core\L4_PH\L4_PH_Analysis_Router_Module.f90

INTEGER, PARAMETER :: COMPATIBILITY_MATRIX(0:4, 0:3, 0:11) = &
  RESHAPE([ &
    ! Solver=0 (Standard)
    ! C0(OneShot)
    1,1,1,0,0,0,0,0,0,0,1,1, &
    ! C1(OneWay)
    1,0,0,0,0,0,0,0,0,0,0,0, &
    ! C2(Weak)
    1,1,0,0,0,0,1,1,0,0,1,1, &
    ! C3(Strong)
    1,0,0,0,0,0,1,1,0,0,1,1, &
    
    ! Solver=1 (Explicit)
    ! C0(OneShot only)
    1,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    
    ! Solver=2 (Acoustic)
    ! C0(OneShot only)
    0,0,0,1,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    
    ! Solver=3 (EM)
    ! C0(OneShot only)
    0,0,0,0,1,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    0,0,0,0,0,0,0,0,0,0,0,0, &
    
    ! Solver=4 (CFD)
    ! C0(OneShot)
    0,0,0,0,0,1,0,0,0,0,0,1, &
    ! C1(OneWay) - 无
    0,0,0,0,0,0,0,0,0,0,0,0, &
    ! C2(Weak)
    0,0,0,0,0,1,0,0,0,1,0,0, &
    ! C3(Strong)
    0,0,0,0,0,1,0,0,1,0,0,0 &
  ], SHAPE=[5, 4, 12])
```

### 矩阵访问示例

```fortran
! 检查[1][3][7]是否有效 (ThermalStruct+Weak)
!  1-based: [1][3][7]
!  0-based: [0][2][6]
solver_idx = 0
coupling_idx = 2
physics_idx = 6
is_valid = (COMPATIBILITY_MATRIX(solver_idx, coupling_idx, physics_idx) == 1)  ! 结果：1 (有效)

! 检查[2][3][1]是否有效 (Explicit+Weak+Structure)
!  1-based: [2][3][1]
!  0-based: [1][2][0]
solver_idx = 1
coupling_idx = 2
physics_idx = 0
is_valid = (COMPATIBILITY_MATRIX(solver_idx, coupling_idx, physics_idx) == 1)  ! 结果：0 (无效)
```

---

## Group路由逻辑

### L4_PH层的路由决策

```fortran
SUBROUTINE route_analysis_group(group, error_code)
  TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: group
  INTEGER, INTENT(OUT) :: error_code
  
  ! Step 1: 验证组合的合法性
  INTEGER :: compat_matrix(0:4, 0:3, 0:11)
  CALL get_compatibility_matrix(compat_matrix)
  
  IF (compat_matrix(group%solver_idx, group%coupling_idx, group%physics_idx) == 0) THEN
    error_code = -1
    PRINT *, "ERROR: Invalid group combination [", group%solver_1based, "][", &
             group%coupling_1based, "][", group%physics_1based, "]"
    RETURN
  END IF
  
  ! Step 2: 启用主求解器处理器
  SELECT CASE (group%solver_1based)
    CASE (1)  ! Standard
      CALL enable_standard_processor()
    CASE (2)  ! Explicit
      CALL enable_explicit_processor()
    CASE (3)  ! Acoustic
      CALL enable_acoustic_processor()
    CASE (4)  ! EM
      CALL enable_em_processor()
    CASE (5)  ! CFD
      CALL enable_cfd_processor()
  END SELECT
  
  ! Step 3: 检查是否需要辅助求解器
  IF (group%requires_auxiliary_solver) THEN
    CALL enable_auxiliary_solver(group%auxiliary_solver_id)
    
    ! 设置耦合参数
    SELECT CASE (group%physics_1based)
      CASE (9)  ! FluidStruct
        CALL setup_fsi_coupling_params()
      CASE (10) ! FluidThermal
        CALL setup_multiphysics_coupling_params()
    END SELECT
  END IF
  
  error_code = 0
  
END SUBROUTINE route_analysis_group
```

---

## 特殊场景处理

### 多求解器耦合标记

```fortran
SUBROUTINE check_auxiliary_solver_requirement(group)
  TYPE(MD_Analysis_Group_DESC), INTENT(INOUT) :: group
  
  ! FluidStruct (physics_id = 9, 0-based索引=8)
  IF (group%physics_1based == 9 .AND. group%solver_1based == 5) THEN
    group%requires_auxiliary_solver = .TRUE.
    group%auxiliary_solver_id = SOLVER_STANDARD
    
  ! FluidThermal (physics_id = 10, 0-based索引=9)
  ELSE IF (group%physics_1based == 10 .AND. group%solver_1based == 5) THEN
    group%requires_auxiliary_solver = .TRUE.
    group%auxiliary_solver_id = SOLVER_STANDARD  ! 或SOLVER_THERMAL
    
  ELSE
    group%requires_auxiliary_solver = .FALSE.
    group%auxiliary_solver_id = 0
  END IF
  
END SUBROUTINE check_auxiliary_solver_requirement
```

### Geo处理（Material族标记）

```fortran
! Geo分析仍使用Structure物理场
! [1][1][1] + Material_Family=GEO → 岩土准静态分析
! [1][3][1] + Material_Family=GEO → 岩土瞬态分析

TYPE :: MD_Analysis_Geo_DESC
  TYPE(MD_Analysis_Group_DESC) :: base_group
  INTEGER :: material_family_id  ! = GEO_FAMILY
  LOGICAL :: has_initial_stress
  LOGICAL :: has_construction_stage
  INTEGER :: n_excavation_stages
END TYPE

! 识别逻辑
IF (base_group%physics_1based == 1) THEN  ! Structure
  IF (material_family_id == GEO_FAMILY) THEN
    CALL setup_geo_analysis(base_group)
  END IF
END IF
```

---

## 相关文档

- 📍 顶层设计：`01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`
- 📍 核心映射表：`02_核心映射表/ABAQUS_PROC_到_Group_ID_完整映射.md`
- 📍 快速参考：`04_快速参考/三维坐标_快速参考表.md`

---

**实现位置**：  
- `UFC\ufc_core\L3_MD\L3_MD_Analysis_Group_Module.f90`
- `UFC\ufc_core\L4_PH\L4_PH_Analysis_Router_Module.f90`
