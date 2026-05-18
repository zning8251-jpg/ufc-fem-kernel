!===============================================================================
! MODULE:   MD_Solv_Mgr
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Solver（域缩 **Solv**）
! ROLE:     _Mgr — **域平坦容器** + **SIO `*_Arg`** + **Bridge**（**四型真源：`MD_Solv_Def`**）
! BRIEF:   `MD_Solver_Domain` CRUD, Apply_* SIO, step-index bridge hooks
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构（+Args）** 中的 **Mgr 容器 / SIO 包** + **过程算法**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构 — 与 **`MD_Solv_Def`** 头 **[1]** 对表 + **本文件专有 TYPE**
!       （**`MD_Solv_` vs `MD_Solver_*`**：**全局—局部命名律** 见 **`MD_Solv_Def`** 头同标题段）
!
!       **A. 真源在 `MD_Solv_Def`（此处仅消费）**
!       — **`MD_Solver_Desc` / `State` / `Algo` / `Ctx`** 及嵌套 **`MD_Solv_*`** — **不** 在本文件重定义。
!
!       **B. 本文件 TYPE（+1 Args + 域容器）**
!       — **`MD_Solver_Domain`**：**Mgr 平坦槽** — **`configs(:)`**（**`ALLOCATABLE`** **`MD_Solver_Desc`**）
!         + **`n_configs` / `capacity` / `initialized`**；**TBP** **`Init` / `Finalize` / `AddConfig` / `GetConfig` /
!         `GetSummary`**。**语义**：**多配置注册表**，**不是** 贯通四型里的 **`MD_Solver_Ctx`**（勿混名）。  
!       — **`MD_Solver_AddConfig_Arg` / `GetConfig_Arg` / `GetSummary_Arg` / `GetConfigForStep_Arg`**：**SIO Arg**
!         包（**`KIND: Arg`** — **结构化 +1**；**禁** 嵌套四型 **Desc/State/Algo/Ctx** 于 Arg 内）。  
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）
!       — **时间维**：**`Init` / `Finalize`** — 槽位生命周期；**`MD_Solver_SyncFromStep`**（在 **`MD_Solv_Sync`**）
!         驱动 **步 → 域** 全量刷新；本 **`_Mgr`** 过程多为 **COLD / 步前**。  
!       — **空间维**：**`MD_Solver_Brg_GetConfigForStep(_Select)`** — 用 **`step_idx` → `solver_config_id` → `MD_Solver_Desc`**
!         做 **索引路由**（**无** 网格几何）。  
!       — **动作维**：**`AddConfig` / `GetConfig` / `GetSummary`** — **Mutate / Query**；**`MD_Solver_Apply_*_Arg`** —
!         **SIO Apply**；**`MD_Solver_GetConfig_Idx`** — 兼容索引 API。
!
!       **过程命名模板**：**`MD_Solver_<Verb>`**（**TBP**）；**`MD_Solver_Apply_<Op>_Arg`**；**`MD_Solver_Brg_<...>`**。
!
! **依赖**：**`MD_Solv_Def`**（**`MD_Solver_Desc`**）、**`MD_Step_Mgr`**（**`MD_Step_Domain`**）、**`UFC_GlobalContainer_Core`**
!   （**`g_ufc_global`** — **l3Frozen** 等全局策略）。  
! **非依赖**：**不** 定义 **`MD_Solver_Desc`** 字段布局（见 **`MD_Solv_Def`**）。
!
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Solv | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Solver/CONTRACT.md

MODULE MD_Solv_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Solv_Def, ONLY: MD_Solver_Desc
  USE MD_Step_Mgr, ONLY: MD_Step_Domain
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  !-- 域容器 + SIO Args（+1）；四型见 MD_Solv_Def

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_Domain
  ! KIND:   **Mgr 容器**（**非** 贯通四型之 **`MD_Solver_Ctx`**）
  ! ROLE:   平坦 **`configs(:)`** 注册多 **`MD_Solver_Desc`**；**TBP** 生命周期 + CRUD
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_Domain
    TYPE(MD_Solver_Desc), ALLOCATABLE :: configs(:)
    INTEGER(i4)                        :: n_configs = 0_i4
    INTEGER(i4)                        :: capacity  = 0_i4
    LOGICAL                            :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddConfig
    PROCEDURE :: GetConfig
    PROCEDURE :: GetSummary
  END TYPE MD_Solver_Domain

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_AddConfig_Arg
  ! KIND:   Arg（SIO +1 · **禁** 内嵌四型包）
  ! ROLE:   **`AddConfig`** 入参 **`desc`** + 出参 **`config_id`** + **`status`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_AddConfig_Arg
    TYPE(MD_Solver_Desc)  :: desc       ! (IN)
    INTEGER(i4)           :: config_id = 0_i4  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_AddConfig_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_GetConfig_Arg
  ! KIND:   Arg（SIO +1）
  ! ROLE:   **`GetConfig`**：`config_id` **[IN]**，`desc` **[OUT]**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_GetConfig_Arg
    INTEGER(i4)           :: config_id = 0_i4  ! (IN)
    TYPE(MD_Solver_Desc)  :: desc              ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetConfig_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_GetSummary_Arg
  ! KIND:   Arg（SIO +1）
  ! ROLE:   **`GetSummary`**：文本摘要 **[OUT]**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Solver_GetConfigForStep_Arg
  ! KIND:   Arg（SIO +1）
  ! ROLE:   步索引 **`step_idx`** + 输出 **`desc`**（由 **`MD_Solver_Brg_*`** 填充）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Solver_GetConfigForStep_Arg
    INTEGER(i4)           :: step_idx = 0_i4  ! [IN]
    TYPE(MD_Solver_Desc)  :: desc            ! [OUT]
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetConfigForStep_Arg

  PUBLIC :: MD_Solver_Domain, MD_Solver_AddConfig_Arg, MD_Solver_GetConfig_Arg, &
            MD_Solver_GetSummary_Arg, MD_Solver_GetConfigForStep_Arg
  PUBLIC :: MD_Solver_GetConfig_Idx
  PUBLIC :: MD_Solver_Apply_AddConfig_Arg, MD_Solver_Apply_GetConfig_Arg, &
            MD_Solver_Apply_GetSummary_Arg, MD_Solver_Apply_GetConfig_Idx_Arg
  PUBLIC :: MD_Solver_Brg_GetConfigForStep, MD_Solver_Brg_GetConfigForStep_Select
  PUBLIC :: MD_Solver_Apply_GetConfigForStep_Arg, &
            MD_Solver_Apply_GetConfigForStep_Select_Arg

CONTAINS

  SUBROUTINE Finalize(this)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%configs)) DEALLOCATE(this%configs)
    this%n_configs = 0_i4
    this%capacity  = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE Init(this, initial_capacity, status)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: initial_capacity
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%capacity = MAX(16_i4, initial_capacity)
    ALLOCATE(this%configs(this%capacity))
    this%n_configs = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !====================================================================
  ! MD_Solv_AddCfg
  ! Add solver config, return config_id (index)
  !====================================================================
  SUBROUTINE AddConfig(this, desc, config_id, status)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    TYPE(MD_Solver_Desc),    INTENT(IN)    :: desc
    INTEGER(i4),             INTENT(OUT)   :: config_id
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    TYPE(MD_Solver_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap

    CALL init_error_status(status)
    config_id = 0_i4
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddConfig not allowed"
      RETURN
    END IF
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not initialized"
      RETURN
    END IF
    IF (desc%itr%max_iterations < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "AddConfig: max_iterations must be >= 1"
      RETURN
    END IF
    IF (desc%itr%residual_tol <= 0.0_wp .OR. desc%itr%correction_tol <= 0.0_wp .OR. desc%itr%energy_tol <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "AddConfig: tolerances must be strictly positive"
      RETURN
    END IF

    IF (this%n_configs >= this%capacity) THEN
      new_cap = MAX(16_i4, this%capacity * 2_i4)
      ALLOCATE(tmp(new_cap))
      IF (this%n_configs > 0) tmp(1:this%n_configs) = this%configs(1:this%n_configs)
      CALL MOVE_ALLOC(tmp, this%configs)
      this%capacity = new_cap
    END IF

    this%n_configs = this%n_configs + 1_i4
    config_id = this%n_configs
    this%configs(config_id) = desc
    this%configs(config_id)%cfg%config_id = config_id
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddConfig

  !====================================================================
  ! MD_Solv_GetCfg
  ! Get solver config by index
  !====================================================================
  SUBROUTINE GetConfig(this, config_id, desc, status)
    CLASS(MD_Solver_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: config_id
    TYPE(MD_Solver_Desc),    INTENT(OUT) :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. config_id < 1_i4 .OR. config_id > this%n_configs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid solver config_id"
      RETURN
    END IF
    desc = this%configs(config_id)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetConfig

  !====================================================================
  ! MD_Solver_Apply_GetConfig_Idx_Arg — SIO：`g_ufc_global%md_layer%solver`
  !====================================================================
  SUBROUTINE MD_Solver_Apply_GetConfig_Idx_Arg(config_id, arg)
    INTEGER(i4),                   INTENT(IN)    :: config_id
    TYPE(MD_Solver_GetConfig_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    arg%config_id = config_id
    ASSOCIATE(dom => g_ufc_global%md_layer%solver)
      IF (.NOT. dom%initialized .OR. config_id < 1_i4 .OR. config_id > dom%n_configs) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "Invalid solver config_id"
        RETURN
      END IF
      arg%desc = dom%configs(config_id)
    END ASSOCIATE
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_Apply_GetConfig_Idx_Arg

  !====================================================================
  ! MD_Solver_GetConfig_Idx - Index-style API（兼容第三参 `status` ≡ `arg%status`）
  !====================================================================
  SUBROUTINE MD_Solver_GetConfig_Idx(config_id, arg, status)
    INTEGER(i4),                   INTENT(IN)    :: config_id
    TYPE(MD_Solver_GetConfig_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL MD_Solver_Apply_GetConfig_Idx_Arg(config_id, arg)
    status = arg%status
  END SUBROUTINE MD_Solver_GetConfig_Idx

  !====================================================================
  ! SIO：`dom%AddConfig` / `GetConfig` / `GetSummary` 的 Apply 封装（幅值域对齐）
  !====================================================================
  SUBROUTINE MD_Solver_Apply_AddConfig_Arg(solv_dom, arg)
    CLASS(MD_Solver_Domain),          INTENT(INOUT) :: solv_dom
    TYPE(MD_Solver_AddConfig_Arg), INTENT(INOUT) :: arg

    arg%config_id = 0_i4
    CALL init_error_status(arg%status)
    CALL solv_dom%AddConfig(arg%desc, arg%config_id, arg%status)
  END SUBROUTINE MD_Solver_Apply_AddConfig_Arg

  SUBROUTINE MD_Solver_Apply_GetConfig_Arg(solv_dom, arg)
    CLASS(MD_Solver_Domain),          INTENT(IN)    :: solv_dom
    TYPE(MD_Solver_GetConfig_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    CALL solv_dom%GetConfig(arg%config_id, arg%desc, arg%status)
  END SUBROUTINE MD_Solver_Apply_GetConfig_Arg

  SUBROUTINE MD_Solver_Apply_GetSummary_Arg(solv_dom, arg)
    CLASS(MD_Solver_Domain),           INTENT(IN)    :: solv_dom
    TYPE(MD_Solver_GetSummary_Arg), INTENT(INOUT) :: arg

    CALL solv_dom%GetSummary(arg)
  END SUBROUTINE MD_Solver_Apply_GetSummary_Arg

  SUBROUTINE MD_Solver_Apply_GetConfigForStep_Arg(solver_domain, step_domain, arg)
    TYPE(MD_Solver_Domain),              INTENT(IN)    :: solver_domain
    TYPE(MD_Step_Domain),                INTENT(IN)    :: step_domain
    TYPE(MD_Solver_GetConfigForStep_Arg), INTENT(INOUT) :: arg

    CALL MD_Solver_Brg_GetConfigForStep(solver_domain, step_domain, arg%step_idx, &
         arg%desc, arg%status)
  END SUBROUTINE MD_Solver_Apply_GetConfigForStep_Arg

  SUBROUTINE MD_Solver_Apply_GetConfigForStep_Select_Arg(arg)
    TYPE(MD_Solver_GetConfigForStep_Arg), INTENT(INOUT) :: arg

    CALL MD_Solver_Brg_GetConfigForStep_Select(arg%step_idx, arg%desc, arg%status)
  END SUBROUTINE MD_Solver_Apply_GetConfigForStep_Select_Arg

  !====================================================================
  ! MD_Solv_GetSummary  [Phase B Arg wrapper]
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Solver_Domain),        INTENT(IN)    :: this
    TYPE(MD_Solver_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Solver domain not initialized"
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A)') &
      "Solver Summary: n_configs=", this%n_configs, &
      ", capacity=", this%capacity, " (all registered)"
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE GetSummary

  !=============================================================================
  ! MD_Solver_Brg_GetConfigForStep (ex-MD_Solv_Brg)
  ! Get solver config for step by index (uses step%solver_config_id).
  !=============================================================================
  SUBROUTINE MD_Solver_Brg_GetConfigForStep(solver_domain, step_domain, step_idx, &
       desc, status)
    TYPE(MD_Solver_Domain),     INTENT(IN)  :: solver_domain
    TYPE(MD_Step_Domain),       INTENT(IN)  :: step_domain
    INTEGER(i4),                INTENT(IN)  :: step_idx
    TYPE(MD_Solver_Desc),       INTENT(OUT) :: desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    INTEGER(i4) :: config_id

    CALL init_error_status(status)
    IF (.NOT. solver_domain%initialized .OR. .NOT. step_domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver or Step domain not initialized"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > step_domain%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid step index"
      RETURN
    END IF

    config_id = step_domain%steps(step_idx)%solver_config_id
    IF (config_id < 1_i4 .OR. config_id > solver_domain%n_configs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Step has no solver config (solver_config_id invalid)"
      RETURN
    END IF

    CALL solver_domain%GetConfig(config_id, desc, status)
  END SUBROUTINE MD_Solver_Brg_GetConfigForStep

  !=============================================================================
  ! MD_Solver_Brg_GetConfigForStep_Select — dispatcher when Global ready
  !=============================================================================
  SUBROUTINE MD_Solver_Brg_GetConfigForStep_Select(step_idx, desc, status)
    INTEGER(i4),                INTENT(IN)  :: step_idx
    TYPE(MD_Solver_Desc),       INTENT(OUT) :: desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%solver%initialized .AND. &
        g_ufc_global%md_layer%step%initialized .AND. &
        g_ufc_global%md_layer%solver%n_configs > 0_i4) THEN
      CALL MD_Solver_Brg_GetConfigForStep(g_ufc_global%md_layer%solver, &
           g_ufc_global%md_layer%step, step_idx, desc, status)
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not ready; use legacy step%algo%sol_ctrl"
    END IF
  END SUBROUTINE MD_Solver_Brg_GetConfigForStep_Select

END MODULE MD_Solv_Mgr