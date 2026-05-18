!===============================================================================
! MODULE:   MD_Cpl_Def
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Coupling（域缩 **Cpl**）
! ROLE:     _Def — **`MD_Cpl_*`** 主四型 + **`MD_Coup_*`** 辅对 TYPE **真源**
! BRIEF:   Multi-field coupling: Desc / State / Algo / Ctx + pair + step-control
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构**；**过程算法**在 **`MD_Cpl_Core`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主 / 辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名模板（层前缀 + 域缩 + 角色段 + 四型后缀）**
!       — 层前缀：**`MD_`**（L3_MD）| **`PH_`**（L4_PH）| **`RT_`**（L5_RT）。  
!       — 本柱：**`MD_Cpl_<...>_(Desc|State|Algo|Ctx)`** — **Cpl** = Coupling **半柱**域缩。  
!       — **辅对**（并列通道，区别于柱前缀）：**`MD_Coup_<...>`** — **Coup** = **cou**pling
!         **p**air 缩写。  
!       — **扩展语义段**（仍属本柱，非新域）：如 **`MD_Cpl_Stp_Ctl_Desc`** =
!         **`MD_Cpl`** + **`Stp`**（step 序）+ **`Ctl`**（control）+ **`_Desc`**。
!
!       **主（贯通四型）** — 前缀 **`MD_Cpl_*`**
!       — **Desc** **`MD_Cpl_Desc`**：**主容器**；与 **`pairs(1:MD_COUP_MAX_PAIRS)`**
!         **并列** 存放各 **`TYPE(MD_Coup_PairDef)`**；**嵌套** **`ctl`** →
!         **`MD_Cpl_Stp_Ctl_Desc`**（步序 / 数值控制 **从属** 主 Desc）。  
!       — **State** **`MD_Cpl_State`**：**嵌套** **`inc`**（**`MD_Cpl_Inc_Evo_State`**
!         · 历程 / 活跃对计数）与 **`stp`**（**`MD_Cpl_Stp_Ctl_State`**
!         · Populate 镜像 / 开关）。  
!       — **Algo** **`MD_Cpl_Algo`**：**嵌套** **`stp`** → **`MD_Cpl_Stp_Ctl_Algo`**
!         （松弛、Aitken、子循环等）。  
!       — **Ctx** **`MD_Cpl_Ctx`**：**嵌套** **`brg`** → **`MD_Cpl_Pop_Brg_Ctx`**
!         （L3→L5 Populate / WriteBack **握手**）。
!
!       **辅（子 TYPE，被主四型引用）**
!       — **`MD_Coup_PairDef`**：单通道 **Desc**（src/dst 场、界面面 ID、标度等），
!         **并列** 填满主 **`MD_Cpl_Desc%pairs`**。  
!       — **`MD_Cpl_Stp_Ctl_*`**：**主从** 于主 **`Desc` / `State` / `Algo`**；表达
!         **Stp**（步）+ **Ctl**（控）子语义。  
!       — **`MD_Cpl_Inc_Evo_State`**：嵌在 **`MD_Cpl_State%inc`**（**Inc**rement /
!         **Evo**lution）。
!
!       **Args（+1）**  
!       — 本 **`_Def`** **不** 声明嵌套 **`MD_Cpl_*_Arg`** 四型包；门面过程以
!         **显式形参** 表达 IO（见 **`MD_Cpl_Core`**：`desc` / `pair` / 标量 OUT +
!         **`ErrorStatusType`** 等）。  
!       — 跨层复合 **`MD_Cpl_Populate_Arg`** 等仅 **合同层** 预留（见
!         **`Analysis/Coupling/CONTRACT.md`**）。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）— **实现：`MD_Cpl_Core`**
!       — **时间维**：**Desc / Algo** 偏 **COLD**（建模写入、步前冻结）；**State /
!         Ctx** 承载 **Populate 标记** 等 **WARM** 片段。  
!       — **空间维**：**`MD_Coup_PairDef%interface_surf_id`** 等为 **面集引用占位**；
!         **无** 面积分 / 面几何 — 归 **Mesh / LoadBC** 等域。  
!       — **动作维**：**`MD_Cpl_<Verb>_Proc`**（**Init / Finalize / AddPair /
!         Validate / Get\***）对主 **Desc** 与辅 **`MD_Coup_PairDef`** 做 **Init /
!         Mutate / Validate / Query**；与本 **`_Def`** 字段一一对应。
!
! **依赖**：**`IF_Prec_Core`**（**`wp`**, **`i4`**）。  
! **非依赖**：**不** `USE` **`MD_Cpl_Core`**（避免 **Def ⇄ Core** 模块环）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — 主 TYPE + 辅 TYPE (Depth≤3)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Coupling | Role:Types | FuncSet:Desc,State,Algo,Ctx
!>>> UFC_L3_CONTRACT | Analysis/Coupling/CONTRACT.md

MODULE MD_Cpl_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-- Public TYPEs (主四型 + 辅对 + 嵌套子段)
  PUBLIC :: MD_Coup_PairDef
  PUBLIC :: MD_Cpl_Stp_Ctl_Desc, MD_Cpl_Inc_Evo_State, MD_Cpl_Stp_Ctl_State
  PUBLIC :: MD_Cpl_Stp_Ctl_Algo, MD_Cpl_Pop_Brg_Ctx
  PUBLIC :: MD_Cpl_Desc, MD_Cpl_State, MD_Cpl_Algo, MD_Cpl_Ctx

  !-- Public enums (L3↔L5 / keyword traceability)
  PUBLIC :: MD_COUP_FIELD_STR, MD_COUP_FIELD_THM, MD_COUP_FIELD_FLD
  PUBLIC :: MD_COUP_FIELD_DIF, MD_COUP_FIELD_EM, MD_COUP_FIELD_ACO
  PUBLIC :: MD_COUP_STRAT_ONEWAY, MD_COUP_STRAT_STAG
  PUBLIC :: MD_COUP_STRAT_PARTITER, MD_COUP_STRAT_MONO

  !=============================================================================
  ! Field ID constants (mirror RT_MF_FIELD_* for L3↔L5 traceability)
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_STR = 1_i4  ! Structural
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_THM = 2_i4  ! Thermal
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_FLD = 3_i4  ! Fluid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_DIF = 4_i4  ! Diffusion
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_EM = 5_i4  ! Electromagnetic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_FIELD_ACO = 6_i4  ! Acoustic

  !=============================================================================
  ! Coupling strategy constants (mirror RT_MF_COUP_* for traceability)
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_STRAT_ONEWAY = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_STRAT_STAG = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_STRAT_PARTITER = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_STRAT_MONO = 3_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_COUP_MAX_PAIRS = 16_i4

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Coup_PairDef
  ! KIND:   Desc（辅 · 单对并列单元）
  ! ROLE:   双场通道；被 **`MD_Cpl_Desc%pairs`** 引用
  ! SPACE:  **`interface_surf_id`** — 面集 ID 占位（几何在 Mesh 域）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Coup_PairDef
    INTEGER(i4) :: pair_id = 0_i4
    INTEGER(i4) :: src_field_id = 0_i4       ! MD_COUP_FIELD_*
    INTEGER(i4) :: dst_field_id = 0_i4       ! MD_COUP_FIELD_*
    INTEGER(i4) :: qty_type = 0_i4           ! what is transferred (1-10)
    INTEGER(i4) :: interface_surf_id = 0_i4  ! mesh surface set reference
    REAL(wp) :: scale_factor = 1.0_wp
    LOGICAL :: is_active = .TRUE.
    CHARACTER(LEN=64) :: label = ''
    CHARACTER(LEN=128) :: keyword_source = ''  ! e.g. "*COUPLED TEMPERATURE-DISPLACEMENT"
  END TYPE MD_Coup_PairDef

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Stp_Ctl_Desc
  ! KIND:   Desc（辅 · 嵌套于 **`MD_Cpl_Desc%ctl`**）
  ! ROLE:   全局策略 + 数值控制（**Stp** 序 + **Ctl** 控）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_Desc
    INTEGER(i4) :: strategy = MD_COUP_STRAT_STAG
    INTEGER(i4) :: interp_method = 0_i4      ! 0=NN, 1=RBF, 2=MLS, 3=C0
    INTEGER(i4) :: max_coupling_iter = 10_i4
    REAL(wp) :: coupling_tol = 1.0E-4_wp
    LOGICAL :: is_configured = .FALSE.
  END TYPE MD_Cpl_Stp_Ctl_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Desc
  ! KIND:   Desc（主 · 耦合配置容器）
  ! NEST:   **`ctl`** → **`MD_Cpl_Stp_Ctl_Desc`**；**`pairs`** → **`MD_Coup_PairDef`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Desc
    INTEGER(i4) :: n_pairs = 0_i4                       ! active pair count
    TYPE(MD_Coup_PairDef) :: pairs(MD_COUP_MAX_PAIRS)
    TYPE(MD_Cpl_Stp_Ctl_Desc) :: ctl
  END TYPE MD_Cpl_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Inc_Evo_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Cpl_State%inc`**）
  ! ROLE:   **Inc**rement 历程索引 + **Evo** 活跃对统计
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Inc_Evo_State
    INTEGER(i4) :: current_step_id = 0_i4
    INTEGER(i4) :: n_active_pairs = 0_i4
  END TYPE MD_Cpl_Inc_Evo_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Stp_Ctl_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Cpl_State%stp`**）
  ! ROLE:   运行开关；**`populated_to_l5`** — Populate 镜像
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_State
    LOGICAL :: is_active = .FALSE.
    LOGICAL :: populated_to_l5 = .FALSE.
  END TYPE MD_Cpl_Stp_Ctl_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_State
  ! KIND:   State（主）
  ! NEST:   **`inc`** / **`stp`** — 见上两辅 State
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_State
    TYPE(MD_Cpl_Inc_Evo_State) :: inc
    TYPE(MD_Cpl_Stp_Ctl_State) :: stp
  END TYPE MD_Cpl_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Stp_Ctl_Algo
  ! KIND:   Algo（辅 · 嵌套于 **`MD_Cpl_Algo%stp`**）
  ! ROLE:   松弛 / Aitken / 子循环 / 交错策略等
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_Algo
    REAL(wp) :: relaxation_factor = 1.0_wp
    LOGICAL :: use_aitken = .FALSE.
    REAL(wp) :: aitken_init = 0.01_wp           ! initial Aitken relaxation
    INTEGER(i4) :: subcycle_ratio = 1_i4      ! 1=no subcycle, 2=double, ...
    LOGICAL :: subcycle_adaptive = .FALSE.    ! auto-adjust subcycle ratio
    REAL(wp) :: subcycle_min_dt = 0.0_wp      ! minimum subcycle dt
    INTEGER(i4) :: stagger_strategy = 0_i4    ! 0=sequential, 1=parallel, 2=block
    LOGICAL :: use_predictor = .FALSE.        ! predict fields between stagger
    INTEGER(i4) :: predict_type = 0_i4        ! 0=zero, 1=linear, 2=extrapolation
    REAL(wp) :: relaxation_min = 0.01_wp      ! minimum relaxation factor
    REAL(wp) :: relaxation_max = 0.99_wp      ! maximum relaxation factor
  END TYPE MD_Cpl_Stp_Ctl_Algo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Algo
  ! KIND:   Algo（主）
  ! NEST:   **`stp`** → **`MD_Cpl_Stp_Ctl_Algo`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Algo
    TYPE(MD_Cpl_Stp_Ctl_Algo) :: stp
  END TYPE MD_Cpl_Algo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Pop_Brg_Ctx
  ! KIND:   Ctx（辅 · 嵌套于 **`MD_Cpl_Ctx%brg`**）
  ! ROLE:   **Pop**ulate / WriteBack **Brg** 握手标志
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Pop_Brg_Ctx
    LOGICAL :: populate_pending = .FALSE.
    LOGICAL :: writeback_done = .FALSE.
  END TYPE MD_Cpl_Pop_Brg_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Cpl_Ctx
  ! KIND:   Ctx（主）
  ! NEST:   **`brg`** → **`MD_Cpl_Pop_Brg_Ctx`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Cpl_Ctx
    TYPE(MD_Cpl_Pop_Brg_Ctx) :: brg
  END TYPE MD_Cpl_Ctx

END MODULE MD_Cpl_Def
