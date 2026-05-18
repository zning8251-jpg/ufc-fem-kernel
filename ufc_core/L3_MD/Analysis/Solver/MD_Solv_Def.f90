!===============================================================================
! MODULE:   MD_Solv_Def
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Solver（域缩 **Solv** / 贯通名 **Solver**）
! ROLE:     _Def — **`MD_Solver_*`** 主四型 + **`MD_Solv_*`** 嵌套段 **真源**
! BRIEF:   L3 solver configuration: Desc / State / Algo / Ctx + cold Desc helpers
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构** + **Desc 冷路径小过程**；**域 CRUD / SIO / Bridge** 在 **`MD_Solv_Mgr`**；**步同步** 在 **`MD_Solv_Sync`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名（层前缀 + 域 + 四型后缀）**
!       — 层前缀：**`MD_`**（L3_MD）| **`PH_`**（L4_PH）| **`RT_`**（L5_RT）。  
!       — **模块 / 文件三段式**：**`MD_Solv_*`**（域缩 **Solv**）。  
!       — **贯通四型主名**：**`MD_Solver_Desc` / `MD_Solver_State` / `MD_Solver_Algo` / `MD_Solver_Ctx`**
!         （**Solver** 全词 + **`_Desc|_State|_Algo|_Ctx`**）。  
!       — **嵌套语义段**（仍属本柱）：**`MD_Solv_<语义段>_...`**，如 **`MD_Solv_Itr_Com_*`**
!         （**Itr** 迭代 + **Com** 收敛）、**`MD_Solv_Stp_Ctl_*`**（**Stp** 步 + **Ctl** 控）、
!         **`MD_Solv_Cfg_Init_Desc`**（**Cfg** 配置 + **Init** 身份）。
!
!       **全局—局部命名律（冻结，勿混用）**
!       — **全局 / 编译单元**：**`MODULE MD_Solv_{Def,Mgr,Sync}`** + 文件名 **`MD_Solv_*.f90`** — **域缩
!         `Solv`**（与 **`RT_Solv_*`**、目录 **Solver/** 对齐）。  
!       — **局部 / 贯通四型 + 域级门面过程**：**`MD_Solver_*`** — **Solver** 全词，承载 **Desc/State/Algo/Ctx**
!         四型及 **`MD_Solver_Desc_*`**、**`MD_Solver_Algo_From_Desc`** 等 **对外稳定名**（**不**再缩成 **`MD_Solv_`**，
!         以免与 **模块名** 冲突）。  
!       — **局部 / 嵌套辅段 TYPE**：**`MD_Solv_*`** — 仅 **四型内部语义段**（**Cfg/Itr/Stp + Com/Ctl/Init/Evo**），
!         类比 Coupling 柱 **`MD_Cpl_*`** + **`MD_Coup_*`**。
!
!       **主（贯通四型）** — **`MD_Solver_*`**
!       — **Desc `MD_Solver_Desc`**：**嵌套** **`cfg`** → **`MD_Solv_Cfg_Init_Desc`**；**`itr`** →
!         **`MD_Solv_Itr_Com_Desc`**；**`stp`** → **`MD_Solv_Stp_Ctl_Desc`**。  
!       — **Algo `MD_Solver_Algo`**：**`itr`** → **`MD_Solv_Itr_Com_Algo`**（回切、线搜索等 **Algo 扩展**）。  
!       — **State `MD_Solver_State`**：**`stp`** → **`MD_Solv_Stp_Ctl_State`**；**`itr`** → **`MD_Solv_Itr_Com_State`**。  
!       — **Ctx `MD_Solver_Ctx`**：**`itr`** → **`MD_Solv_Itr_Com_Ctx`**；并列 **裸 `POINTER`** 工作引用
!         **`work_vec` / `rhs`**（**非** 独立辅 TYPE；**注意** 生命周期与宿主一致）。
!
!       **辅（L5 / 桥接占位，非本域主循环）**
!       — **`MD_LinearSolver_Desc`**、**`MD_NR_Algo`**、**`MD_Precond_Desc`**：与 L5 **`RT_Solv_*`**
!         对齐的 **stub / 占位**，**并列** 于主柱演进。
!
!       **Args（+1）**  
!       — 本 **`_Def`** **不** 承载 **`MD_Solver_*_Arg`**；**结构化 SIO Args** 定义在 **`MD_Solv_Mgr`**
!         （**`MD_Solver_AddConfig_Arg`** 等）。  
!       — **`CONTAINS`** 内 **`MD_Solver_Desc_*`** 与 **`MD_Solver_Desc_From_Algo` / `MD_Solver_Algo_From_Desc`**
!         使用 **显式形参** + **`ErrorStatusType`**，**无** **`*_Arg`** 包。
!
!   [2] 过程算法（三维度）— **本文件仅 Desc 冷子程序**
!       — **时间维**：**`MD_Solver_Desc_Init` / `Finalize` / `SetTolerances`** — **COLD**（建模 / 重置）；  
!         **`MD_Solver_Desc_From_Algo` / `Algo_From_Desc`** — **Desc ↔ Algo 映射**（无步内时间积分）。  
!       — **空间维**：本模块 **无** 网格 / DoF；**`MD_Solver_Ctx`** 中指针 **不** 在本文件绑定具体网格。  
!       — **动作维**：**Init / Set / Finalize / Map** 对 **`MD_Solver_Desc` / `MD_Solver_Algo`** 做 **Setup / Mutate / Query**。
!
!       **Mgr / Sync 侧过程命名**（**不在**本文件）：**`MD_Solver_Domain%Init`** 等 **TBP**；**`MD_Solver_Apply_*_Arg`**；
!         **`MD_Solver_Brg_*`**；**`MD_Solver_SyncFromStep`** — 见 **`MD_Solv_Mgr`** / **`MD_Solv_Sync`**。
!
! **依赖**：**`IF_Prec_Core`**、**`IF_Err_Brg`**。  
! **非依赖**：**不** `USE` **`MD_Solv_Mgr`** / **`MD_Solv_Sync`**（避免 **Def ⇄ Mgr/Sync** 环）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — 主TYPE + 辅TYPE (Depth≤3), L3 冷数据允许 ALLOCATABLE
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Solv | Role:Types | FuncSet:Desc,Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Solver/CONTRACT.md

MODULE MD_Solv_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Solv_Cfg_Init_Desc, MD_Solv_Itr_Com_Desc, MD_Solv_Stp_Ctl_Desc
  PUBLIC :: MD_Solv_Itr_Com_Algo
  PUBLIC :: MD_Solv_Stp_Ctl_State, MD_Solv_Itr_Com_State
  PUBLIC :: MD_Solv_Itr_Com_Ctx
  PUBLIC :: MD_Solver_Desc, MD_Solver_Algo, MD_Solver_State, MD_Solver_Ctx
  PUBLIC :: MD_LinearSolver_Desc, MD_NR_Algo, MD_Precond_Desc

  !-- 嵌套段（MD_Solv_*）+ 主四型（MD_Solver_*）+ L5 辅 stub

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Cfg_Init_Desc
  ! KIND:   Desc（辅 · 嵌套于 **`MD_Solver_Desc%cfg`**）
  ! ROLE:   **Cfg** 槽位 + **Init** 索引（`config_id` / `step_ref`）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Cfg_Init_Desc
    INTEGER(i4) :: config_id = 0_i4
    INTEGER(i4) :: step_ref = 0_i4
  END TYPE MD_Solv_Cfg_Init_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Itr_Com_Desc
  ! KIND:   Desc（辅 · 嵌套于 **`MD_Solver_Desc%itr`**）
  ! ROLE:   **Itr** 迭代 + **Com** 收敛判据（Desc 侧建模快照）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Desc
    INTEGER(i4) :: max_iterations = 16_i4
    REAL(wp) :: residual_tol = 1.0e-5_wp
    REAL(wp) :: correction_tol = 1.0e-3_wp
    REAL(wp) :: energy_tol = 1.0e-4_wp
    LOGICAL :: check_residual = .TRUE.
    LOGICAL :: check_correction = .TRUE.
    LOGICAL :: check_energy = .FALSE.
    LOGICAL :: line_search = .FALSE.
    REAL(wp) :: line_search_tol = 0.25_wp
  END TYPE MD_Solv_Itr_Com_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Stp_Ctl_Desc
  ! KIND:   Desc（辅 · 嵌套于 **`MD_Solver_Desc%stp`**）
  ! ROLE:   **Stp** 稳定化 + **Ctl** 数值控制（Desc 侧）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Stp_Ctl_Desc
    LOGICAL :: stabilize = .FALSE.
    REAL(wp) :: stabilize_factor = 2.0e-4_wp
    REAL(wp) :: stabilize_energy_fraction = 0.05_wp
  END TYPE MD_Solv_Stp_Ctl_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_Desc
  ! KIND:   Desc（主）
  ! NEST:   **`cfg` / `itr` / `stp`** — 见上三辅 **Desc** 段
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_Desc
    TYPE(MD_Solv_Cfg_Init_Desc) :: cfg
    TYPE(MD_Solv_Itr_Com_Desc)  :: itr
    TYPE(MD_Solv_Stp_Ctl_Desc)  :: stp
  END TYPE MD_Solver_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Itr_Com_Algo
  ! KIND:   Algo（辅 · 嵌套于 **`MD_Solver_Algo%itr`**）
  ! ROLE:   迭代 + 收敛 + **回切** 参数（运行侧可调段）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Algo
    INTEGER(i4) :: max_iterations = 16_i4
    REAL(wp) :: residual_tol = 1.0e-5_wp
    REAL(wp) :: correction_tol = 1.0e-3_wp
    REAL(wp) :: energy_tol = 1.0e-4_wp
    LOGICAL :: check_residual = .TRUE.
    LOGICAL :: check_correction = .TRUE.
    LOGICAL :: check_energy = .FALSE.
    LOGICAL :: line_search = .FALSE.
    REAL(wp) :: line_search_tol = 0.25_wp
    INTEGER(i4) :: max_cutbacks = 5_i4
    REAL(wp) :: cutback_factor = 0.5_wp
  END TYPE MD_Solv_Itr_Com_Algo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_Algo
  ! KIND:   Algo（主）
  ! NEST:   **`itr`** → **`MD_Solv_Itr_Com_Algo`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_Algo
    TYPE(MD_Solv_Itr_Com_Algo) :: itr
  END TYPE MD_Solver_Algo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Stp_Ctl_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Solver_State%stp`**）
  ! ROLE:   当前配置索引 / 失败步计数
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Stp_Ctl_State
    INTEGER(i4) :: current_config_idx = 0_i4
    INTEGER(i4) :: failed_steps = 0_i4
  END TYPE MD_Solv_Stp_Ctl_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Itr_Com_State
  ! KIND:   State（辅 · 嵌套于 **`MD_Solver_State%itr`**）
  ! ROLE:   迭代统计 / 收敛标志
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Itr_Com_State
    INTEGER(i4) :: total_iterations = 0_i4
    INTEGER(i4) :: max_iterations_reached = 0_i4
    REAL(wp) :: last_residual_norm = 0.0_wp
    REAL(wp) :: last_correction_norm = 0.0_wp
    LOGICAL :: converged = .FALSE.
  END TYPE MD_Solv_Itr_Com_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_State
  ! KIND:   State（主）
  ! NEST:   **`stp`** / **`itr`** — 见上两辅 **State**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_State
    TYPE(MD_Solv_Stp_Ctl_State) :: stp
    TYPE(MD_Solv_Itr_Com_State) :: itr
  END TYPE MD_Solver_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solv_Itr_Com_Ctx
  ! KIND:   Ctx（辅 · 嵌套于 **`MD_Solver_Ctx%itr`**）
  ! ROLE:   瞬态工作缓冲（范数、迭代计数、回切意图）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Ctx
    REAL(wp) :: current_residual_norm = 0.0_wp
    REAL(wp) :: current_correction_norm = 0.0_wp
    REAL(wp) :: energy_ratio = 0.0_wp
    INTEGER(i4) :: iteration_count = 0_i4
    LOGICAL :: needs_cutback = .FALSE.
    REAL(wp) :: cutback_factor = 0.5_wp
  END TYPE MD_Solv_Itr_Com_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_Ctx
  ! KIND:   Ctx（主）
  ! NEST:   **`itr`** → **`MD_Solv_Itr_Com_Ctx`**
  ! NOTE:   **`work_vec` / `rhs`** — 裸 **POINTER**，与宿主 **Ctx** 生命周期绑定
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_Ctx
    TYPE(MD_Solv_Itr_Com_Ctx) :: itr
    REAL(wp), POINTER :: work_vec(:) => NULL()
    REAL(wp), POINTER :: rhs(:) => NULL()
  END TYPE MD_Solver_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:   MD_LinearSolver_Desc
  ! KIND:   Desc（辅 stub · L5 **`RT_Solv_*`** 对齐占位）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LinearSolver_Desc
    INTEGER(i4) :: solver_id = 0_i4
  END TYPE MD_LinearSolver_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_NR_Algo
  ! KIND:   Algo（辅 stub · NR 参数占位）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NR_Algo
    INTEGER(i4) :: max_iter = 16_i4
  END TYPE MD_NR_Algo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Precond_Desc
  ! KIND:   Desc（辅 stub · 预条件器占位）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Precond_Desc
    INTEGER(i4) :: precond_type = 0_i4
  END TYPE MD_Precond_Desc

  !---------------------------------------------------------------------------
  ! 冷路径：`MD_Solver_Desc` / `MD_Solver_Algo` 互转与 Desc 初始化（**非** SIO `*_Arg`）
  !---------------------------------------------------------------------------
  PUBLIC :: MD_Solver_Desc_Init
  PUBLIC :: MD_Solver_Desc_SetTolerances
  PUBLIC :: MD_Solver_Desc_Finalize
  PUBLIC :: MD_Solver_Desc_From_Algo, MD_Solver_Algo_From_Desc

CONTAINS

  ! 动作维 · Map / Query：**`MD_Solver_Desc` <- `MD_Solver_Algo`**（重叠 **itr** 建模字段；**`PURE`**）
  !> 将 **`MD_Solver_Algo`** 中与 **`MD_Solver_Desc`** 重叠的建模字段拷入 Desc（不含 `config_id`/`step_ref`/稳定化项）。
  PURE SUBROUTINE MD_Solver_Desc_From_Algo(algo, desc)
    TYPE(MD_Solver_Algo), INTENT(IN)  :: algo
    TYPE(MD_Solver_Desc), INTENT(OUT) :: desc

    desc%cfg%config_id = 0_i4
    desc%itr%max_iterations = algo%itr%max_iterations
    desc%itr%residual_tol = algo%itr%residual_tol
    desc%itr%correction_tol = algo%itr%correction_tol
    desc%itr%energy_tol = algo%itr%energy_tol
    desc%itr%check_residual = algo%itr%check_residual
    desc%itr%check_correction = algo%itr%check_correction
    desc%itr%check_energy = algo%itr%check_energy
    desc%itr%line_search = algo%itr%line_search
    desc%itr%line_search_tol = algo%itr%line_search_tol
    desc%stp%stabilize = .FALSE.
    desc%stp%stabilize_factor = 2.0e-4_wp
    desc%stp%stabilize_energy_fraction = 0.05_wp
    desc%cfg%step_ref = 0_i4
  END SUBROUTINE MD_Solver_Desc_From_Algo

  ! 动作维 · Map / Query：**`MD_Solver_Algo` <- `MD_Solver_Desc`**（+ 默认 **回切** 参数；**`PURE`**）
  !> 从 **`MD_Solver_Desc`** 抽出与 **`MD_Solver_Algo`** 重叠部分（不含 Desc 专有的稳定化与 `step_ref`）。
  PURE SUBROUTINE MD_Solver_Algo_From_Desc(desc, algo)
    TYPE(MD_Solver_Desc), INTENT(IN)  :: desc
    TYPE(MD_Solver_Algo), INTENT(OUT) :: algo

    algo%itr%max_iterations = desc%itr%max_iterations
    algo%itr%residual_tol = desc%itr%residual_tol
    algo%itr%correction_tol = desc%itr%correction_tol
    algo%itr%energy_tol = desc%itr%energy_tol
    algo%itr%check_residual = desc%itr%check_residual
    algo%itr%check_correction = desc%itr%check_correction
    algo%itr%check_energy = desc%itr%check_energy
    algo%itr%line_search = desc%itr%line_search
    algo%itr%line_search_tol = desc%itr%line_search_tol
    algo%itr%max_cutbacks = 5_i4
    algo%itr%cutback_factor = 0.5_wp
  END SUBROUTINE MD_Solver_Algo_From_Desc

  ! 动作维 · Init：**`MD_Solver_Desc`** 建模空态 + 默认 **itr/stp/cfg**（**COLD**；**`ErrorStatusType`**）
  SUBROUTINE MD_Solver_Desc_Init(desc, st)
    TYPE(MD_Solver_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    desc%cfg%config_id = 0_i4
    desc%itr%max_iterations = 16_i4
    desc%itr%residual_tol = 1.0e-5_wp
    desc%itr%correction_tol = 1.0e-3_wp
    desc%itr%energy_tol = 1.0e-4_wp
    desc%itr%check_residual = .TRUE.
    desc%itr%check_correction = .TRUE.
    desc%itr%check_energy = .FALSE.
    desc%itr%line_search = .FALSE.
    desc%itr%line_search_tol = 0.25_wp
    desc%stp%stabilize = .FALSE.
    desc%stp%stabilize_factor = 2.0e-4_wp
    desc%stp%stabilize_energy_fraction = 0.05_wp
    desc%cfg%step_ref = 0_i4
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_Desc_Init

  ! 动作维 · Mutate：写 **`MD_Solver_Desc%itr`** 三项容差（**COLD**）
  SUBROUTINE MD_Solver_Desc_SetTolerances(desc, residual_tol, correction_tol, energy_tol, st)
    TYPE(MD_Solver_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: residual_tol, correction_tol, energy_tol
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    desc%itr%residual_tol = residual_tol
    desc%itr%correction_tol = correction_tol
    desc%itr%energy_tol = energy_tol
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_Desc_SetTolerances

  ! 动作维 · Finalize：**`MD_Solver_Desc`** 轻量 Teardown（**`step_ref`** 复位；**COLD**）
  SUBROUTINE MD_Solver_Desc_Finalize(desc, st)
    TYPE(MD_Solver_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    desc%cfg%step_ref = 0_i4
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_Desc_Finalize

END MODULE MD_Solv_Def
