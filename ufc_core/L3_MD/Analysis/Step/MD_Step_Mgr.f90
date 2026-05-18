!===============================================================================
! MODULE:   MD_Step_Mgr
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Step（域缩 **Step**）
! ROLE:      _Mgr — **`MD_Step_Domain` / `MD_Step_Desc` / `StepAlgo`** + **`*_Arg`** + **生命周期 TBP**
! BRIEF:    步域 **AUTHORITY** 容器：步表、全局默认 **Algo**、SymTbl 注册、**SIO Args** 门面
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构 · Desc/Domain/Args + Algo 嵌套** + **过程算法 · TBP/Idx API**；
!   **State/Ctx 辅段 TYPE** 在 **`MD_Step_Def`**；**PROC/UF_* 真源** 在 **`MD_Step_Proc`**；
!   **Legacy 同步 / LoadDef 冷路径** 在 **`MD_Step_Sync`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名（层前缀 + 域缩 + 角色 + 四型后缀）**
!       — 层前缀：**`MD_`** | **`PH_`** | **`RT_`**（约定同 **`MD_Solv_*`** / **`MD_Cpl_*`** 柱）。  
!       — **本模块主名**：**`MD_Step_Desc`**（**Desc** · 单步 **Write-Once** 元数据 + **索引树** + **内嵌
!         `algo`**）、**`MD_Step_Domain`**（**Desc** · 步表容器 + **TBP**）、**`StepAlgo`**（**Algo** 语义块 ·
!         **嵌套** **`UF_*Control`**，类型定义在 **`MD_Step_Proc`**）。  
!       — **`MD_Step_*_Arg`**：**Args（+1）** — **Get / GetByName / WriteBack** 等 **SIO** 束。  
!       — **`MD_Step_State` / `MD_Step_Ctx`**：**不**在本文件重定义 — 见 **`MD_Step_Def`**（可与 **`MD_Step_Desc`**
!         内 **扁平 State 片段** 对照：Desc 上 **`current_*` / `is_*`** 为 **WriteBack 靶**）。
!
!       **主从 / 嵌套**  
!       — **`MD_Step_Domain`** **主** 容器；**`steps(:)`** **并列** **`MD_Step_Desc`**；**`algo`** 为 **域级默认
!         Algo**（与每步 **`desc%algo`** **主从**）。  
!       — **`MD_Step_Desc%algo`** → **`StepAlgo`** → **`inc_ctrl` / `sol_ctrl` / `dyn`** **嵌套**。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）— **`CONTAINS`：TBP + Idx 门面**
!       — **时间维**：**`Add` / `Advance` / `WriteBack`** — 步序与 **WriteBack 白名单**（**`current_time`** 等）；
!         **COLD** 注册在 **`g_ufc_global%md_layer%l3Frozen`** 之前。  
!       — **空间维**：**无** 体网格；**`load_ids` / `bc_ids` / `pair_ids`** 为 **ID 索引树**（几何真源在别域）。  
!       — **动作维**：**`Init` / `Finalize` / `Add` / `Advance` / `Get*` / `WriteBack` / `Add*Id`** —
!         **Init / Mutate / Query / IO**；**`MD_Step_*_Idx`** 为 **Harness** 直连 **`g_ufc_global`** 的 **门面**。
!
! **依赖**：**`MD_Step_Proc`**（**`UF_*`**, **`PROC_*`**, **`NLGEOM_*`**）、**`IF_*`**, **`UFC_GlobalContainer_*`** 等。  
! **交叉只读**：**`MD_Step_Def`** 中 **`MD_Step_State` / `MD_Step_Ctx`** 与 **`MD_Step_Desc`** 内嵌运行态字段
!   可对照阅读；**本模块不 `USE MD_Step_Def`**（当前构建树无硬依赖）。  
! **非依赖**：**不** `USE` **`MD_Step_Sync`**（**Sync** 单向调用 **Mgr**，防环）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — 主 TYPE + 辅 TYPE (Depth≤3), Phase×Verb 归组
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Mgr | FuncSet:Init,Query,Mutate | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/Step/CONTRACT.md

MODULE MD_Step_Mgr
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, &
                            IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_DP
  USE IF_Base_SymTbl, ONLY: register_variable, get_variable_data_id, &
                            symbol_table_exists, &
                            IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_STRUCT
  USE IF_Log_Logger,     ONLY: IF_Log_Warning
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Step_Proc, ONLY: UF_IncrementControl, UF_SolutionControl, UF_DynamicParams, &
                           PROC_STATIC, NLGEOM_OFF

  IMPLICIT NONE
  PRIVATE

  !-- 主 **Desc** / **Domain** + **`StepAlgo`** 嵌套 + **`*_Arg`（+1）**

  !---------------------------------------------------------------------------
  ! TYPE:   StepAlgo
  ! KIND:   Algo（嵌套于 **`MD_Step_Desc%algo`** 与 **`MD_Step_Domain%algo`**）
  ! ROLE:   步级 / 域级默认 **增量控制 + Newton 控制 + 动力积分** 参数束
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: StepAlgo
    TYPE(UF_IncrementControl) :: inc_ctrl  !! Time increment control (Dt_0/Dt_min/Dt_max)
    TYPE(UF_SolutionControl)  :: sol_ctrl  !! Newton-Raphson control (max_iter/eps_res)
    TYPE(UF_DynamicParams)    :: dyn       !! Dynamic integration (Newmark beta/gamma/HHT)
  END TYPE StepAlgo

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Desc
  ! KIND:   Desc（主 · 单步 **Write-Once** + **WriteBack 靶** 运行片段）
  ! ROLE:   **`PROC_*` / `nlgeom` / 时间窗 / 索引树** + **嵌套** **`algo`**（**`StepAlgo`**）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Desc
    !--- Desc (Write-Once) ---
    CHARACTER(LEN=64) :: name         = ""
    INTEGER(i4)       :: step_number  = 0_i4
    INTEGER(i4)       :: procedure    = PROC_STATIC   !! PROC_STATIC/DYNAMIC_IMPLICIT/etc.
    INTEGER(i4)       :: nlgeom       = NLGEOM_OFF    !! 0=off, 1=on
    REAL(wp)          :: time_period  = 1.0_wp        !! Step time period T (Real)
    REAL(wp)          :: start_time   = 0.0_wp        !! Absolute start time t_0 (Real)
    LOGICAL           :: perturbation = .FALSE.       !! Perturbation step flag
    !--- Index tree: load_ids/bc_ids/pair_ids (from Domain_Core) ---
    ! See BOUNDARY_DOMAIN_DESIGN.md / INTERACTION_DOMAIN_DESIGN.md
    INTEGER(i4), ALLOCATABLE :: load_ids(:)   !! Load IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: bc_ids(:)     !! BC IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: pair_ids(:)   !! Contact pair IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: output_ids(:) !! Output request IDs active for this Step (OUTPUT_DOMAIN_DESIGN Phase A)
    INTEGER(i4)             :: solver_config_id = 0_i4 !! Solver config index in MD_Solver_Domain (SOLVER_INDEX_FLAT)
    !--- Algo (frozen at parse) ---
    TYPE(StepAlgo)    :: algo
    !--- State (WriteBack target ONLY - do NOT write directly) ---
    REAL(wp)    :: current_time      = 0.0_wp         !! Current time t (Real)
    INTEGER(i4) :: current_increment = 0_i4           !! Current increment n_inc (Integer)
    LOGICAL     :: is_active         = .TRUE.         !! Step is current
    LOGICAL     :: is_complete       = .FALSE.        !! Step has finished
  END TYPE MD_Step_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Domain
  ! KIND:   Desc（主 · **域容器** + **生命周期 TBP**）
  ! ROLE:   **`steps(:)`** 步表 + **当前步 / 增量索引** + **域默认 `algo`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Domain
    TYPE(MD_Step_Desc), ALLOCATABLE :: steps(:)           !! All step definitions
    INTEGER(i4)                     :: n_steps        = 0_i4
    INTEGER(i4)                     :: current_step_idx = 0_i4
    INTEGER(i4)                     :: current_incr_idx = 0_i4  !! [ ] L5 InitIncrement
    REAL(wp)                        :: total_time     = 0.0_wp  !! Sum of time_period
    TYPE(StepAlgo)                  :: algo            !! Global default algo params
    LOGICAL                         :: initialized    = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Add
    PROCEDURE :: Advance
    PROCEDURE :: GetCurrent
    PROCEDURE :: Get
    PROCEDURE :: GetByName
    PROCEDURE :: GetSummary
    PROCEDURE :: WriteBack
    PROCEDURE :: AddLoadId
    PROCEDURE :: AddBCId
    PROCEDURE :: AddPairId
    PROCEDURE :: AddOutputId
    PROCEDURE :: SetSolverConfigId
  END TYPE MD_Step_Domain

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_GetSummary_Arg
  ! KIND:   Arg（+1 · **GetSummary** 束）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Step_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_Get_Arg
  ! KIND:   Arg（+1 · **Get** 束）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Get_Arg
    TYPE(MD_Step_Desc) :: desc
  END TYPE MD_Step_Get_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_GetByName_Arg
  ! KIND:   Arg（+1 · **GetByName** 束）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_GetByName_Arg
    INTEGER(i4) :: step_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Step_GetByName_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Step_WriteBack_Arg
  ! KIND:   Arg（+1 · **WriteBack** 白名单束）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_WriteBack_Arg
    REAL(wp)  :: current_time      = 0.0_wp
    INTEGER(i4) :: current_increment = 0_i4
    LOGICAL   :: is_complete       = .FALSE.
  END TYPE MD_Step_WriteBack_Arg

  PUBLIC :: MD_Step_Domain, MD_Step_Desc, StepAlgo
  PUBLIC :: MD_Step_Get_Arg, MD_Step_GetStep_Idx
  PUBLIC :: MD_Step_GetByName_Arg, MD_Step_GetStepByName_Idx
  PUBLIC :: MD_Step_WriteBack_Arg, MD_Step_WriteBack_Idx

CONTAINS

  !============================================================================
  ! MD_Step_Domain_AddStep
  ! Register one step definition during L6_AP parse phase.
  ! Called before l3Frozen=.TRUE.; must NOT be called after freeze.
  !============================================================================
  SUBROUTINE Add(this, desc, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    TYPE(MD_Step_Desc),    INTENT(IN)    :: desc
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddStep not allowed"
      RETURN
    END IF
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. ALLOCATED(this%steps)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_Domain_AddStep: steps not allocated"
      RETURN
    END IF
    IF (this%n_steps >= INT(SIZE(this%steps), i4)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_Domain_AddStep: step table full (max_steps)"
      RETURN
    END IF

    this%n_steps               = this%n_steps + 1_i4
    this%steps(this%n_steps)   = desc
    this%total_time            = this%total_time + desc%time_period

    !--- Activate first step immediately ---
    IF (this%n_steps == 1_i4) THEN
      this%current_step_idx    = 1_i4
      this%steps(1)%is_active  = .TRUE.
    END IF

    ! SymTbl: register user-named step for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(desc%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "STEP:", TRIM(desc%name)
        WRITE(sym_val, '(I0)') this%n_steps
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Add

  !============================================================================
  ! MD_Step_Domain_AdvanceStep
  ! Mark the current step complete and advance to the next step.
  ! Called by L5_RT at the Step boundary; updates current_step_idx.
  !============================================================================
  SUBROUTINE Advance(this, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    idx = this%current_step_idx
    IF (idx < 1_i4 .OR. idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    this%steps(idx)%is_complete = .TRUE.
    this%steps(idx)%is_active   = .FALSE.

    IF (idx < this%n_steps) THEN
      this%current_step_idx          = idx + 1_i4
      this%steps(idx + 1_i4)%is_active = .TRUE.
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Advance

  !============================================================================
  ! MD_Step_Domain_Finalize
  ! Deallocate steps array; called in reverse init order (L5->L4->L3).
  !============================================================================
  SUBROUTINE Finalize(this)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%steps)) DEALLOCATE(this%steps)
    this%n_steps           = 0_i4
    this%current_step_idx  = 0_i4
    this%current_incr_idx  = 0_i4
    this%total_time        = 0.0_wp
    this%initialized       = .FALSE.

  END SUBROUTINE Finalize

  !============================================================================
  ! MD_Step_Domain_GetCurrentStep
  ! Read-only copy of the currently active step descriptor.
  ! Called by L4_PH (step boundary) and L5_RT (per iteration).
  !============================================================================
  SUBROUTINE GetCurrent(this, desc, status)
    CLASS(MD_Step_Domain), INTENT(IN)  :: this
    TYPE(MD_Step_Desc),    INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL Get(this, this%current_step_idx, desc, status)

  END SUBROUTINE GetCurrent

  !============================================================================
  ! MD_Step_Domain_GetStep
  ! Read-only copy of step descriptor by index.
  !============================================================================
  SUBROUTINE Get(this, idx, desc, status)
    CLASS(MD_Step_Domain), INTENT(IN)  :: this
    INTEGER(i4),           INTENT(IN)  :: idx
    TYPE(MD_Step_Desc),    INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (idx < 1_i4 .OR. idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    desc = this%steps(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Get

  !============================================================================
  ! MD_Step_GetStep_Idx - Standalone index-based API (Phase 2)
  !   Signature: (step_idx, arg, status) - uses g_ufc_global internally.
  !   Returns full step descriptor (incl. load_ids, bc_ids, pair_ids).
  !============================================================================
  SUBROUTINE MD_Step_GetStep_Idx(step_idx, arg, status)
    INTEGER(i4),                 INTENT(IN)    :: step_idx
    TYPE(MD_Step_Get_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)
    ASSOCIATE(dom => g_ufc_global%md_layer%step)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Step domain not initialized"
        RETURN
      END IF
      IF (step_idx < 1_i4 .OR. step_idx > dom%n_steps) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      arg%desc = dom%steps(step_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Step_GetStep_Idx

  !============================================================================
  ! MD_Step_WriteBack_Idx - Standalone WriteBack (Phase 2)
  !   Whitelist: current_time, current_increment, is_complete only
  !============================================================================
  SUBROUTINE WriteBack_Idx(step_idx, arg, status)
    INTEGER(i4),                   INTENT(IN)    :: step_idx
    TYPE(MD_Step_WriteBack_Arg),   INTENT(IN)    :: arg
    TYPE(ErrorStatusType),         INTENT(OUT)   :: status

    CALL init_error_status(status)
    ASSOCIATE(dom => g_ufc_global%md_layer%step)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Step domain not initialized"
        RETURN
      END IF
      IF (step_idx < 1_i4 .OR. step_idx > dom%n_steps) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      dom%steps(step_idx)%current_time      = arg%current_time
      dom%steps(step_idx)%current_increment = arg%current_increment
      dom%steps(step_idx)%is_complete       = arg%is_complete
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE WriteBack_Idx

  !============================================================================
  ! MD_Step_Domain_Init
  ! Allocate step array; called during system initialization (before parse).
  !   P2 DataPlatform: registers MD_Step_Desc type for persistence.
  !============================================================================
  SUBROUTINE Init(this, max_steps, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: max_steps
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (max_steps < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! P2 DataPlatform: register MD_Step_Desc struct type (optional; Init continues if fails)
    CALL MD_Step_DP_RegisterStructType(status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      CALL IF_Log_Warning("MD_Step_Domain_Init: DataPlatform registration failed; continuing")
      CALL init_error_status(status)
    END IF

    ALLOCATE(this%steps(max_steps))
    this%n_steps          = 0_i4
    this%current_step_idx = 0_i4
    this%total_time       = 0.0_wp
    this%initialized      = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !============================================================================
  ! MD_Step_DP_RegisterStructType - DataPlatform type registration (P2)
  !   Registers MD_Step_Desc fixed fields for checkpoint/persistence.
  !   Note: load_ids/bc_ids/pair_ids/output_ids (allocatable) excluded.
  !============================================================================
  SUBROUTINE MD_Step_DP_RegisterStructType(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(StructFieldDesc) :: fields(10)
    INTEGER(i4) :: offset

    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'name'
    fields(1)%data_type = IF_DATA_TYPE_CHAR
    fields(1)%offset_bytes = offset
    fields(1)%elem_len = 64
    offset = offset + 64
    fields(2)%field_name = 'step_number'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'procedure'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'nlgeom'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'time_period'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%offset_bytes = offset
    offset = offset + 8
    fields(6)%field_name = 'start_time'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%offset_bytes = offset
    offset = offset + 8
    fields(7)%field_name = 'solver_config_id'
    fields(7)%data_type = IF_DATA_TYPE_INT
    fields(7)%offset_bytes = offset
    offset = offset + 4
    fields(8)%field_name = 'current_time'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    fields(9)%field_name = 'current_increment'
    fields(9)%data_type = IF_DATA_TYPE_INT
    fields(9)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type('MD_Step_Desc', fields, 9, status)
  END SUBROUTINE MD_Step_DP_RegisterStructType

  !============================================================================
  ! MD_Step_WriteBack
  ! ONLY legal L5_RT WriteBack path for step runtime state.
  ! Updates: current_time / current_increment / is_complete.
  ! Prohibited fields (frozen): procedure/nlgeom/time_period/start_time/algo.
  !============================================================================
  SUBROUTINE WriteBack(this, step_idx, current_time, current_increment, &
                                is_complete, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    REAL(wp),              INTENT(IN)    :: current_time
    INTEGER(i4),           INTENT(IN)    :: current_increment
    LOGICAL,               INTENT(IN)    :: is_complete
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_WriteBack: step domain not initialized"
      RETURN
    END IF
    IF (this%n_steps < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_WriteBack: no steps registered"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_WriteBack: step_idx out of range"
      RETURN
    END IF

    this%steps(step_idx)%current_time      = current_time
    this%steps(step_idx)%current_increment = current_increment
    this%steps(step_idx)%is_complete       = is_complete

    status%status_code = IF_STATUS_OK
  END SUBROUTINE WriteBack

  !============================================================================
  ! MD_Step_Domain_GetStepByName
  ! Get step index by name (linear search)
  !============================================================================
  SUBROUTINE GetByName(this, name, step_idx, found, status)
    CLASS(MD_Step_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),      INTENT(IN)  :: name
    INTEGER(i4),           INTENT(OUT) :: step_idx
    LOGICAL,               INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, ios

    CALL init_error_status(status)
    step_idx = 0_i4
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Step domain not initialized"
      RETURN
    END IF

    ! SymTbl fast path: O(1) lookup
    IF (symbol_table_exists()) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        INTEGER(i4) :: idx
        WRITE(sym_key, '(A,A)') "STEP:", TRIM(name)
        CALL get_variable_data_id(TRIM(sym_key), sym_val, sym_st)
        IF (sym_st%status_code == IF_STATUS_OK .AND. LEN_TRIM(sym_val) > 0) THEN
          READ(sym_val, *, IOSTAT=ios) idx
          IF (ios == 0 .AND. idx >= 1 .AND. idx <= this%n_steps) THEN
            found = .TRUE.
            step_idx = idx
            status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END IF
      END BLOCK
    END IF

    ! Fallback: O(n) linear scan
    DO i = 1, this%n_steps
      IF (TRIM(this%steps(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        step_idx = i
        EXIT
      END IF
    END DO

    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Step '", TRIM(name), "' not found"
    END IF

  END SUBROUTINE GetByName

  !============================================================================
  ! MD_Step_GetStepByName_Idx - Index-style API (Phase B)
  !   Direct access to g_ufc_global%md_layer%step
  !============================================================================
  SUBROUTINE MD_Step_GetStepByName_Idx(name, arg, status)
    CHARACTER(LEN=*), INTENT(IN)    :: name
    TYPE(MD_Step_GetByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%inc%step_idx = 0_i4
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%step)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Step domain not initialized"
        RETURN
      END IF
      DO i = 1, dom%n_steps
        IF (TRIM(dom%steps(i)%name) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%inc%step_idx = i
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,A,A)') "Step '", TRIM(name), "' not found"
  END SUBROUTINE MD_Step_GetStepByName_Idx

  !============================================================================
  ! MD_Step_Domain_GetSummary  [Arg wrapper]
  !============================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Step_Domain),        INTENT(IN)    :: this
    TYPE(MD_Step_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL MD_Step_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  SUBROUTINE MD_Step_GetSummary_Impl(this, summary, status)
    CLASS(MD_Step_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),    INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Step domain not initialized"
      RETURN
    END IF

    IF (this%current_step_idx >= 1_i4 .AND. this%current_step_idx <= this%n_steps) THEN
      WRITE(summary, '(A,I0,A,I0,A,F12.4,A,L1,A,L1)') &
        "Step Summary: Steps=", this%n_steps, &
        ", Current=", this%current_step_idx, &
        ", TotalTime=", this%total_time, &
        ", Active=", this%steps(this%current_step_idx)%is_active, &
        ", Complete=", this%steps(this%current_step_idx)%is_complete
    ELSE
      WRITE(summary, '(A,I0,A,I0,A)') &
        "Step Summary: Steps=", this%n_steps, &
        ", Current=", this%current_step_idx, &
        ", no active step"
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Step_GetSummary_Impl

  !============================================================================
  ! MD_Step_Domain_AddLoadId / MD_Step_Domain_AddBCId
  ! Register load/BC ID to current step (see BOUNDARY_DOMAIN_DESIGN).
  ! Actual load/BC data stored in MD_LoadBC_Domain_Core; step holds only IDs.
  !============================================================================
  SUBROUTINE AddLoadId(this, step_idx, load_id, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    INTEGER(i4),           INTENT(IN)    :: load_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: n
    INTEGER(i4), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddLoadId not allowed"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    n = 0
    IF (ALLOCATED(this%steps(step_idx)%load_ids)) n = SIZE(this%steps(step_idx)%load_ids)
    ALLOCATE(tmp(n + 1))
    IF (n > 0) tmp(1:n) = this%steps(step_idx)%load_ids
    tmp(n + 1) = load_id
    CALL MOVE_ALLOC(tmp, this%steps(step_idx)%load_ids)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddLoadId

  SUBROUTINE AddBCId(this, step_idx, bc_id, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    INTEGER(i4),           INTENT(IN)    :: bc_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: n
    INTEGER(i4), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddBCId not allowed"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    n = 0
    IF (ALLOCATED(this%steps(step_idx)%bc_ids)) n = SIZE(this%steps(step_idx)%bc_ids)
    ALLOCATE(tmp(n + 1))
    IF (n > 0) tmp(1:n) = this%steps(step_idx)%bc_ids
    tmp(n + 1) = bc_id
    CALL MOVE_ALLOC(tmp, this%steps(step_idx)%bc_ids)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddBCId

  !============================================================================
  ! MD_Step_Domain_AddPairId
  ! Register contact pair ID to step (INTERACTION_DOMAIN_DESIGN).
  !============================================================================
  SUBROUTINE AddPairId(this, step_idx, pair_id, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    INTEGER(i4),           INTENT(IN)    :: pair_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: n
    INTEGER(i4), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddPairId not allowed"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    n = 0
    IF (ALLOCATED(this%steps(step_idx)%pair_ids)) n = SIZE(this%steps(step_idx)%pair_ids)
    ALLOCATE(tmp(n + 1))
    IF (n > 0) tmp(1:n) = this%steps(step_idx)%pair_ids
    tmp(n + 1) = pair_id
    CALL MOVE_ALLOC(tmp, this%steps(step_idx)%pair_ids)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddPairId

  !============================================================================
  ! MD_Step_Domain_AddOutputId
  ! Register output request ID to step (OUTPUT_DOMAIN_DESIGN Phase A).
  ! Actual output request data stored in MD_Output_Domain_Core; step holds only IDs.
  !============================================================================
  SUBROUTINE AddOutputId(this, step_idx, output_id, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    INTEGER(i4),           INTENT(IN)    :: output_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: n
    INTEGER(i4), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddOutputId not allowed"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    n = 0
    IF (ALLOCATED(this%steps(step_idx)%output_ids)) n = SIZE(this%steps(step_idx)%output_ids)
    ALLOCATE(tmp(n + 1))
    IF (n > 0) tmp(1:n) = this%steps(step_idx)%output_ids
    tmp(n + 1) = output_id
    CALL MOVE_ALLOC(tmp, this%steps(step_idx)%output_ids)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddOutputId

  !============================================================================
  ! MD_Step_Domain_SetSolverConfigId
  ! Set solver config index for a step (SOLVER_INDEX_FLAT migration).
  ! Called by MD_Solver_SyncFromStep after AddConfig.
  !============================================================================
  SUBROUTINE SetSolverConfigId(this, step_idx, config_id, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_idx
    INTEGER(i4),           INTENT(IN)    :: config_id
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (g_ufc_global%md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: SetSolverConfigId not allowed"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%steps(step_idx)%solver_config_id = config_id
    status%status_code = IF_STATUS_OK
  END SUBROUTINE SetSolverConfigId

END MODULE MD_Step_Mgr