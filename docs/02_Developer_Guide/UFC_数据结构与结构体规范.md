# UFC 数据结构与结构体规范

> **版本**：1.0 | **更新日期**：2026-04-15  
> **用途**：UFC 六层架构中 Fortran TYPE 结构体的组织范式、设计规则及各层核心结构体参考手册。  
> **关联文档**：命名约定见 [UFC_命名与数据结构规范.md](UFC_命名与数据结构规范.md)；层间接口契约见各层 `contracts/` 目录；结构化 IO 参数传递见 [PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md](PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md)。

---

## 一、概述

### 1.1 设计原则

UFC 数据结构设计遵循以下三条核心原则：

1. **一致性**：同层同域内相同性质的结构体采用统一的四型（Desc/State/Algo/Ctx）范式，确保设计语言在全库保持一贯。
2. **可维护性**：数据归属明确，每个字段只有唯一的"真相源"（Source of Truth），跨层访问通过 Bridge 模块进行，不允许隐含跨层读写。
3. **可扩展性**：Ctx 类型保留组合（CONTAINS）扩展点，AI 插槽（AI-ready slots）通过 `PROCEDURE POINTER` 或 `ABSTRACT INTERFACE` 注入，不改变已有 TYPE 签名。

### 1.2 应用范围

本规范适用于 `UFC/ufc_core/` 下所有 L1_IF 至 L6_AP 层的 Fortran TYPE 定义、成员命名、内存策略及参数传递约定。外部库（`ExternalLibs/`）不受本规范约束，但 UFC 内对外部库的封装模块须符合本规范。

---

## 二、四类 TYPE 组织范式

UFC 在物理/数值计算域（L3_MD、L4_PH、L5_RT）采用统一的四型范式，每个域最多定义四种结构体角色：

| 类型后缀  | 语义角色           | 数据特征        | 典型生命周期         |
|-----------|--------------------|-----------------|----------------------|
| `_Desc`   | 模型描述 / 只读配置 | 冷数据，只读    | 模型建立 → 模型销毁  |
| `_State`  | 运行时可变状态      | 温/热数据，可写 | Step 初始 → Step 结束 |
| `_Algo`   | 算法控制参数        | 冷数据，迭代只读 | 分析步初始化 → 步结束 |
| `_Ctx`    | 局部调用上下文      | 热数据，栈分配   | 子程序调用入口 → 返回 |

### 2.1 职责边界

- **Desc**：存储来自输入文件（INP）解析的静态参数，如材料常数、截面属性、单元拓扑。在分析全过程只读，禁止在热路径中修改。
- **State**：存储求解过程中持续更新的物理量，如应力张量、状态变量（STATEV）、位移/速度/加速度。需要 Rollback（回退）机制支持非线性迭代。
- **Algo**：存储算法决策参数，如积分格式枚举、收敛容差、最大迭代数。在步内只读，跨步可重配置。
- **Ctx**：在单次子程序调用期间聚合所有输入驱动量，如应变增量 `dstran`、温度场、积分点坐标。调用返回后即废弃，禁止堆分配（热路径约束）。

### 2.2 类型裁剪规则

并非所有域都需要全部四型。裁剪准则：

- 若某域无运行时更新量，则省略 `_State`。
- 若某域无算法可配置参数，则省略 `_Algo`（如 L4_PH/Element 在 v4.0 已移除 `PH_Elem_Base_Algo`，将 Newmark 参数上移至框架层 `RT_Com_Base_Ctx`）。
- L5_RT 层为"框架通道"，通常仅需 `_Ctx`；Solver 域因热路径访问需要保留 `_Algo`（Architecture Exception，须在模块注释中说明）。

---

## 三、结构体设计规范

### 3.1 成员命名约定

成员名遵循 [UFC_命名与数据结构规范.md](UFC_命名与数据结构规范.md) 第六章简写表，核心约定摘要：

| 全称             | 简写         | 示例                          |
|------------------|--------------|-------------------------------|
| properties       | props        | `props(:)` 材料参数数组        |
| temperature      | temp         | `temp` 当前温度               |
| material         | mat          | `mat_id`、`mat_ctx`           |
| coordinate(s)    | coord/coords | `coords(:,:)` 节点坐标        |
| number/count     | n / num      | `nprops`、`n_integration`     |
| coefficient      | coef         | `coef_thermal` 热导率         |
| context          | ctx          | `mat_ctx`、`elem_ctx`         |
| parameter(s)     | param/params | `newmark_params(3)`           |

成员名长度不超过 **20 字符**；禁止 Context 成员以 `_state` 结尾，禁止 State 成员以 `_ctx` 结尾（与四型语义混淆）。

### 3.2 基础类型选择

```fortran
USE IF_Prec, ONLY: wp, i4
! IF_Prec 统一对外导出 wp、i4（其真相源位于 IF_Err_Type）
! 所有浮点量使用 REAL(wp)，所有整型使用 INTEGER(i4)
```

- **浮点量**：一律 `REAL(wp)`，字面量须带后缀 `0.0_wp`。
- **整型**：一律 `INTEGER(i4)`，字面量后缀 `0_i4`。
- **逻辑量**：`LOGICAL`（无种别），初始值显式赋 `.FALSE.` 或 `.TRUE.`。
- **字符串**：`CHARACTER(LEN=32)` 用于类型标签，`LEN=64` 用于路径/注释；禁止变长字符串在热路径类型中出现。

### 3.3 初始化规则

TYPE 定义中应为所有标量成员提供默认初始值，防止未初始化访问：

```fortran
TYPE, PUBLIC :: RT_ControlDesc
  CHARACTER(LEN=32) :: analysis_type          = "Static"
  INTEGER(i4)       :: max_iterations         = 100_i4
  REAL(wp)          :: tolerance_force        = 1.0e-3_wp
  LOGICAL           :: automatic_time_stepping = .TRUE.
END TYPE RT_ControlDesc
```

ALLOCATABLE 数组成员不提供默认值（Fortran 标准要求），但须在对应的 `Init` 子程序中 ALLOCATE 并赋初值。

### 3.4 内存策略分级

| 级别     | 数据温度 | 分配方式              | 典型类型              |
|----------|----------|-----------------------|-----------------------|
| 冷路径   | 冷       | ALLOCATABLE，模型级   | `_Desc`、`_Algo`       |
| 温路径   | 温       | ALLOCATABLE，Step 级  | `_State`              |
| 热路径   | 热       | 栈分配 / 零 ALLOCATE  | `_Ctx`                |

热路径 Ctx 类型的目标约束如下：
- 优先采用**零调用期分配**：单次 Gauss 点/材料点评估过程中不应发生新的 ALLOCATE/DEALLOCATE。
- 若当前实现仍保留 `ALLOCATABLE` 成员，则必须在调用外层或初始化阶段一次性完成分配，并在热循环中仅复用缓存。
- 建议 64-byte 对齐（支持 AVX-512 向量化）。
- 数组维度优先由外层规模信息或初始化阶段确定，而不是在热路径内部临时扩展。

---

## 四、各层结构体总览

### 4.1 L1_IF — 基础设施层

L1_IF 提供全局精度类型和基础 Context 基类，不涉及有限元物理量：

| 类型名              | 文件                       | 用途                             |
|---------------------|----------------------------|----------------------------------|
| `wp`, `i4`          | `IF_Prec.f90`              | 全局精度种别常量（PARAMETER）      |
| `ErrorStatusType`   | `IF_Err_Type.f90`（推断）  | 错误状态载体，跨层传递错误信息     |
| `BaseCtx`           | `IF_Base/`                 | 所有 Ctx 的继承基类（ctx_id 等）   |

示例（`IF_Prec` 为项目**唯一**精度入口；手代码禁止 `ISO_FORTRAN_ENV` / `SELECTED_REAL_KIND` 自定义 KIND）：
```fortran
! IF_Prec.f90 — 消费侧典型写法（节选）
USE IF_Prec, ONLY: wp, i4
! 工作精度与整数种别由 IF_Prec 统一配置；不在业务模块重复定义 sp/dp/qp
```

### 4.2 L3_MD — 模型层

L3_MD 负责前处理数据：几何、材料定义、截面、边界条件、Step 参数。各域均含完整四型（或视需裁剪）：

| 域        | 核心类型名               | 职责                              |
|-----------|--------------------------|-----------------------------------|
| Material  | `MD_Mat_Desc`            | 材料 ID、类型、props 数组、nprops  |
|           | `MD_Mat_State`           | 应力(6)、应变(6)、statev           |
|           | `MD_Mat_Algo`            | 积分方法枚举、maxIter、tol         |
|           | `MD_Mat_Ctx`             | ndir/nshr/ntens、temp、dtime       |
| Element   | `MD_Elem_Desc`           | 单元拓扑、截面类型、截面参数        |
| Model     | `MD_Model_Ctx`           | 模型操作上下文（顶层容器）          |
| Mesh      | 节点坐标、连接矩阵结构体  | 几何数据                           |

**L3_MD/Material 四型字段示例**：

```fortran
! Desc — 静态参数（来自 INP 文件）
TYPE :: MD_Mat_Desc
  INTEGER(i4)              :: id           ! 材料编号
  CHARACTER(LEN=32)        :: materialType ! 类型标签
  REAL(wp), ALLOCATABLE    :: props(:)     ! 参数数组
  INTEGER(i4)              :: nprops       ! 参数数量
END TYPE MD_Mat_Desc

! Ctx — 调用上下文（热路径，栈分配）
TYPE :: MD_Mat_Ctx
  INTEGER(i4) :: ndir   ! 法向分量数
  INTEGER(i4) :: nshr   ! 剪切分量数
  INTEGER(i4) :: ntens  ! 张量分量总数 = ndir + nshr
  REAL(wp)    :: temp   ! 当前温度
  REAL(wp)    :: dtime  ! 时间增量
END TYPE MD_Mat_Ctx
```

### 4.3 L4_PH — 物理层

L4_PH 负责本构关系计算、单元公式（Ke/Fe）、接触力学。**热路径核心层**，Ctx 类型须零堆分配。

**Material 域**：

| 类型名              | 关键字段                                           |
|---------------------|----------------------------------------------------|
| `PH_Mat_Desc`       | mat_id、mat_type、rho、el、nu、props(:)            |
| `PH_Mat_State`      | stress(:,:)、statev(:)、ddsdde(:,:)、energy(:)     |
| `PH_Mat_Algo`       | integ_scheme、max_iter、tol、ai_enabled            |
| `PH_Mat_Base_Ctx`   | dstran(:)、dfgrd1(:,:)、drot(:,:)、temp、coords(:) |

**Element 域**（v4.0 仅保留 Ctx + State）：

```fortran
! PH_Elem_Base_Ctx — 单元级增量驱动量（内嵌材料上下文）
! 注：以下数组成员在当前实现中为 ALLOCATABLE，但其设计意图是“外层一次分配，热循环内复用”。
TYPE, PUBLIC :: PH_Elem_Base_Ctx
  TYPE(PH_Mat_Base_Ctx)     :: mat_ctx           ! 内嵌材料上下文
  REAL(wp), ALLOCATABLE     :: coords(:,:)       ! [ndim, nnode] 坐标
  REAL(wp), ALLOCATABLE     :: du(:,:)           ! [nnode, ndof] 位移增量
  INTEGER(i4)               :: elem_type_id = 0  ! 单元类型 ID
  INTEGER(i4)               :: n_integration = 0 ! 积分点数
  TYPE(GaussRule)            :: gauss_rule        ! Gauss 积分规则
  ! 积分点缓存（热路径）
  REAL(wp), ALLOCATABLE     :: gauss_xi(:,:)     ! [np, dim] 自然坐标
  REAL(wp), ALLOCATABLE     :: gauss_w(:)        ! [np] 权重
  REAL(wp), ALLOCATABLE     :: shape_N(:,:)      ! [np, nnode] 形函数
  REAL(wp), ALLOCATABLE     :: shape_dN_dx(:,:,:)! [np, nnode, dim] 梯度
END TYPE PH_Elem_Base_Ctx

! PH_Elem_Base_State — UEL 输出（回写求解器）
TYPE, PUBLIC :: PH_Elem_Base_State
  REAL(wp), ALLOCATABLE :: rhs(:,:)    ! [ndofel, nrhs] 残差向量
  REAL(wp), ALLOCATABLE :: amatrx(:,:) ! [ndofel, ndofel] 刚度矩阵
  REAL(wp), ALLOCATABLE :: svars(:)    ! [nsvars] 状态变量
  REAL(wp)              :: energy(8)   ! 能量矢量（ABAQUS 8分量）
  REAL(wp), ALLOCATABLE :: u(:)        ! 当前位移
  REAL(wp), ALLOCATABLE :: v(:)        ! 当前速度
  REAL(wp), ALLOCATABLE :: a(:)        ! 当前加速度
END TYPE PH_Elem_Base_State
```

### 4.4 L5_RT — 运行时层

L5_RT 控制 Step 循环、全局组装、收敛判断。按 UFC v5.0 架构，L5_RT 通常仅持有 Ctx 类型；Solver 域因热路径需要保留 Algo（已注释架构例外）。

| 类型名              | 文件                    | 关键字段                                           |
|---------------------|-------------------------|----------------------------------------------------|
| `RT_Com_Base_Ctx`   | `RT_Com_Types.f90`      | time_step/total/dtime、kstep/kinc/iter、lflags(6)、newmark_params(3) |
| `RT_ControlDesc`    | `RT_Global_Types.f90`   | analysis_type、max_steps、tolerance_force 等       |
| `RT_SolverCtx`      | `RT_Global_Types.f90`   | control、global_ctx(PTR)、global_stiffness/mass/force |

**RT_Com_Base_Ctx 示例**（增量书签，UMAT/UEL 共享）：

```fortran
TYPE, PUBLIC :: RT_Com_Base_Ctx
  ! 时间量
  REAL(wp)    :: time_step  = 0.0_wp   ! 步开始时刻
  REAL(wp)    :: time_total = 0.0_wp   ! 分析总时刻
  REAL(wp)    :: dtime      = 0.0_wp   ! 增量时间步长 Δt
  ! 计数器
  INTEGER(i4) :: kstep  = 0            ! 步号（1-based）
  INTEGER(i4) :: kinc   = 0            ! 步内增量号
  INTEGER(i4) :: iter   = 0            ! 当前平衡迭代次数
  ! 分析类型
  INTEGER(i4) :: analysis_type = 0     ! 1=静力 2=动力 3=热 …
  LOGICAL     :: nlgeom = .FALSE.       ! 大变形标志
  INTEGER(i4) :: lflags(6) = 0         ! ABAQUS LFLAGS
  ! Newmark/HHT 时间积分参数（由框架注入）
  REAL(wp)    :: newmark_params(3) = [0.25_wp, 0.50_wp, 0.0_wp]
END TYPE RT_Com_Base_Ctx
```

### 4.5 L2_NM — 数值层

L2_NM 负责线性/非线性方程组求解（K·u = f）。核心结构体以矩阵/向量容器为主：

| 类型名        | 文件                    | 用途                              |
|---------------|-------------------------|-----------------------------------|
| `RT_CSRMatrix` | `RT_Shared_Type.f90`   | CSR 稀疏矩阵容器（被 L5_RT 引用） |
| NM_Solver_* 系 | L2_NM/Solver/          | Krylov/直接求解器参数              |

### 4.6 L6_AP — 应用层

L6_AP 负责 INP 解析、后处理输出（ODB/VTU）、用户接口。结构体以描述型和上下文型为主，不含物理量：

| 类型名         | 用途                              |
|----------------|-----------------------------------|
| `AP_Job_Ctx`   | Job 执行上下文（继承自 BaseCtx）   |
| `AP_Input_*`   | INP 文件解析结果容器               |

---

## 五、常见设计模式

### 5.1 内嵌组合（CONTAINS ACROSS DOMAIN）

当单元域（Element）需要材料上下文时，通过在 Ctx 内嵌材料 Ctx 实现，避免重复字段：

```fortran
! 推荐：内嵌方式，明确所有权
TYPE :: PH_Elem_Base_Ctx
  TYPE(PH_Mat_Base_Ctx) :: mat_ctx   ! 内嵌，不用指针
  ! ... 单元级字段
END TYPE

! 禁止：直接复制材料字段到单元类型
```

### 5.2 指针聚合（热路径零复制）

Ctx 层全局数据通过指针引用，避免大结构体复制：

```fortran
TYPE :: RT_SolverCtx
  TYPE(RT_ControlDesc)           :: control       ! 值语义（冷数据）
  TYPE(RT_Global_Ctx), POINTER   :: global_ctx => NULL()  ! 指针（热路径唯一时源）
  TYPE(RT_CSRMatrix), ALLOCATABLE :: global_stiffness      ! 温数据
END TYPE RT_SolverCtx
```

### 5.3 多态处理（SELECT TYPE）

当需要根据材料类型分派本构计算时，使用 `SELECT TYPE` 多态分派，而非枚举 IF 树：

```fortran
! 推荐：CLASS(*) + SELECT TYPE
SUBROUTINE PH_Mat_Eval_Dispatch(mat_desc, mat_state, mat_algo, mat_ctx)
  CLASS(*), INTENT(IN) :: mat_desc   ! 多态输入
  SELECT TYPE(mat_desc)
    TYPE IS (PH_Mat_Elast_Desc)
      CALL PH_Mat_Elast_Eval(...)
    TYPE IS (PH_Mat_Plast_Desc)
      CALL PH_Mat_Plast_Eval(...)
  END SELECT
END SUBROUTINE
```

### 5.4 五参/六参结构化 IO（SIO 范式）

过程接口采用统一的五参或六参签名，配合 `*_Arg` 捆绑包（详见 [UFC_Principle14 规范](PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md)）：

```fortran
! 五参：(desc, state, algo, ctx, args)
SUBROUTINE PH_Mat_Elast_Eval(desc, state, algo, ctx, args)
  TYPE(PH_Mat_Elast_Desc),    INTENT(IN)    :: desc   ! [IN]
  TYPE(PH_Mat_State),         INTENT(INOUT) :: state  ! [OUT] 应力更新
  TYPE(PH_Mat_Algo),          INTENT(IN)    :: algo   ! [IN]
  TYPE(PH_Mat_Base_Ctx),      INTENT(IN)    :: ctx    ! [IN]
  TYPE(PH_Mat_Elast_Eval_Arg),INTENT(INOUT) :: args   ! [IN/OUT] 扩展参数
END SUBROUTINE

! 六参：(desc, state, algo, ctx, rt_ctx, args)  — 含运行时上下文
SUBROUTINE PH_Mat_Plast_Eval(desc, state, algo, ctx, rt_ctx, args)
  TYPE(RT_Com_Base_Ctx), INTENT(IN) :: rt_ctx  ! [IN] 框架注入
  ! ...
END SUBROUTINE
```

禁止使用废弃的 `inp/out` 对偶参数风格（R-01b 仅遗留兼容）。

### 5.5 Bridge 跨层访问

L4_PH 需要 L3_MD 的材料参数时，通过 Bridge 模块而非直接 USE L3_MD：

```fortran
! L4_PH/Bridge/PH_L4_L3_Mat_Contract.f90
MODULE PH_L4_L3_Mat_Contract
  USE MD_Mat_Domain_Core, ONLY: MD_Mat_Desc  ! 唯一跨层引用点
  IMPLICIT NONE
  ! 提供稳定的合同接口
END MODULE
```

### 5.6 因果叙事（可观测横切，非第五链）

仓库合同与门禁中的「链」闭集仍为 **理论 / 逻辑 / 计算 / 数据** 四链（域 `CONTRACT.md`、Harness 四链监控等均不扩展为「五链」）。若需向读者或排障工具解释 **why**（谁触发、依赖哪段上游数据），将叙事放在 **可观测性** 侧：在 trace/span、诊断日志或调试导出中附加轻量元数据（例如 `trigger`/`reason`、`upstream` 字段名或层域过程标识、可选 `chain_hint` 指向四链之一），或在设计文档中增加简短 **「因果说明」** 小节，用自然语言说明四链如何共同回答因果问题。**禁止**把「因果链」写成与四链并列的合同条款或新的 `ChainMonitor_*` 枚举值。

---

## 六、与 UFC_命名与数据结构规范.md 的关系

| 内容                        | 本文档（结构体规范）                         | UFC_命名与数据结构规范.md             |
|-----------------------------|----------------------------------------------|---------------------------------------|
| TYPE 四型角色（Desc/State/Algo/Ctx）| 详细定义各型职责、字段设计、内存策略  | 仅列出四型后缀格式 `_Desc/_State/_Algo/_Ctx` |
| 成员命名约定                | 引用简写表，给出各层具体示例              | 完整简写表（第六章）                  |
| 模块/文件命名               | 不涉及                                       | 三级/四级命名格式（第三章）           |
| 变量/过程命名               | 不涉及                                       | 场景 C/D 详细规则（第四/五章）        |
| 各层结构体清单              | 本文档核心内容（第四章）                   | 不涉及                                |
| 设计模式（内嵌/指针/SIO）   | 本文档核心内容（第五章）                   | 不涉及                                |

**交叉引用规则**：
- 确定 TYPE 的命名格式（后缀、长度限制）→ 查 [UFC_命名与数据结构规范.md](UFC_命名与数据结构规范.md)。
- 确定 TYPE 的成员字段设计、内存策略、组合模式 → 查本文档。
- 确定层间参数传递接口签名 → 查 [Principle14 规范](PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md)。

---

## 七、快速查阅索引

### 按层查找核心 TYPE

| 层        | 典型结构体                                                              |
|-----------|-------------------------------------------------------------------------|
| L1_IF     | `wp`、`i4`（精度种别）、`ErrorStatusType`、`BaseCtx`                    |
| L2_NM     | `RT_CSRMatrix`、NM_Solver 参数类型                                      |
| L3_MD     | `MD_Mat_Desc/State/Algo/Ctx`、`MD_Elem_Desc`、`MD_Model_Ctx`            |
| L4_PH     | `PH_Mat_Desc/State/Algo/Base_Ctx`、`PH_Elem_Base_Ctx/State`             |
| L5_RT     | `RT_Com_Base_Ctx`、`RT_ControlDesc`、`RT_SolverCtx`                     |
| L6_AP     | `AP_Job_Ctx`、`AP_Input_*`                                              |

### 按用途查找

| 用途                       | 结构体                          | 所在文件                          |
|----------------------------|---------------------------------|-----------------------------------|
| 全局时间/步号书签          | `RT_Com_Base_Ctx`               | `L5_RT/RT_Com_Types.f90`          |
| 材料参数（INP 输入）       | `MD_Mat_Desc` / `PH_Mat_Desc`   | `L3_MD/Material/` / `L4_PH/Material/` |
| 本构调用驱动量             | `PH_Mat_Base_Ctx`               | `L4_PH/Material/`                 |
| 应力/状态变量              | `PH_Mat_State`                  | `L4_PH/Material/`                 |
| 单元刚度/残差输出          | `PH_Elem_Base_State`            | `L4_PH/Element/PH_Elem_Types.f90` |
| 单元增量驱动量             | `PH_Elem_Base_Ctx`              | `L4_PH/Element/PH_Elem_Types.f90` |
| 求解器控制参数             | `RT_ControlDesc`                | `L5_RT/RT_Global_Types.f90`       |
| 全局刚度/质量矩阵          | `RT_SolverCtx`                  | `L5_RT/RT_Global_Types.f90`       |
| 增量步内 Newmark 参数      | `RT_Com_Base_Ctx.newmark_params`| `L5_RT/RT_Com_Types.f90`          |

---

*版本 1.0 | 基于 UFC ufc_core 实际代码（L3_MD/Material、L4_PH/Material、L4_PH/Element、L5_RT）及现有文档整理，不含虚构字段。*
