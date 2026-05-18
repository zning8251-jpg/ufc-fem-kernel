---
name: ufc-domain-keyword
description: "UFC KeyWord域完整性补全技能。定义关键字解析四类TYPE(Desc/State/Algo/Ctx)，覆盖ABAQUS全部关键字语法树与参数约束，四链贯通(理论链:ABAQUS手册→Fortran映射,逻辑链:KeyWord↔Parser↔Model树闭环,数据链:关键字参数生命周期)，三级命名体系。触发：KeyWord域、关键字解析、Parser、关键字手册。"
---

# UFC KeyWord 域完整性补全技能

## 何时使用

| 场景 | 触发条件 |
|------|----------|
| KeyWord域设计 | 用户说「KeyWord域」「关键字解析」「Parser」 |
| 四类TYPE定义 | 用户说「定义KeyWord的Desc/State/Algo/Ctx」 |
| 关键字手册 | 用户说「关键字契约」「语法树」 |
| ABAQUS兼容性 | 用户说「支持*STATIC/*DYNAMIC等关键字」 |

---

## 第一步：域定位与层级归属

### 层级归属（来源：00-域级划分规范.md）

| 层级 | 域 | 职责 |
|------|-----|------|
| **L3_MD** | `KeyWord` | ABAQUS关键字解析、语法树构建、Model树注册 |

```
ABAQUS输入文件 (*.inp)
    ↓ lexer/parser
MD_KeyWord_Parser
    ↓
MD_ModelTree (装配模型)
    ↓ Bridge
L3_MD/* 域（Material/Assembly/Boundary/...）
```

---

## 第二步：四类TYPE定义

### 2.1 MD_KeyWord_Desc（描述符—冷数据）

```fortran
!===============================================================================
! Module: MD_KeyWord_Types
! Layer: L3_MD - Model Data Layer
! Domain: KeyWord
!
! 四类TYPE定义 — KeyWord域
! 覆盖ABAQUS全部关键字语法树与参数约束
!===============================================================================
MODULE MD_KeyWord_Types
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-------------------------------------------------------
  ! 关键字定义常量
  !-------------------------------------------------------
  INTEGER(i4), PARAMETER :: KW_TYPE_UNKNOWN       = 0_i4
  INTEGER(i4), PARAMETER :: KW_TYPE_MODEL_DEF      = 1_i4  ! *PART, *ASSEMBLY
  INTEGER(i4), PARAMETER :: KW_TYPE_MATERIAL       = 2_i4  ! *MATERIAL, *ELASTIC
  INTEGER(i4), PARAMETER :: KW_TYPE_BOUNDARY      = 3_i4  ! *BOUNDARY, *CLOAD
  INTEGER(i4), PARAMETER :: KW_TYPE_STEP          = 4_i4  ! *STATIC, *DYNAMIC
  INTEGER(i4), PARAMETER :: KW_TYPE_OUTPUT         = 5_i4  ! *OUTPUT, *FIELD
  INTEGER(i4), PARAMETER :: KW_TYPE_INTERACTION    = 6_i4  ! *CONTACT PAIR

  !-------------------------------------------------------
  ! Desc: 关键字描述符（不变配置）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWord_Desc
    !-- 关键字标识
    CHARACTER(64) :: keyword_name      ! 关键字名称（不含*）
    CHARACTER(128):: keyword_line      ! 原始行内容
    INTEGER(i4)   :: keyword_type      ! 关键字类型（见KW_TYPE_*）

    !-- 语法树
    INTEGER(i4)   :: n_parameters      ! 参数个数
    CHARACTER(64), ALLOCATABLE :: parameter_names(:)
    CHARACTER(256),ALLOCATABLE :: parameter_values(:)
    LOGICAL,      ALLOCATABLE :: parameter_defined(:)

    !-- 嵌套结构
    INTEGER(i4)   :: nesting_level     ! 嵌套层级（0=顶层）
    CHARACTER(64) :: parent_keyword    ! 父关键字

    !-- 数据块标识
    LOGICAL     :: has_data_block      ! 是否有数据块
    INTEGER(i4) :: data_line_start     ! 数据块起始行
    INTEGER(i4) :: data_line_end       ! 数据块结束行
  END TYPE MD_KeyWord_Desc

  !-------------------------------------------------------
  ! State: 解析状态（运行时—热数据）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWord_State
    !-- 解析进度
    INTEGER(i4)  :: current_line       ! 当前解析行
    INTEGER(i4)  :: total_lines        ! 总行数
    INTEGER(i4)  :: parsed_count        ! 已解析关键字数

    !-- 错误追踪
    TYPE(ErrorStatusType) :: status
    INTEGER(i4)  :: error_line          ! 错误行号
    CHARACTER(256) :: error_message     ! 错误消息

    !-- 解析缓存
    CHARACTER(512) :: current_line_buf  ! 当前行缓存
    LOGICAL        :: line_consumed    ! 行已消费
  END TYPE MD_KeyWord_State

  !-------------------------------------------------------
  ! Algo: 解析算法参数（可调参数）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWord_Algo
    !-- 解析控制
    LOGICAL  :: case_sensitive = .FALSE.  ! 大小写敏感
    LOGICAL  :: allow_duplicate = .TRUE.   ! 允许重复关键字
    LOGICAL  :: strict_syntax = .TRUE.     ! 严格语法检查

    !-- 兼容性选项
    INTEGER(i4) :: abaqus_version      ! ABAQUS版本（2016/2020/2023）
    INTEGER(i4) :: dialect_mode        ! 方言模式（STANDARD/EXPLICIT/CFD）

    !-- 错误处理
    INTEGER(i4) :: max_errors          ! 最大错误容忍数
    LOGICAL    :: continue_on_error    ! 遇错继续
  END TYPE MD_KeyWord_Algo

  !-------------------------------------------------------
  ! Ctx: 解析上下文（指针引用）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWord_Ctx
    !-- 源文件引用
    CHARACTER(512) :: input_file_path  ! 输入文件路径
    INTEGER(i4)    :: file_unit        ! 文件单元号

    !-- 模型树引用
    TYPE(MD_ModelTree), POINTER :: model_tree_ptr => NULL()

    !-- 关键字注册表引用
    TYPE(MD_KeyWord_Registry), POINTER :: registry_ptr => NULL()

    !-- 解析工作区
    TYPE(MD_KeyWord_Desc), ALLOCATABLE :: keyword_buffer(:)
    INTEGER(i4) :: keyword_buffer_size
    INTEGER(i4) :: keyword_buffer_count
  END TYPE MD_KeyWord_Ctx

END MODULE MD_KeyWord_Types
```

---

## 第三步：ABAQUS关键字分类

### 3.1 P0级核心关键字（24个）

| 类别 | 关键字 | 映射域 |
|------|--------|--------|
| **几何** | `*NODE`, `*ELEMENT`, `*SURFACE`, `*NSET`, `*ELSET` | Mesh |
| **装配** | `*PART`, `*END PART`, `*ASSEMBLY`, `*INSTANCE`, `*END INSTANCE` | Assembly |
| **材料** | `*MATERIAL`, `*ELASTIC`, `*PLASTIC`, `*DENSITY` | Material |
| **截面** | `*SOLID SECTION`, `*SHELL SECTION` | Section |
| **边界** | `*BOUNDARY`, `*CLOAD`, `*DLOAD` | Boundary/Load |
| **分析步** | `*STEP`, `*STATIC`, `*DYNAMIC` | Analysis |
| **接触** | `*CONTACT PAIR`, `*SURFACE INTERACTION` | Interaction |
| **输出** | `*FIELD OUTPUT`, `*HISTORY OUTPUT` | Output |

### 3.2 关键字语法树示例

```
*ELASTIC
  TYPE=ISOTROPIC
  200000.0
  0.3
*PLASTIC
  HARDENING=ISOTROPIC
  200.0,0.0
  250.0,0.1
  300.0,0.2
```

---

## 第四步：四链贯通验证

### 4.1 理论链

```
ABAQUS Analysis User's Manual (关键字语法)
    ↓ 手工映射
UFC KeyWord Parser (Fortran实现)
    ↓
MD_KeyWord_* TYPE定义
    ↓
MD_ModelTree 注册
    ↓ Bridge
L3_MD各域 (Material/Boundary/...)
```

### 4.2 逻辑链

```
MD_KeyWord_Parser
    ↓ parses
MD_KeyWord_Desc (关键字描述)
    ↓ validates
MD_KeyWord_State (解析状态)
    ↓ feeds
MD_ModelTree
    ↑ references
MD_KeyWord_Registry (关键字注册表)
```

### 4.3 计算链

```
输入文件 → Lexer (词法分析)
    → Token Stream
    → Parser (语法分析)
    → AST (抽象语法树)
    → ModelTree (模型树)
    → 各域Desc注册
```

### 4.4 数据链

```
MD_KeyWord_Ctx%keyword_buffer ← [生命周期]
    Parse: 分配/填充
    Register: 消费/注册到ModelTree
    Finalize: 释放
```

---

## 第五步：三级命名体系

| 实体 | UFC命名 | 说明 |
|------|---------|------|
| 模块 | `MD_KeyWord_Types` | _Types后缀 |
| TYPE | `MD_KeyWord_Desc/State/Algo/Ctx` | 层前缀+域前缀+类型后缀 |
| 过程 | `MD_KeyWord_Parse/Validate/Register` | 层前缀+域前缀+动词 |
| 解析器 | `MD_KW_Parser` | 简写（历史兼容） |
| 词法器 | `MD_KW_Lexer` | 简写（历史兼容） |
| 注册表 | `MD_KW_Registry` | 简写（历史兼容） |

---

## 第六步：接口规范

### 6.1 主解析接口

```fortran
SUBROUTINE MD_KeyWord_Parse_File(desc, state, algo, ctx, file_path, model_tree, ierr)
  TYPE(MD_KeyWord_Desc),  INTENT(INOUT) :: desc
  TYPE(MD_KeyWord_State), INTENT(INOUT) :: state
  TYPE(MD_KeyWord_Algo),  INTENT(IN)    :: algo
  TYPE(MD_KeyWord_Ctx),   INTENT(INOUT) :: ctx
  CHARACTER(*),            INTENT(IN)    :: file_path
  TYPE(MD_ModelTree),     INTENT(INOUT) :: model_tree
  INTEGER(i4),            INTENT(OUT)   :: ierr
  !...
END SUBROUTINE
```

### 6.2 关键字验证

```fortran
SUBROUTINE MD_KeyWord_Validate(desc, state, algo, ierr)
  TYPE(MD_KeyWord_Desc),  INTENT(IN)    :: desc
  TYPE(MD_KeyWord_State), INTENT(INOUT) :: state
  TYPE(MD_KeyWord_Algo),  INTENT(IN)    :: algo
  INTEGER(i4),            INTENT(OUT)   :: ierr
  !...
END SUBROUTINE
```

---

## 第七步：合规检查清单

- [ ] 四类TYPE(Desc/State/Algo/Ctx)完整定义
- [ ] Desc覆盖P0级24个关键字
- [ ] 理论链：ABAQUS手册→Fortran映射
- [ ] 逻辑链：KeyWord↔Parser↔ModelTree闭环
- [ ] 数据链：关键字参数生命周期管理
- [ ] 命名符合三级体系
- [ ] 兼容ABAQUS 2016/2020/2023

---

**技能版本**: v1.0 | **日期**: 2026-04-04
**规范锚点**: `UFC/docs/六层架构拆分/00-总纲/00-关键字契约表.md`
