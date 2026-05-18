# ABAQUS Section 架构在 UFC 中的实现

## 📌 核心发现

**ABAQUS 的数据模型**：
```
单元号 (Element ID) → 截面号 (Section ID) → 材料号 (Material ID)
```

**关键特性**：
- ✅ 单元和材料**独立定义**，通过截面关联
- ✅ **多对多映射**：多个单元可共享同一材料（不同截面指向同一材料）
- ✅ **截面层添加属性**：厚度、方向、积分规则等（不属于材料范畴）

---

## 🏗️ 三层架构设计

### 架构对比

| 层级 | 传统理解 | UFC 架构（含 Section） |
|------|---------|----------------------|
| **L3_MD (Mesh)** | Element | Element + **Section** |
| **L3_MD (Material)** | Material | Material（不变） |
| **数据流** | UEL → UMAT | **UEL → Section → UMAT** |

### 类型定义

```fortran
!===============================================================================
! L3_MD (Mesh Domain) - Element Types
!===============================================================================
TYPE ElemType
  INTEGER :: elem_type, nnode, ndof_el
  INTEGER :: nintegration_pts
  ! ... topology, integration rule
END TYPE

TYPE ElemCtx
  TYPE(MD_Mat_Ctx_Base) :: mat_ctx    ! 共享字段（时间、温度、步数）
  REAL(wp), ALLOCATABLE :: coords(:,:) ! 单元独有字段
  REAL(wp), ALLOCATABLE :: u(:), du(:)
  ! ... geometry, BCs
END TYPE

!===============================================================================
! L3_MD (Section Domain) - NEW! Section Type
!===============================================================================
TYPE SectionType
  !-- IDENTIFICATION
  INTEGER :: section_id               ! 截面唯一 ID
  CHARACTER(LEN=64) :: section_name
  
  !-- MATERIAL REFERENCE
  INTEGER :: mat_id                   ! 引用材料 ID
  TYPE(MD_Mat_Desc_Base), POINTER :: mat_desc  ! 指向材料的指针
  
  !-- GEOMETRIC PROPERTIES (section-specific, NOT material)
  REAL(wp) :: thickness               ! 壳/梁的厚度 [m]
  REAL(wp) :: orientation(3)          ! 纤维方向向量
  REAL(wp) :: offset                  ! 截面偏移
  
  !-- COMPOSITE/INTEGRATION
  INTEGER :: nlayer                   ! 复合层数
  INTEGER :: nintegration_pts         ! 厚度方向积分点数
  CHARACTER(LEN=16) :: integ_rule     ! 积分规则名
  
  !-- SECTION TYPE
  INTEGER :: section_family           ! 1=Solid, 2=Shell, 3=Beam, 4=Membrane
  INTEGER :: section_type             ! 具体类型
END TYPE

!===============================================================================
! L3_MD (Material Domain) - Material Types
!===============================================================================
TYPE MD_Mat_Desc_Base
  REAL(wp) :: E, nu, G, K, lambda     ! 弹性参数
  REAL(wp) :: rho                     ! 密度
  INTEGER :: mat_id                   ! 材料 ID
  INTEGER :: mat_family               ! 材料族
  CHARACTER(LEN=64) :: model_name     ! 模型名称
END TYPE

TYPE MD_Mat_State_Base
  REAL(wp) :: stress(6)               ! 应力
  REAL(wp) :: strain(6)               ! 应变
  REAL(wp) :: ddsdde(6,6)             ! 切线刚度
  REAL(wp) :: statev(:)               ! 状态变量
END TYPE

TYPE MD_Mat_Ctx_Base
  REAL(wp) :: time_val, dtime         ! 时间
  REAL(wp) :: temp, dtemp             ! 温度
  INTEGER :: kstep, kinc              ! 步数
  INTEGER :: elem_id, gauss_pt        ! 位置标识
END TYPE
```

---

## 🔄 数据流示例

### UEL 通过 Section 调用 UMAT

```fortran
SUBROUTINE UEL(RHS, AMATRX, SVARS, ENERGY, NDOFEL, NRHS, NSVARS, &
     1 PROPS, NPROPS, COORDS, MCRD, NNODE, U, DU, V, A, JTYPE, TIME, &
     2 DTIME, KSTEP, KINC, JELEM, PARAMS, NDLOAD, JDLTYP, ADLMAG, &
     3 PREDEF, NPREDF, LFLAGS, MLVARX, DDLMAG, MDLOAD, PNEWDT, &
     4 JPROPS, NJPROP, PERIOD)
  
  !-- Step 1: Pack UEL arrays → UFC structures
  TYPE(ElemCtx) :: ctx
  TYPE(ElemState) :: state
  TYPE(XXX_XXX_Desc) :: desc
  TYPE(SectionType) :: section  ! ← NEW!
  
  ! Pack element context
  ctx%coords => COORDS
  ctx%u => U
  ctx%du => DU
  ctx%time_val => TIME
  ctx%dtime => DTIME
  ctx%kstep => KSTEP
  ctx%kinc => KINC
  ctx%elem_id => JELEM
  
  ! Get section from registry (user-defined mapping)
  CALL Get_Section_For_Element(JELEM, section)
  
  ! Associate material through section
  IF (.NOT. ASSOCIATED(section%mat_desc)) THEN
    CALL Error_Material_Not_Associated(section%mat_id)
  END IF
  
  !-- Step 2: Call unified interface
  CALL PH_XXX_UEL(ctx, state, desc, section)  ! ← Pass section
  
  !-- Step 3: Unpack results
  RHS = state%rhs
  AMATRX = state%amatrx
  SVARS = state%svars
  ENERGY = state%energy
  
END SUBROUTINE UEL


!===============================================================================
! Unified Interface: PH_XXX_UEL
!===============================================================================
SUBROUTINE PH_XXX_UEL(ctx, state, desc, section)
  TYPE(ElemCtx), INTENT(INOUT) :: ctx
  TYPE(ElemState), INTENT(INOUT) :: state
  TYPE(XXX_XXX_Desc), INTENT(IN) :: desc
  TYPE(SectionType), INTENT(IN) :: section  ! ← Section bridge
  
  DO ip = 1, desc%nintegration_pts
    
    !--- Compute strain at IP
    state%ip_state(ip)%strain_inc = MATMUL(B_matrix, ctx%du)
    
    !--- Call material model THROUGH SECTION
    !     section%mat_desc points to material descriptor
    CALL PH_MAT_UMAT(ctx%mat_ctx, state%ip_state(ip), &
                     section%mat_desc, algo, flags)
    
    !--- Assemble element matrices
    internal_force += MATMUL(B_matrix, state%ip_state(ip)%stress) * detJ * weight
    state%amatrx += MATMUL(MATMUL(TRANSPOSE(B_matrix), &
                     state%ip_state(ip)%ddsdde), B_matrix) * detJ * weight
    
  END DO
  
END SUBROUTINE PH_XXX_UEL
```

---

## ✅ 设计验证

### Q1: Section 层引入是否破坏现有组合设计？

**A: 否！** Section 层与组合设计正交：

```fortran
! ElemCtx CONTAINS mat_ctx (共享字段管理)
TYPE ElemCtx
  TYPE(MD_Mat_Ctx_Base) :: mat_ctx    ! 时间、温度、步数等
  ! ... element-specific fields
END TYPE

! Section 只负责关联 (桥梁角色)
TYPE SectionType
  TYPE(MD_Mat_Desc_Base), POINTER :: mat_desc  ! 仅指向材料描述
END TYPE

! 职责分离：
!   - mat_ctx: 管理 UEL+UMAT 共享字段（组合关系）
!   - mat_desc: 管理材料参数引用（指针关联）
!   - section: 管理单元→材料映射（中间桥梁）
```

### Q2: 如何支持多对多映射？

**A: 通过 Section 注册表**：

```fortran
! 场景 1: 多个单元集合共享同一材料
SECTION_SET_1: SECTION id=101 → MATERIAL id=1 (Steel)
SECTION_SET_2: SECTION id=102 → MATERIAL id=1 (Steel)
ELEMENT_SET_E1 → SECTION 101
ELEMENT_SET_E2 → SECTION 102
! 结果：E1 和 E2 都使用 Steel 材料

! 场景 2: 一个单元集合使用不同材料（复合结构）
ELEMENT_SET_SHELL → SECTION 201 (nlayer=3)
  Layer 1: MATERIAL id=10 (Carbon fiber)
  Layer 2: MATERIAL id=11 (Glass fiber)
  Layer 3: MATERIAL id=10 (Carbon fiber)
```

### Q3: Section 层添加哪些独特属性？

**A: 几何/数值属性（不属于 Material）**：

| 属性类别 | Section 字段 | Material 字段 |
|---------|-------------|--------------|
| **几何** | `thickness`, `offset`, `orientation` | ❌ 无 |
| **积分** | `nintegration_pts`, `integ_rule` | ❌ 无 |
| **复合** | `nlayer`, `layer_thickness(:)` | ❌ 无 |
| **材料** | `mat_id`, `mat_desc` (指针) | `E`, `nu`, `statev` |

---

## 🎯 实现清单

### 已完成
- ✅ `MD_Section_Types.f90` - Section 类型定义
- ✅ `SectionRegistryType` - Section 注册表
- ✅ `PH_XXX_UEL.f90` 模板更新（包含 section 参数）
- ✅ `MD_Elem_Mat_Coupling_Design.f90` 架构文档

### 待实现
- ⏳ Section 注册表的实际使用（在 L5_RT 或 UEL Wrapper 中）
- ⏳ 复合截面的多层材料关联逻辑
- ⏳ Section 方向的旋转矩阵计算（用于各向异性材料）
- ⏳ Section 厚度的参数化研究支持

---

## 📚 参考

### ABAQUS 关键字对应

```inp
*Element, TYPE=C3D8, ELSET=E1
  1, 1, 2, 3, 4, 5, 6, 7, 8

*Solid Section, ELSET=E1, MATERIAL=M1
  <no data required for solid>

*Material, NAME=M1
*Elastic
  210000., 0.3
*Plastic
  300., 0.
```

### UFC 对应代码

```fortran
! Create material
TYPE(MD_Mat_Desc_Base), TARGET :: steel
CALL Init_Steel(steel, E=210000._wp, nu=0.3_wp)

! Create section and associate material
TYPE(SectionType) :: section_101
CALL section_101%InitBasic(101_i4, "SolidSection", 1_i4, &
                           SECTION_FAMILY_SOLID)
CALL section_101%AssociateMaterial(steel)  ! Pointer association

! Map element to section (in solver or wrapper)
element_set_E1 → section_101 → steel
```

---

## 🔍 关键洞察

**Section 层的本质**：
1. **解耦**：单元和材料独立演化，互不影响
2. **灵活性**：支持复杂的工程场景（复合、夹层、梯度材料）
3. **性能**：通过指针关联，零拷贝开销
4. **清晰性**：职责分离（Element 管几何，Section 管关联，Material 管本构）

**UFC 架构的优势**：
- ✅ 完全兼容 ABAQUS 的 Section 模式
- ✅ 保持组合设计的简洁性（ElemCtx CONTAINS mat_ctx）
- ✅ 支持 Many-to-Many 映射
- ✅ 扩展性强（易于添加新的 Section 类型）
