# UFC材料域三层贯通设计 — L3/L4/L5架构完整实现

## 一、概述

本文档描述UFC材料域的完整L3/L4/L5三层贯通设计，以弹性材料族作为黄金模板，展示：
- **主辅TYPE三层嵌套**：family_type + sub_type + property_flags
- **四类TYPE系统**：Desc/State/Algo/Ctx
- **三层架构贯通**：L3_MD → L4_PH → L5_RT
- **单向数据流**：L3是唯一真相来源（SSOT）

## 二、架构总览

### 2.1 三层职责划分

```
┌─────────────────────────────────────────────────────────────┐
│ L3_MD (Model Description Layer)                             │
│ - 材料定义真源（Single Source of Truth）                    │
│ - ABAQUS关键字解析                                          │
│ - 材料参数存储与验证                                        │
│ - 派生参数计算                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓ Bridge (MD_Mat_Elas_Brg)
┌─────────────────────────────────────────────────────────────┐
│ L4_PH (Physics Layer)                                       │
│ - 本构积分（应力更新）                                      │
│ - 切线刚度计算                                              │
│ - 热路径优化                                                │
│ - 算法绑定（空相设计）                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓ Dispatch (RT_Mat_Elas_Core)
┌─────────────────────────────────────────────────────────────┐
│ L5_RT (Runtime Layer)                                       │
│ - 材料调度路由                                              │
│ - State演化管理（Commit/Rollback）                         │
│ - WriteBack协调                                             │
│ - 分派表管理                                                │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流向

```
用户输入（ABAQUS inp文件）
    ↓
L3_MD: 解析关键字 → 创建Desc → 验证 → 注册
    ↓ Populate
L4_PH: 接收Desc → 构建刚度矩阵 → 计算应力/切线
    ↓ Dispatch
L5_RT: 路由调度 → 管理State → Commit/Rollback
    ↓ WriteBack (可选)
L3_MD: 更新状态（如需要）
```

## 三、已创建的文件清单

### 3.1 L3_MD层（材料定义真源）

| 文件 | 角色 | 功能 | 行数 |
|------|------|------|------|
| `MD_Mat_Family_Def.f90` | Def | 三层嵌套枚举定义 | ~200 |
| `MD_Mat_Elas_Def.f90` | Def | 四类TYPE定义 | ~180 |
| `MD_Mat_Elas_Core.f90` | Core | 核心实现（初始化/验证/注册） | ~200 |
| `MD_Mat_Elas_Brg.f90` | Brg | L3→L4桥接 | ~150 |

**关键TYPE定义**：
```fortran
TYPE, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Desc
  ! 三层嵌套结构
  INTEGER(i4) :: family_type      ! Level 1: 主族（ELASTIC）
  INTEGER(i4) :: sub_type         ! Level 2: 变体（ISO/ORTHO/etc.）
  INTEGER(i4) :: property_flags   ! Level 3: 附加属性（位标志）
  
  ! 材料参数
  INTEGER(i4) :: num_constants
  INTEGER(i4) :: dependencies
  REAL(wp), ALLOCATABLE :: constants(:,:)
  
  ! 派生参数
  REAL(wp) :: E, nu, G, K, lambda, mu  ! 各向同性
  REAL(wp) :: E11, E22, E33, ...       ! 正交异性
  REAL(wp) :: C(6,6)                   ! 各向异性
END TYPE MD_Mat_Elas_Desc
```

### 3.2 L4_PH层（材料本构计算）

| 文件 | 角色 | 功能 | 行数 |
|------|------|------|------|
| `PH_Mat_Elas_Def_New.f90` | Def | 四类TYPE定义 | ~120 |
| `PH_Mat_Elas_Core_New.f90` | Core | 核心计算（刚度/应力/切线） | ~250 |
| `PH_Mat_Elas_Eval.f90` | Eval | 求值入口（SIO模式） | ~120 |

**关键函数签名**：
```fortran
! 标准四TYPE签名
SUBROUTINE PH_Mat_Elas_Eval_Stress_Tangent(desc, state, algo, ctx, &
                                            strain, stress, ddsdde, status)
  TYPE(PH_Mat_Elas_Desc), INTENT(IN) :: desc
  TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state
  TYPE(PH_Mat_Elas_Algo), INTENT(IN) :: algo
  TYPE(PH_Mat_Elas_Ctx), INTENT(INOUT) :: ctx
  REAL(wp), INTENT(IN) :: strain(6)
  REAL(wp), INTENT(OUT) :: stress(6)
  REAL(wp), INTENT(OUT) :: ddsdde(6,6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```

### 3.3 L5_RT层（材料调度路由）

| 文件 | 角色 | 功能 | 行数 |
|------|------|------|------|
| `RT_Mat_Elas_Def.f90` | Def | 路由TYPE定义 | ~80 |
| `RT_Mat_Elas_Core.f90` | Core | 调度核心（路由/Commit/Rollback） | ~150 |

**关键数据结构**：
```fortran
TYPE :: RT_Mat_Elas_Dispatch_Table
  TYPE(RT_Mat_Elas_Route_Entry), ALLOCATABLE :: entries(:)
  INTEGER(i4) :: num_entries
  LOGICAL :: initialized
END TYPE

TYPE :: RT_Mat_Elas_Route_Entry
  INTEGER(i4) :: mat_id
  INTEGER(i4) :: sub_type
  INTEGER(i4) :: l4_slot_index
  PROCEDURE(...), POINTER :: eval_proc
END TYPE
```

## 四、三层嵌套设计详解

### 4.1 第1层：材料主族（11个）

```fortran
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_ELASTIC      = 1_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_PLASTIC      = 2_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_GEOTECHNICAL = 3_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_HYPERELASTIC = 4_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_VISCOELASTIC = 5_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_CREEP        = 6_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_DAMAGE       = 7_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_COMPOSITE    = 8_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_THERMAL      = 9_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_ACOUSTIC     = 10_i4
INTEGER(i4), PARAMETER :: MD_MAT_FAMILY_USER         = 11_i4
```

### 4.2 第2层：材料变体（65个）

以弹性材料族为例：
```fortran
! 弹性材料辅TYPE（101~110）
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_ISO        = 101_i4  ! 各向同性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_ORTHO      = 102_i4  ! 正交异性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_TRANSISO   = 103_i4  ! 横观各向同性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_ANISO      = 104_i4  ! 各向异性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_POROUS     = 105_i4  ! 多孔
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_HYPO       = 106_i4  ! 假弹性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_SHEAR      = 107_i4  ! 剪切模量形式
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_ENGINEERING = 108_i4 ! 工程常数
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_THERMO     = 109_i4  ! 热弹性
INTEGER(i4), PARAMETER :: MD_MAT_ELAS_SUB_PIEZO      = 110_i4  ! 压电弹性
```

### 4.3 第3层：附加属性（位标志，可组合）

```fortran
INTEGER(i4), PARAMETER :: MD_MAT_PROP_NONE         = 0_i4
INTEGER(i4), PARAMETER :: MD_MAT_PROP_TEMP_DEP     = 1_i4   ! 温度相关
INTEGER(i4), PARAMETER :: MD_MAT_PROP_FIELD_DEP    = 2_i4   ! 场变量相关
INTEGER(i4), PARAMETER :: MD_MAT_PROP_MODULI       = 4_i4   ! MODULI选项
INTEGER(i4), PARAMETER :: MD_MAT_PROP_LONG_TERM    = 8_i4   ! LONG TERM选项
INTEGER(i4), PARAMETER :: MD_MAT_PROP_RATE_DEP     = 16_i4  ! 率相关
INTEGER(i4), PARAMETER :: MD_MAT_PROP_PRESSURE_DEP = 32_i4  ! 压力相关
```

**组合示例**：
```fortran
! 温度相关 + 压力相关
property_flags = IOR(MD_MAT_PROP_TEMP_DEP, MD_MAT_PROP_PRESSURE_DEP)
! 结果：property_flags = 33 (1 + 32)
```

## 五、ABAQUS关键字映射

### 5.1 映射规则

```
*ELASTIC, TYPE=ISOTROPIC, DEPENDENCIES=1
  ↓
family_type = MD_MAT_FAMILY_ELASTIC (1)
sub_type = MD_MAT_ELAS_SUB_ISO (101)
property_flags = MD_MAT_PROP_TEMP_DEP (1)
```

### 5.2 支持的关键字

| ABAQUS关键字 | sub_type | 参数个数 |
|-------------|----------|---------|
| `*ELASTIC, TYPE=ISOTROPIC` | 101 | 2 (E, nu) |
| `*ELASTIC, TYPE=ORTHOTROPIC` | 102 | 9 (E11~E33, nu12~nu23, G12~G23) |
| `*ELASTIC, TYPE=TRAVERSE` | 103 | 5 |
| `*ELASTIC, TYPE=ANISOTROPIC` | 104 | 21 (C11~C66) |
| `*ELASTIC, TYPE=POROUS` | 105 | 4 |
| `*ELASTIC, TYPE=HYPOELASTIC` | 106 | 6 |
| `*ELASTIC, TYPE=SHEAR` | 107 | 2 (G, K) |
| `*ELASTIC, TYPE=ENGINEERING` | 108 | 9 |

## 六、四类TYPE系统

### 6.1 Desc（描述符）

**职责**：静态材料定义，只读
**生命周期**：模型定义阶段创建，求解过程不变
**所有者**：L3_MD层

```fortran
TYPE :: MD_Mat_Elas_Desc
  ! 三层嵌套
  INTEGER(i4) :: family_type, sub_type, property_flags
  ! 材料参数
  REAL(wp), ALLOCATABLE :: constants(:,:)
  ! 派生参数
  REAL(wp) :: E, nu, G, K, lambda, mu
END TYPE
```

### 6.2 State（状态）

**职责**：运行时可变状态
**生命周期**：求解过程动态更新
**所有者**：L5_RT层（L4计算，L5管理）

```fortran
TYPE :: PH_Mat_Elas_State
  REAL(wp) :: stress(6)
  REAL(wp) :: strain(6)
  REAL(wp) :: elastic_strain(6)
  LOGICAL :: initialized
  INTEGER(i4) :: num_evaluations
END TYPE
```

### 6.3 Algo（算法）

**职责**：算法控制参数
**生命周期**：初始化时设置，求解过程只读
**所有者**：L4_PH层

```fortran
TYPE :: PH_Mat_Elas_Algo
  INTEGER(i4) :: tangent_type
  LOGICAL :: use_numerical_tangent
  REAL(wp) :: numerical_perturbation
END TYPE
```

### 6.4 Ctx（上下文）

**职责**：迭代级临时工作区
**生命周期**：每次调用创建，使用后可释放
**所有者**：L4_PH层（热路径）

```fortran
TYPE :: PH_Mat_Elas_Ctx
  REAL(wp) :: D_el(6,6)           ! 刚度矩阵
  LOGICAL :: D_el_cached
  REAL(wp) :: stress_trial(6)
  REAL(wp) :: temperature
END TYPE
```

## 七、数据流转详解

### 7.1 Populate阶段（L3→L4）

```fortran
! L3层：创建材料描述符
CALL MD_Mat_Elas_Create_Isotropic(l3_desc, E=210.0e9_wp, nu=0.3_wp, status)

! L3→L4桥接：填充L4描述符
CALL MD_Mat_Elas_Brg_Populate_L4(l3_desc, l4_props, l4_nprops, status)

! L4层：从L3数据初始化
CALL PH_Mat_Elas_Populate_From_L3(l4_desc, l4_props, l4_nprops, &
                                   l3_desc%sub_type, status)
```

### 7.2 Evaluation阶段（L4计算）

```fortran
! 构建刚度矩阵
CALL PH_Mat_Elas_Build_Stiffness(desc, ctx, status)

! 计算应力
CALL PH_Mat_Elas_Compute_Stress(ctx, strain, stress, status)

! 计算切线
CALL PH_Mat_Elas_Compute_Tangent(ctx, ddsdde, status)

! 更新状态
CALL PH_Mat_Elas_Update_State(state, stress, strain, status)
```

### 7.3 Dispatch阶段（L5路由）

```fortran
! 构建路由表（初始化时）
CALL RT_Mat_Elas_Build_Table_From_L4(mat_ids, sub_types, slot_indices, &
                                      num_mats, status)

! 运行时调度（热路径）
CALL RT_Mat_Elas_Dispatch(mat_id, ip_index, strain, stress, ddsdde, status)

! 状态管理
CALL RT_Mat_Elas_Commit_State(mat_id, ip_index, status)  ! 成功时
CALL RT_Mat_Elas_Rollback_State(mat_id, ip_index, status)  ! 失败时
```

## 八、设计亮点

### 8.1 严格三层嵌套

- **嵌套深度限制**：≤3层，通过验证函数强制执行
- **清晰映射**：直接对应ABAQUS关键字结构
- **易于扩展**：第3层使用位标志，可灵活组合

### 8.2 单向数据流

```
L3_MD (SSOT) → L4_PH (计算) → L5_RT (路由)
     ↑                              ↓
     └──────── WriteBack ───────────┘
            (仅在必要时)
```

- L3是唯一真相来源
- L4/L5只读L3数据
- WriteBack仅用于状态同步

### 8.3 零拷贝设计

- 桥接模块使用指针和引用
- 避免不必要的数据复制
- 热路径优化

### 8.4 命名规范统一

- 完全符合UFC_命名规范_v3.0
- `_Def` 角色后缀：TYPE定义
- `_Core` 角色后缀：核心实现
- `_Brg` 角色后缀：桥接模块
- `_Eval` 角色后缀：求值入口

## 九、使用示例

### 9.1 创建各向同性弹性材料

```fortran
! L3层：创建材料
TYPE(MD_Mat_Elas_Desc) :: l3_desc
TYPE(ErrorStatusType) :: status

CALL MD_Mat_Elas_Create_Isotropic(l3_desc, E=210.0e9_wp, nu=0.3_wp, status)

! 验证
CALL MD_Mat_Elas_Desc_Validate(l3_desc, status)

! 注册
INTEGER(i4) :: mat_id
CALL MD_Mat_Elas_Register(l3_desc, mat_id, status)
```

### 9.2 L4层计算应力

```fortran
! L4层：初始化
TYPE(PH_Mat_Elas_Desc) :: l4_desc
TYPE(PH_Mat_Elas_State) :: l4_state
TYPE(PH_Mat_Elas_Algo) :: l4_algo
TYPE(PH_Mat_Elas_Ctx) :: l4_ctx

! 从L3填充
CALL PH_Mat_Elas_Populate_From_L3(l4_desc, l3_props, l3_nprops, &
                                   l3_sub_type, status)

! 计算应力和切线
REAL(wp) :: strain(6), stress(6), ddsdde(6,6)
strain = [0.001_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]

CALL PH_Mat_Elas_Eval_Stress_Tangent(l4_desc, l4_state, l4_algo, l4_ctx, &
                                      strain, stress, ddsdde, status)
```

### 9.3 L5层调度

```fortran
! L5层：构建路由表
CALL RT_Mat_Elas_Build_Table_From_L4(mat_ids, sub_types, slot_indices, &
                                      num_mats, status)

! 运行时调度
CALL RT_Mat_Elas_Dispatch(mat_id=1, ip_index=1, &
                          strain=strain, stress=stress, ddsdde=ddsdde, &
                          status=status)
```

## 十、后续工作

### 10.1 文件整合

当前创建的新文件使用了 `_New` 后缀（L4层），需要：
1. 备份现有文件
2. 用新模板替换旧文件
3. 更新所有引用
4. 测试兼容性

### 10.2 其他材料族推广

按照弹性材料族的黄金模板，依次实现：
1. Plastic（塑性）— 15+个辅TYPE
2. Hyperelastic（超弹性）— 11个辅TYPE
3. Damage（损伤）— 6个辅TYPE
4. Creep（蠕变）— 8个辅TYPE
5. Viscoelastic（粘弹性）— 4个辅TYPE
6. Geotechnical（岩土）— 8个辅TYPE
7. Composite（复合材料）— 5个辅TYPE
8. Thermal（热学）— 3个辅TYPE
9. Acoustic（声学）— 2个辅TYPE
10. User-Defined（用户定义）— 2个辅TYPE

### 10.3 测试与验证

1. 单元测试：每个辅TYPE
2. 集成测试：L3→L4→L5完整流程
3. 性能测试：与ABAQUS对标
4. 回归测试：确保兼容性

## 十一、总结

本文档展示了UFC材料域的完整L3/L4/L5三层贯通设计，包括：

✅ **三层嵌套设计**：family_type + sub_type + property_flags，严格限制≤3层
✅ **四类TYPE系统**：Desc/State/Algo/Ctx完整实现
✅ **三层架构贯通**：L3_MD → L4_PH → L5_RT单向数据流
✅ **命名规范统一**：符合UFC_命名规范_v3.0
✅ **ABAQUS兼容**：完整支持*ELASTIC关键字解析
✅ **黄金模板**：可推广到其他10个材料族

这个设计为UFC材料域的统一重构提供了坚实的基础，是其他域（Element/LoadBC/Contact/Output/WriteBack）重构的参考模板。
