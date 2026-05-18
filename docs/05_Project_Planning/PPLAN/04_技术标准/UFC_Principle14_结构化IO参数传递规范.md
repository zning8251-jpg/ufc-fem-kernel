# UFC Principle #14 — 结构化 IO 参数传递规范

> **版本**: v2.0（升级版）  
> **归属**: UFC 架构总纲 第12章 子总纲⑩ 全局命名规范 / 子总纲⑤ 热路径隔离  
> **覆盖范围**: 所有 L5_RT 过程接口，推广至 L4_PH 公开接口  
> **设计基因对应**: 基因① 热路径隔离、基因③ 可验证性、基因④ AI-ready、基因⑩ 全局命名规范  
> **状态**: ✅ 正式规范，已落地 Assembly / LoadBC 域；Solver 域 TYPE 违规已修复（v2.0）

---

## 目录

1. [背景与动机](#1-背景与动机)
2. [核心问题诊断](#2-核心问题诊断)
3. [规范定义：结构化 IO 模式](#3-规范定义结构化-io-模式)
4. [命名规范（无 _Structured / _Impl 后缀）](#4-命名规范)
5. [三层 Ctx 指针链架构](#5-三层-ctx-指针链架构)
6. [热路径保护六条禁令](#6-热路径保护六条禁令)
7. [Populate 期三大任务](#7-populate-期三大任务)
8. [推广矩阵：适用 / 不适用场景](#8-推广矩阵)
9. [与 UFC 十大设计基因的对应关系](#9-与-ufc-十大设计基因的对应关系)
10. [潜在问题与规避策略](#10-潜在问题与规避策略)
11. [验证工具与机器检查规则](#11-验证工具与机器检查规则)
12. [典型实现示例](#12-典型实现示例)
13. [域级推广状态矩阵](#13-域级推广状态矩阵)

---

## 1. 背景与动机

### 1.1 传统散列参数接口的三大痛点

传统有限元内核中，过程调用大量使用"散列参数"模式：

```fortran
! ❌ 旧模式：散列参数接口
SUBROUTINE RT_Asm_Init(n_elements, n_nodes, n_dofs_per_node, &
                       assemble_K, assemble_M, assemble_f, &
                       initialized, error_code)
```

**痛点 1 — 接口稳定性差**  
每次增加一个参数，所有调用点都必须修改。在 UFC 六层架构中，L5_RT 的接口改动会级联影响 L6_AP 的所有驱动入口。

**痛点 2 — 可验证性缺失**  
散列参数无法携带元数据（版本号、必填项标记、范围约束），Harness 工具无法自动验证接口契约合规性。

**痛点 3 — AI 接管障碍**  
AI 模型对结构化 TYPE 的理解和生成能力远强于对散列参数列表的处理，不符合 UFC 基因④ AI-ready 原则。

### 1.2 设计目标

> 每个域过程必须通过一对专属的 `_In` / `_Out` TYPE 完成参数传递，过程签名只包含四大类状态量 + 一对 IO 结构体，共六个参数。

---

## 2. 核心问题诊断

### 2.1 已发现的主要问题


| 问题编号 | 问题描述                                                | 严重度     | 所在文件                  |
| ---- | --------------------------------------------------- | ------- | --------------------- |
| P-01 | Proc 层用 `_Structured` 后缀，Impl 层用散列参数，接口脱节           | 高       | RT_Asm_Proc.f90 (旧版)  |
| P-02 | TYPE 成员字段错误使用 `INTENT(...)` 声明                      | 严重/编译错误 | RT_Solv_Proc.f90 (旧版) |
| P-03 | `_Structured` 后缀冗余，含义重复（模块名已表达语义）                   | 低       | 所有 Proc 模块            |
| P-04 | `_Impl` 后缀与 Proc 在同名情况下造成混淆                         | 中       | RT_Asm_Impl.f90       |
| P-05 | RT_Analysis_Ctx 与 RT_Com_Base_Ctx 职责完全重叠            | 高       | RT_Types.f90          |
| P-06 | 时间字段 (time_current/dtime) 在多个 Ctx 中重复定义             | 高       | 多处                    |
| P-07 | "Common"含义模糊（UMAT+UEL 共享？还是所有域共享？）                  | 中       | RT_Com_Types.f90      |
| P-08 | 抽象接口签名只有 2 个参数（input/output），违反六参数规范                | 严重      | RT_Solv_Proc.f90 (旧版) |
| P-09 | `_In` TYPE 内嵌四大类状态 TYPE（desc/state/algo/ctx），接口边界失守 | 严重      | RT_Solv_Proc.f90 (旧版) |


> **P-08 / P-09 修复状态**：`RT_Solv_Proc.f90` 已于 v2.0 修复。所有 TYPE 成员 INTENT 声明已删除；抽象接口已升级为六参数；`_In` TYPE 已剥离四大类成员（desc/state/algo/ctx 改为独立形参）。

### 2.2 根本原因

- 缺乏统一的 Ctx 层级架构规范，导致各域自行定义时间字段
- 命名体系未在总纲级明确"Proc 模块只需语义名，无需技术后缀"
- Fortran TYPE 成员与子程序形参的 INTENT 规则混淆（TYPE 成员**不支持** INTENT 声明）

---

## 3. 规范定义：结构化 IO 模式

### 3.1 标准过程签名（六参数规范）

```fortran
! 规范：每个域过程恰好 6 个参数
SUBROUTINE RT_XXX_OpName(desc, state, algo, ctx, inp, out)
  TYPE(RT_XXX_Desc),   INTENT(INOUT) :: desc   ! 冷数据（配置）
  TYPE(RT_XXX_State),  INTENT(INOUT) :: state  ! 热数据（迭代状态）
  TYPE(RT_XXX_Algo),   INTENT(IN)    :: algo   ! 算法参数（只读）
  TYPE(RT_XXX_Ctx),    INTENT(INOUT) :: ctx    ! 热路径缓冲（无 ALLOCATABLE）
  TYPE(RT_XXX_OpName_In),  INTENT(IN)  :: inp  ! 本次调用输入
  TYPE(RT_XXX_OpName_Out), INTENT(OUT) :: out  ! 本次调用输出
END SUBROUTINE
```

### 3.2 _In / _Out TYPE 设计规则

```fortran
! _In TYPE：纯输入，只含值/指针，不含 ALLOCATABLE
TYPE :: RT_XXX_OpName_In
  INTEGER(i4) :: param_a = 0_i4          ! 带默认值（调用方可选填）
  REAL(wp)    :: param_b = 0.0_wp
  REAL(wp), POINTER :: array_c(:) => NULL()  ! 用指针，不用 ALLOCATABLE
END TYPE

! _Out TYPE：输出结果，允许 ALLOCATABLE（仅 Out 侧）
TYPE :: RT_XXX_OpName_Out
  TYPE(ErrorStatusType) :: status         ! 必须包含状态码
  LOGICAL :: success = .FALSE.            ! 操作成功标志
  REAL(wp), ALLOCATABLE :: result(:)      ! 输出侧允许 ALLOCATABLE
END TYPE
```

### 3.4 迁移对比：两参数 → 六参数（Solver 域示例）

以 `RT_Solv_Proc.f90` 从旧版（v1.0）升级到规范版（v2.0）为例，说明迁移的三步操作。

**Step 1：删除 TYPE 成员上的 INTENT 属性**

```fortran
! ❌ 旧版（v1.0）：TYPE 成员非法附 INTENT
TYPE, PUBLIC :: RT_Solv_Init_In
  TYPE(RT_Solv_Base_Desc), INTENT(INOUT) :: desc   ! 编译错误！
  TYPE(RT_Solv_Algo),      INTENT(INOUT) :: algo   ! 编译错误！
  INTEGER(i4),             INTENT(IN)   :: n_dofs  ! 编译错误！
END TYPE

! ✅ 规范版（v2.0）：成员无 INTENT；desc/algo 升为独立形参
TYPE, PUBLIC :: RT_Solv_Init_In
  INTEGER(i4) :: n_dofs     = 0_i4   ! 纯输入标量，无 INTENT
  INTEGER(i4) :: n_elements = 0_i4
  INTEGER(i4) :: n_nodes    = 0_i4
  LOGICAL     :: validate_config = .TRUE.
END TYPE
```

**Step 2：将四大类从 `_In` 内部提升为独立形参**

```fortran
! ❌ 旧版抽象接口：2 参数（所有信息塞入 input/output）
ABSTRACT INTERFACE
  SUBROUTINE RT_Solv_Init_Interface(input, output)
    TYPE(RT_Solv_Init_In),  INTENT(INOUT) :: input   ! 包含 desc/algo！
    TYPE(RT_Solv_Init_Out), INTENT(OUT)   :: output
  END SUBROUTINE
END INTERFACE

! ✅ 规范版抽象接口：6 参数（desc/state/algo/ctx 独立，inp 仅含输入值）
ABSTRACT INTERFACE
  SUBROUTINE RT_Solv_Init_Interface(desc, state, algo, ctx, inp, out)
    TYPE(RT_Solv_Base_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Solv_NRState),   INTENT(INOUT) :: state
    TYPE(RT_Solv_Algo),      INTENT(IN)    :: algo
    TYPE(RT_Solv_Ctx),       INTENT(INOUT) :: ctx
    TYPE(RT_Solv_Init_In),   INTENT(IN)    :: inp
    TYPE(RT_Solv_Init_Out),  INTENT(OUT)   :: out
  END SUBROUTINE
END INTERFACE
```

**Step 3：`_Out` TYPE 中大数组改用 ALLOCATABLE（`_In` 禁用 ALLOCATABLE）**

```fortran
! ❌ 旧版 _Out：数组字段带 INTENT（TYPE 成员非法）
TYPE, PUBLIC :: RT_Solv_Equilibrium_Out
  REAL(wp), INTENT(OUT) :: residual(:)                ! 非法！
  REAL(wp), INTENT(OUT) :: displacement_correction(:) ! 非法！
END TYPE

! ✅ 规范版 _Out：ALLOCATABLE（_Out 侧允许）
TYPE, PUBLIC :: RT_Solv_Equilibrium_Out
  REAL(wp), ALLOCATABLE :: residual(:)                ! ✅ 正确
  REAL(wp), ALLOCATABLE :: displacement_correction(:) ! ✅ 正确
  TYPE(ErrorStatusType) :: status                     ! 必须包含
END TYPE
```

**迁移检查清单**：

- TYPE 定义体内所有成员已删除 `INTENT(...)` 属性
- `_In` TYPE 中不再含 `Desc` / `State` / `Algo` / `Ctx` 四大类字段
- 抽象接口已升级为恰好 6 个参数
- `_Out` TYPE 含 `ErrorStatusType` 字段
- `_In` TYPE 无 `ALLOCATABLE`；`_Out` TYPE 按需使用 `ALLOCATABLE`

---

### 3.3 INTENT 规则速查（Fortran 规范）

```fortran
! ✅ 正确：INTENT 只用于子程序/函数的形参
SUBROUTINE MyProc(x, y)
  REAL(wp), INTENT(IN)    :: x   ! 合法：形参 INTENT
  REAL(wp), INTENT(INOUT) :: y   ! 合法：形参 INTENT
END SUBROUTINE

! ❌ 错误：TYPE 定义体内的成员不能有 INTENT
TYPE :: MyType
  REAL(wp), INTENT(IN) :: x      ! 编译错误！Fortran 规范不允许
END TYPE
```

---

## 4. 命名规范

### 4.1 核心原则：语义自洽，无技术后缀

UFC 命名哲学：**名字表达"是什么"，而非"怎么实现"**。


| 旧命名（废弃）                       | 新命名（规范）             | 理由                       |
| ----------------------------- | ------------------- | ------------------------ |
| `RT_Asm_Init_Structured`      | `RT_Asm_Init`       | `_Structured` 是实现细节，不是语义 |
| `RT_Asm_Init_Impl`            | `RT_Asm_Init`（同模块内） | `_Impl` 冗余，模块名已区分        |
| `RT_LoadBC_Update_Structured` | `RT_LoadBC_Update`  | 同上                       |


### 4.2 三级命名体系

```
层级前缀_域前缀_操作名[_IO后缀]
  │        │       │        │
  RT_      Asm_    Init     _In / _Out
  L5_RT    Assembly 初始化   IO结构体专用后缀
```

**规则**：

- 过程名：`RT_<Domain>_<OpName>`（无后缀）
- IO 结构体：`RT_<Domain>_<OpName>_In` / `RT_<Domain>_<OpName>_Out`
- 四大类 TYPE：`RT_<Domain>_Desc` / `_State` / `_Algo` / `_Ctx`

### 4.3 禁止列表

禁止在**过程名**中使用以下后缀（可用于内部实现时作注释说明）：

- `_Structured`（冗余）
- `_Impl`（混淆）
- `_Core`（歧义，与文件名混淆）
- `_Wrapper`（表达不稳定性，应直接命名）
- `_New` / `_V2`（版本号应入文档，不入名字）

---

## 5. 三层 Ctx 指针链架构

### 5.1 架构图

```
┌─────────────────────────────────────────┐
│ Level 1: RT_Global_Ctx                   │
│  职责：全局唯一时间/步骤管理中心           │
│  生命周期：整个分析过程                   │
│  关键字段：                               │
│    time_current, dtime                   │
│    kstep, kinc                           │
│    analysis_type, nlgeom                 │
│    convergence_tol_force/energy/disp     │
└──────────────┬──────────────────────────┘
               │ POINTER（只读引用）
┌──────────────▼──────────────────────────┐
│ Level 2: RT_Com_Base_Ctx                 │
│  职责：UMAT + UEL 共享增量步上下文        │
│  生命周期：每个增量步                    │
│  关键字段：                               │
│    global_ctx → RT_Global_Ctx (指针)     │
│    lflags(6)  ABAQUS 原始标志            │
│    elem_id, gauss_pt（位置标识）          │
│    nrhs, mlvarx, ndload（UEL专属）       │
│    newmark_params(3)（动力学参数）        │
└──────────────┬──────────────────────────┘
               │ POINTER（域级继承）
┌──────────────▼──────────────────────────┐
│ Level 3: RT_Mat_Ctx / RT_Elem_Ctx /      │
│          RT_Asm_Ctx / RT_LoadBC_Ctx ...  │
│  职责：域专用热路径缓冲                   │
│  生命周期：每个材料点/单元               │
│  关键字段：                               │
│    com_ctx → RT_Com_Base_Ctx（指针）     │
│    域特定固定尺寸数组（无 ALLOCATABLE）   │
│    通过 com_ctx%global_ctx 访问全局时间  │
└─────────────────────────────────────────┘
```

### 5.2 标准 Level 3 Ctx 定义模板

```fortran
TYPE, PUBLIC :: RT_XXX_Ctx
  !-- 层级引用链（必须，顺序固定）
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()  ! → Level 2
  
  !-- 域特定字段（固定尺寸，禁止 ALLOCATABLE）
  REAL(wp) :: local_buffer(MAX_XXX_SIZE)  = 0.0_wp
  INTEGER(i4) :: work_int(MAX_XXX_INT)    = 0_i4
  
  !-- 可选：非占有指针（指向外部已分配数组，不负责释放）
  REAL(wp), POINTER :: external_ref(:) => NULL()

CONTAINS
  PROCEDURE :: Init   => RT_XXX_Ctx_Init
  PROCEDURE :: Attach => RT_XXX_Ctx_Attach   ! 建立指针关联
  PROCEDURE :: Detach => RT_XXX_Ctx_Detach   ! 清空指针（析构前调用）
  PROCEDURE :: Clear  => RT_XXX_Ctx_Clear    ! 清零缓冲区（热路径调用）
END TYPE
```

### 5.3 指针关联（Populate 期建立，热路径只读）

```fortran
! ✅ Populate 期建立关联（UFC_Populate_All 中）
DO i = 1, n_mat_pts
  rt_mat_ctx(i)%com_ctx => global_com_ctx     ! 关联 Level 2
END DO

! ✅ 热路径访问（零拷贝，O(1)）
time_now = mat_ctx%com_ctx%global_ctx%time_current

! ❌ 禁止：热路径内建立/断开指针关联
mat_ctx%com_ctx => some_other_ctx   ! 禁止在增量步内执行！
```

### 5.5 RT_Com_Base_Ctx 升级路径

当 `RT_Com_Base_Ctx` 需要加入 `global_ctx` 指针字段时（从旧版无指针结构升级），按以下步骤执行：

**Step 1：在 `RT_Com_Base_Ctx` TYPE 定义中添加指针字段**

```fortran
! 修改 RT_Com_Types.f90 中的 RT_Com_Base_Ctx
TYPE, PUBLIC :: RT_Com_Base_Ctx
  !-- [新增] Level 1 全局上下文指针（Populate 期建立，热路径只读）
  TYPE(RT_Global_Ctx), POINTER :: global_ctx => NULL()  ! ← 新增此行
  
  !-- 原有字段（保持不变）
  INTEGER(i4) :: lflags(6)  = 0_i4
  INTEGER(i4) :: elem_id    = 0_i4
  INTEGER(i4) :: gauss_pt   = 0_i4
  INTEGER(i4) :: nrhs       = 0_i4
  INTEGER(i4) :: mlvarx     = 0_i4
  INTEGER(i4) :: ndload     = 0_i4
  REAL(wp)    :: newmark_params(3) = 0.0_wp
END TYPE RT_Com_Base_Ctx
```

**Step 2：在 `UFC_Populate_All` 中建立指针关联**

```fortran
! UFC_Populate_All 中 Task 3（指针关联阶段）
! 先关联 global_ctx 到 global_com_ctx，再让所有域 Ctx 指向 global_com_ctx
model%global_com_ctx%global_ctx => model%global_ctx   ! ← 新增此行

DO i = 1, model%n_mat_pts
  model%rt_mat_ctx(i)%com_ctx => model%global_com_ctx
END DO
! ... 其他域同理
```

**Step 3：更新 USE 语句**

```fortran
! 在 RT_Com_Types.f90 顶部添加对 RT_Global_Ctx 的 USE
USE RT_Global_Ctx_Types, ONLY: RT_Global_Ctx   ! ← 新增
```

**升级注意事项**：

- `global_ctx` 指针必须在 `Populate` 期绑定，**不得**在增量步内修改（违反禁令 3）
- `RT_Global_Ctx_Types` 模块不得反向 USE `RT_Com_Types`（保持单向依赖）
- 升级后所有 Level 3 Ctx 可通过 `ctx%com_ctx%global_ctx%time_current` 零拷贝访问全局时间

---

### 5.4 职责清晰化对照表


| 字段                      | 应在哪里定义                       | 其他 Ctx 如何访问                           |
| ----------------------- | ---------------------------- | ------------------------------------- |
| `time_current`, `dtime` | `RT_Global_Ctx`              | `ctx%com_ctx%global_ctx%time_current` |
| `kstep`, `kinc`         | `RT_Global_Ctx`              | 同上                                    |
| `lflags(6)`             | `RT_Com_Base_Ctx`            | `ctx%com_ctx%lflags`                  |
| `elem_id`, `gauss_pt`   | `RT_Com_Base_Ctx`            | `ctx%com_ctx%elem_id`                 |
| 材料点局部应变缓冲               | `RT_Mat_Ctx`                 | 直接访问                                  |
| 单元刚度矩阵缓冲                | `RT_Elem_Ctx` / `RT_Asm_Ctx` | 直接访问                                  |


---

## 6. 热路径保护六条禁令

> **定义热路径**：在增量步（Increment）内、平衡迭代循环（Iteration Loop）中被频繁调用的代码路径。

### 禁令 1：禁止在增量步内执行 O(n) 扫描

```fortran
! ❌ 禁止：增量步内调用 GetById（O(n) 线性扫描）
DO iter = 1, max_iter
  CALL MD_Mat_GetById(mat_id, mat_desc)   ! 每次调用 O(n)，极端性能杀手
  CALL PH_Compute(mat_desc, ...)
END DO

! ✅ 正确：Populate 期建立指针，热路径 O(1) 访问
! （Populate 期）
rt_mat_ctx(i)%md_desc => mat_lib(mat_id)

! （热路径）
DO iter = 1, max_iter
  CALL PH_Compute(rt_mat_ctx(i)%md_desc, ...)  ! O(1) 指针访问
END DO
```

### 禁令 2：禁止在 Ctx TYPE 中使用 ALLOCATABLE

```fortran
! ❌ 禁止：Ctx 中 ALLOCATABLE（热路径内触发堆分配）
TYPE :: RT_Mat_Ctx
  REAL(wp), ALLOCATABLE :: stress_buffer(:)   ! 禁止！
END TYPE

! ✅ 正确：固定尺寸数组（栈分配，热路径友好）
INTEGER(i4), PARAMETER :: RT_MAT_NSTRESS_MAX = 6
TYPE :: RT_Mat_Ctx
  REAL(wp) :: stress_buffer(RT_MAT_NSTRESS_MAX) = 0.0_wp
END TYPE
```

### 禁令 3：禁止在增量步内建立/断开指针关联

```fortran
! ❌ 禁止：热路径内改变指针关联
SUBROUTINE HotPathSub(ctx, ...)
  ctx%com_ctx => new_com_ctx   ! 严重违规！
END SUBROUTINE

! ✅ 正确：指针关联在 Populate 期一次性完成，热路径只读
```

### 禁令 4：禁止在增量步内调用 ALLOCATE/DEALLOCATE

```fortran
! ❌ 禁止：迭代循环内动态内存操作
DO iter = 1, max_iter
  ALLOCATE(temp(n_dofs))   ! 禁止！堆操作严重拖慢热路径
  ! ...
  DEALLOCATE(temp)
END DO

! ✅ 正确：在 Init 期或 Populate 期一次性分配，热路径复用
```

## 禁令 5：禁止在热路径内执行 I/O 操作

```fortran
! ❌ 禁止：迭代循环内写文件/日志（除 DEBUG 编译选项外）
DO iter = 1, max_iter
  WRITE(*, *) "iter=", iter, "residual=", res   ! 禁止（性能杀手）
END DO

! ✅ 正确：通过观测钩子（AI-ready 接口）异步记录，或仅在收敛后输出
```

### 禁令 6：禁止在 `_In` TYPE 中嵌入四大类状态 TYPE 字段

`_In` TYPE 代表"本次操作的输入参数"，四大类状态量（Desc / State / Algo / Ctx）必须作为独立形参传递，绝不能嵌入 `_In` 内部作为成员字段。

```fortran
! ❌ 禁止：_In 内嵌四大类（Solver 域旧版违规模式）
TYPE :: RT_Solv_Init_In
  TYPE(RT_Solv_Base_Desc) :: desc   ! 禁止！应是独立形参
  TYPE(RT_Solv_Algo)      :: algo   ! 禁止！应是独立形参
  INTEGER(i4) :: n_dofs = 0_i4
END TYPE

! 调用时必须额外解包：
!   call_site 无法区分 inp%desc 和 desc 形参，AI 代码生成困难
CALL RT_Solv_Init(inp%desc, state, inp%algo, ctx, inp, out)  ! 混乱！

! ✅ 正确：四大类作为独立形参，_In 只含纯输入值
TYPE :: RT_Solv_Init_In
  INTEGER(i4) :: n_dofs     = 0_i4   ! 纯输入：本次初始化的规模
  INTEGER(i4) :: n_elements = 0_i4
  LOGICAL     :: validate_config = .TRUE.
END TYPE

! 调用时六参数清晰对应：
CALL RT_Solv_Init(desc, state, algo, ctx, inp, out)  ! 清晰！
```

**内嵌的危害**：

1. 六参数规范被破坏，抽象接口无法统一
2. TYPE 成员需要 `INTENT` 才能表达意图，导致 P-02 违规（Fortran 编译错误）
3. `_In` 需要深拷贝整个状态 TYPE，增量步内产生大量冗余拷贝
4. AI 模型无法从签名推断哪些参数会被修改（可验证性损失）

---

## 7. Populate 期三大任务

Populate 期（模型读取完成后、热路径开始前）必须完成以下三项任务，顺序不可颠倒：

```fortran
SUBROUTINE UFC_Populate_All(model, global_ctx)
  TYPE(UFC_Model), INTENT(INOUT) :: model
  TYPE(RT_Global_Ctx), INTENT(INOUT) :: global_ctx

  !===========================================================
  ! Task 1：读取 INP，填充 L3_MD Desc（冷数据，Write-Once）
  !===========================================================
  CALL MD_Mat_ReadFromINP(model%mat_lib, model%inp_data)
  CALL MD_Elem_ReadFromINP(model%elem_lib, model%inp_data)
  CALL MD_Node_ReadFromINP(model%node_lib, model%inp_data)
  ! ... 所有域 Desc 填充完毕，之后禁止修改 Desc 字段

  !===========================================================
  ! Task 2：分配 L4_PH / L5_RT 数组（只分配，不关联）
  !===========================================================
  ALLOCATE(model%ph_mat_state(model%n_mat_pts))
  ALLOCATE(model%rt_mat_ctx(model%n_mat_pts))
  ALLOCATE(model%rt_elem_ctx(model%n_elems))
  ALLOCATE(model%rt_asm_ctx)   ! 单例
  ! ... 其他域分配

  !===========================================================
  ! Task 3：建立指针关联（最关键！决定热路径性能）
  !===========================================================
  DO i = 1, model%n_mat_pts
    model%rt_mat_ctx(i)%com_ctx => model%global_com_ctx
    model%rt_mat_ctx(i)%md_desc => model%mat_lib(i)
    model%rt_mat_ctx(i)%ph_state => model%ph_mat_state(i)
  END DO
  DO i = 1, model%n_elems
    model%rt_elem_ctx(i)%com_ctx => model%global_com_ctx
    model%rt_elem_ctx(i)%md_desc => model%elem_lib(i)
  END DO
  model%rt_asm_ctx%com_ctx => model%global_com_ctx

END SUBROUTINE UFC_Populate_All
```

---

## 8. 推广矩阵

### 8.1 适用场景（强烈推荐）


| 场景                 | 推荐原因                       | 典型域                               |
| ------------------ | -------------------------- | --------------------------------- |
| L5_RT 所有过程接口       | 接口稳定性、AI-ready、Harness 可验证 | Assembly, LoadBC, Solver, Element |
| L4_PH 公开接口（非热路径核心） | 跨域调用时提供清晰契约                | PH_Mat_Compute, PH_Elem_Stiffness |
| L6_AP 驱动入口         | 用户定制扩展点需要明确契约              | AP_Analysis_Run, AP_Step_Execute  |
| 任何参数超过 4 个的过程      | 超过 4 参数时散列模式难以维护           | 普遍适用                              |


### 8.2 不适用场景


| 场景                  | 原因            | 建议做法               |
| ------------------- | ------------- | ------------------ |
| L4_PH 热路径内核心循环      | IO 结构体解包有额外开销 | 使用直接参数传递，保持最小签名    |
| L2_NM 数值算法（BLAS级别）  | 纯数值接口，参数语义固定  | 遵循 BLAS/LAPACK 约定  |
| TYPE-bound 方法（内部实现） | OOP 封装内无需额外包装 | 直接使用 `SELF` 访问所有字段 |
| 单参数/双参数简单过程         | 包装成本高于收益      | 直接传参即可             |


### 8.3 全层级覆盖推广路线

```
阶段 1（已完成）：L5_RT Assembly / LoadBC 域
阶段 2（进行中）：L5_RT 所有域（Solver/Element/Contact/StepDriver）
阶段 3（计划中）：L4_PH 公开接口层（非核心热路径）
阶段 4（长期）：L6_AP 驱动接口层
```

---

## 9. 与 UFC 十大设计基因的对应关系


| 基因编号 | 基因名称     | 本规范的贡献                                     |
| ---- | -------- | ------------------------------------------ |
| 基因①  | 热路径隔离    | Ctx 无 ALLOCATABLE；指针关联在 Populate 期完成；五条禁令  |
| 基因②  | 单向依赖铁律   | _In/_Out TYPE 定义在 Proc 模块内，避免跨层依赖          |
| 基因③  | 可验证性第一   | 每个 _Out 必含 ErrorStatusType；Harness 可自动检查   |
| 基因④  | AI-ready | 结构化 TYPE 比散列参数更易被 AI 理解和生成                 |
| 基因⑤  | 全局命名规范   | 三级命名体系；禁止 _Structured/_Impl/_New 等技术后缀     |
| 基因⑥  | 可实时观测    | _Out TYPE 可扩展观测字段（norm/count/timing）而不破坏接口 |
| 基因⑦  | 可增量演进    | 新增参数只修改 _In TYPE，不改过程签名（接口稳定）              |
| 基因⑧  | 容错回滚     | ErrorStatusType 统一错误传播链                    |
| 基因⑨  | 资源可计量    | _Out TYPE 可携带 cpu_time/mem_used 等计量字段      |
| 基因⑩  | 模型可治理    | _In TYPE 提供版本号字段，支持契约版本检查                  |


---

## 10. 潜在问题与规避策略

### 问题 1：_In TYPE 中的 POINTER 字段安全性

**风险**：`_In` 中的指针字段如果在调用方提前释放，导致悬空指针。

**规避**：

```fortran
! 规则：_In 中的 POINTER 字段必须在注释中标注"非占有"
TYPE :: RT_Asm_AssembleK_In
  ! [NON_OWNING_PTR] 调用方负责生命周期，本过程不 DEALLOCATE
  REAL(wp), POINTER :: Ke(:,:) => NULL()
  ! [NON_OWNING_PTR]
  INTEGER(i4), POINTER :: dof_map(:) => NULL()
END TYPE
```

### 问题 2：嵌套 TYPE 的默认初始化陷阱

**风险**：`_Out` 中嵌套的 `ErrorStatusType` 可能未被正确初始化，导致假阳性成功状态。

**规避**：

```fortran
! 规则：_Out 的 Init 方法必须显式重置 status
TYPE :: RT_XXX_OpName_Out
  TYPE(ErrorStatusType) :: status
  LOGICAL :: success = .FALSE.   ! 默认 FALSE，成功时才设 TRUE
END TYPE
! 每次调用前：out%success = .FALSE.（由 Harness 强制检查）
```

### 问题 3：过度包装导致的编译器优化障碍

**风险**：编译器可能无法内联展开多层 TYPE 访问，影响热路径性能。

**规避**：

- `_In`/`_Out` 模式仅用于 L5_RT 接口层（Proc 模块），不渗透到 L4_PH 核心热路径
- L4_PH 内核心子程序继续使用最小化直接参数
- 编译时使用 `-O2 -finline-functions` 确保结构体访问被优化

### 问题 4：_Out 中 ALLOCATABLE 的生命周期管理

**风险**：`_Out%result` 在调用方使用后未释放，造成内存泄漏。

**规避**：

```fortran
! 规则：含 ALLOCATABLE 的 _Out 必须提供 Finalize 接口
! 调用方责任：
TYPE(RT_Asm_ComputeResidual_Out) :: res_out
CALL RT_Asm_ComputeResidual(desc, state, algo, ctx, inp, res_out)
! ... 使用 res_out%residual
IF (ALLOCATED(res_out%residual)) DEALLOCATE(res_out%residual)
```

---

## 11. 验证工具与机器检查规则

UFC Harness 工具应自动检查以下规则：


| 规则 ID  | 检查项                                                                 | 错误级别    |
| ------ | ------------------------------------------------------------------- | ------- |
| SIO-01 | Proc 模块中所有 PUBLIC 过程签名是否恰好 6 个参数                                    | ERROR   |
| SIO-02 | 第 5/6 参数是否为对应的 `_In`/`_Out` TYPE                                    | ERROR   |
| SIO-03 | `_Out` TYPE 是否包含 `ErrorStatusType` 字段                               | ERROR   |
| SIO-04 | Proc 模块 PUBLIC 名称是否含 `_Structured`/`_Impl` 后缀                       | WARNING |
| SIO-05 | `_In` TYPE 中的 POINTER 字段是否有 `[NON_OWNING_PTR]` 注释                   | WARNING |
| SIO-06 | `RT_XXX_Ctx` 中是否存在 `ALLOCATABLE` 字段                                 | ERROR   |
| SIO-07 | TYPE 定义体内是否存在 `INTENT(...)` 声明                                      | ERROR   |
| SIO-08 | Level 3 Ctx 是否包含 `com_ctx` 指针字段                                     | WARNING |
| SIO-09 | 热路径子程序（标注 `!$UFC HOT_PATH`）内是否有 ALLOCATE                            | ERROR   |
| SIO-10 | 热路径子程序内是否有 `GetById` / `FindBy` 类扫描调用                               | ERROR   |
| SIO-11 | TYPE 定义体内（TYPE...END TYPE 块中）是否存在 `INTENT(...)` 属性                  | ERROR   |
| SIO-12 | ABSTRACT INTERFACE 中的过程是否恰好 6 个参数（desc/state/algo/ctx/inp/out）      | ERROR   |
| SIO-13 | `_In` TYPE 成员中是否含有四大类名称模式（`_Desc` / `_State` / `_Algo` / `_Ctx` 后缀） | WARNING |
| SIO-14 | `_In` TYPE 成员中是否存在 `ALLOCATABLE` 属性                                 | ERROR   |


---

## 12. 典型实现示例

### 12.1 完整域 Proc 模块骨架

```fortran
!===========================================================================
! Module: RT_XXX_Proc                                              [v2.0]
! Layer:  L5_RT — Runtime Layer
! Domain: XXX
!
! Principle #14: Structured IO Pattern
!   - All procedures follow 6-parameter convention
!   - No _Structured / _Impl suffix in PUBLIC names
!   - _In/_Out TYPE pairs defined in this module
!===========================================================================
MODULE RT_XXX_Proc
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE RT_XXX_Types
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC: 语义命名，无技术后缀
  PUBLIC :: RT_XXX_Init
  PUBLIC :: RT_XXX_Compute
  PUBLIC :: RT_XXX_Finalize

  !-- IO 类型定义（本模块私有，通过 PUBLIC 过程暴露功能）
  TYPE :: RT_XXX_Init_In
    INTEGER(i4) :: n_items = 0_i4
    LOGICAL     :: option_a = .FALSE.
  END TYPE

  TYPE :: RT_XXX_Init_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL :: initialized = .FALSE.
  END TYPE

  TYPE :: RT_XXX_Compute_In
    ! [NON_OWNING_PTR]
    REAL(wp), POINTER :: input_data(:) => NULL()
    REAL(wp) :: scale = 1.0_wp
  END TYPE

  TYPE :: RT_XXX_Compute_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: result_norm = 0.0_wp
    LOGICAL  :: computed = .FALSE.
  END TYPE

  TYPE :: RT_XXX_Finalize_In
    LOGICAL :: keep_state = .FALSE.
  END TYPE

  TYPE :: RT_XXX_Finalize_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL :: finalized = .FALSE.
  END TYPE

CONTAINS

  SUBROUTINE RT_XXX_Init(desc, state, algo, ctx, inp, out)
    TYPE(RT_XXX_Desc),     INTENT(INOUT) :: desc
    TYPE(RT_XXX_State),    INTENT(INOUT) :: state
    TYPE(RT_XXX_Algo),     INTENT(IN)    :: algo
    TYPE(RT_XXX_Ctx),      INTENT(INOUT) :: ctx
    TYPE(RT_XXX_Init_In),  INTENT(IN)    :: inp
    TYPE(RT_XXX_Init_Out), INTENT(OUT)   :: out
    ! TODO: 路由至 L3_MD 或 L4_PH 对应子程序
    out%initialized = .TRUE.
  END SUBROUTINE RT_XXX_Init

  SUBROUTINE RT_XXX_Compute(desc, state, algo, ctx, inp, out)
    TYPE(RT_XXX_Desc),        INTENT(INOUT) :: desc
    TYPE(RT_XXX_State),       INTENT(INOUT) :: state
    TYPE(RT_XXX_Algo),        INTENT(IN)    :: algo
    TYPE(RT_XXX_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_XXX_Compute_In),  INTENT(IN)    :: inp
    TYPE(RT_XXX_Compute_Out), INTENT(OUT)   :: out
    ! TODO: 路由至 L4_PH 物理计算
    out%computed = .TRUE.
  END SUBROUTINE RT_XXX_Compute

  SUBROUTINE RT_XXX_Finalize(desc, state, algo, ctx, inp, out)
    TYPE(RT_XXX_Desc),        INTENT(INOUT) :: desc
    TYPE(RT_XXX_State),       INTENT(INOUT) :: state
    TYPE(RT_XXX_Algo),        INTENT(IN)    :: algo
    TYPE(RT_XXX_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_XXX_Finalize_In), INTENT(IN)    :: inp
    TYPE(RT_XXX_Finalize_Out),INTENT(OUT)   :: out
    out%finalized = .TRUE.
  END SUBROUTINE RT_XXX_Finalize

END MODULE RT_XXX_Proc
```

### 12.2 三层 Ctx 访问模式（调用方示例）

```fortran
! 热路径示例：通过指针链访问时间信息
SUBROUTINE PH_Mat_Compute_Stress(mat_ctx, stress, statev, ddsdde)
  !$UFC HOT_PATH  ! 标注热路径，Harness 检查禁令
  TYPE(RT_Mat_Ctx), INTENT(INOUT) :: mat_ctx
  REAL(wp), INTENT(INOUT) :: stress(:), statev(:)
  REAL(wp), INTENT(OUT)   :: ddsdde(:,:)

  REAL(wp) :: dtime_local, time_local

  ! 零拷贝访问全局时间（O(1) 指针链）
  dtime_local = mat_ctx%com_ctx%global_ctx%dtime
  time_local  = mat_ctx%com_ctx%global_ctx%time_current

  ! ... 核心本构计算
END SUBROUTINE
```

---

## 13. 域级推广状态矩阵

> 追踪 L5_RT 各域对 Principle #14 六参数规范的落地状态。

### 13.1 当前覆盖状态（L5_RT 全域）


| 域              | Proc 文件                  | Types 文件                  | 六参数规范                   | TYPE 成员无 INTENT | _Out 含 ErrorStatus | com_ctx 指针        | 状态      |
| -------------- | ------------------------ | ------------------------- | ----------------------- | --------------- | ------------------ | ----------------- | ------- |
| **Assembly**   | `RT_Asm_Proc.f90`        | `RT_Asm_Types.f90`        | ✅ 已完成                   | ✅ 合规            | ✅ 合规               | ✅ 已建立             | ✅ 完成    |
| **LoadBC**     | `RT_LoadBC_Proc.f90`     | —                         | ✅ 已完成                   | ✅ 合规            | ✅ 合规               | —                 | ✅ 完成    |
| **Solver**     | `RT_Solv_Proc.f90`       | `RT_Solv_Types.f90`       | ✅ v2.0已修复               | ✅ v2.0已修复       | ✅ 合规               | ⚠️ 待加入 global_ctx | ⚠️ 基本完成 |
| **Material**   | `RT_Mat_Proc.f90`        | `RT_Mat_Types.f90`        | ⚠️ _In/_Out 已定义，过程签名待验证 | ⚠️ 需审查          | ⚠️ 需审查             | ⚠️ 未确认            | 🔄 进行中  |
| **Element**    | 无 `_Proc.f90`            | `RT_Elem_Types.f90`       | ❌ 尚未建立                  | —               | —                  | —                 | ❌ 未开始   |
| **Contact**    | 无 `_Proc.f90`            | `RT_Contact_Types.f90`    | ❌ 尚未建立                  | —               | —                  | —                 | ❌ 未开始   |
| **StepDriver** | `RT_StepDriver_Impl.f90` | `RT_StepDriver_Types.f90` | ❌ 未使用六参数规范              | —               | —                  | ✅ 已有 Ctx          | ❌ 未开始   |
| **Mesh**       | —                        | —                         | ❌ 尚未建立                  | —               | —                  | —                 | ❌ 未开始   |
| **Output**     | —                        | —                         | ❌ 尚未建立                  | —               | —                  | —                 | ❌ 未开始   |
| **WriteBack**  | —                        | —                         | ❌ 尚未建立                  | —               | —                  | —                 | ❌ 未开始   |


图例：✅ 已完成 | ⚠️ 部分完成 | 🔄 进行中 | ❌ 未开始 | — 不适用

### 13.2 推广优先级与待完成项

**P0 — 立即修复（影响编译/正确性）**


| 编号   | 域        | 任务描述                                    | 对应文件                |
| ---- | -------- | --------------------------------------- | ------------------- |
| A-01 | Solver   | `RT_Solv_Ctx` 加入 `com_ctx` 指针，对齐三层架构    | `RT_Solv_Types.f90` |
| A-02 | Material | 审查 `RT_Mat_Proc.f90` 过程签名是否满足六参数规范      | `RT_Mat_Proc.f90`   |
| A-03 | Material | 审查 `RT_Mat_Proc.f90` 所有 TYPE 成员无 INTENT | `RT_Mat_Proc.f90`   |


**P1 — 本阶段推广（L5_RT 高优先域）**


| 编号   | 域          | 任务描述                                                 |
| ---- | ---------- | ---------------------------------------------------- |
| B-01 | Element    | 新建 `RT_Elem_Proc.f90`，包含 Init/Compute/Finalize 六参数接口 |
| B-02 | StepDriver | 将 `RT_StepDriver_Impl.f90` 升级为六参数 Proc 接口            |
| B-03 | Contact    | 新建 `RT_Cont_Proc.f90`，统一接触域 Proc 入口                  |


**P2 — 次阶段推广（完善域）**


| 编号   | 域         | 任务描述                       |
| ---- | --------- | -------------------------- |
| C-01 | Mesh      | 新建 `RT_Mesh_Proc.f90`      |
| C-02 | Output    | 新建 `RT_Output_Proc.f90`    |
| C-03 | WriteBack | 新建 `RT_WriteBack_Proc.f90` |


### 13.3 推广路线（更新版）

```
阶段 1（✅ 已完成）：L5_RT Assembly / LoadBC 域
阶段 2（⚠️ 进行中）：L5_RT Solver / Material 域（基本完成，待最终验证）
阶段 3（❌ 计划中）：L5_RT Element / StepDriver / Contact 域
阶段 4（❌ 计划中）：L5_RT Mesh / Output / WriteBack 域
阶段 5（❌ 长期）  ：L4_PH 公开接口层（非核心热路径）
阶段 6（❌ 长期）  ：L6_AP 驱动接口层
```

---

*文档维护：UFC 架构组 | 对齐总纲 v5.0 第12章*  
*下次审查：当推广至 Element / StepDriver 域时*