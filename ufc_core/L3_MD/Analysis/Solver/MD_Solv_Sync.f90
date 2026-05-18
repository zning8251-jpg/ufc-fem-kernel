!===============================================================================
! MODULE:   MD_Solv_Sync
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Solver（域缩 **Solv**）
! ROLE:     _Sync — **步域 `sol_ctrl` → `MD_Solver_Desc`** 再 **灌入 `MD_Solver_Domain`**
! BRIEF:   Transactional `MD_Solver_SyncFromStep` + config compaction
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**过程算法** 为主；**不** 引入新四型 / **无** 本域 `*_Arg` TYPE）
!---------------------------------------------------------------------------
!
!   [1] 数据结构
!       — **无** 新增 TYPE；消费 **`MD_Solv_Def`**（**`MD_Solver_Desc`**）与 **`MD_Solv_Mgr`**
!         （**`MD_Solver_Domain`**）。**命名律**：见 **`MD_Solv_Def`** 头「**全局—局部命名律**」。  
!       — **Args**：**`MD_Solver_SyncFromStep(md_layer, status)`** — **显式**形参 +
!         **`ErrorStatusType`**（合同：**不** 为仅包 **`status`** 再设 **`*_Arg`**）。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）
!       — **时间维**：**`MD_Solver_SyncFromStep`** — **步序 1..`n_steps`** 上 **幂等** 重建
!         **`solver%configs`** 与 **`step%steps(:)%solver_config_id`**；**事务**：失败 **回滚**
!         备份 **`bak_cfg` / `prev_sid`**。末尾 **`MD_Solv_Sync_CompactConfigs`** — **COLD** 收缩槽。  
!       — **空间维**：**`SolCtrl_To_SolverDesc`** — 将 **`UF_SolutionControl`** 标量控制 **映射** 到
!         **`MD_Solver_Desc%itr` / `%stp` / `%cfg`**（**无** DoF）。  
!       — **动作维**：**Populate 类 Sync** — **`AddConfig`** + **`SetSolverConfigId`**；与 **`MD_Solv_Mgr`**
!         **协作**完成 **Mutate**。
!
! **依赖**：**`MD_Solv_Def`**、**`MD_Solv_Mgr`**、**`MD_Step_Proc`**、**`MD_L3_Layer`**。  
! **非依赖**：**不** 直接调用 L5 **`RT_Solv_*`**。
!
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Solv | Role:Sync | FuncSet:Sync | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Solver/CONTRACT.md

MODULE MD_Solv_Sync
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Solv_Def,      ONLY: MD_Solver_Desc
  USE MD_Solv_Mgr, ONLY: MD_Solver_Domain
  USE MD_Step_Proc,          ONLY: UF_SolutionControl
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  IMPLICIT NONE
  PRIVATE

  !-- 主 API（无本域 `*_Arg` TYPE；见头 **[1]** Args 说明）

  PUBLIC :: MD_Solver_SyncFromStep

CONTAINS

  !---------------------------------------------------------------------------
  ! SolCtrl_To_SolverDesc — **空间维 / 动作维**：UF 解控标量 -> **`MD_Solver_Desc`**
  !---------------------------------------------------------------------------
  PURE SUBROUTINE SolCtrl_To_SolverDesc(sol_ctrl, step_ref, desc)
    TYPE(UF_SolutionControl), INTENT(IN)  :: sol_ctrl
    INTEGER(i4),              INTENT(IN)  :: step_ref
    TYPE(MD_Solver_Desc),     INTENT(OUT) :: desc

    desc%itr%max_iterations  = sol_ctrl%max_iterations
    desc%itr%residual_tol    = sol_ctrl%residual_tol
    desc%itr%correction_tol  = sol_ctrl%correction_tol
    desc%itr%energy_tol      = sol_ctrl%energy_tol
    desc%itr%check_residual  = sol_ctrl%check_residual
    desc%itr%check_correction = sol_ctrl%check_correction
    desc%itr%check_energy    = sol_ctrl%check_energy
    desc%itr%line_search     = sol_ctrl%line_search
    desc%itr%line_search_tol = sol_ctrl%line_search_tol
    desc%stp%stabilize       = sol_ctrl%stabilize
    desc%stp%stabilize_factor = sol_ctrl%stabilize_factor
    desc%stp%stabilize_energy_fraction = sol_ctrl%stabilize_energy_fraction
    desc%cfg%step_ref        = step_ref
  END SUBROUTINE SolCtrl_To_SolverDesc

  !---------------------------------------------------------------------------
  ! MD_Solver_SyncFromStep — **时间维 / 动作维**：全步 **Populate** + **事务回滚**
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Solver_SyncFromStep(md_layer, status)
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: s, n_steps, config_id, n_prev, alloc_stat, s2
    INTEGER(i4), ALLOCATABLE :: prev_sid(:)
    TYPE(MD_Solver_Desc), ALLOCATABLE :: bak_cfg(:)
    TYPE(MD_Solver_Desc) :: desc

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Solver_SyncFromStep: md_layer not initialized"
      RETURN
    END IF
    IF (.NOT. md_layer%step%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Solver_SyncFromStep: step domain not initialized"
      RETURN
    END IF
    IF (.NOT. md_layer%solver%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Solver_SyncFromStep: solver domain not initialized"
      RETURN
    END IF
    IF (md_layer%l3Frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Solver_SyncFromStep: L3 frozen; cannot replace solver configs"
      RETURN
    END IF

    n_steps = md_layer%step%n_steps
    IF (n_steps <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    n_prev = md_layer%solver%n_configs
    ALLOCATE(prev_sid(n_steps), STAT=alloc_stat)
    IF (alloc_stat /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Solver_SyncFromStep: allocate prev_sid failed"
      RETURN
    END IF
    DO s = 1, n_steps
      prev_sid(s) = md_layer%step%steps(s)%solver_config_id
    END DO

    IF (n_prev > 0_i4) THEN
      IF (.NOT. ALLOCATED(md_layer%solver%configs)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_Solver_SyncFromStep: solver configs not allocated"
        DEALLOCATE(prev_sid)
        RETURN
      END IF
      IF (n_prev > INT(SIZE(md_layer%solver%configs), i4)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_Solver_SyncFromStep: n_configs exceeds configs allocation"
        DEALLOCATE(prev_sid)
        RETURN
      END IF
      ALLOCATE(bak_cfg(n_prev), STAT=alloc_stat)
      IF (alloc_stat /= 0) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_Solver_SyncFromStep: allocate bak_cfg failed"
        DEALLOCATE(prev_sid)
        RETURN
      END IF
      bak_cfg(1:n_prev) = md_layer%solver%configs(1:n_prev)
    END IF

    ! Idempotent replace: drop current flat configs and step bindings before rebuild.
    md_layer%solver%n_configs = 0_i4
    DO s = 1, n_steps
      md_layer%step%steps(s)%solver_config_id = 0_i4
    END DO

    DO s = 1, n_steps
      CALL SolCtrl_To_SolverDesc(md_layer%step%steps(s)%algo%sol_ctrl, s, desc)
      CALL md_layer%solver%AddConfig(desc, config_id, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        IF (n_prev > 0_i4 .AND. ALLOCATED(bak_cfg)) THEN
          md_layer%solver%configs(1:n_prev) = bak_cfg(1:n_prev)
          md_layer%solver%n_configs = n_prev
        ELSE
          md_layer%solver%n_configs = 0_i4
        END IF
        DO s2 = 1, n_steps
          md_layer%step%steps(s2)%solver_config_id = prev_sid(s2)
        END DO
        IF (ALLOCATED(prev_sid)) DEALLOCATE(prev_sid)
        IF (ALLOCATED(bak_cfg)) DEALLOCATE(bak_cfg)
        IF (LEN_TRIM(status%message) < 1) THEN
          status%message = "MD_Solver_SyncFromStep: AddConfig failed (restored prior solver state)"
        END IF
        RETURN
      END IF
      CALL md_layer%step%SetSolverConfigId(s, config_id, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        IF (n_prev > 0_i4 .AND. ALLOCATED(bak_cfg)) THEN
          md_layer%solver%configs(1:n_prev) = bak_cfg(1:n_prev)
          md_layer%solver%n_configs = n_prev
        ELSE
          md_layer%solver%n_configs = 0_i4
        END IF
        DO s2 = 1, n_steps
          md_layer%step%steps(s2)%solver_config_id = prev_sid(s2)
        END DO
        IF (ALLOCATED(prev_sid)) DEALLOCATE(prev_sid)
        IF (ALLOCATED(bak_cfg)) DEALLOCATE(bak_cfg)
        IF (LEN_TRIM(status%message) < 1) THEN
          status%message = "MD_Solver_SyncFromStep: SetSolverConfigId failed (restored prior solver state)"
        END IF
        RETURN
      END IF
    END DO

    IF (ALLOCATED(prev_sid)) DEALLOCATE(prev_sid)
    IF (ALLOCATED(bak_cfg)) DEALLOCATE(bak_cfg)

    CALL MD_Solv_Sync_CompactConfigs(md_layer%solver)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_SyncFromStep

  !---------------------------------------------------------------------------
  ! MD_Solv_Sync_CompactConfigs — **动作维**：收缩 **`configs(:)`** 容量（**COLD**）
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Solv_Sync_CompactConfigs(dom)
    TYPE(MD_Solver_Domain), INTENT(INOUT) :: dom
    TYPE(MD_Solver_Desc), ALLOCATABLE :: tmp_trim(:)
    INTEGER(i4) :: nc, cap_new, ast

    IF (.NOT. dom%initialized) RETURN
    IF (.NOT. ALLOCATED(dom%configs)) RETURN
    nc = dom%n_configs
    cap_new = MAX(16_i4, nc)
    IF (INT(SIZE(dom%configs), i4) <= cap_new) RETURN

    ALLOCATE(tmp_trim(cap_new), STAT=ast)
    IF (ast /= 0) RETURN
    IF (nc > 0_i4) tmp_trim(1:nc) = dom%configs(1:nc)
    CALL MOVE_ALLOC(tmp_trim, dom%configs)
    dom%capacity = cap_new
  END SUBROUTINE MD_Solv_Sync_CompactConfigs

END MODULE MD_Solv_Sync
