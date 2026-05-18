!===============================================================================
! MODULE:   MD_Amp_Mgr
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Amplitude（域缩 **Amp**）
! ROLE:     _Mgr — 求值门面 / 槽→域 / Legacy 同步 / 再导出（**不**在本文件声明四型本体）
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：_Mgr 编排 + 映射；TYPE 真源在 **MD_Amp_Def** / **MD_Amp_UF**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + *_Arg + 主/辅 / 嵌套·并列·主从）
!       — **本文件**：无新增 `PUBLIC` 四型 TYPE；**主从**为
!           **AUTHORITY（L3）**：**`MD_Amp_Domain`**、**`MD_Amp_Desc`**、**`MD_Amp_State`**、
!           **`MD_Amp_Algo`** 在 **`MD_Amp_Def`** 定义，经 **`USE` 再导出**。
!           **槽侧建模**：**`MD_Amp_Slot_Desc`** / **`MD_Amp_Slot_Ctx`** 在 **`MD_Amp_UF`**；
!           本模块 **再导出** 便于 **`USE MD_Amp_Mgr, ONLY: MD_Amp_Slot_*`**。
!           **UAMP 捆绑**：**`MD_Amp_Eval_*`**、**`MD_Amp_Eval_In`** / **`Out`** 在 **`MD_Amp_UF`**；
!           仅结构化 UAMP 契约（**非**解析 Eval 第二条总线；见 **Amplitude/CONTRACT.md**）。
!           **Ctx**：**不**在本文件单列；**`MD_Amp_Eval_Ctx`** 在 **`MD_Amp_UF`**；L3 容器语境由
!           **`MD_L3_LayerContainer`** / **`md_layer%amplitude`**（若存在）承载。
!       — **SIO（Args）**：**`MD_Amp_*_Arg`**、**`MD_Amp_Apply_*_Arg`** 在 **`MD_Amp_Def`**；
!           **`MD_Amp_Apply_AddAmplitude_MDL`**：`initialized` / **`l3Frozen`** 守卫后转调
!           **`MD_Amp_Apply_Add_Arg`**。
!       — **命名模板**：**`MD_ | PH_ | RT_<域缩>_<Role>_(Desc|State|Algo|Ctx)`**；域缩 **Amp**；
!           **`_Mgr`** = 角色后缀（门面），**≠** FourKind。
!
!   [2] 过程算法（三维度）
!       — **时间维**：**`Amp_GetFactor`**、**`MD_Amp_Apply_EvalAtTime_Arg`**、**`MD_Amp_Slot_To_MD_Desc`**
!           — 标量 **t**、**`TIME_STEP`/`TIME_TOTAL`** 映射、谐波/衰减窗等（数值核见 **`MD_Amp_Def`**）。
!       — **空间维**：**A(t)** 为 **全局标量**；本模块 **无** 单元 / 高斯积分。
!       — **动作维**：**`MD_Amp_SyncFromLegacy`**（Populate / 幂等）、**`MD_Amp_ResolveName`**（Query）、
!           **`amp_md_desc_dealloc_arrays`**（私有，释放 Desc 负载）、Pilot 视图一致性钩。
!
! **依赖**：`MD_Amp_UF`、`MD_Amp_Def`、`MD_L3_Layer`、`MD_Model_Lib_Core`、`IF_Err_Brg`、`IF_Prec_Core`。
! **非依赖**：**不** `USE` **`g_ufc_global`**（全局索引见 **`MD_Amp_Idx`**）。
!===============================================================================

MODULE MD_Amp_Mgr
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
    USE MD_Model_Lib_Core, ONLY: UF_ModelDef
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx, MD_Amp_MATH_PI, &
         MAX_AMPLITUDE_NAME, MAX_AMP_POINTS, MAX_AMPLITUDES, AMPDB_INIT_CAP_DEFAULT, &
         TIME_STEP, TIME_TOTAL, &
         MD_Amp_Eval_In, MD_Amp_Eval_Out, MD_Amp_Eval_Desc, MD_Amp_Eval_Algo, &
         MD_Amp_Eval_Ctx, MD_Amp_Eval_State
    USE MD_Amp_Def, ONLY: MD_Amp_Domain, MD_Amp_Desc, MD_Amp_State, MD_Amp_Algo, &
         AMP_TABULAR, AMP_SMOOTH, AMP_PERIODIC, AMP_MODULATED, AMP_DECAY, AMP_USER, &
         AMP_EQUALLY_SPACED, AMP_RAMP, AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD, &
         INTERP_LINEAR, INTERP_SMOOTH, INTERP_STEP, MD_Amp_GetSummary_Arg, &
         MD_Amp_Add_Arg, MD_Amp_Get_Arg, MD_Amp_EvalAtTime_Arg, &
         MD_Amp_Apply_Add_Arg, MD_Amp_Apply_Get_Arg, &
         MD_Amp_Apply_EvalAtTime_Arg, MD_Amp_Apply_GetSummary_Arg, &
         MD_Amp_Desc_Cfg_View, MD_Amp_Desc_Itr_View, MD_Amp_Desc_Pilot_Views, &
         MD_Amp_Desc_Get_Cfg_View, MD_Amp_Desc_Get_Itr_View, MD_Amp_Desc_Get_Pilot_Views, &
         MD_Amp_Desc_Apply_Cfg_View, MD_Amp_Desc_Apply_Itr_View, MD_Amp_Desc_Apply_Pilot_Views
    IMPLICIT NONE
    
    PRIVATE
    ! --- Legacy UF containers ---
    PUBLIC :: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx, MD_Amp_MATH_PI
    PUBLIC :: MAX_AMPLITUDE_NAME, MAX_AMP_POINTS, MAX_AMPLITUDES, AMPDB_INIT_CAP_DEFAULT
    PUBLIC :: TIME_STEP, TIME_TOTAL
    ! --- AMP_* / INTERP_* re-export (Def-defined; discoverability for USE ... ONLY) ---
    PUBLIC :: AMP_TABULAR, AMP_SMOOTH, AMP_PERIODIC, AMP_MODULATED
    PUBLIC :: AMP_DECAY, AMP_USER
    PUBLIC :: AMP_EQUALLY_SPACED, AMP_RAMP, AMP_SOLUTION_DEPENDENT
    PUBLIC :: AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD
    ! --- UAMP structured bundle (not analytical bus; see Amplitude/CONTRACT.md) ---
    PUBLIC :: MD_Amp_Eval_In, MD_Amp_Eval_Out
    PUBLIC :: MD_Amp_Eval_Desc, MD_Amp_Eval_Algo
    PUBLIC :: MD_Amp_Eval_Ctx, MD_Amp_Eval_State
    ! --- Slot / name factors + Def re-export ---
    PUBLIC :: MD_Amp_GetFactor
    PUBLIC :: Amp_GetFactor
    PUBLIC :: MD_Amp_Algo, MD_Amp_Desc, MD_Amp_State, MD_Amp_Domain
    PUBLIC :: MD_Amp_Desc_Cfg_View, MD_Amp_Desc_Itr_View, MD_Amp_Desc_Pilot_Views
    PUBLIC :: MD_Amp_Desc_Get_Cfg_View, MD_Amp_Desc_Get_Itr_View, MD_Amp_Desc_Get_Pilot_Views
    PUBLIC :: MD_Amp_Desc_Apply_Cfg_View, MD_Amp_Desc_Apply_Itr_View, MD_Amp_Desc_Apply_Pilot_Views
    PUBLIC :: INTERP_LINEAR, INTERP_SMOOTH, INTERP_STEP
    PUBLIC :: MD_Amp_GetSummary_Arg
    PUBLIC :: MD_Amp_Slot_To_MD_Desc
    ! --- SIO *_Arg + Apply_* (Principle #14) ---
    PUBLIC :: MD_Amp_Add_Arg, MD_Amp_Get_Arg, &
              MD_Amp_EvalAtTime_Arg
    PUBLIC :: MD_Amp_Apply_Add_Arg, MD_Amp_Apply_AddAmplitude_MDL, &
              MD_Amp_Apply_Get_Arg, &
              MD_Amp_Apply_EvalAtTime_Arg, MD_Amp_Apply_GetSummary_Arg
    PUBLIC :: MD_Amp_SyncFromLegacy, MD_Amp_ResolveName

CONTAINS

    !===========================================================================
    ! [P] _Mgr — SIO 守卫 / A(t) / UF→MD / Legacy 同步（过程入口总览）
    !===========================================================================

    !===========================================================================
    ! MD_Amp_Apply_AddAmplitude_MDL — Harness / Bridge path with L3 freeze guard
    !   Prefer over raw **`MD_Amp_Apply_Add_Arg`** when **`md_layer`** is in scope.
    !===========================================================================
    SUBROUTINE MD_Amp_Apply_AddAmplitude_MDL(md_layer, arg)
      TYPE(MD_L3_LayerContainer),            INTENT(IN)    :: md_layer
      TYPE(MD_Amp_Add_Arg), INTENT(INOUT) :: arg

      CALL init_error_status(arg%status)
      IF (.NOT. md_layer%initialized) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "MD_Amp_Apply_AddAmplitude_MDL: md_layer not initialized"
        RETURN
      END IF
      IF (md_layer%l3Frozen) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "L3 frozen: AddAmplitude not allowed"
        RETURN
      END IF
      CALL MD_Amp_Apply_Add_Arg(md_layer%amplitude, arg)
    END SUBROUTINE MD_Amp_Apply_AddAmplitude_MDL

    !===========================================================================
    ! Amp_GetFactor — CONTRACT Amplitude/CONTRACT.md: slot-indexed A(t)
    !   1) Optional amp_dom: MD_Amp_Domain%EvalAtTime when initialized and id in range.
    !   2) Else UF array slot amplitudes(id)%evaluate(time) when allocated and in range.
    !   3) Else fac = 1. Domain branch only on IF_STATUS_OK (unknown amp_type -> INVALID -> UF).
    ! L5: RT_Amp_FactorAt passes md_layer%amplitude as amp_dom when g_ufc_global%IsReady().
    !===========================================================================
    FUNCTION Amp_GetFactor(amplitudes, amplitudeId, time, amp_dom) RESULT(fac)
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE, INTENT(IN) :: amplitudes(:)
        INTEGER(i4), INTENT(IN) :: amplitudeId
        REAL(wp), INTENT(IN) :: time
        TYPE(MD_Amp_Domain), INTENT(IN), OPTIONAL :: amp_dom
        REAL(wp) :: fac
        TYPE(MD_Amp_EvalAtTime_Arg) :: ev_arg

        IF (amplitudeId <= 0_i4) THEN
            fac = 1.0_wp
            RETURN
        END IF

        IF (PRESENT(amp_dom)) THEN
            IF (amp_dom%initialized) THEN
                IF (amplitudeId >= 1_i4 .AND. amplitudeId <= amp_dom%n_amplitudes) THEN
                    ev_arg%time = time
                    CALL MD_Amp_Apply_EvalAtTime_Arg(amp_dom, amplitudeId, ev_arg)
                    IF (ev_arg%status%status_code == IF_STATUS_OK) THEN
                        fac = ev_arg%value
                        RETURN
                    END IF
                END IF
            END IF
        END IF

        IF (.NOT. ALLOCATED(amplitudes)) THEN
            fac = 1.0_wp
            RETURN
        END IF
        IF (amplitudeId > SIZE(amplitudes)) THEN
            fac = 1.0_wp
            RETURN
        END IF
        fac = amplitudes(amplitudeId)%evaluate(time)
    END FUNCTION Amp_GetFactor


    !===========================================================================
    ! MD_Amp_GetFactor — 按名 A(t)（槽 Ctx）；无 g_ufc_global（槽索引优先 Amp_GetFactor）
    !===========================================================================
    !> @brief A(t) by name via MD_Amp_Slot_Ctx (legacy helper; prefer Amp_GetFactor + domain).
    !! @param[out] factor A(t); unknown name -> 1 (via ampdb_evaluate default).
    !! @note Name-based path only; slot-indexed loads use Amp_GetFactor(..., amp_dom=...).
    FUNCTION MD_Amp_GetFactor(amplitudeDB, amplitudeName, time) RESULT(factor)
        TYPE(MD_Amp_Slot_Ctx), INTENT(IN) :: amplitudeDB
        CHARACTER(LEN=*), INTENT(IN) :: amplitudeName
        REAL(wp), INTENT(IN) :: time
        REAL(wp) :: factor
        
        ! Use existing ampdb_evaluate function
        factor = amplitudeDB%evaluate(TRIM(amplitudeName), time)
        
    END FUNCTION MD_Amp_GetFactor

    !> Deallocate allocatable payload on MD_Amp_Desc (Slot_to_MD and tabular refresh).
    SUBROUTINE amp_md_desc_dealloc_arrays(d)
        TYPE(MD_Amp_Desc), INTENT(INOUT) :: d

        IF (ALLOCATED(d%time_data)) DEALLOCATE(d%time_data)
        IF (ALLOCATED(d%value_data)) DEALLOCATE(d%value_data)
        IF (ALLOCATED(d%fourier_a)) DEALLOCATE(d%fourier_a)
        IF (ALLOCATED(d%fourier_b)) DEALLOCATE(d%fourier_b)
    END SUBROUTINE amp_md_desc_dealloc_arrays

    !> Regression guard: pilot cfg/itr views must mirror flat **MD_Amp_Desc** scalars.
    PURE FUNCTION amp_md_pilot_views_match_flat(pv, d) RESULT(ok)
        TYPE(MD_Amp_Desc_Pilot_Views), INTENT(IN) :: pv
        TYPE(MD_Amp_Desc), INTENT(IN) :: d
        LOGICAL :: ok

        ok = (pv%cfg%name == d%name) .AND. &
            (pv%cfg%amp_id == d%amp_id) .AND. &
            (pv%cfg%amp_type == d%amp_type) .AND. &
            (pv%cfg%definition == d%definition) .AND. &
            (pv%cfg%n_points == d%n_points) .AND. &
            (pv%cfg%smooth .EQV. d%smooth) .AND. &
            (pv%cfg%tabular_extrapolate .EQV. d%tabular_extrapolate) .AND. &
            (pv%cfg%interp_method == d%interp_method) .AND. &
            (pv%itr%omega == d%omega) .AND. &
            (pv%itr%periodic_t0 == d%periodic_t0) .AND. &
            (pv%itr%n_fourier == d%n_fourier) .AND. &
            (pv%itr%decay_a0 == d%decay_a0) .AND. &
            (pv%itr%decay_a1 == d%decay_a1) .AND. &
            (pv%itr%decay_t0 == d%decay_t0) .AND. &
            (pv%itr%decay_td == d%decay_td) .AND. &
            (pv%itr%mod_carr_freq == d%mod_carr_freq) .AND. &
            (pv%itr%mod_carr_amp == d%mod_carr_amp) .AND. &
            (pv%itr%mod_carr_phase == d%mod_carr_phase) .AND. &
            (pv%itr%mod_fm == d%mod_fm) .AND. &
            (pv%itr%mod_depth == d%mod_depth) .AND. &
            (pv%itr%smooth_t1 == d%smooth_t1) .AND. &
            (pv%itr%smooth_t2 == d%smooth_t2) .AND. &
            (pv%itr%smooth_a1 == d%smooth_a1) .AND. &
            (pv%itr%smooth_a2 == d%smooth_a2) .AND. &
            (pv%itr%ramp_t_end == d%ramp_t_end)
    END FUNCTION amp_md_pilot_views_match_flat

    SUBROUTINE amp_md_pilot_mismatch_hook()
    END SUBROUTINE amp_md_pilot_mismatch_hook

    !> Copy MD_Amp_Slot_Desc into MD_Amp_Desc for Domain / LoadBC path (also used by Sync + tests).
    SUBROUTINE MD_Amp_Slot_To_MD_Desc(slot_desc, md_desc)
        TYPE(MD_Amp_Slot_Desc), INTENT(IN)  :: slot_desc
        TYPE(MD_Amp_Desc),     INTENT(OUT) :: md_desc
        INTEGER(i4) :: np

        md_desc%name   = TRIM(slot_desc%name)
        md_desc%amp_id = 0_i4
        md_desc%amp_type = slot_desc%amp_type
        md_desc%definition = MERGE(1_i4, 0_i4, slot_desc%time_type == TIME_TOTAL)
        md_desc%n_points = 0_i4
        md_desc%smooth  = .FALSE.
        md_desc%tabular_extrapolate = .FALSE.
        md_desc%interp_method = INTERP_LINEAR
        md_desc%omega   = 0.0_wp
        md_desc%periodic_t0 = 0.0_wp
        md_desc%n_fourier   = 0_i4
        md_desc%decay_a0 = 0.0_wp
        md_desc%decay_a1 = 1.0_wp
        md_desc%decay_t0 = 0.0_wp
        md_desc%decay_td = 1.0_wp
        md_desc%mod_carr_freq  = 0.0_wp
        md_desc%mod_carr_amp   = 0.0_wp
        md_desc%mod_carr_phase = 0.0_wp
        md_desc%mod_fm         = 0.0_wp
        md_desc%mod_depth      = 0.0_wp
        md_desc%smooth_t1 = 0.0_wp
        md_desc%smooth_t2 = 1.0_wp
        md_desc%smooth_a1 = 0.0_wp
        md_desc%smooth_a2 = 1.0_wp
        md_desc%ramp_t_end = 1.0_wp

        SELECT CASE (slot_desc%amp_type)
        CASE (AMP_TABULAR)
            np = slot_desc%num_points
            md_desc%tabular_extrapolate = slot_desc%tabular_extrapolate
            IF (np > 0_i4 .AND. ALLOCATED(slot_desc%time) .AND. ALLOCATED(slot_desc%value)) THEN
                np = MIN(np, INT(SIZE(slot_desc%time), i4), INT(SIZE(slot_desc%value), i4))
                CALL amp_md_desc_dealloc_arrays(md_desc)
                md_desc%n_points = np
                ALLOCATE(md_desc%time_data(np))
                ALLOCATE(md_desc%value_data(np))
                md_desc%time_data(1:np)  = slot_desc%time(1:np)
                md_desc%value_data(1:np) = slot_desc%value(1:np)
            END IF
        CASE (AMP_SMOOTH)
            md_desc%amp_type = AMP_SMOOTH
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%n_fourier = 0_i4
            md_desc%smooth_t1 = slot_desc%smooth_t1
            md_desc%smooth_t2 = slot_desc%smooth_t2
            md_desc%smooth_a1 = slot_desc%smooth_a1
            md_desc%smooth_a2 = slot_desc%smooth_a2
        CASE (AMP_RAMP)
            md_desc%amp_type = AMP_RAMP
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%ramp_t_end = MAX(slot_desc%ramp_t_end, TINY(1.0_wp))
        CASE (AMP_PERIODIC)
            md_desc%amp_type = AMP_PERIODIC
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%omega       = 2.0_wp * MD_Amp_MATH_PI * slot_desc%periodic_freq
            md_desc%periodic_t0 = 0.0_wp
            md_desc%n_fourier   = 1_i4
            ALLOCATE(md_desc%fourier_a(2))
            ALLOCATE(md_desc%fourier_b(1))
            md_desc%fourier_a(1) = slot_desc%periodic_offset
            md_desc%fourier_a(2) = slot_desc%periodic_amp * SIN(slot_desc%periodic_phase)
            md_desc%fourier_b(1) = slot_desc%periodic_amp * COS(slot_desc%periodic_phase)
        CASE (AMP_DECAY)
            md_desc%amp_type = AMP_DECAY
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%decay_a0 = 0.0_wp
            md_desc%decay_a1 = slot_desc%decay_a0
            md_desc%decay_t0 = 0.0_wp
            md_desc%decay_td = MERGE(1.0_wp / slot_desc%decay_rate, 1.0_wp, slot_desc%decay_rate > TINY(1.0_wp))
        CASE (AMP_MODULATED)
            md_desc%amp_type = AMP_MODULATED
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%n_fourier = 0_i4
            md_desc%omega = 0.0_wp
            md_desc%mod_carr_freq  = slot_desc%periodic_freq
            md_desc%mod_carr_amp   = slot_desc%periodic_amp
            md_desc%mod_carr_phase = slot_desc%periodic_phase
            md_desc%mod_fm         = slot_desc%modulated_freq
            md_desc%mod_depth      = slot_desc%modulated_depth
        CASE (AMP_USER)
            ! Domain EvalAtTime uses amp_state%currentValue (WriteBack / solver); no tabular mirror.
            md_desc%amp_type = AMP_USER
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%n_fourier = 0_i4
            md_desc%tabular_extrapolate = .FALSE.
        CASE (AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD)
            ! CONTRACT: neutral 1.0 in domain; strip tabular/Fourier so EvalAtTime hits explicit CASE.
            CALL amp_md_desc_dealloc_arrays(md_desc)
            md_desc%n_points = 0_i4
            md_desc%n_fourier = 0_i4
            md_desc%tabular_extrapolate = .FALSE.
        CASE DEFAULT
            ! Unknown amp_type: mirror tabular pairs when present; else leave header fields from slot_desc.
            np = slot_desc%num_points
            md_desc%tabular_extrapolate = slot_desc%tabular_extrapolate
            IF (np > 0_i4 .AND. ALLOCATED(slot_desc%time) .AND. ALLOCATED(slot_desc%value)) THEN
                np = MIN(np, INT(SIZE(slot_desc%time), i4), INT(SIZE(slot_desc%value), i4))
                md_desc%amp_type = AMP_TABULAR
                CALL amp_md_desc_dealloc_arrays(md_desc)
                md_desc%n_points = np
                ALLOCATE(md_desc%time_data(np))
                ALLOCATE(md_desc%value_data(np))
                md_desc%time_data(1:np)  = slot_desc%time(1:np)
                md_desc%value_data(1:np) = slot_desc%value(1:np)
            END IF
        END SELECT
        ! Pilot cfg/itr mirror on UF→MD hot path (bridge may read pv; flat md_desc + DP unchanged).
        ASSOCIATE (pv => MD_Amp_Desc_Get_Pilot_Views(md_desc))
            IF (.NOT. amp_md_pilot_views_match_flat(pv, md_desc)) CALL amp_md_pilot_mismatch_hook()
        END ASSOCIATE
    END SUBROUTINE MD_Amp_Slot_To_MD_Desc

    !===========================================================================
    ! MD_Amp_SyncFromLegacy — Legacy **`UF_ModelDef%amplitudes`** → **`md_layer%amplitude`**
    !   时间维：无单独 t；动作维：Populate / 幂等早退；守卫：**`initialized`** / **`l3Frozen`**
    !===========================================================================
    SUBROUTINE MD_Amp_SyncFromLegacy(model_def, md_layer, status)
      TYPE(UF_ModelDef),           INTENT(IN)    :: model_def
      TYPE(MD_L3_LayerContainer),    INTENT(INOUT) :: md_layer
      TYPE(ErrorStatusType),       INTENT(OUT)   :: status

      INTEGER(i4) :: i, n_amp
      TYPE(MD_Amp_Desc) :: md_desc

      CALL init_error_status(status)
      IF (.NOT. md_layer%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_Amp_SyncFromLegacy: md_layer not initialized"
        RETURN
      END IF
      IF (md_layer%l3Frozen) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_Amp_SyncFromLegacy: L3 frozen; cannot add amplitudes"
        RETURN
      END IF

      IF (.NOT. md_layer%amplitude%initialized) RETURN
      IF (md_layer%amplitude%n_amplitudes > 0_i4) THEN
        status%status_code = IF_STATUS_OK
        RETURN
      END IF

      n_amp = model_def%num_amplitudes
      IF (n_amp <= 0) THEN
        status%status_code = IF_STATUS_OK
        RETURN
      END IF

      IF (.NOT. ALLOCATED(model_def%amplitudes)) THEN
        status%status_code = IF_STATUS_OK
        RETURN
      END IF

      IF (n_amp > SIZE(model_def%amplitudes)) n_amp = SIZE(model_def%amplitudes)

      DO i = 1, n_amp
        CALL MD_Amp_Slot_To_MD_Desc(model_def%amplitudes(i), md_desc)
        CALL md_layer%amplitude%AddAmplitude(md_desc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO

      status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Amp_SyncFromLegacy

    !===========================================================================
    ! MD_Amp_ResolveName — 按 **`name`** 解析槽索引（Query / 动作维；无时间维）
    !===========================================================================
    PURE FUNCTION MD_Amp_ResolveName(md_layer, name) RESULT(amp_ref)
      TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer
      CHARACTER(LEN=*),          INTENT(IN) :: name
      INTEGER(i4) :: amp_ref
      INTEGER(i4) :: j

      amp_ref = 0_i4
      IF (.NOT. md_layer%amplitude%initialized) RETURN
      IF (LEN_TRIM(name) == 0) RETURN
      IF (md_layer%amplitude%n_amplitudes < 1) RETURN
      IF (.NOT. ALLOCATED(md_layer%amplitude%amplitudes)) RETURN

      DO j = 1, md_layer%amplitude%n_amplitudes
        IF (TRIM(md_layer%amplitude%amplitudes(j)%name) == TRIM(name)) THEN
          amp_ref = j
          RETURN
        END IF
      END DO
    END FUNCTION MD_Amp_ResolveName

END MODULE MD_Amp_Mgr