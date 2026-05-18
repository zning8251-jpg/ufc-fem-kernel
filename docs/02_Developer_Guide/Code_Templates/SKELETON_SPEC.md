# UFC 标准 .f90 骨架规范

> **版本**: v1.0 | **日期**: 2026-04-25
> **用途**: 新建 .f90 文件时的标准骨架模板。三种典型角色各有一份骨架。
> **关联**: [命名规范](../UFC_命名与数据结构规范.md) · [数据结构规范](../UFC_数据结构与结构体规范.md) · [十件套 v2.0](../PPLAN/11_闭环落地专项/05_中间架构层新版总纲_全景套件v3.0.md)

---

## 一、三种标准骨架

| 骨架 | 文件后缀 | 角色 | 十件套对应 |
|------|----------|------|-----------|
| **Def** | `_Def.f90` | 类型定义：四型 TYPE + 枚举 + 常量 | Definition/Schema, Desc, State, Algo, Ctx |
| **Core** | 无后缀或 `_Core.f90` | 主算法/管理：Init/Compute/Query/Finalize | Kernel, Populate, Registry |
| **Brg** | `_Brg.f90` | 跨层桥接：上下文切片、类型转换 | Bridge/Facade |

---

## 二、通用规则（所有骨架共用）

1. **USE 顺序**: L1_IF 基座 → 同层依赖 → 本域 Def
2. **IMPLICIT NONE**: 紧跟 USE 块之后，MODULE 级和每个子程序内
3. **PRIVATE 默认**: MODULE 级 `PRIVATE`，显式 `PUBLIC` 导出
4. **精度**: `USE IF_Prec, ONLY: wp, i4`，禁止 ISO_FORTRAN_ENV
5. **错误**: `USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK`
6. **头注释**: 模块头包含 Module/Layer/Domain/Purpose/四链/Status

---

## 三、骨架 A: `_Def.f90`（类型定义）

```fortran
!======================================================================
! Module:  {Layer}_{Domain}_{Feature}_Def
! Layer:   {L?_XX}
! Domain:  {Domain}
! Purpose: TYPE definitions (Desc/State/Algo/Ctx), enums, constants.
!          NO computational logic in CONTAINS (Init/default only).
!
! Theory chain:  {物理概念 → 数据结构映射}
! Logic chain:   {KW解析 → 本模块 Desc 填充 → Bridge → L4/L5 消费}
! Data chain:    {容器路径: g_ufc_global%??_layer%domain%...}
!
! Status: {DRAFT|ACTIVE|DEPRECATED}
! Last verified: YYYY-MM-DD
!======================================================================
MODULE {Layer}_{Domain}_{Feature}_Def
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! 枚举常量
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: {DOMAIN}_TYPE_XXX = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: {DOMAIN}_TYPE_YYY = 2_i4

  !--------------------------------------------------------------------
  ! Desc — 模型描述（冷数据，Write-Once）
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: {Layer}_{Domain}_Desc
    INTEGER(i4)           :: id           = 0_i4
    CHARACTER(LEN=32)     :: name         = ""
    ! ... 域特定的只读配置字段
  END TYPE {Layer}_{Domain}_Desc

  !--------------------------------------------------------------------
  ! State — 运行时状态（温数据，步间演化）
  ! 省略条件: 域无运行时更新量时可不定义
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: {Layer}_{Domain}_State
    LOGICAL               :: is_initialized = .FALSE.
    ! ... 域特定的可变状态字段
  END TYPE {Layer}_{Domain}_State

  !--------------------------------------------------------------------
  ! Algo — 算法控制（冷数据，步内只读）
  ! 省略条件: 域无算法可配置参数时可不定义
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: {Layer}_{Domain}_Algo
    INTEGER(i4)           :: method       = 1_i4
    REAL(wp)              :: tolerance    = 1.0e-6_wp
    INTEGER(i4)           :: max_iter     = 100_i4
  END TYPE {Layer}_{Domain}_Algo

  !--------------------------------------------------------------------
  ! Ctx — 调用上下文（热数据，单次调用级）
  ! 省略条件: 纯数据存储域可不定义
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: {Layer}_{Domain}_Ctx
    ! ... 临时工作数组、驱动量
  END TYPE {Layer}_{Domain}_Ctx

  !--------------------------------------------------------------------
  ! *_Arg — 结构化 IO 参数束（按需，>=2 字段共演进时使用）
  !--------------------------------------------------------------------
  ! TYPE, PUBLIC :: {Layer}_{Domain}_{Op}_Arg
  !   {fields}    ! [IN]  / [OUT] / [INOUT]
  !   INTEGER(i4) :: status = 0_i4  ! [OUT]
  ! END TYPE

END MODULE {Layer}_{Domain}_{Feature}_Def
```

### 四型裁剪决策树

```
本域是否有模型配置数据?
  ├─ 是 → 定义 Desc (必选)
  └─ 否 → 跳过 Desc (如 Bridge 域)

本域是否有步间演化量?
  ├─ 是 → 定义 State (如 Material 积分点应力)
  └─ 否 → 跳过 State (如 Section 纯查询)

本域是否有可配置算法开关/容差?
  ├─ 是 → 定义 Algo (如 Material 积分方法选择)
  └─ 否 → 跳过 Algo (如 Mesh 纯拓扑)

本域是否参与计算或编排?
  ├─ 是 → 定义 Ctx (如 Element 单元上下文)
  └─ 否 → 跳过 Ctx (如 Part 纯数据)
```

---

## 四、骨架 B: `_Core.f90` / 主模块（主算法/管理）

```fortran
!======================================================================
! Module:  {Layer}_{Domain}_{Feature}
! Layer:   {L?_XX}
! Domain:  {Domain}
! Purpose: Core computation / management for {Feature}.
!          Init, Compute, Query, Finalize entry points.
!
! Theory chain:  {理论公式}
! Logic chain:   {调用路径}
! Computation chain: {计算流: 输入→算法→输出}
! Data chain:    {Desc→State→Algo→Ctx}
!
! Status: {DRAFT|ACTIVE}
! Last verified: YYYY-MM-DD
!======================================================================
MODULE {Layer}_{Domain}_{Feature}
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  ! 本域定义
  USE {Layer}_{Domain}_{Feature}_Def, ONLY: &
      {Layer}_{Domain}_Desc, &
      {Layer}_{Domain}_State, &
      {Layer}_{Domain}_Ctx
  IMPLICIT NONE
  PRIVATE

  !-- 公开接口 --
  PUBLIC :: {Domain}_{Feature}_Init
  PUBLIC :: {Domain}_{Feature}_Compute   ! 或 Query/Eval/...
  PUBLIC :: {Domain}_{Feature}_Finalize

CONTAINS

  !--------------------------------------------------------------------
  ! Init: 初始化 + 分配
  !--------------------------------------------------------------------
  SUBROUTINE {Domain}_{Feature}_Init(desc, state, status)
    TYPE({Layer}_{Domain}_Desc),  INTENT(IN)    :: desc
    TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state
    INTEGER(i4),                  INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! ... 初始化逻辑
  END SUBROUTINE {Domain}_{Feature}_Init

  !--------------------------------------------------------------------
  ! Compute: 核心计算（热路径）
  !--------------------------------------------------------------------
  SUBROUTINE {Domain}_{Feature}_Compute(desc, state, ctx, status)
    TYPE({Layer}_{Domain}_Desc),  INTENT(IN)    :: desc    ! 冷
    TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state   ! 温
    TYPE({Layer}_{Domain}_Ctx),   INTENT(INOUT) :: ctx     ! 热
    INTEGER(i4),                  INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! ... 计算逻辑
  END SUBROUTINE {Domain}_{Feature}_Compute

  !--------------------------------------------------------------------
  ! Finalize: 释放资源
  !--------------------------------------------------------------------
  SUBROUTINE {Domain}_{Feature}_Finalize(state, status)
    TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state
    INTEGER(i4),                  INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! ... 释放逻辑
  END SUBROUTINE {Domain}_{Feature}_Finalize

END MODULE {Layer}_{Domain}_{Feature}
```

### 功能集 → 子程序映射

| 功能集 | 典型子程序名 | 归入文件 |
|--------|-------------|----------|
| Init | `*_Init`, `*_Allocate`, `*_Reset` | 主模块 / `_Core.f90` |
| Finalize | `*_Finalize`, `*_Cleanup` | 主模块 / `_Core.f90` |
| Query | `*_Get`, `*_GetByIndex`, `*_Count`, `*_Has` | 主模块 / `_Core.f90` |
| Mutate | `*_Add`, `*_Set`, `*_Update`, `*_Remove` | 主模块 / `_Core.f90` |
| Compute | `*_Compute_Ke`, `*_Compute_Fe`, `*_Eval` | 主模块 或 `_Ops.f90` |
| Valid | `*_Validate`, `*_Check` | 主模块 / `_Core.f90` |
| Parse | `*_Parse`, `*_Read`, `*_Register` | 仅 L3/L6 |
| Algo | `*_Select`, `*_Configure` | 主模块 |

---

## 五、骨架 C: `_Brg.f90`（跨层桥接）

```fortran
!======================================================================
! Module:  {Layer}_{Domain}_Brg
! Layer:   {L?_XX}
! Domain:  {Domain} (Bridge)
! Purpose: Cross-layer adapter. Context slicing, type conversion,
!          contract adaptation. NO physics computation here.
!
! Logic chain:   {上层} → Brg → {下层}
! Data chain:    上层 Desc/State → 切片 → 下层 Ctx/Desc
!
! Status: {DRAFT|ACTIVE}
! Last verified: YYYY-MM-DD
!======================================================================
MODULE {Layer}_{Domain}_Brg
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  ! 上层类型（源）
  USE {UpperLayer}_{Domain}_Def, ONLY: {Upper}_Desc
  ! 下层类型（目标）
  USE {LowerLayer}_{Domain}_Def, ONLY: {Lower}_Desc, {Lower}_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: {Domain}_Brg_Populate
  PUBLIC :: {Domain}_Brg_WriteBack  ! 仅 WriteBack 场景

CONTAINS

  !--------------------------------------------------------------------
  ! Populate: 上层 Desc → 下层 Desc/Ctx (只读注入)
  !--------------------------------------------------------------------
  SUBROUTINE {Domain}_Brg_Populate(upper_desc, lower_desc, status)
    TYPE({Upper}_Desc), INTENT(IN)    :: upper_desc
    TYPE({Lower}_Desc), INTENT(INOUT) :: lower_desc
    INTEGER(i4),        INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! 字段映射 / 切片 / 转换
    ! lower_desc%field = upper_desc%field
  END SUBROUTINE {Domain}_Brg_Populate

  !--------------------------------------------------------------------
  ! WriteBack: 下层 State → 上层 State (白名单字段)
  ! 仅在 WriteBack 场景使用；纯 Populate Bridge 可省略此子程序
  !--------------------------------------------------------------------
  SUBROUTINE {Domain}_Brg_WriteBack(lower_state, upper_state, status)
    TYPE({Lower}_State), INTENT(IN)    :: lower_state
    TYPE({Upper}_State), INTENT(INOUT) :: upper_state
    INTEGER(i4),         INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! 仅写回白名单字段
    ! upper_state%current_value = lower_state%current_value
  END SUBROUTINE {Domain}_Brg_WriteBack

END MODULE {Layer}_{Domain}_Brg
```

### Bridge 设计约束

1. Bridge 内**不执行**物理计算，只做数据映射/切片/转换
2. Bridge 是**唯一允许跨层 USE** 的模块类型
3. 上下文切片：只传下层实际需要的字段，禁止把上层大对象整体传下
4. WriteBack 严格遵守白名单，禁止修改 Desc/Algo

---

## 六、_Proc.f90 骨架（L5 SIO 入口，补充）

仅 L5_RT 和 Harness 编排入口使用 `_Proc` 后缀，遵循 SIO 五参/六参签名：

```fortran
!======================================================================
! Module:  RT_{Domain}_Proc
! Layer:   L5_RT
! Domain:  {Domain}
! Purpose: SIO entry point for Harness / step driver orchestration.
!          Five-param (desc,state,algo,ctx,args) or
!          six-param (+RT_Com_Base_Ctx,args) convention.
!======================================================================
MODULE RT_{Domain}_Proc
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  USE RT_{Domain}_Def, ONLY: RT_{Domain}_Desc, RT_{Domain}_State, &
                              RT_{Domain}_Algo, RT_{Domain}_Ctx
  ! 统一 Arg 束（若适用）
  ! USE RT_{Domain}_Def, ONLY: RT_{Domain}_Run_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_{Domain}_Run

CONTAINS

  SUBROUTINE RT_{Domain}_Run(desc, state, algo, ctx, status)
    TYPE(RT_{Domain}_Desc),  INTENT(IN)    :: desc
    TYPE(RT_{Domain}_State), INTENT(INOUT) :: state
    TYPE(RT_{Domain}_Algo),  INTENT(IN)    :: algo
    TYPE(RT_{Domain}_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),             INTENT(OUT)   :: status

    status = IF_STATUS_OK
    ! ... 编排逻辑
  END SUBROUTINE RT_{Domain}_Run

END MODULE RT_{Domain}_Proc
```

---

*最后更新: 2026-04-25*