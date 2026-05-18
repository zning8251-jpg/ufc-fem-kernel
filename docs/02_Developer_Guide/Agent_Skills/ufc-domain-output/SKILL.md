---
name: ufc-domain-output
description: "UFC Output子域完整性补全技能。定义输出域四类TYPE(Desc/State/Algo/Ctx)，覆盖Field Output/History Output/Nodal Output/Element Output，四链贯通(理论链:场变量定义,逻辑链:Output↔Solver↔Model数据流,计算链:ODB写入,数据链:变量生命周期)，三级命名体系。触发：Output域、场变量输出、Field Output、History Output、ODB。"
---

# UFC Output 域完整性补全技能

## 何时使用

| 场景 | 触发条件 |
|------|----------|
| Output域设计 | 用户说「Output域」「场变量输出」「Field Output」 |
| 四类TYPE定义 | 用户说「定义Output的Desc/State/Algo/Ctx」 |
| 结果输出 | 用户说「History Output」「Nodal Output」 |
| ODB集成 | 用户说「ODB写入」「输出变量」 |

---

## 第一步：域定位与层级归属

### 层级归属（来源：00-域级划分规范.md）

| 层级 | 域 | 职责 |
|------|-----|------|
| **L3_MD** | `Output` | 输出定义描述（Model层） |
| **L5_RT** | `Output` | 输出执行（Runtime层） |

```
L3_MD/Output (定义)
    ↓ *FIELD OUTPUT, *HISTORY OUTPUT
MD_Output_Desc (输出变量定义)
    ↓ Bridge
L5_RT/Output (执行)
    ↓
ODB文件 / 结果场
```

---

## 第二步：四类TYPE定义

### 2.1 MD_Output_Desc（描述符—冷数据）

```fortran
!===============================================================================
! Module: MD_Output_Types
! Layer: L3_MD - Model Data Layer
! Domain: Output
!
! 四类TYPE定义 — Output域
! 覆盖Field/History/Nodal/Element Output
!===============================================================================
MODULE MD_Output_Types
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-------------------------------------------------------
  ! 输出类型枚举
  !-------------------------------------------------------
  INTEGER(i4), PARAMETER :: OUTPUT_FIELD     = 1_i4  ! 场变量输出
  INTEGER(i4), PARAMETER :: OUTPUT_HISTORY   = 2_i4  ! 历史输出
  INTEGER(i4), PARAMETER :: OUTPUT_NODAL     = 3_i4  ! 节点输出
  INTEGER(i4), PARAMETER :: OUTPUT_ELEMENT   = 4_i4  ! 单元输出

  !-------------------------------------------------------
  ! 输出变量定义（内置变量库）
  !-------------------------------------------------------
  INTEGER(i4), PARAMETER :: OUT_VAR_DISPLACEMENT    = 1001_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_VELOCITY        = 1002_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_ACCELERATION    = 1003_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_STRESS          = 2001_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_STRAIN          = 2002_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_PLASTIC_STRAIN = 2003_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_MISES          = 2004_i4
  INTEGER(i4), PARAMETER :: OUT_VAR Contact_pressure= 3001_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_TEMP            = 4001_i4
  INTEGER(i4), PARAMETER :: OUT_VAR_HEAT_FLUX     = 4002_i4

  !-------------------------------------------------------
  ! Desc: 输出描述符（不变配置）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_Desc
    !-- 输出标识
    CHARACTER(64) :: output_name        ! 输出名称
    INTEGER(i4)   :: output_id          ! 唯一ID
    INTEGER(i4)     :: output_type        ! 输出类型（见OUTPUT_*）

    !-- 输出变量定义
    INTEGER(i4)   :: n_variables         ! 变量个数
    INTEGER(i4),  ALLOCATABLE :: variable_ids(:)     ! 变量ID列表
    CHARACTER(64),ALLOCATABLE :: variable_names(:)    ! 变量名列表

    !-- 输出范围
    INTEGER(i4)   :: region_type         ! 输出区域（WHOLE/MATERIAL/SET）
    CHARACTER(64):: region_name         ! 区域名称（NSET/ELSET）
    INTEGER(i4)   :: section_point      ! 截面点位置

    !-- 输出频率
    INTEGER(i4)   :: frequency          ! 输出频率（每N步输出）
    INTEGER(i4)   :: time_interval      ! 时间间隔
    LOGICAL      :: output_at_end       ! 仅在分析步结束时输出
  END TYPE MD_Output_Desc

  !-------------------------------------------------------
  ! State: 输出状态（运行时—热数据）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_State
    !-- 输出状态
    LOGICAL      :: is_output_requested  ! 当前步是否输出
    INTEGER(i4)  :: current_frequency_cnt ! 当前频率计数
    REAL(wp)      :: last_output_time     ! 上次输出时间

    !-- 缓冲区状态
    LOGICAL, ALLOCATABLE :: node_output_ready(:)
    LOGICAL, ALLOCATABLE :: elem_output_ready(:)

    !-- 错误追踪
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Output_State

  !-------------------------------------------------------
  ! Algo: 输出算法参数（可调参数）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_Algo
    !-- 精度控制
    INTEGER(i4)   :: precision          ! 输出精度（有效位数）
    LOGICAL      :: scientific_notation   ! 科学计数法

    !-- 压缩选项
    LOGICAL      :: compress_output      ! 压缩输出文件
    INTEGER(i4)   :: compression_level  ! 压缩级别

    !-- 选择性输出
    LOGICAL      :: output_nodes         ! 输出节点结果
    LOGICAL      :: output_elements      ! 输出单元结果
    LOGICAL      :: output_integration   ! 输出积分点结果
  END TYPE MD_Output_Algo

  !-------------------------------------------------------
  ! Ctx: 输出上下文（指针引用）
  !-------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_Ctx
    !-- ODB引用
    TYPE(ODB_Handle), POINTER :: odb_ptr => NULL()

    !-- 数据引用
    TYPE(MD_ModelTree),   POINTER :: model_tree_ptr => NULL()
    TYPE(RT_Field_Buffer),POINTER :: field_buffer_ptr => NULL()

    !-- 输出缓冲区
    REAL(wp), ALLOCATABLE :: nodal_results(:,:)   ! (n_node, n_vars)
    REAL(wp), ALLOCATABLE :: element_results(:,:)  ! (n_elem, n_vars)

    !-- 工作数组
    REAL(wp), ALLOCATABLE :: work_array(:)
  END TYPE MD_Output_Ctx

END MODULE MD_Output_Types
```

---

## 第三步：ABAQUS输出变量分类

### 3.1 标准场变量

| 变量ID | 变量名 | 说明 | 单位 |
|--------|--------|------|------|
| 1001 | U | 位移 | mm |
| 1002 | V | 速度 | mm/s |
| 1003 | A | 加速度 | mm/s² |
| 2001 | S | 应力分量 | MPa |
| 2002 | E | 应变分量 | - |
| 2003 | PEEQ | 等效塑性应变 | - |
| 2004 | Mises | Mises应力 | MPa |
| 3001 | CPRESS | 接触压力 | MPa |
| 4001 | NT | 温度 | K |
| 4002 | RFL | 热通量 | mW/mm² |

### 3.2 History Output变量

```
能量:
  ALLKE - 动能
  ALLSE - 应变能
  ALLAE - 伪应变能

功率:
  ALLWK - 外力功
  ETOTAL - 总能量

收敛:
  CFLUX - 约束反力
  TFOLDER - 时间
```

---

## 第四步：四链贯通验证

### 4.1 理论链

```
ABAQUS Analysis User's Manual (输出变量定义)
    ↓
场变量数学定义 (应力/应变/位移公式)
    ↓
UFC Output TYPE定义
    ↓
L5_RT/Output 执行
    ↓
ODB文件格式
```

### 4.2 逻辑链

```
L5_RT/Solver (求解结果)
    ↓ produces
RT_Field_Buffer (场数据缓冲)
    ↓ consumed
L5_RT/Output (输出执行)
    ↓ writes
ODB_File (结果文件)
    ↑ queries
MD_Output_Desc (输出定义)
```

### 4.3 计算链

```
求解完成 → 触发输出检查
    → MD_Output_Check_Request (检查是否需要输出)
    → 收集场数据 (RT_Field_Gather)
    → 格式化输出 (RT_Output_Format)
    → ODB写入 (RT_Output_Write)
```

### 4.4 数据链

```
MD_Output_Ctx%nodal_results ← [生命周期]
    Init: 分配缓冲区
    Gather: 填充数据
    Write: 写入ODB
    Finalize: 释放
```

---

## 第五步：三级命名体系

| 实体 | UFC命名 | 说明 |
|------|---------|------|
| 模块 | `MD_Output_Types` / `RT_Output_Exec` | _Types/_Exec后缀 |
| TYPE | `MD_Output_Desc/State/Algo/Ctx` | 层前缀+域前缀+类型后缀 |
| 过程 | `MD_Output_Init/Register` / `RT_Output_Write` | 层前缀+域前缀+动词 |
| 变量常量 | `OUT_VAR_DISPLACEMENT` | 全大写+下划线分隔 |

---

## 第六步：接口规范

### 6.1 输出定义注册

```fortran
SUBROUTINE MD_Output_Register(desc, state, algo, model_tree, ierr)
  TYPE(MD_Output_Desc),  INTENT(INOUT) :: desc
  TYPE(MD_Output_State), INTENT(INOUT) :: state
  TYPE(MD_Output_Algo),  INTENT(IN)    :: algo
  TYPE(MD_ModelTree),    INTENT(INOUT) :: model_tree
  INTEGER(i4),           INTENT(OUT)   :: ierr
  !...
END SUBROUTINE
```

### 6.2 输出执行

```fortran
SUBROUTINE RT_Output_Write(desc, state, algo, ctx, field_buffer, step_ctx, ierr)
  TYPE(MD_Output_Desc),   INTENT(IN)    :: desc
  TYPE(MD_Output_State), INTENT(INOUT) :: state
  TYPE(MD_Output_Algo),  INTENT(IN)    :: algo
  TYPE(MD_Output_Ctx),  INTENT(INOUT) :: ctx
  TYPE(RT_Field_Buffer), INTENT(IN)    :: field_buffer
  TYPE(RT_Step_Context),  INTENT(IN)    :: step_ctx
  INTEGER(i4),           INTENT(OUT)   :: ierr
  !...
END SUBROUTINE
```

---

## 第七步：合规检查清单

- [ ] 四类TYPE(Desc/State/Algo/Ctx)完整定义
- [ ] Desc覆盖Field/History/Nodal/Element Output
- [ ] 理论链：场变量数学定义
- [ ] 逻辑链：Output↔Solver↔Model数据流
- [ ] 计算链：ODB写入
- [ ] 数据链：变量生命周期管理
- [ ] 命名符合三级体系

---

**技能版本**: v1.0 | **日期**: 2026-04-04
**规范锚点**: `UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md`
