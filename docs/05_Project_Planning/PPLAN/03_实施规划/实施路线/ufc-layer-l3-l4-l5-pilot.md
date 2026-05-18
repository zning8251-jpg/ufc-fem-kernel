# UFC L3/L4/L5 三层主TYPE+辅TYPE多级嵌套试点方案

## Context

当前UFC每个Module仅有一个主TYPE（如`PH_Mat_Desc`仅4字段），当Module包含多个过程（6时相×8动词覆盖约29格有效过程）时，主TYPE过于扁平庞大，缺乏按"时相×动词"维度的精准分组。接口签名扩散、字段归属不清、局部过程无法精准匹配数据载体。

**目标**：引入主TYPE+辅TYPE多级嵌套（2-3层），利用Fortran 90/2003 TYPE嵌套能力，使每个Module的过程能精准匹配到对应的辅TYPE，同时遵循"嵌套索引（语义）+扁平域存储（性能）"双规范。试点选择**Material 贯通柱 P1**（L3→L4→L5 完整垂直切片，见 [UFC_DOMAIN_PILLAR_ARCHITECTURE.md](../../06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md)），再按**贯通柱 P2–P6 → 半贯通柱 H* → 层专属 S*** 全域铺开；**详细波次、每域 DoD、合同路径**见同目录 [UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md)。

**默认执行序（与铺开计划一致）**：**先做 P1 Material 竖切合入**，再 **P2 Element**；禁止在 P1 未绿前并行大改 P3–P6，避免 Bridge/Populate 多点失稳。

**Fortran语法规范策略**：
- **主路径**：严格使用Fortran 90/2003语法（向后兼容，保证gfortran/ifort/intel编译器全覆盖）
- **允许Fortran 2008的模块**：部分模块可选择性使用Fortran 2008特性，需在模块头注释中显式标注`! F2008: <feature>`
- 详见下方"Fortran语法规范分级"章节

---

## 〇、文档关联与全域铺开口径

| 读者需要 | 权威入口 |
|----------|----------|
| **域柱分类**（贯通×6、半贯通、层专属） | [UFC_DOMAIN_PILLAR_ARCHITECTURE.md](../../06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md) v3.0 §2 |
| **L3/L4/L5 目录真源** | [UFC_ufc_core_目录权威分类.md](../../06_核心架构/UFC_ufc_core_目录权威分类.md) |
| **域柱合同（P1–P6 数据流）** | 域柱架构文档 §5 / §5b |
| **全域铺开执行计划（波次、DoD、CONTRACT 清单）** | [UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md) |

**铺开顺序（硬约束）**：

1. **贯通柱 P1→P6**（每层内仍遵守本文 §3.2 嵌套深度与 §3.3 双规范）。
2. **半贯通柱 H1、H2、H3、H4a、H4b、H4c、H6、H7**（H7 含 L2_NM，与 L4 单元侧协同）。
3. **层专属 S1–S6**（L3 KeyWord/Model/Part/Section/Mesh 非单元部分、L5 Logging 等）。
4. **Bridge**：非独立域柱，随 P5/P6 与 `RT_Brg_*` / `PH_*Bridge*` 改造同步嵌入辅 TYPE 策略，见执行计划 **W0**。

**每域统一四步**（与 §七 对齐，不可跳步）：**Step1 纯 TYPE** → **Step2 Init/Populate** → **Step3 热路径算法** → **Step4 去 DEPRECATED + 合同 + 回归**。

---

## 一、6时相×8动词双轴体系（已确立规范）

**权威文档**：[UFC_命名规范_v3.0.md](../../04_技术标准/UFC_命名规范_v3.0.md) §5.3-5.5，[UFC_PhaseVerb_过程双轴体系.md](../../06_核心架构/UFC_PhaseVerb_过程双轴体系.md)

| Phase | 标记 | 温度 | 对应TYPE | 执行频率 |
|-------|------|------|---------|---------|
| Config | Cfg | 冷 | Desc | 1次/分析 |
| Populate | Pop | 冷 | Desc→Ctx桥接 | 1次/分析 |
| Step | Stp | 温 | State(步级) | 10-100次 |
| Increment | Inc | 温热 | State(增量级) | 100-10K次 |
| Iteration | Itr | 热 | Ctx | 1K-100K次 |
| Local | Lcl | 最热 | Ctx+State(IP) | 百万级 |

8族动词标记：`Init`/`Vld`(Validate)/`Comp`(Compute)/`Evo`(Evolve)/`Asm`(Assemble)/`Acc`(Access)/`Ctl`(Control)/`Brg`(Bridge)

---

## 二、Fortran语法规范分级

### 2.0.1 主路径：Fortran 90/2003（向后兼容）

所有**_Def.f90**（TYPE定义文件）和**L3_MD层**严格使用Fortran 90/2003语法。核心特性：

| 特性 | Fortran标准 | 在本项目中的用途 |
|------|-----------|---------------|
| TYPE嵌套（TYPE内含TYPE组件） | F90 | 主TYPE→辅TYPE嵌套 |
| TYPE EXTENDS | F2003 | MD_Mat_Desc EXTENDS DescBase |
| ALLOCATABLE组件 | F2003 | props(:), stateVars(:) 等动态数组 |
| PROCEDURE POINTER | F2003 | constitutive/integrator策略指针 |
| ABSTRACT INTERFACE | F2003 | PH_Mat_Constitutive_Ifc 等 |
| TYPE CONTAINS + TBP | F2003 | Init/Destroy/Valid等绑定过程 |
| PRIVATE/PUBLIC访问控制 | F90 | 模块封装 |
| POINTER组件 | F90 | 非拥有引用（Bridge域） |

**禁止在_Def.f90中使用**：SUBMODULE、DO CONCURRENT、CONTIGUOUS、coarray、parameterized derived type（均为F2008+）

### 2.0.2 允许Fortran 2008的模块

以下模块可选择性使用Fortran 2008特性，需在模块头注释标注：

| Fortran 2008特性 | 允许使用的模块范围 | 理由 |
|-----------------|---------------|------|
| **SUBMODULE** | _Core.f90（TBP实现体） | 分离接口与实现，减少重编译级联 |
| **DO CONCURRENT** | L4_PH热路径循环 | 元素/IP并行化语义提示 |
| **CONTIGUOUS属性** | L5_RT Bridge热路径指针 | 保证缓存行对齐，热路径优化 |

**SUBMODULE使用规范**（最关键的F2008特性）：

```fortran
! === _Def.f90 (F2003, 纯TYPE定义+接口声明) ===
MODULE PH_Mat_Domain_Core
  ! ... TYPE definitions with CONTAINS ...
  INTERFACE
    MODULE SUBROUTINE PH_Mat_AllocSlot_Idx(slot_idx, desc, status)
      ! 接口声明，实现体在SUBMODULE中
    END SUBROUTINE
  END INTERFACE
END MODULE

! === _Core.f90 (F2008, SUBMODULE提供实现) ===
! F2008: SUBMODULE
SUBMODULE(PH_Mat_Domain_Core) PH_Mat_Domain_Core_Impl
CONTAINS
  MODULE SUBROUTINE PH_Mat_AllocSlot_Idx(slot_idx, desc, status)
    ! 实际实现代码
  END SUBROUTINE
END SUBMODULE
```

**策略**：_Def.f90保持F2003纯声明，_Core.f90使用F2008 SUBMODULE提供实现。编译器不支持F2008时，_Core.f90回退为普通MODULE+CONTAINS模式（条件编译或手动切换）。

---

## 三、主TYPE+辅TYPE命名与嵌套规范

### 3.1 命名规则

- **主TYPE**：`{Layer}_{Domain}_{四型}` — 四型后缀用下划线分隔，保持命名一致性
  - 修正前：`MD_MatDesc`, `MD_MatState` — 四型后缀未用下划线与域名分隔，不一致
  - 修正后：`MD_Mat_Desc`, `MD_Mat_State` — 与 `PH_Mat_Desc` 格式统一
  - 例：`PH_Mat_Desc`, `PH_Mat_Ctx`, `PH_Mat_State`, `PH_Mat_Algo`
- **辅TYPE**：`{Layer}_{Domain}_{Phase}_{Verb}_{四型}` — 格式本身已合理，无需改动
  - Phase标记：`Cfg`/`Pop`/`Stp`/`Inc`/`Itr`/`Lcl`
  - Verb标记：`Init`/`Vld`(Validate)/`Comp`(Compute)/`Evo`(Evolve)/`Asm`(Assemble)/`Acc`(Access)/`Ctl`(Control)/`Brg`(Bridge)
  - 例：`PH_Mat_Lcl_Comp_Ctx` — Material域, Local时相, Compute动词, Ctx型
- **TBP实现名短名化规则**：TYPE名已包含`{Layer}_{Domain}_{四型}`前缀，实现函数名省略冗余部分
  - 主TYPE TBP实现名公式：`{Layer}_{Domain}_{短动词}` — 省略四型后缀
    - 修正前：`Init => MD_Mat_Desc_Init_Base` — `MD_Mat_Desc_`冗余
    - 修正后：`Init => MD_Mat_Init` — 省略`_Desc`（已由TYPE名隐含）
  - 辅TYPE TBP实现名公式：`{Layer}_{Domain}_{Phase}_{短动词}` — 省略Verb+四型后缀
    - 例：`PH_Mat_Lcl_Comp_Ctx` 的 `Validate` → 实现名 `PH_Mat_Lcl_Validate`
  - Domain容器TBP实现名公式：`{Layer}_{Domain}_{短动词}` — 同主TYPE规则
    - 例：`MD_Mat_Domain` 的 `Register` → 实现名 `MD_Mat_Register`
  - **禁止TBP bridge wrapper**：TYPE的CONTAINS中PROCEDURE绑定直接指向独立子程序，禁止创建仅转发调用的薄封装层

### 3.2 嵌套深度规则

- **Depth 1**：主TYPE（域级身份锚点）
- **Depth 2**：辅TYPE（Phase×Verb分组）— 默认展开
- **Depth 3**：仅当某Phase下某Verb组字段数>5时展开 — 例外情况
- **禁止Depth 4**

### 3.3 双规范实施

- **嵌套索引**：`mat%cfg%matId` — 语义给人看
- **扁平域存储**：`MD_Mat_Domain%desc_array(:)` / `state_array(:)` — 连续内存给计算机看
- **ALLOCATABLE分层规则**：
  - L5_RT Bridge辅TYPE（热路径固定缓冲）：**禁止ALLOCATABLE**，改用固定大小数组+实际长度计数器
  - L4_PH State/Ctx辅TYPE：**允许ALLOCATABLE**（如`PH_Mat_Lcl_Comp_State`的`C_tan(:,:)`、`stress(:)`），因这些在Init时分配、热路径只读写不分配
  - L3_MD Desc辅TYPE：**允许ALLOCATABLE**（如`MD_Mat_Desc%props(:)`），因L3是冷数据层
- 单字段辅TYPE**降级为裸字段**，用注释标注时相归属：`! [Phase:Cfg|Verb:Init]`
- **过度封装防范**：辅TYPE必须承载≥2个字段的Phase×Verb语义分组，否则降级为裸字段。辅TYPE不是数据转发层，而是语义归组层

### 3.4 主TYPE与辅TYPE的职责边界

| | 主TYPE | 辅TYPE |
|---|--------|--------|
| 出现位置 | 四型平级传递签名 | 主TYPE的嵌套成员 |
| 职责 | 跨时相共享字段+聚合锚点 | 时相×动词精准归组 |
| 生命周期 | 域级完整生命周期 | 时相内局部生命周期 |
| 命名 | 全名`{Layer}_{Domain}_{四型}` | 全名`{Layer}_{Domain}_{Phase}_{Verb}_{四型}` |
| TBP实现名 | `{Layer}_{Domain}_{短动词}` | `{Layer}_{Domain}_{Phase}_{短动词}` |

---

## 四、Material域贯通域柱设计（首个试点 L3→L4→L5）

### 4.1 L3_MD/Material 辅TYPE设计

L3是冷数据层，主要活跃在Config和Populate时相。现有`MD_Mat_Desc`(EXTENDS DescBase)含8字段+5 TBP。

**新结构**：

```fortran
! === 辅TYPE定义（新增于 MD_Mat_Def.f90）===

! [Phase:Cfg|Verb:Init] Config时相初始化字段
TYPE, PUBLIC :: MD_Mat_Cfg_Init_Desc
  INTEGER(i4)       :: id          = 0_i4   ! 全局材料ID
  CHARACTER(len=32) :: materialType = ""     ! 材料类型标签
  INTEGER(i4)       :: class_id    = 0_i4   ! 族分类ID
  CHARACTER(len=32) :: behavior    = ""     ! 行为标签
  CHARACTER(len=64) :: description = ""     ! 描述文本
END TYPE MD_Mat_Cfg_Init_Desc

! [Phase:Pop|Verb:Vld] Populate时相验证字段
TYPE, PUBLIC :: MD_Mat_Pop_Vld_Desc
  INTEGER(i4) :: nProps  = 0_i4    ! 属性数组长度
  INTEGER(i4) :: nStateV = 0_i4    ! 状态变量数
END TYPE MD_Mat_Pop_Vld_Desc

! === 主TYPE重构（修改 MD_Mat_Desc）===
TYPE, PUBLIC, EXTENDS(DescBase) :: MD_Mat_Desc
  TYPE(MD_Mat_Cfg_Init_Desc) :: cfg     ! Config时相字段组
  TYPE(MD_Mat_Pop_Vld_Desc)  :: pop     ! Populate时相字段组
  REAL(wp), ALLOCATABLE :: props(:)     ! [Phase:Pop|Verb:Brg] 属性数组（降级裸字段）
CONTAINS
  PROCEDURE :: Init      => MD_Mat_Init
  PROCEDURE :: Destroy   => MD_Mat_Destroy
  PROCEDURE :: Valid     => MD_Mat_Valid
  PROCEDURE :: RegLayout => MD_Mat_RegLayout
  PROCEDURE :: Ensure    => MD_Mat_Ensure
END TYPE MD_Mat_Desc
```

**L3 MD_Mat_Ctx 辅TYPE**（现有已有按族分组的POINTER结构，保持`MD_Mat_BaseDef`中`MD_Mat_Ctx`不变，辅TYPE改动最小化）

**L3 MD_Mat_Domain容器**保持不变（`desc_array` + `state_array` + TBP），这是扁平域存储层。Domain的TBP实现名也遵循短名规则：
```fortran
TYPE :: MD_Mat_Domain
  ! ...
CONTAINS
  PROCEDURE :: Init     => MD_Mat_Domain_Init     ! 非 MD_Mat_Domain_Init_Mat_Domain
  PROCEDURE :: Finalize => MD_Mat_Domain_Finalize
  PROCEDURE :: Register => MD_Mat_Domain_Register
  PROCEDURE :: GetById  => MD_Mat_Domain_GetById
END TYPE
```

### 4.2 L4_PH/Material 辅TYPE设计（核心重点）

L4是温热计算层，现有4型各4-5字段。辅TYPE按时相精准注入。

```fortran
! === 新文件: PH_Mat_Aux_Def.f90 ===

! ---- PH_Mat_Desc 辅TYPE ----
! [Phase:Cfg|Verb:Init]
TYPE, PUBLIC :: PH_Mat_Cfg_Init_Desc
  INTEGER(i4) :: matId    = 0_i4            ! 全局材料ID
  INTEGER(i4) :: matModel = PH_MAT_UNKNOWN  ! 族enum
END TYPE PH_Mat_Cfg_Init_Desc

! [Phase:Pop|Verb:Vld]
TYPE, PUBLIC :: PH_Mat_Pop_Vld_Desc
  INTEGER(i4) :: mat_model_id = 0_i4        ! 离散模型ID (101..1102)
END TYPE PH_Mat_Pop_Vld_Desc

! ---- PH_Mat_Ctx 辅TYPE ----
! [Phase:Inc|Verb:Evo]
TYPE, PUBLIC :: PH_Mat_Inc_Evo_Ctx
  INTEGER(i4) :: step_idx = 0_i4   ! 当前步
  INTEGER(i4) :: incr_idx = 0_i4   ! 当前增量
  REAL(wp)    :: dt       = 0.0_wp ! 时间增量
END TYPE PH_Mat_Inc_Evo_Ctx

! [Phase:Lcl|Verb:Comp]
TYPE, PUBLIC :: PH_Mat_Lcl_Comp_Ctx
  REAL(wp) :: temperature = 0.0_wp  ! 温度 [K]
  REAL(wp) :: strain_rate = 0.0_wp  ! 等效应变速率 [1/s]
END TYPE PH_Mat_Lcl_Comp_Ctx

! ---- PH_Mat_State 辅TYPE ----
! [Phase:Lcl|Verb:Comp]
TYPE, PUBLIC :: PH_Mat_Lcl_Comp_State
  REAL(wp), ALLOCATABLE :: C_tan(:,:)   ! 算法切线 [ntens x ntens]
  REAL(wp), ALLOCATABLE :: stress(:)    ! 当前应力 (Voigt)
END TYPE PH_Mat_Lcl_Comp_State

! [Phase:Lcl|Verb:Evo]
TYPE, PUBLIC :: PH_Mat_Lcl_Evo_State
  REAL(wp), ALLOCATABLE :: stateVars(:)    ! SDVs at n+1
  REAL(wp), ALLOCATABLE :: stateVars_n(:)  ! SDVs at n (converged)
END TYPE PH_Mat_Lcl_Evo_State

! ---- PH_Mat_Algo 辅TYPE ----
! [Phase:Stp|Verb:Ctl]
TYPE, PUBLIC :: PH_Mat_Stp_Ctl_Algo
  REAL(wp)    :: tol_yield    = 1.0e-6_wp ! 屈服容差
  REAL(wp)    :: tol_residual = 1.0e-8_wp ! NR残差容差
  INTEGER(i4) :: max_iter     = 20_i4     ! 最大局部NR迭代
  INTEGER(i4) :: integ_scheme = 1_i4      ! 1=BE, 2=MP
END TYPE PH_Mat_Stp_Ctl_Algo
! constitutive PROCEDURE POINTER 降级为裸字段 [Phase:Cfg|Verb:Brg]

! ---- PH_Mat_Eval_Arg 按时相拆分 ----
! [Phase:Lcl|Verb:Comp] 输入
TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgIn
  INTEGER(i4) :: nprops  = 0_i4
  INTEGER(i4) :: ntens   = 6_i4
  INTEGER(i4) :: nsdv    = 0_i4
  REAL(wp), ALLOCATABLE :: strain(:)      ! 总应变
  REAL(wp), ALLOCATABLE :: d_strain(:)    ! 应变增量
END TYPE PH_Mat_Lcl_Comp_ArgIn

! [Phase:Lcl|Verb:Comp] 输出
TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgOut
  REAL(wp), ALLOCATABLE :: stress_new(:)  ! 更新应力
  REAL(wp), ALLOCATABLE :: tangent(:,:)   ! 切线模量
END TYPE PH_Mat_Lcl_Comp_ArgOut
```

**主TYPE重构**（修改现有TYPE定义）：

```fortran
! ---- PH_Mat_Desc 重构 ----
TYPE :: PH_Mat_Desc
  TYPE(PH_Mat_Cfg_Init_Desc) :: cfg    ! Config时相字段
  TYPE(PH_Mat_Pop_Vld_Desc)  :: pop    ! Populate时相字段
  REAL(wp), ALLOCATABLE :: props(:)     ! [Phase:Pop|Verb:Brg] 属性数组
END TYPE PH_Mat_Desc

! ---- PH_Mat_Ctx 重构 ----
TYPE :: PH_Mat_Ctx
  TYPE(PH_Mat_Inc_Evo_Ctx)  :: inc     ! Increment时相字段
  TYPE(PH_Mat_Lcl_Comp_Ctx) :: lcl     ! Local时相字段
END TYPE PH_Mat_Ctx

! ---- PH_Mat_State 重构 ----
TYPE :: PH_Mat_State
  TYPE(PH_Mat_Lcl_Comp_State) :: comp   ! Local Compute输出
  TYPE(PH_Mat_Lcl_Evo_State)  :: evo    ! Local Evolve演化
END TYPE PH_Mat_State

! ---- PH_Mat_Algo 重构 ----
TYPE :: PH_Mat_Algo
  TYPE(PH_Mat_Stp_Ctl_Algo) :: stp      ! Step Control参数
  PROCEDURE(PH_Mat_Constitutive_Ifc), POINTER :: constitutive => NULL()
    ! [Phase:Cfg|Verb:Brg] 策略过程指针
END TYPE PH_Mat_Algo

! ---- PH_Mat_Eval_Arg 重构 ----
TYPE :: PH_Mat_Eval_Arg
  TYPE(PH_Mat_Lcl_Comp_ArgIn)  :: inp   ! Local Compute输入
  TYPE(PH_Mat_Lcl_Comp_ArgOut) :: out   ! Local Compute输出
END TYPE PH_Mat_Eval_Arg
```

**PH_Mat_Slot时相索引**（语义标记，不参与计算）：

```fortran
TYPE :: PH_Mat_Slot_PhaseIdx
  LOGICAL :: cfg_ready     = .FALSE.  ! Config时相完成
  LOGICAL :: pop_validated = .FALSE.  ! Populate验证通过
  LOGICAL :: stp_setup     = .FALSE.  ! Step初始化完成
  LOGICAL :: inc_evolving  = .FALSE.  ! Increment演化中
  LOGICAL :: itr_assembly  = .FALSE.  ! Iteration组装中
  LOGICAL :: lcl_computing = .FALSE.  ! Local计算中
END TYPE PH_Mat_Slot_PhaseIdx
```

### 4.3 L5_RT/Material 辅TYPE设计

L5的`RT_Mat_Bridge_Ctx`（11字段）是L4→L5的数据传递管道，按时相拆分：

```fortran
! [Phase:Stp|Verb:Ctl] Step时相控制字段
TYPE :: RT_Mat_Stp_Ctl_BrgCtx
  INTEGER(i4) :: mat_id     = 0_i4
  INTEGER(i4) :: mat_family = 0_i4
  INTEGER(i4) :: algo_id    = 0_i4
END TYPE RT_Mat_Stp_Ctl_BrgCtx

! [Phase:Lcl|Verb:Brg] Local时相桥接字段
TYPE :: RT_Mat_Lcl_Brg_Ctx
  INTEGER(i4) :: integ_pt_id = 0_i4
  REAL(wp)    :: dtime       = 0.0_wp
  REAL(wp)    :: time_step   = 0.0_wp
  REAL(wp)    :: time_total  = 0.0_wp
  INTEGER(i4) :: kstep       = 0_i4
  INTEGER(i4) :: kinc        = 0_i4
  INTEGER(i4) :: noel        = 0_i4
  INTEGER(i4) :: npt         = 0_i4
END TYPE RT_Mat_Lcl_Brg_Ctx

! ---- RT_Mat_Bridge_Ctx 重构 ----
TYPE :: RT_Mat_Bridge_Ctx
  TYPE(RT_Mat_Stp_Ctl_BrgCtx) :: stp   ! Step控制字段
  TYPE(RT_Mat_Lcl_Brg_Ctx)    :: lcl   ! Local桥接字段
  INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE  ! [Phase:*|Verb:Ctl]
END TYPE RT_Mat_Bridge_Ctx
```

### 4.4 三层垂直数据流映射

```
L3_MD: MD_Mat_Desc
  .cfg.id         ──Populate──→ PH_Mat_Desc.cfg.matId
  .cfg.class_id   ──Populate──→ PH_Mat_Desc.cfg.matModel
  .pop.nProps     ──Populate──→ PH_Mat_Desc.pop.mat_model_id + props(:)长度
  .pop.nStateV    ──Populate──→ PH_Mat_Slot slot stateVars alloc

L4_PH: PH_Mat_Slot
  .ctx.inc.step_idx ──Bridge──→ RT_Com_Base_Ctx.kstep
  .ctx.inc.dt       ──Bridge──→ RT_Com_Base_Ctx.dtime
  .state.comp.stress ──Bridge──→ RT_Mat_Domain_Ctx热路径
  .state.comp.C_tan  ──Bridge──→ RT_Mat_Domain_Ctx.ddsdde

L5_RT: RT_Mat_Bridge_Ctx
  .stp.mat_family  ←── Bridge Populate ── L4 PH_Mat_Desc.cfg.matModel
  .lcl.dtime       ←── per-call fill ──── RT_Com_Base_Ctx.dtime
  .lcl.kstep/kinc  ←── per-call fill ──── RT_Com_Base_Ctx
```

---

## 五、Element域设计（第二个试点，验证方案泛化性）

### 5.1 L4_PH/Element 辅TYPE设计

Element域主TYPE字段数远多于Material，是辅TYPE拆分的最佳验证场景。

```fortran
! ---- PH_Elem_Desc 辅TYPE ----
TYPE :: PH_Elem_Cfg_Init_Desc
  INTEGER(i4) :: elem_type_id = 0_i4  ! MD_ELEM_C3D8等
  INTEGER(i4) :: family_id    = 0_i4  ! PH_ELEM_FAMILY_*
  INTEGER(i4) :: ndim         = 0_i4  ! 空间维数
  INTEGER(i4) :: section_type = 0_i4  ! 截面类型
END TYPE PH_Elem_Cfg_Init_Desc

TYPE :: PH_Elem_Pop_Vld_Desc
  INTEGER(i4) :: n_nodes       = 0_i4
  INTEGER(i4) :: n_dof         = 0_i4
  INTEGER(i4) :: dof_per_node  = 0_i4
  INTEGER(i4) :: n_integration = 0_i4
  INTEGER(i4) :: n_elements    = 0_i4
END TYPE PH_Elem_Pop_Vld_Desc

! ---- PH_Elem_Ctx 辅TYPE ----
TYPE :: PH_Elem_Itr_Asm_Ctx
  INTEGER(i4) :: current_ip   = 0_i4
  INTEGER(i4) :: current_elem = 0_i4
  REAL(wp)    :: det_J        = 0.0_wp
  REAL(wp)    :: weight       = 0.0_wp
END TYPE PH_Elem_Itr_Asm_Ctx

TYPE :: PH_Elem_Lcl_Comp_Ctx
  REAL(wp), ALLOCATABLE :: u_elem(:)   ! (n_dof) 总位移
  REAL(wp), ALLOCATABLE :: du_elem(:)  ! (n_dof) 位移增量
  REAL(wp), ALLOCATABLE :: dN_dX(:,:)  ! (ndim,n_node) 形函数导数
  REAL(wp), ALLOCATABLE :: J_mat(:,:)  ! (ndim,ndim) 雅可比
END TYPE PH_Elem_Lcl_Comp_Ctx

TYPE :: PH_Elem_Lcl_Evo_Ctx
  REAL(wp), ALLOCATABLE :: Ke_mat(:,:)  ! 材料刚度
  REAL(wp), ALLOCATABLE :: Ke_geo(:,:)  ! 几何刚度
  REAL(wp), ALLOCATABLE :: Ke(:,:)      ! 总刚度
  REAL(wp), ALLOCATABLE :: R_int(:)     ! 内力
END TYPE PH_Elem_Lcl_Evo_Ctx

! ---- PH_Elem_Algo 辅TYPE ----
TYPE :: PH_Elem_Stp_Ctl_Algo
  INTEGER(i4) :: integration_order = 2_i4
  INTEGER(i4) :: hourglass_control = 0_i4
  REAL(wp)    :: hourglass_coeff   = 0.0_wp
  LOGICAL     :: nlgeom            = .FALSE.
END TYPE PH_Elem_Stp_Ctl_Algo

TYPE :: PH_Elem_Stp_Ctl_Dyn_Algo
  LOGICAL     :: reduced_integ = .FALSE.
  INTEGER(i4) :: mass_type     = 1_i4   ! 1=一致, 2=集中
  REAL(wp)    :: alpha_rayleigh = 0.0_wp
  REAL(wp)    :: beta_rayleigh  = 0.0_wp
END TYPE PH_Elem_Stp_Ctl_Dyn_Algo
! integrator PROCEDURE POINTER 降级为裸字段 [Phase:Cfg|Verb:Brg]
```

**Element SIO Arg聚合归组**：

```fortran
! SIO参数包按Phase×Verb归入辅TYPE容器
TYPE :: PH_Elem_Itr_Asm_ArgHub
  TYPE(PH_Elem_Core_Ke_Arg)    :: Ke     ! 刚度矩阵
  TYPE(PH_Elem_Core_Fe_Arg)    :: Fe     ! 等效力
  TYPE(PH_Elem_Core_Fint_Arg)  :: Fint   ! 内力
  TYPE(PH_Elem_Core_Mass_Arg)  :: Mass   ! 质量矩阵
END TYPE PH_Elem_Itr_Asm_ArgHub

TYPE :: PH_Elem_Lcl_Comp_ArgHub
  TYPE(PH_Elem_NL_TL_Arg)           :: nl_tl   ! 全Lagrange
  TYPE(PH_Elem_NL_UL_Arg)           :: nl_ul   ! 更新Lagrange
  TYPE(PH_Elem_JacB_Arg)            :: jacb    ! 雅可比+B阵
  TYPE(PH_Elem_ComplexStiff_Form_Arg) :: cpx   ! 复刚度
END TYPE PH_Elem_Lcl_Comp_ArgHub

TYPE :: PH_Elem_Lcl_Brg_ArgHub
  TYPE(PH_Elem_Contact_Arg)    :: contact   ! 接触贡献
  TYPE(PH_Elem_Constraint_Arg) :: constr    ! 约束应用
END TYPE PH_Elem_Lcl_Brg_ArgHub
```

### 5.2 L5_RT/Element Bridge辅TYPE

```fortran
TYPE :: RT_Elem_Stp_Ctl_BrgCtx
  INTEGER(i4) :: elem_id     = 0_i4
  INTEGER(i4) :: jtype       = 0_i4
  INTEGER(i4) :: elem_family = 0_i4
END TYPE RT_Elem_Stp_Ctl_BrgCtx

TYPE :: RT_Elem_Lcl_Brg_Ctx
  INTEGER(i4) :: lflags(5)   = 0_i4
  REAL(wp)    :: dtime       = 0.0_wp
  REAL(wp)    :: time_step   = 0.0_wp
  REAL(wp)    :: time_total  = 0.0_wp
  INTEGER(i4) :: kstep       = 0_i4
  INTEGER(i4) :: kinc        = 0_i4
  INTEGER(i4) :: nrhs        = 1_i4
  INTEGER(i4) :: isym        = 1_i4
END TYPE RT_Elem_Lcl_Brg_Ctx

TYPE :: RT_Elem_Bridge_Ctx
  TYPE(RT_Elem_Stp_Ctl_BrgCtx) :: stp
  TYPE(RT_Elem_Lcl_Brg_Ctx)    :: lcl
  INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
END TYPE RT_Elem_Bridge_Ctx
```

---

## 六、L5_RT StepDriver与L4对接

RT_Step_Ctx三级状态机(Step/Inc/Iter)与L4辅TYPE天然对应：

| RT_Step状态 | L4 Phase | L4辅TYPE示例 |
|-------------|----------|-------------|
| RT_STEP_RUNNING | Step | PH_Mat_Inc_Evo_Ctx.step_idx |
| RT_INC_ITERATING | Increment | PH_Mat_Inc_Evo_Ctx.incr_idx, dt |
| RT_ITER_ASSEMBLING | Iteration | PH_Elem_Itr_Asm_Ctx |
| RT_ITER_SOLVING | Local | PH_Mat_Lcl_Comp_Ctx |

RT_Step_Def本身已有`RT_StepDriver_TimeCfg`/`RT_StepDriver_Algo`等嵌套子TYPE（Depth 2），与辅TYPE设计天然一致，**无需改动**，作为现成范例。

---

## 七、实施步骤（四步顺序：数据结构先行）

> **全域执行**：下列 Step 1–4 **对每一根域柱 / 半柱重复套用**；默认 **先完成 P1 Material 全 Step 再开 P2 Element 波次**，避免单 PR 内 Material+Element 齐改（见 §〇）；其它域按 [全域铺开执行计划](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md) 波次推进。

### Step 1: TYPE定义（纯数据结构，零算法改动，F2003语法）

**P1 Material（W1，首发）**

1. **新建** `ufc_core/L4_PH/Material/PH_Mat_Aux_Def.f90` — 定义 Material 域辅 TYPE（F2003）
2. **修改** `ufc_core/L4_PH/Material/PH_Mat_Domain_Core.f90` — 主 TYPE 字段迁入辅 TYPE（F2003）
3. **修改** `ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90` — L3 `MD_Mat_Desc` 等迁入辅 TYPE（F2003）
4. **修改** `ufc_core/L5_RT/Bridge/RT_Brg_Def.f90` — **仅** `RT_Mat_*` / 材料 Bridge 相关 `TYPE` 按时相重组（F2003）；勿在同一 PR 内改 `RT_Elem_*` 等其它域
5. **更新** re-export hub（`PH_Mat_Def.f90`、`RT_Com_Def.f90` 等）导出新辅 TYPE
6. **评估 SUBMODULE 改造**（可选、独立 PR）：`PH_Mat_Domain_Core` 的 TBP 迁入 SUBMODULE（F2008），`_Def.f90` 仅保留 `INTERFACE` 声明 — 见 §十四

**P2 Element（W2，P1 全 Step 完成后再做）**

7. **新建** `ufc_core/L4_PH/Element/PH_Elem_Aux_Def.f90` — Element 域辅 TYPE（F2003）
8. **修改** `ufc_core/L4_PH/Element/PH_Elem_Def.f90` — 主 TYPE 迁入辅 TYPE（F2003）；L3 `Elem/` 侧对称改造见执行计划 **W2**

**关键**：旧字段暂保留，标记`! DEPRECATED: use %cfg%matId`，保证编译通过。旧 TYPE 名同步 `! DEPRECATED` 指向新名。

### Step 2: 初始化路径（Init/Populate 时相）

**P1**

9. **修改** `PH_Mat_Apply_Init_Arg`（及等价入口）→ 填充 `cfg` 等辅 TYPE 字段  
10. **修改** `PH_Mat_AllocSlot_Idx` → 按辅 TYPE 分组初始化  
11. **修改** Bridge Populate → L3 辅 TYPE → L4 辅 TYPE  
12. **修改** `RT_Brg_Mgr.f90`（材料路径）→ `RT_Mat_*` Bridge 从 L4 辅 TYPE 取字段  

**P2**：Element 侧 Init/Populate 对称项见执行计划 **W2**。

### Step 3: 算法路径（Compute/Evolve/Assemble 时相，_Core.f90 可用 F2008 可选）

**P1**

13. **修改** `PH_Mat_Execute_Flow` → 管道读写辅 TYPE  
14. **修改** `PH_Mat_Constitutive_Ifc` 及本构实现族 → 内部访问辅 TYPE 路径  

**P2 / 装配 / 步进**

15. **修改** `PH_Elem_Core.f90` / `PH_Elem_Eval.f90` → 辅 TYPE（**W2**）  
16. **修改** `RT_Asm_Solv.f90` / `RT_Step_Exec.f90` → Bridge 辅 TYPE（按域渐进；与 **H3/H4a** 波次协调，见执行计划 **W7**）  
17. **DO CONCURRENT / CONTIGUOUS** — §十四，独立 PR  

### Step 4: 清理与验证

18. 移除本波次已废弃的 DEPRECATED 扁平字段（满足 §十二去废弃周期）  
19. 更新本域 **`CONTRACT.md`** 与域柱合同对齐小节  
20. 全量/约定回归（至少 §9.4 矩阵中与本域相关用例）  
21. 编译器矩阵（主线 F2003；F2008 不阻塞合入）

---

## 八、关键文件清单

> 增加 **波次** 列与 [全域铺开执行计划](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md) 对齐。

| 波次 | 文件路径 | 操作 | 说明 |
|------|---------|------|------|
| W1 | `ufc_core/L4_PH/Material/PH_Mat_Aux_Def.f90` | **新建** | Material 域辅 TYPE（F2003） |
| W1 | `ufc_core/L4_PH/Material/PH_Mat_Domain_Core.f90` | 修改 | 主 TYPE + 辅 TYPE 嵌套 |
| W1 | `ufc_core/L4_PH/Material/PH_Mat_Core.f90` | 修改 | 可选 SUBMODULE（§十四） |
| W2 | `ufc_core/L4_PH/Element/PH_Elem_Aux_Def.f90` | **新建** | Element 域辅 TYPE（F2003） |
| W2 | `ufc_core/L4_PH/Element/PH_Elem_Def.f90` | 修改 | 主 TYPE + 辅 TYPE 嵌套 |
| W2 | `ufc_core/L4_PH/Element/PH_Elem_Core.f90` | 修改 | 可选 SUBMODULE（§十四） |
| W1 | `ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90` | 修改 | L3 辅 TYPE 分组（F2003） |
| W1 | `ufc_core/L3_MD/Material/Base/MD_Mat_BaseDef.f90` | 修改 | Base 层对齐（F2003） |
| W1 | `ufc_core/L3_MD/Material/Domain/MD_MatDomain_Def.f90` | 修改 | Domain 容器访问路径（F2003） |
| W1 | `ufc_core/L5_RT/Bridge/RT_Brg_Def.f90` | 修改 | 材料 Bridge 按时相重组（F2003） |
| — | `ufc_core/L5_RT/RT_Com_Def.f90` | 参考 | `RT_Com_Base_Ctx` 保持；仅评估 re-export |
| — | `ufc_core/L5_RT/StepDriver/RT_Step_Def.f90` | 参考 | Depth2 范例 |
| W1 | `ufc_core/L4_PH/Material/PH_Mat_Def.f90` | 修改 | re-export hub |

---

## 九、验证方案

### 9.1 编译期验证

- **F2003合规性**：gfortran `-std=f2003` 编译所有_Def.f90，零warning
- **F2008合规性**：gfortran `-std=f2008` 编译允许F2008的_Core.f90，零error
- **编译器矩阵**：gfortran 13+ / ifort 2021+ / ifx 2024+ 三编译器通过
- 嵌套深度检查：grep TYPE定义确保无Depth>3
- 热路径辅TYPE中ALLOCATABLE审计（L5 Bridge辅TYPE禁止ALLOCATABLE）
- 命名规范检查：辅TYPE命名匹配`{Layer}_{Domain}_{Phase}_{Verb}_{四型}`
- SUBMODULE回退验证：若编译器不支持F2008，_Core.f90回退为MODULE+CONTAINS模式可编译通过
- Linter校验项（LINT-TYPE-001~005）：见§10.4约束5与§十二

### 9.2 数据流验证

- **位相等测试**：同一输入文件，重构前后`stress(:)`、`C_tan(:,:)`、`stateVars(:)`位相等
- **Bridge值拷贝验证**：Populate阶段断言辅TYPE值等于L4源
- **Phase标记一致性**：运行时断言`PH_Mat_Slot_PhaseIdx`标记与实际执行阶段一致

### 9.3 性能验证

- 热路径零开销：`mat%lcl%temperature` vs `mat%temperature` 在-O2下无差异
- 单C3D8弹性单元基准：重构前后CPU时间偏差<1%

### 9.4 回归测试矩阵

| 测试用例 | 覆盖层 | 覆盖域 | 验证内容 |
|---------|--------|--------|---------|
| 线弹性C3D8 | L3+L4+L5 | Material+Element | 基线位相等 |
| J2弹塑性C3D8 | L4+L5 | Material(Inc+Lcl) | stateVars演化正确 |
| 超弹性C3D8H | L4 | Material(HyperElas族) | 族分派正确 |
| 接触+弹塑性 | L4+L5 | Element+Contact+Material | Bridge多域协同 |

---

## 十、UFC架构规范合规性审查

方案实施前必须通过以下合规性检查，确保与总纲→规范→底层方案的优先级链一致，避免返工：

### 10.1 与架构总纲对齐

| 总纲原则 | 方案对齐情况 | 状态 |
|---------|------------|------|
| 架构渐进式演进，拒绝推倒重来 | 保留主TYPE四型体系不变，仅增加辅TYPE嵌套层 | ✅ |
| 数据结构先行，TYPE完备后才注入算法 | 四步实施：TYPE→Init→Algo→Clean | ✅ |
| 全局字段补全优先于嵌套 | 单字段辅TYPE降级为裸字段+注释标注 | ✅ |
| 四链补全强制（理论/逻辑/计算/数据） | 数据流映射覆盖数据链，合同卡同步覆盖四链 | ✅ |
| 数据链全生命周期路径（L3→L4→L5→L6单向） | Bridge域严格遵守L3→L4→L5单向流动，禁止旁路 | ✅ |

### 10.2 与命名规范v3.0对齐

| v3.0规则 | 方案对齐情况 | 状态 |
|---------|------------|------|
| 核心公式 `{层缀}_{域缩}_{功能}_{后缀}` | 主TYPE `MD_Mat_Desc` = MD+Mat+(功能空)+Desc | ✅ |
| 层缀必填 | 辅TYPE首段为Layer标记(PH_/MD_/RT_) | ✅ |
| PascalCase | 所有TYPE名PascalCase | ✅ |
| 四型后缀仅用于TYPE禁作文件名 | `_Desc/_State/_Algo/_Ctx`仅出现在TYPE定义中 | ✅ |
| 后缀必须携带信息量 | 辅TYPE后缀仍为四型之一，Phase+Verb在前缀位携带语义 | ✅ |
| 层级标识冗余去除 | TBP实现名省略TYPE已包含的冗余前缀 | ✅ |

### 10.3 与设计规则对齐

| 设计规则 | 方案对齐情况 | 状态 |
|---------|------------|------|
| 禁止TBP bridge wrapper封装层 | TBP直接指向独立子程序，无薄封装 | ✅ |
| 禁止单字段TYPE（降级为裸标量） | 单字段辅TYPE降级为裸字段+时相注释 | ✅ |
| Coupling域TYPE内聚规范 | 辅TYPE定义内聚于`PH_Mat_Aux_Def.f90`单一语义文件 | ✅ |
| 三维正交设计（Phase×Verb×四型） | 辅TYPE按三维正交组织，可组合可扩展 | ✅ |
| BEAM统一架构正交维度原则 | 辅TYPE按Phase×Verb分组而非按具体材料族分支 | ✅ |

### 10.4 关键约束确认（避免返工）

**约束1：四型平级传递签名不变性**
辅TYPE嵌套是TYPE内部字段重组，不改变外部接口签名：
```fortran
! 签名不变：仍然是 (desc, state, algo, ctx, status)
SUBROUTINE PH_Mat_Constitutive_Ifc(desc, state, arg, status)
  TYPE(PH_Mat_Desc),  INTENT(IN)    :: desc   ! 内部已从扁平→嵌套
  TYPE(PH_Mat_State), INTENT(INOUT) :: state  ! 内部已从扁平→嵌套
  ...
END SUBROUTINE
```

**约束2：AI插槽兼容性**
`PH_Mat_Algo%constitutive` PROCEDURE POINTER是AI插槽①(AI_StepController)的接入点。辅TYPE嵌套后，constitutive指针作为裸字段保留在`PH_Mat_Algo`主TYPE中，AI插槽接口签名不受影响。

**约束3：过度封装防范**
- 辅TYPE必须承载≥2个字段的语义分组 → 否则降级为裸字段
- 辅TYPE不添加仅为"转发"的TBP → 禁止bridge wrapper
- 辅TYPE内部字段直接暴露（无getter/setter封装）→ 访问路径`mat%cfg%matId`，不经过函数
- 评估标准：如果去掉辅TYPE嵌套，代码可读性是否显著下降？若是，则辅TYPE有价值

**约束4：合同卡同步**
TYPE重构后必须同步更新CONTRACT.md，覆盖字段完整性、接口契约一致性、文档同步性三方面。

**约束5：linter可校验性**
辅TYPE命名规则需可自动化校验，linter检查项：
- `LINT-TYPE-001`：主TYPE命名匹配 `{Layer}_{Domain}_{四型}` 正则
- `LINT-TYPE-002`：辅TYPE命名匹配 `{Layer}_{Domain}_{Phase}_{Verb}_{四型}` 正则
- `LINT-TYPE-003`：TBP实现名省略四型后缀（主TYPE）或Verb+四型后缀（辅TYPE）
- `LINT-TYPE-004`：嵌套深度≤3
- `LINT-TYPE-005`：L5 Bridge辅TYPE禁止ALLOCATABLE

---

## 十一、扩展路径（试点成功后）

> **执行顺序以域柱文档与《全域铺开执行计划》为准**；下列条目映射到 **P3–P6、H*、S***，不再使用模糊的「半域主/专属层」口语作为唯一依据。

1. **P3 Contact** → L3 `Interaction/` + L4 `Contact/` + L5 `Contact/` 辅 TYPE 化（已有 `PH_Cont_*` 等雏形可收敛命名）。
2. **P4 LoadBC** → L3 `Boundary/` + L4 `LoadBC/` + L5 `LoadBC/`。
3. **P5 Output / P6 WriteBack** → L4 经 `Bridge/Output`、`Bridge/WriteBack` 与 L5 域对齐。
4. **半贯通柱** → H1 Constraint、H2 Field、H3 Assembly、H4a Step、H4b Solver、H4c Amplitude、H6 Coupling；**H7 DiffPhys** → L2+L4 协同。
5. **层专属** → S1–S5（L3）、S6（L5 Logging）；**L1/L6** 不在本试点主线的必做列表，若推广辅 TYPE，须单独立项以免污染内核依赖方向。

---

## 十二、实施门禁（DoD）与 PR 切分

### 12.1 每个 Step 的完成定义（合并前必勾）

| Step | 完成定义（DoD） |
|------|-----------------|
| **Step1** | 新增/调整 `_Def` 或 `*_Aux_Def.f90` 后，约定编译目标 **`gfortran -std=f2003 -fsyntax-only`**（或 CI 等价）对**本域涉及单元**零错误；旧字段保留且 `! DEPRECATED` 标注齐全；嵌套深度 ≤3；L5 Bridge 辅 TYPE 无 ALLOCATABLE。 |
| **Step2** | Init/Populate/Bridge 路径读写新嵌套成员，**双写期**可选：断言新旧字段一致（调试开关）。 |
| **Step3** | 热路径仅访问辅 TYPE 分组字段；**外部过程签名**仍满足 §10.4 约束1（四型平级不变）。 |
| **Step4** | 删除 DEPRECATED 扁平字段；**本域 `CONTRACT.md` 与域柱合同小节**已更新；命名检查通过（LINT-TYPE-001~005 或手工对照）；§9.2–9.4 对应用例绿。 |

### 12.2 PR 粒度建议

- **单 PR 域界**：优先 **一根贯通柱（如仅 P1）** 或 **单根半柱（如仅 H4a）**，避免单 PR 跨 P2+P3+P4。
- **机械大改**（仅移动字段、无算法语义变更）可与 Step1 同 PR；**算法路径变更**单独 PR 便于 bisect。

### 12.3 去废弃周期

- DEPRECATED 字段至少经历 **一次发布窗口 / 或主分支上 N 次绿构建**（由团队定 N≥5）再在 Step4 删除；执行计划表中 **「删弃」列** 跟踪。

---

## 十三、SIO / `*_Arg` 与主辅嵌套的协同规则

与仓库 **Principle #14**、各域 `CONTRACT.md` 中「SIO / `*_Arg`（本域偏好）」对齐：

1. **主辅嵌套解决的是 TYPE 内部字段归组**；**跨过程边界的 `*_Arg`** 在 **(a) 多字段协同演进** 或 **(b) Harness/编排消费** 时保留，不因嵌套而强行拆掉。
2. **禁止**：仅为包 `status` 或与主 TYPE 内已嵌套字段 **100% 重复** 的薄 `*_Arg`；若输入输出可合并进已有辅 TYPE 且调用链单一，再评估收敛。
3. **推荐形态**：主 TYPE 内 `TYPE(xxx_Lcl_Comp_ArgIn) :: comp_in` 等 **成员型 Arg 聚合**（见 §5 Element ArgHub 示例），与独立 `SUBROUTINE ...(..., arg)` 的 `*_Arg` **二选一或分层**：热路径偏好成员、Harness 仍可保留顶层 `Apply_*_Arg`。
4. **每域落地后**：在该域 `CONTRACT.md` 增列 **「主辅 TYPE 与 `*_Arg` 对照」** 小节（3～10 行即可）。

---

## 十四、F2008 / SUBMODULE 可选分叉（不阻塞主线）

- **主线合入门槛**：仅 **F2003**；`_Def.f90` 禁止 F2008 特性（见 §2.0.1）。
- **SUBMODULE / DO CONCURRENT / CONTIGUOUS**：放在 **独立 PR** 或 Phase-2 里程碑；编译矩阵未覆盖前不得作为 Step4 删弃的前提。
- 若某编译器不支持 SUBMODULE：**回退** `MODULE+CONTAINS` 的构建开关须在 CMake/文档中写明（见 §2.0.2 策略）。

---

## 十五、双规范运行手册（嵌套语义 ↔ 扁平存储 ↔ L1 索引）

本节把实施中反复出现的四个问题固化为**可执行规则**，与 §3.2–§3.3、§10.4 一致。

### 15.1 一级嵌套是否够用？多级何时必要？

- **默认**：Depth 1（主 TYPE）+ Depth 2（辅 TYPE，按 Phase×Verb 分组）即够用；**禁止 Depth 4**（§3.2）。
- **Depth 3 例外**：仅当某 Phase 下某 Verb 组内字段数 **>5** 时再拆一层子分组；否则用**并列辅 TYPE**（同层多成员）而非继续加深。
- **判断**：若去掉某辅 TYPE，可读性/责任边界不显著变差，则该辅 TYPE 应**降级为裸字段**并加 `! [Phase:X|Verb:Y]` 注释（§3.3）。

### 15.2 嵌套会不会「侵犯」扁平域存储？

不会，前提是三条不变量同时成立：

| 编号 | 不变量 | 说明 |
|------|--------|------|
| I1 | **语义在 TYPE 内** | 辅 TYPE 只出现在 `MD_Mat_Desc` / `PH_Elem_Desc` 等四型主 TYPE 的成员位，不替代 Domain 容器 |
| I2 | **存储在 Domain 阵列** | `desc_array(:)` / `state_array(:)` 等保持连续、可索引；Populate/Bridge 只经容器 TBP 或显式 `GetById` 取槽 |
| I3 | **L5 Bridge 辅 TYPE 无 ALLOCATABLE** | 热路径固定缓冲 + 计数器；与 §3.3、LINT-TYPE-005 一致 |

违反任一条（例如在全局容器里再嵌一套「小 Domain」、或热路径 ALLOCATABLE）即构成对双规范的侵犯。

### 15.3 嵌套索引与扁平存储如何映射？

推荐三件套（与 L3 域容器实践一致）：

1. **槽索引 `idx`**：`1..n_materials`（或各域 `n_*`）— O(1) 访问 `desc_array(idx)`。
2. **业务主键 `id`**：`id_to_index` 或对称映射 — `GetById(id)` → `idx`。
3. **命名解析（可选加速）**：`IF_Base_SymTbl` 维护 `name → data_id`（整数槽或业务 id）；**SymTbl 不持有 Desc 本体**，只持索引/元数据，避免与 I2 冲突。

Populate/Bridge 子程序负责 **L3 辅字段 → L4 辅字段 → L5 `%stp/%lcl`** 的单向拷贝；禁止在热路径绕过该链直读 L3。

### 15.4 L1 符号表 / 持久化对主辅设计的帮助

| L1 能力 | 用途 |
|---------|------|
| `register_variable` / `find_variable` | 冷路径 `GetByName` O(1)；与 Domain 扁平槽配合 |
| `register_variable_batch` | Populate 末批量注册材料/部件名 |
| `save_symbol_table_to_file` / `load_symbol_table_to_file` | 重启后名→槽一致；与 Domain 序列化分工（表≠载荷数组本体） |
| 版本 / LRU（若启用） | 迁移期双写断言、热点名诊断 |

### 15.5 L5 Bridge 平场字段与 `%stp/%lcl` 镜像（Step4 前奏）

- **真源**：以 **`%stp` / `%lcl`** 为读写真源；遗留 **DEPRECATED 平场** 仅作兼容镜像。
- **装配推荐入口**：`RT_Asm_Brg_ApplyMatBridge_Flat_IP` / `ApplyElemBridge_Flat_IP` 应 **先写 `%stp/%lcl`**，再调用 `RT_*_Bridge_Sync_Deprecated_From_Aux` 保持平场与嵌套一致，便于逐步淘汰只读平场的调用方。
- **删弃**：须满足 §12.3（N≥5 绿构建或发布窗口）后再从 TYPE 定义中移除平场成员；删除前 grep 全仓库无直接 `mat_brg%mat_id` 等访问。
