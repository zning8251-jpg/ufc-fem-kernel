!===============================================================================
! MODULE:   MD_Step_Sync
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Step（域缩 **Step**）
! ROLE:      _Sync — **Legacy → 索引域** 冷路径 + **LoadBC → `LoadDef(:)`**（L5 Assembly）
! BRIEF:    (1) **`UF_ModelDef%step_mgr` → `MD_Step_Domain`**；(2) **`UF_Step_BuildLegacyLoadDefs_FromLdbc`**
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**过程算法 · Populate / Flatten** 为主；**不**再声明 **Desc/State/Algo/Ctx**
!   四型 — **数据结构** 真源在 **`MD_Step_Mgr`** / **`MD_Step_Def`** / **`MD_Step_Proc`** / **`MD_LBC_*`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args — **本文件不定义**）
!       — **读侧**：**`MD_Step_Desc`**, **`MD_LoadBC_Domain`**, **`MD_Load_Desc`**, **`LoadDef`**。  
!       — **写侧**：**`md_layer%step`**（**`MD_Step_Domain`**）、**`loads_out(:)`**（**`LoadDef`** 分配式 OUT）。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）
!       — **时间维**：**`MD_Step_SyncFromLegacy`** — **COLD**（建模 / 导入后、**`l3Frozen`** 前）；**无** 步内时间积分。  
!       — **空间维**：**`UF_Step_BuildLegacyLoadDefs_FromLdbc`** — **节点 / 集 / 面** **`TARGET_*`** 解析（**`Ldbc_Find*`**）；
!         **PRIVATE** **`map_domain_load_type_to_mgr`** — **Ldbc 载荷类 → `MD_Load_Mgr` 枚举**（**动作维 · Map**）。  
!       — **动作维**：**`MD_Step_SyncFromLegacy`** — **Mutate** 索引域步表；**`UF_Step_…`** — **Query** LoadBC +
!         **Build** 扁平载荷向量；**`resolve_md_load_target`** — **Resolve** 目标 **ID**。
!
! **依赖**：**`MD_Step_Mgr`**, **`MD_L3_Layer`**, **`MD_Model_Lib_Core`**, **`MD_LBC_*`**, **`MD_Load_Mgr`**。  
! **非依赖**：**不** `USE` **`MD_Step_Proc`**（**Legacy 步树** 已由 **`UF_ModelDef`** 持有；避免 **Sync ⇄ Proc** 环）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — Populate / Bridge (COLD)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Sync | FuncSet:Populate,LegacyLoad | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/Step/CONTRACT.md · L5_RT/Assembly/CONTRACT.md
!

MODULE MD_Step_Sync
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Step_Mgr, ONLY: MD_Step_Domain, MD_Step_Desc
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef, UF_Model
  USE MD_LBC_Domain, ONLY: MD_LoadBC_Domain, MD_Load_Desc, &
      LOAD_CLOAD, LOAD_DLOAD, LOAD_DSLOAD, LOAD_BODY_FORCE, LOAD_GRAVITY, LOAD_PRESSURE
  USE MD_Load_Mgr, ONLY: LoadDef, LoadDef_Init, &
      LOAD_CONCENTRAT, LOAD_DISTRIBUTE, &
      TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET
  USE MD_LBC_Query, ONLY: Ldbc_FindNodeSetId, Ldbc_FindSurfaceSetId, &
      Ldbc_FindElementSetId
  IMPLICIT NONE
  PRIVATE

  !-- **PUBLIC**：跨层 Populate；**PRIVATE**：载荷类型 / 目标解析助手

  PUBLIC :: MD_Step_SyncFromLegacy
  PUBLIC :: UF_Step_BuildLegacyLoadDefs_FromLdbc

CONTAINS

  !---------------------------------------------------------------------------
  ! **map_domain_load_type_to_mgr**（PRIVATE）
  ! **动作维 · Map** — **`MD_Load_Desc%load_type`**（**`LOAD_*`** 常数，**`USE MD_LBC_Domain`**）→ **`MD_Load_Mgr`**
  !   扁平 **`LoadDef`** 所用 **`LOAD_CONCENTRAT` / `LOAD_DISTRIBUTE`** 等及 **体/重力/压力** 数值槽（**`LoadDef_Init`** 契约）。
  ! **时间维**：N/A（纯映射，无步内时钟 / 增量状态）。
  ! **仅** 供 **`UF_Step_BuildLegacyLoadDefs_FromLdbc`** 调用。
  !---------------------------------------------------------------------------
  SUBROUTINE map_domain_load_type_to_mgr(md_lt, mgr_lt)
    INTEGER(i4), INTENT(IN) :: md_lt
    INTEGER(i4), INTENT(OUT) :: mgr_lt

    SELECT CASE (md_lt)
    CASE (LOAD_CLOAD)
      mgr_lt = LOAD_CONCENTRAT
    CASE (LOAD_DLOAD, LOAD_DSLOAD)
      mgr_lt = LOAD_DISTRIBUTE
    CASE (LOAD_BODY_FORCE)
      mgr_lt = 4_i4
    CASE (LOAD_GRAVITY)
      mgr_lt = 5_i4
    CASE (LOAD_PRESSURE)
      mgr_lt = 3_i4
    CASE default
      mgr_lt = LOAD_DISTRIBUTE
    END SELECT
  END SUBROUTINE map_domain_load_type_to_mgr

  !---------------------------------------------------------------------------
  ! **空间维 · Resolve** — **`MD_Load_Desc`** 目标字符串 / **node_id** → **`TARGET_*`** + **集 ID**
  !---------------------------------------------------------------------------
  SUBROUTINE resolve_md_load_target(ld, model, tt, tid)
    TYPE(MD_Load_Desc), INTENT(IN) :: ld
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    INTEGER(i4), INTENT(OUT) :: tt, tid

    CHARACTER(len=64) :: rgn
    INTEGER(i4) :: nid

    tt = TARGET_NODE
    tid = 0_i4
    nid = ld%node_id
    IF (nid > 0_i4) THEN
      tt = TARGET_NODE
      tid = nid
      RETURN
    END IF
    rgn = TRIM(ld%target_set)
    IF (LEN_TRIM(rgn) > 0_i4) THEN
      tid = Ldbc_FindNodeSetId(model, rgn)
      IF (tid > 0_i4) THEN
        tt = TARGET_NODESET
        RETURN
      END IF
      tid = Ldbc_FindSurfaceSetId(model, rgn)
      IF (tid > 0_i4) THEN
        tt = TARGET_SURFACE
        RETURN
      END IF
      tid = Ldbc_FindElementSetId(model, rgn)
      IF (tid > 0_i4) THEN
        tt = TARGET_ELEMSET
        RETURN
      END IF
    END IF
    IF (ld%load_type == LOAD_BODY_FORCE .OR. ld%load_type == LOAD_GRAVITY) THEN
      tt = TARGET_ELEMSET
      tid = 1_i4
    END IF
  END SUBROUTINE resolve_md_load_target

  !====================================================================
  ! **MD_Step_SyncFromLegacy**
  ! **时间维 · COLD** | **动作维 · Populate** — **`UF_ModelDef%step_mgr` → `md_layer%step`**
  ! 须在 **LoadBC_Sync / Output_Sync / Interaction_Sync** 之前调用。
  !====================================================================
  SUBROUTINE MD_Step_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef), INTENT(IN) :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: s, n_steps
    TYPE(MD_Step_Desc) :: step_desc

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_Sync: md_layer not initialized"
      RETURN
    END IF
    IF (.NOT. md_layer%step%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Step_Sync: step domain not initialized (call MD_L3_Init first)"
      RETURN
    END IF

    n_steps = model_def%step_mgr%num_steps
    IF (n_steps <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. ALLOCATED(model_def%step_mgr%steps)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (n_steps > SIZE(model_def%step_mgr%steps)) THEN
      n_steps = SIZE(model_def%step_mgr%steps)
    END IF

    DO s = 1, n_steps
      step_desc%name = model_def%step_mgr%steps(s)%name
      step_desc%step_number = model_def%step_mgr%steps(s)%step_number
      step_desc%procedure = model_def%step_mgr%steps(s)%procedure
      step_desc%nlgeom = model_def%step_mgr%steps(s)%nlgeom
      step_desc%time_period = model_def%step_mgr%steps(s)%time_period
      step_desc%start_time = model_def%step_mgr%steps(s)%start_time
      step_desc%perturbation = model_def%step_mgr%steps(s)%perturbation
      step_desc%algo%inc_ctrl = model_def%step_mgr%steps(s)%inc_ctrl
      step_desc%algo%sol_ctrl = model_def%step_mgr%steps(s)%sol_ctrl
      step_desc%algo%dyn = model_def%step_mgr%steps(s)%dyn_params
      CALL md_layer%step%AddStep(step_desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Step_SyncFromLegacy

  !====================================================================
  ! **UF_Step_BuildLegacyLoadDefs_FromLdbc**
  ! **空间维 · Flatten** | **动作维 · Build** — **`MD_LoadBC_Domain` → `LoadDef(:)`**（**`RT_Asm_GlobalLoad`**）
  ! 从原独立模块并入；避免 **`MD_Step_Proc`** 环依赖。
  !====================================================================
  SUBROUTINE UF_Step_BuildLegacyLoadDefs_FromLdbc(ldbcdom, model, step_idx, loads_out, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN) :: ldbcdom
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    INTEGER(i4), INTENT(IN) :: step_idx
    TYPE(LoadDef), ALLOCATABLE, INTENT(OUT) :: loads_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4), ALLOCATABLE :: widx(:)
    INTEGER(i4) :: nmax, n_found, i, k, mgr_lt, tt, tid, idof
    TYPE(MD_Load_Desc) :: ld
    TYPE(ErrorStatusType) :: st2

    CALL init_error_status(status)
    IF (ALLOCATED(loads_out)) DEALLOCATE(loads_out)
    IF (.NOT. ldbcdom%initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    nmax = MAX(1_i4, ldbcdom%n_loads)
    ALLOCATE(widx(nmax))
    CALL ldbcdom%GetLoadsForStep(step_idx, widx, n_found, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      IF (ALLOCATED(widx)) DEALLOCATE(widx)
      RETURN
    END IF
    IF (n_found <= 0_i4) THEN
      IF (ALLOCATED(widx)) DEALLOCATE(widx)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ALLOCATE(loads_out(n_found))
    DO k = 1, n_found
      i = widx(k)
      CALL ldbcdom%GetLoad(i, ld, st2)
      IF (st2%status_code /= IF_STATUS_OK) THEN
        status = st2
        IF (ALLOCATED(widx)) DEALLOCATE(widx)
        IF (ALLOCATED(loads_out)) DEALLOCATE(loads_out)
        RETURN
      END IF

      CALL map_domain_load_type_to_mgr(ld%load_type, mgr_lt)
      CALL resolve_md_load_target(ld, model, tt, tid)

      idof = ld%dof
      IF (idof < 1_i4 .OR. idof > 6_i4) idof = 3_i4

      CALL LoadDef_Init(loads_out(k), ld%load_id, TRIM(ld%name), mgr_lt, tt, tid, idof, &
          ld%magnitude, ld%amp_ref, st2)
      IF (st2%status_code /= IF_STATUS_OK) THEN
        status = st2
        IF (ALLOCATED(widx)) DEALLOCATE(widx)
        IF (ALLOCATED(loads_out)) DEALLOCATE(loads_out)
        RETURN
      END IF
      IF (tid <= 0_i4 .AND. ld%load_type /= LOAD_BODY_FORCE .AND. ld%load_type /= LOAD_GRAVITY) THEN
        loads_out(k)%isActive = .FALSE.
      END IF
    END DO

    IF (ALLOCATED(widx)) DEALLOCATE(widx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Step_BuildLegacyLoadDefs_FromLdbc

END MODULE MD_Step_Sync
