!===============================================================================
! MODULE:   MD_Step_Def
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Step（域缩 **Step**）
! ROLE:      _Def — **`MD_Step_State` / `MD_Step_Ctx`** + **`MD_Step_*_*` 辅语义段** **真源**
! BRIEF:    步域四型中的 **State / Ctx** 半柱：`Inc`（历程）与 `Itr`（积分算子参数）子段拆分
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构 · State/Ctx**；**Desc / Domain / Algo 嵌套 /
!   Args / TBP** 在 **`MD_Step_Mgr`**；**PROC 枚举 + UF_* Legacy Desc + 步管理器** 在 **`MD_Step_Proc`**；
!   **Legacy→索引域同步 / LoadBC→LoadDef** 在 **`MD_Step_Sync`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名（层前缀 + 域缩 + 语义段 + 四型后缀）**
!       — 层前缀：**`MD_`**（L3_MD）| **`PH_`**（L4_PH）| **`RT_`**（L5_RT）。  
!       — **本柱域缩**：**`MD_Step_*`** — 与 **`MODULE MD_Step_{Def,Mgr,Proc,Sync}`**、文件名 **`MD_Step_*.f90`** 对齐。  
!       — **本文件仅** **`State` / `Ctx`** 及其 **嵌套辅段**：**`MD_Step_Inc_Evo_*`**（**Inc**rement /
!         **Evo**lution）、**`MD_Step_Itr_Com_*`**（**Itr**ation + **Com**putation / 积分上下文）。  
!       — **不出现** **`MD_Step_Desc` / `StepAlgo`** — **Desc + 内嵌 Algo 槽** 在 **`MD_Step_Mgr`**。
!
!       **主（State / Ctx 半柱）**
!       — **`MD_Step_State`**：**嵌套** **`inc`** → **`MD_Step_Inc_Evo_State`**；**`stp`** →
!         **`MD_Step_Stp_Ctl_State`**（步末活跃 / 完成 / 收敛摘要 — **主从** 于增量态）。  
!       — **`MD_Step_Ctx`**：**嵌套** **`inc`** → **`MD_Step_Inc_Evo_Ctx`**；**`itr`** → **`MD_Step_Itr_Com_Ctx`**
!         — **并列** 承载 Newmark / HHT 等与迭代轴相关参数。
!
!       **Args（+1）**  
!       — 本 **`_Def`** **不** 声明 **`*_Arg`**；**`MD_Step_Get_*_Arg`**、**`MD_Step_WriteBack_Arg`** 等在 **`MD_Step_Mgr`**。
!
!       **与 `MD_Step_Mgr` 拼合阅读（四型落位）**  
!       — **Desc**：**`MD_Step_Desc`**、**`MD_Step_Domain`**；**Algo**：**`MD_Step_Desc%algo`**（**`StepAlgo`**，
!         内嵌 **`UF_*Control`**，定义见 **`MD_Step_Proc`**）。  
!       — **State / Ctx**：**本文件**。  
!       — **PROC 真值枚举**：**`MD_Step_Proc`** 中 **`PROC_*`**。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）— **本文件无 CONTAINS**
!       — **时间维**：字段表达 **步内时间标尺 / 增量序 / 累积时间**；写回由 **Mgr / L5** 编排。  
!       — **空间维**：**无** 节点 / 单元几何；区域 ID 归 **Mesh / LoadBC**。  
!       — **动作维**：本模块 **Passive TYPE**；**Init / Mutate / Query** 在 **`MD_Step_Mgr`** / Runtime。
!
! **依赖**：**`IF_Prec_Core`**（**`wp`**, **`i4`**）。  
! **非依赖**：**不** `USE` **`MD_Step_Mgr`** / **`MD_Step_Proc`**（避免 **Def ⇄ Mgr/Proc** 环）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — 主 TYPE + 辅 TYPE (Depth≤3), Phase×Verb 归组
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Types | FuncSet:State,Ctx | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/Step/CONTRACT.md

MODULE MD_Step_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Step_Inc_Evo_State, MD_Step_Stp_Ctl_State, MD_Step_State
  PUBLIC :: MD_Step_Inc_Evo_Ctx, MD_Step_Itr_Com_Ctx, MD_Step_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Inc_Evo_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Step_State%inc`**）
  ! ROLE:   [Phase:Inc|Verb:Evo] 增量 / 时间推进 — 历程计数与累积时间
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Inc_Evo_State
    REAL(wp)    :: current_time       = 0.0_wp
    INTEGER(i4) :: current_increment  = 0_i4
    INTEGER(i4) :: total_increments   = 0_i4
    REAL(wp)    :: accumulated_time   = 0.0_wp
  END TYPE MD_Step_Inc_Evo_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Stp_Ctl_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Step_State%stp`**）
  ! ROLE:   [Phase:Stp|Verb:Ctl] 步级控制 / 收敛与回切摘要
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Stp_Ctl_State
    LOGICAL     :: is_active          = .TRUE.
    LOGICAL     :: is_complete        = .FALSE.
    LOGICAL     :: is_converged       = .TRUE.
    INTEGER(i4) :: newton_iterations  = 0_i4
    INTEGER(i4) :: cutback_count      = 0_i4
  END TYPE MD_Step_Stp_Ctl_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_State
  ! KIND:   State（主 · 步级运行态容器）
  ! DESC:   时间 / 增量 / 收敛 / 回切 — **嵌套** `inc` + `stp` 两段
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_State
    TYPE(MD_Step_Inc_Evo_State) :: inc
    TYPE(MD_Step_Stp_Ctl_State) :: stp
  END TYPE MD_Step_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Inc_Evo_Ctx
  ! KIND:   Ctx（辅 · 嵌套于 **`MD_Step_Ctx%inc`**）
  ! ROLE:   [Phase:Inc|Verb:Evo] 增量与历程上下文（步内时间标尺、**`nlgeom`** 等）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Inc_Evo_Ctx
    REAL(wp)    :: step_time          = 0.0_wp
    REAL(wp)    :: total_time         = 0.0_wp
    REAL(wp)    :: time_increment     = 0.0_wp
    INTEGER(i4) :: increment_number   = 0_i4
    INTEGER(i4) :: analysis_type      = 0_i4
    LOGICAL     :: nlgeom             = .FALSE.
    LOGICAL     :: first_increment    = .FALSE.
    LOGICAL     :: last_increment     = .FALSE.
  END TYPE MD_Step_Inc_Evo_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Itr_Com_Ctx
  ! KIND:   Ctx（辅 · 嵌套于 **`MD_Step_Ctx%itr`**）
  ! ROLE:   [Phase:Itr|Verb:Comp] 迭代 / 瞬态积分算子参数（Newmark / HHT）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Itr_Com_Ctx
    INTEGER(i4) :: iteration_number   = 0_i4
    REAL(wp)    :: newmark_gamma      = 0.5_wp
    REAL(wp)    :: newmark_beta       = 0.25_wp
    REAL(wp)    :: hht_alpha          = 0.0_wp
  END TYPE MD_Step_Itr_Com_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Ctx
  ! KIND:   Ctx（主 · 步级跨层上下文容器）
  ! DESC:   时间 / 增量 / 积分算子 — **嵌套** `inc` + `itr` 两段
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Ctx
    TYPE(MD_Step_Inc_Evo_Ctx) :: inc
    TYPE(MD_Step_Itr_Com_Ctx) :: itr
  END TYPE MD_Step_Ctx

END MODULE MD_Step_Def
