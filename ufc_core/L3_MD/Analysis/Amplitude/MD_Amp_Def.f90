!===============================================================================
! MODULE:   MD_Amp_Def
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Amplitude（域缩 **Amp**）
! ROLE:     _Def — TYPE / Arg / Domain(TBP) / 纯函数过程核
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件示例）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + *_Arg + 主/辅）—— **本文件声明顺序**
!       [A] 常量 → [B] **辅** Desc（话题并列）→ [C] **主** Algo → [D] **主** Desc（AUTHORITY）
!       → [E] **主** State + **辅**嵌套 inc → [F] **辅** Desc 视图（cfg∥itr）
!       → [G] *_Arg（SIO）→ [H] **Domain**（TBP 金线）
!
!       命名模板（L3）：`MD_<Amp>_<Role>_<FourKind>`，FourKind ∈ Desc | State | Algo | Ctx
!       — **主**：`MD_Amp_Desc`、`MD_Amp_State`、`MD_Amp_Algo`
!       — **辅 Desc（并列）**：`MD_Amp_Tabular_Desc`、`MD_Amp_User_Desc`、`MD_Amp_Periodic_Desc`、`MD_Amp_Modulated_Desc`
!       — **辅嵌套**：`MD_Amp_State % inc` → `MD_Amp_Inc_Evo_State`
!       — **辅视图**：`MD_Amp_Desc_*_View`、`MD_Amp_Desc_Pilot_Views`
!       — **Ctx**：未单列 TYPE；积分/查询上下文在 `EvalAtTime` 实现内与 `*_Arg`
!       — **SIO**：`MD_Amp_*_Arg`、`MD_Amp_Apply_*_Arg`
!       — **Domain**：`MD_Amp_Domain`
!   [2] 过程算法（三维度 —— Amplitude 域以「时间 t」为主独立变量）
!       — **时间维**：`EvalAtTime`、衰减/周期/调制/RAMP/SMOOTH_STEP 等分支；增量演化见 `inc`
!       — **空间维**：本域为 **全局标量因子 A(t)**，无单元/高斯积分（与载荷域网格积分对照）
!       — **动作维**：插值/外推/阶跃/平滑阶跃（tabular vs STEP）、SymTbl 注册、Populate/WriteBack
!
!   纯函数核（可共享 PH/L6）：`MD_AmpShared_*` — Tabular / Step / SmoothStep / RampUnit / Modulated
!
! Pilot：**MD_Amp_Desc** 扁平面字段顺序固定，`MD_Amp_DP_RegisterStructType` offset 不得破坏；
! **cfg/itr** 逻辑视图仅在本 MODULE。
!===============================================================================

MODULE MD_Amp_Def
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, &
                        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  USE IF_Base_SymTbl, ONLY: register_variable, symbol_table_exists, &
                            IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_STRUCT
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_AmpShared_TabularEval, MD_AmpShared_StepEval, MD_AmpShared_SmoothStep, MD_AmpShared_RampUnit, MD_AmpShared_Modulated
  PUBLIC :: MD_Amp_Inc_Evo_State
  PUBLIC :: MD_Amp_Add_Arg, MD_Amp_Get_Arg, MD_Amp_EvalAtTime_Arg
  PUBLIC :: MD_Amp_Apply_Add_Arg, MD_Amp_Apply_Get_Arg, &
              MD_Amp_Apply_EvalAtTime_Arg, MD_Amp_Apply_GetSummary_Arg
  PUBLIC :: MD_Amp_Desc_Cfg_View, MD_Amp_Desc_Itr_View, MD_Amp_Desc_Pilot_Views
  PUBLIC :: MD_Amp_Desc_Get_Cfg_View, MD_Amp_Desc_Get_Itr_View, MD_Amp_Desc_Get_Pilot_Views
  PUBLIC :: MD_Amp_Desc_Apply_Cfg_View, MD_Amp_Desc_Apply_Itr_View, MD_Amp_Desc_Apply_Pilot_Views

  !===========================================================================
  ! [A] Constants — amp_type / interp_kind（MD_Amp_Desc / EvalAtTime）
  !===========================================================================

  ! Constants (needed by MD_Amp_Desc, MD_Amp_Domain); kinds aligned with IF_Prec i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_TABULAR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_SMOOTH = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_PERIODIC = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_MODULATED = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_DECAY = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_RAMP = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_SOLUTION_DEPENDENT = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_ACTUATOR = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_SPECTRUM = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_USER = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_PSD = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_EQUALLY_SPACED = AMP_TABULAR
  INTEGER(i4), PARAMETER, PUBLIC :: INTERP_LINEAR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: INTERP_SMOOTH = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: INTERP_STEP   = 3_i4

  !===========================================================================
  ! [B] Desc — 话题并列辅 TYPE（解析/专用语义；非 MD_Amp_Desc DP 注册体）
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Tabular_Desc
  ! ROLE:   Desc（辅）
  ! NOTE:  Tabular — piecewise (t, A) pairs.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Tabular_Desc
    CHARACTER(LEN=80)     :: amp_name       = ' '
    INTEGER(i4)           :: n_points       = 0_i4
    REAL(wp), ALLOCATABLE :: t_vals(:)
    REAL(wp), ALLOCATABLE :: a_vals(:)
    INTEGER(i4)           :: interp_method  = INTERP_LINEAR
    LOGICAL               :: smooth         = .FALSE.
    LOGICAL               :: extrapolate    = .FALSE.
    LOGICAL               :: is_active      = .FALSE.
  END TYPE MD_Amp_Tabular_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_User_Desc
  ! ROLE:   Desc（辅）
  ! NOTE:  User-defined — UAMP/VUAMP callback descriptor.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_User_Desc
    CHARACTER(LEN=80)     :: amp_name     = ' '
    LOGICAL               :: use_vuamp    = .FALSE.
    INTEGER(i4)           :: nprops       = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4)           :: nsvars       = 0_i4
    LOGICAL               :: is_active    = .FALSE.
  END TYPE MD_Amp_User_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Periodic_Desc
  ! ROLE:   Desc（辅）
  ! NOTE:  Periodic — sinusoidal / Fourier series.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Periodic_Desc
    CHARACTER(LEN=80)     :: amp_name    = ' '
    INTEGER(i4)           :: n_terms     = 0_i4
    REAL(wp)              :: omega       = 0.0_wp
    REAL(wp)              :: t0          = 0.0_wp
    REAL(wp)              :: a0          = 0.0_wp
    REAL(wp), ALLOCATABLE :: a_coeff(:)
    REAL(wp), ALLOCATABLE :: b_coeff(:)
    LOGICAL               :: is_active   = .FALSE.
  END TYPE MD_Amp_Periodic_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Modulated_Desc
  ! ROLE:   Desc（辅）
  ! NOTE:  Modulated — carrier × envelope product.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Modulated_Desc
    CHARACTER(LEN=80) :: amp_name          = ' '
    CHARACTER(LEN=80) :: carrier_amp_name  = ' '
    CHARACTER(LEN=80) :: envelope_amp_name = ' '
    REAL(wp)          :: scale_carrier     = 1.0_wp
    REAL(wp)          :: scale_envelope    = 1.0_wp
    LOGICAL           :: is_active         = .FALSE.
  END TYPE MD_Amp_Modulated_Desc

  !===========================================================================
  ! [C] Algo — 主 TYPE（域级默认插值/算法开关）
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Algo
  ! ROLE:   Algo（主）
  ! NOTE:  域级默认插值策略；具体条目可在 MD_Amp_Desc % interp_method 覆盖。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Algo
    INTEGER(i4) :: interpolation_method = INTERP_LINEAR
  END TYPE MD_Amp_Algo

  !===========================================================================
  ! [D] Desc — 主 TYPE（AUTHORITY · DP 扁平面）
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Desc
  ! ROLE:   Desc（主）
  ! NOTE:  统一幅值描述 — tabular / periodic / decay / modulated / ramp / smooth …
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: amp_id     = 0_i4
    INTEGER(i4)       :: amp_type   = AMP_TABULAR
    INTEGER(i4)       :: definition = 0_i4
    REAL(wp), ALLOCATABLE :: time_data(:)
    REAL(wp), ALLOCATABLE :: value_data(:)
    INTEGER(i4)           :: n_points = 0_i4
    LOGICAL               :: smooth   = .FALSE.
    REAL(wp)              :: omega       = 0.0_wp
    REAL(wp)              :: periodic_t0 = 0.0_wp
    INTEGER(i4)           :: n_fourier   = 0_i4
    REAL(wp), ALLOCATABLE :: fourier_a(:)
    REAL(wp), ALLOCATABLE :: fourier_b(:)
    REAL(wp) :: decay_a0 = 0.0_wp
    REAL(wp) :: decay_a1 = 1.0_wp
    REAL(wp) :: decay_t0 = 0.0_wp
    REAL(wp) :: decay_td = 1.0_wp
    ! AMP_MODULATED (aligned with MD_Amp_Slot_Desc / MD_Amp_Desc):
    ! A(t) = mod_carr_amp*sin(2*pi*mod_carr_freq*t + mod_carr_phase) * [1 + mod_depth*sin(2*pi*mod_fm*t)]
    REAL(wp) :: mod_carr_freq  = 0.0_wp
    REAL(wp) :: mod_carr_amp   = 0.0_wp
    REAL(wp) :: mod_carr_phase = 0.0_wp
    REAL(wp) :: mod_fm        = 0.0_wp
    REAL(wp) :: mod_depth     = 0.0_wp
    ! Tabular: match MD_Amp_Slot_Desc%tabular_extrapolate when filled from Sync/API
    LOGICAL :: tabular_extrapolate = .FALSE.
    INTEGER(i4) :: interp_method = INTERP_LINEAR  ! Interpolation: LINEAR/SMOOTH/STEP
    ! Native AMP_SMOOTH / AMP_RAMP (avoid relying on tabular compression)
    REAL(wp) :: smooth_t1 = 0.0_wp
    REAL(wp) :: smooth_t2 = 1.0_wp
    REAL(wp) :: smooth_a1 = 0.0_wp
    REAL(wp) :: smooth_a2 = 1.0_wp
    REAL(wp) :: ramp_t_end = 1.0_wp
  END TYPE MD_Amp_Desc

  !===========================================================================
  ! [E] State — 主 TYPE + 辅嵌套（inc）
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Inc_Evo_State
  ! ROLE:   State（辅 · 嵌套）
  ! NOTE:  Step / increment 跟踪（Populate·WriteBack 数据链）。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Inc_Evo_State
    INTEGER(i4) :: step_idx  = 0_i4
    INTEGER(i4) :: incr_idx = 0_i4
  END TYPE MD_Amp_Inc_Evo_State

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_State
  ! ROLE:   State（主）
  ! NOTE:  Runtime — A(t) 当前值、查询时刻、分段索引；**嵌套** `inc`。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_State
    REAL(wp)    :: currentValue = 0.0_wp
    REAL(wp)    :: currentTime  = 0.0_wp
    INTEGER(i4) :: currentIndex = 1_i4
    TYPE(MD_Amp_Inc_Evo_State) :: inc
  END TYPE MD_Amp_State

  !===========================================================================
  ! [F] Desc — Pilot 视图（cfg / itr 并列切片；ALLOCATABLE 列不在 DP 扁平面）
  !===========================================================================

  TYPE, PUBLIC :: MD_Amp_Desc_Cfg_View
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: amp_id = 0_i4
    INTEGER(i4)       :: amp_type = 0_i4
    INTEGER(i4)       :: definition = 0_i4
    INTEGER(i4)       :: n_points = 0_i4
    LOGICAL           :: smooth = .FALSE.
    LOGICAL           :: tabular_extrapolate = .FALSE.
    INTEGER(i4)       :: interp_method = 0_i4
  END TYPE MD_Amp_Desc_Cfg_View

  TYPE, PUBLIC :: MD_Amp_Desc_Itr_View
    REAL(wp)    :: omega = 0.0_wp
    REAL(wp)    :: periodic_t0 = 0.0_wp
    INTEGER(i4) :: n_fourier = 0_i4
    REAL(wp)    :: decay_a0 = 0.0_wp
    REAL(wp)    :: decay_a1 = 0.0_wp
    REAL(wp)    :: decay_t0 = 0.0_wp
    REAL(wp)    :: decay_td = 0.0_wp
    REAL(wp)    :: mod_carr_freq = 0.0_wp
    REAL(wp)    :: mod_carr_amp = 0.0_wp
    REAL(wp)    :: mod_carr_phase = 0.0_wp
    REAL(wp)    :: mod_fm = 0.0_wp
    REAL(wp)    :: mod_depth = 0.0_wp
    REAL(wp)    :: smooth_t1 = 0.0_wp
    REAL(wp)    :: smooth_t2 = 0.0_wp
    REAL(wp)    :: smooth_a1 = 0.0_wp
    REAL(wp)    :: smooth_a2 = 0.0_wp
    REAL(wp)    :: ramp_t_end = 0.0_wp
  END TYPE MD_Amp_Desc_Itr_View

  TYPE, PUBLIC :: MD_Amp_Desc_Pilot_Views
    TYPE(MD_Amp_Desc_Cfg_View) :: cfg
    TYPE(MD_Amp_Desc_Itr_View) :: itr
  END TYPE MD_Amp_Desc_Pilot_Views

  !===========================================================================
  ! [G] SIO Arg bundles — `MD_Amp_<Verb>_Arg` + Principle #14 `Apply_*`
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_GetSummary_Arg
  ! ROLE:   Arg
  ! NOTE:  GetSummary — 摘要字符串 + 状态。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Add_Arg
  ! ROLE:   Arg
  ! NOTE:  Add — Desc [IN]，分配索引 [OUT]。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Add_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [IN]  amplitude descriptor
    INTEGER(i4)           :: amp_idx = 0_i4 ! [OUT] assigned 1-based index on OK
    TYPE(ErrorStatusType) :: status         ! [OUT] AddAmplitude / capacity result
  END TYPE MD_Amp_Add_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Get_Arg
  ! ROLE:   Arg
  ! NOTE:  Get — Desc [OUT]。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Get_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [OUT] amplitude descriptor
    TYPE(ErrorStatusType) :: status         ! [OUT] range / init result
  END TYPE MD_Amp_Get_Arg

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_EvalAtTime_Arg
  ! ROLE:   Arg
  ! NOTE:  EvalAtTime — t [IN]，A(t) [OUT]。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_EvalAtTime_Arg
    REAL(wp)              :: time  = 0.0_wp   ! [IN]  query time t
    REAL(wp)              :: value = 0.0_wp  ! [OUT] A(t)
    INTEGER(i4)           :: step_idx = 0_i4 ! [IN]  trace only (Apply_* does not WriteBack)
    INTEGER(i4)           :: incr_idx = 0_i4 ! [IN]  trace only
    TYPE(ErrorStatusType) :: status            ! [OUT] EvalAtTime result
  END TYPE MD_Amp_EvalAtTime_Arg

  !===========================================================================
  ! [H] Domain — 金线 TBP（聚合 Desc[] / State[] / Algo；过程入口）
  !===========================================================================

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Amp_Domain
  ! ROLE:   Domain（≠ 单一 FourKind；柱内容器）
  ! NOTE:  全模型幅值表 + 并行 State + 域默认 Algo；TBP 绑定见下。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Amp_Domain
    TYPE(MD_Amp_Desc), ALLOCATABLE  :: amplitudes(:)
    INTEGER(i4)                     :: n_amplitudes = 0_i4
    INTEGER(i4)                     :: capacity     = 0_i4
    TYPE(MD_Amp_State), ALLOCATABLE :: amp_state(:)
    TYPE(MD_Amp_Algo) :: algo
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddAmplitude => Add
    PROCEDURE :: GetAmplitude => Get
    PROCEDURE :: EvalAtTime
    PROCEDURE :: WriteBack
    PROCEDURE :: GetSummary
  END TYPE MD_Amp_Domain

CONTAINS

  !===========================================================================
  ! [P] 过程算法 — Pure FUNCTION 核（时间维 · A(t) 标量）
  !===========================================================================

  !> Piecewise linear tabular A(t); shared with UF **`evaluate`** (CONTRACT).
  PURE FUNCTION MD_AmpShared_TabularEval(np, td, vd, extrap, smooth, t) RESULT(value)
    INTEGER(i4), INTENT(IN) :: np
    REAL(wp), INTENT(IN) :: td(:), vd(:)
    LOGICAL, INTENT(IN) :: extrap, smooth
    REAL(wp), INTENT(IN) :: t
    REAL(wp) :: value
    INTEGER(i4) :: i
    REAL(wp) :: xi

    value = 1.0_wp
    IF (np < 1_i4) RETURN
    IF (np == 1_i4) THEN
      value = vd(1)
      RETURN
    END IF

    IF (t < td(1)) THEN
      IF (extrap .AND. np >= 2_i4) THEN
        xi = td(2) - td(1)
        IF (ABS(xi) > EPSILON(1.0_wp)) THEN
          value = vd(1) + (t - td(1)) * (vd(2) - vd(1)) / xi
        ELSE
          value = vd(1)
        END IF
      ELSE
        value = vd(1)
      END IF
      RETURN
    END IF

    IF (t > td(np)) THEN
      IF (extrap .AND. np >= 2_i4) THEN
        xi = td(np) - td(np - 1)
        IF (ABS(xi) > EPSILON(1.0_wp)) THEN
          value = vd(np) + (t - td(np)) * (vd(np) - vd(np - 1)) / xi
        ELSE
          value = vd(np)
        END IF
      ELSE
        value = vd(np)
      END IF
      RETURN
    END IF

    DO i = 1_i4, np - 1_i4
      IF (t >= td(i) .AND. t < td(i + 1)) THEN
        ! Degenerate breakpoints (td(i+1)==td(i)): avoid div-by-zero; hold left value.
        IF (ABS(td(i + 1) - td(i)) <= EPSILON(1.0_wp) * (1.0_wp + ABS(td(i)))) THEN
          value = vd(i)
        ELSE
          xi = (t - td(i)) / (td(i + 1) - td(i))
          IF (smooth) xi = 3.0_wp * xi**2 - 2.0_wp * xi**3
          value = vd(i) + (vd(i + 1) - vd(i)) * xi
        END IF
        RETURN
      END IF
    END DO
    value = vd(np)
  END FUNCTION MD_AmpShared_TabularEval

  !> Step (piecewise-constant) tabular A(t): hold previous time-point value.
  PURE FUNCTION MD_AmpShared_StepEval(np, td, vd, extrap, t) RESULT(value)
    INTEGER(i4), INTENT(IN) :: np
    REAL(wp), INTENT(IN) :: td(:), vd(:)
    LOGICAL, INTENT(IN) :: extrap
    REAL(wp), INTENT(IN) :: t
    REAL(wp) :: value
    INTEGER(i4) :: i

    value = 1.0_wp
    IF (np < 1_i4) RETURN
    IF (np == 1_i4) THEN
      value = vd(1)
      RETURN
    END IF

    ! Before first point
    IF (t < td(1)) THEN
      IF (extrap) THEN
        value = vd(1)   ! Step: hold first value for extrapolation
      ELSE
        value = vd(1)
      END IF
      RETURN
    END IF

    ! After last point
    IF (t >= td(np)) THEN
      value = vd(np)
      RETURN
    END IF

    ! Interior: hold value of left breakpoint (step / piecewise-constant)
    DO i = 1_i4, np - 1_i4
      IF (t >= td(i) .AND. t < td(i + 1)) THEN
        value = vd(i)
        RETURN
      END IF
    END DO
    value = vd(np)
  END FUNCTION MD_AmpShared_StepEval

  PURE FUNCTION MD_AmpShared_SmoothStep(t1, t2, a1, a2, t) RESULT(value)
    REAL(wp), INTENT(IN) :: t1, t2, a1, a2, t
    REAL(wp) :: value
    REAL(wp) :: xi, s

    IF (t <= t1) THEN
      value = a1
    ELSE IF (t >= t2) THEN
      value = a2
    ELSE IF (ABS(t2 - t1) <= EPSILON(1.0_wp)) THEN
      value = a2
    ELSE
      xi = (t - t1) / (t2 - t1)
      s = xi * xi * (3.0_wp - 2.0_wp * xi)
      value = a1 + s * (a2 - a1)
    END IF
  END FUNCTION MD_AmpShared_SmoothStep

  PURE FUNCTION MD_AmpShared_RampUnit(t_end, t) RESULT(value)
    REAL(wp), INTENT(IN) :: t_end, t
    REAL(wp) :: value

    IF (t_end <= 0.0_wp) THEN
      value = 1.0_wp
    ELSE IF (t <= 0.0_wp) THEN
      value = 0.0_wp
    ELSE IF (t >= t_end) THEN
      value = 1.0_wp
    ELSE
      value = t / t_end
    END IF
  END FUNCTION MD_AmpShared_RampUnit

  PURE FUNCTION MD_AmpShared_Modulated(carr_amp, fc, phase, fm, mdep, t, pi) RESULT(value)
    REAL(wp), INTENT(IN) :: carr_amp, fc, phase, fm, mdep, t, pi
    REAL(wp) :: value

    value = carr_amp * SIN(2.0_wp * pi * fc * t + phase) * &
            (1.0_wp + mdep * SIN(2.0_wp * pi * fm * t))
  END FUNCTION MD_AmpShared_Modulated

  !===========================================================================
  ! [Q] TBP — MD_Amp_Domain（对外名：`AddAmplitude`/`GetAmplitude` → 实现体 Add/Get）
  !===========================================================================

  SUBROUTINE Init(this, est_amplitudes, status)
    CLASS(MD_Amp_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                INTENT(IN)    :: est_amplitudes
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    CALL MD_Amp_DP_RegisterStructType(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    this%capacity = MAX(16_i4, est_amplitudes)
    ALLOCATE(this%amplitudes(this%capacity))
    ALLOCATE(this%amp_state(this%capacity))
    this%n_amplitudes = 0_i4
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE MD_Amp_DP_RegisterStructType(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), PARAMETER :: n_md_amp_dp_fields = 25_i4
    TYPE(StructFieldDesc) :: fields(n_md_amp_dp_fields)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'name'
    fields(1)%data_type = IF_DATA_TYPE_CHAR
    fields(1)%elem_len = 64
    fields(1)%offset_bytes = offset
    offset = offset + 64
    fields(2)%field_name = 'amp_id'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'amp_type'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'definition'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'n_points'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'smooth'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    fields(7)%field_name = 'omega'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'periodic_t0'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    fields(9)%field_name = 'n_fourier'
    fields(9)%data_type = IF_DATA_TYPE_INT
    fields(9)%offset_bytes = offset
    offset = offset + 4
    fields(10)%field_name = 'decay_a0'
    fields(10)%data_type = IF_DATA_TYPE_DP
    fields(10)%offset_bytes = offset
    offset = offset + 8
    fields(11)%field_name = 'decay_a1'
    fields(11)%data_type = IF_DATA_TYPE_DP
    fields(11)%offset_bytes = offset
    offset = offset + 8
    fields(12)%field_name = 'decay_t0'
    fields(12)%data_type = IF_DATA_TYPE_DP
    fields(12)%offset_bytes = offset
    offset = offset + 8
    fields(13)%field_name = 'decay_td'
    fields(13)%data_type = IF_DATA_TYPE_DP
    fields(13)%offset_bytes = offset
    offset = offset + 8
    fields(14)%field_name = 'mod_carr_freq'
    fields(14)%data_type = IF_DATA_TYPE_DP
    fields(14)%offset_bytes = offset
    offset = offset + 8
    fields(15)%field_name = 'mod_carr_amp'
    fields(15)%data_type = IF_DATA_TYPE_DP
    fields(15)%offset_bytes = offset
    offset = offset + 8
    fields(16)%field_name = 'mod_carr_phase'
    fields(16)%data_type = IF_DATA_TYPE_DP
    fields(16)%offset_bytes = offset
    offset = offset + 8
    fields(17)%field_name = 'mod_fm'
    fields(17)%data_type = IF_DATA_TYPE_DP
    fields(17)%offset_bytes = offset
    offset = offset + 8
    fields(18)%field_name = 'mod_depth'
    fields(18)%data_type = IF_DATA_TYPE_DP
    fields(18)%offset_bytes = offset
    offset = offset + 8
    fields(19)%field_name = 'tabular_extrapolate'
    fields(19)%data_type = IF_DATA_TYPE_INT
    fields(19)%offset_bytes = offset
    offset = offset + 4
    fields(20)%field_name = 'interp_method'
    fields(20)%data_type = IF_DATA_TYPE_INT
    fields(20)%offset_bytes = offset
    offset = offset + 4
    fields(21)%field_name = 'smooth_t1'
    fields(21)%data_type = IF_DATA_TYPE_DP
    fields(21)%offset_bytes = offset
    offset = offset + 8
    fields(22)%field_name = 'smooth_t2'
    fields(22)%data_type = IF_DATA_TYPE_DP
    fields(22)%offset_bytes = offset
    offset = offset + 8
    fields(23)%field_name = 'smooth_a1'
    fields(23)%data_type = IF_DATA_TYPE_DP
    fields(23)%offset_bytes = offset
    offset = offset + 8
    fields(24)%field_name = 'smooth_a2'
    fields(24)%data_type = IF_DATA_TYPE_DP
    fields(24)%offset_bytes = offset
    offset = offset + 8
    fields(25)%field_name = 'ramp_t_end'
    fields(25)%data_type = IF_DATA_TYPE_DP
    fields(25)%offset_bytes = offset
    CALL dp_register_struct_type('MD_Amp_Desc', fields, n_md_amp_dp_fields, status)
  END SUBROUTINE MD_Amp_DP_RegisterStructType

  SUBROUTINE Finalize(this)
    CLASS(MD_Amp_Domain), INTENT(INOUT) :: this
    IF (ALLOCATED(this%amplitudes)) DEALLOCATE(this%amplitudes)
    IF (ALLOCATED(this%amp_state))  DEALLOCATE(this%amp_state)
    this%n_amplitudes = 0_i4
    this%capacity     = 0_i4
    this%initialized  = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE Add(this, desc, status)
    CLASS(MD_Amp_Domain), INTENT(INOUT) :: this
    TYPE(MD_Amp_Desc),          INTENT(IN)    :: desc
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status
    TYPE(MD_Amp_Desc),  ALLOCATABLE :: tmp_d(:)
    TYPE(MD_Amp_State), ALLOCATABLE :: tmp_s(:)
    INTEGER(i4) :: new_cap
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%n_amplitudes >= this%capacity) THEN
      new_cap = MAX(16_i4, this%capacity * 2_i4)
      ALLOCATE(tmp_d(new_cap))
      ALLOCATE(tmp_s(new_cap))
      IF (this%n_amplitudes > 0) THEN
        tmp_d(1:this%n_amplitudes) = this%amplitudes(1:this%n_amplitudes)
        tmp_s(1:this%n_amplitudes) = this%amp_state(1:this%n_amplitudes)
      END IF
      CALL MOVE_ALLOC(tmp_d, this%amplitudes)
      CALL MOVE_ALLOC(tmp_s, this%amp_state)
      this%capacity = new_cap
    END IF
    this%n_amplitudes = this%n_amplitudes + 1_i4
    this%amplitudes(this%n_amplitudes) = desc
    this%amplitudes(this%n_amplitudes)%amp_id = this%n_amplitudes
    this%amp_state(this%n_amplitudes)%currentValue = 0.0_wp
    this%amp_state(this%n_amplitudes)%currentTime  = 0.0_wp
    this%amp_state(this%n_amplitudes)%currentIndex = 1_i4
    this%amp_state(this%n_amplitudes)%inc%step_idx = 0_i4
    this%amp_state(this%n_amplitudes)%inc%incr_idx = 0_i4

    ! SymTbl: register user-named amplitude for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(desc%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "AMP:", TRIM(desc%name)
        WRITE(sym_val, '(I0)') this%n_amplitudes
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Add

  SUBROUTINE Get(this, idx, desc, status)
    CLASS(MD_Amp_Domain), INTENT(IN)  :: this
    INTEGER(i4),                INTENT(IN)  :: idx
    TYPE(MD_Amp_Desc),          INTENT(OUT) :: desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_amplitudes) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%amplitudes(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Get

  !> **EvalAtTime**：幅值求值主过程 — **时间维**主导（t / 相位 / 衰减窗）；**空间维**无网格积分；
  !> **动作维**：tabular 插值/STEP/SMOOTH、周期谐波、调制、SymTbl 仅在 Add 路径。
  SUBROUTINE EvalAtTime(this, idx, time, value, status)
    CLASS(MD_Amp_Domain), INTENT(IN)  :: this
    INTEGER(i4),                INTENT(IN)  :: idx
    REAL(wp),                   INTENT(IN)  :: time
    REAL(wp),                   INTENT(OUT) :: value
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    INTEGER(i4) :: k, np, nharm
    REAL(wp)    :: xi, t_local, f_sum, pi
    CALL init_error_status(status)
    pi = ACOS(-1.0_wp)
    value = 0.0_wp
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_amplitudes) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    ASSOCIATE(amp => this%amplitudes(idx))
    SELECT CASE (amp%amp_type)
    CASE (AMP_TABULAR)
      np = amp%n_points
      IF (np < 1 .OR. .NOT. ALLOCATED(amp%time_data) .OR. .NOT. ALLOCATED(amp%value_data)) THEN
        value = 1.0_wp; status%status_code = IF_STATUS_OK; RETURN
      END IF
      np = MIN(np, INT(SIZE(amp%time_data), i4), INT(SIZE(amp%value_data), i4))
      SELECT CASE (amp%interp_method)
      CASE (INTERP_STEP)
        value = MD_AmpShared_StepEval(np, amp%time_data, amp%value_data, &
            amp%tabular_extrapolate, time)
      CASE (INTERP_SMOOTH)
        value = MD_AmpShared_TabularEval(np, amp%time_data, amp%value_data, &
            amp%tabular_extrapolate, .TRUE., time)
      CASE DEFAULT  ! INTERP_LINEAR
        value = MD_AmpShared_TabularEval(np, amp%time_data, amp%value_data, &
            amp%tabular_extrapolate, amp%smooth, time)
      END SELECT
      status%status_code = IF_STATUS_OK
    CASE (AMP_PERIODIC)
      IF (.NOT. ALLOCATED(amp%fourier_a)) THEN
        value = 1.0_wp; status%status_code = IF_STATUS_OK; RETURN
      END IF
      t_local = time - amp%periodic_t0
      f_sum   = amp%fourier_a(1)
      IF (amp%n_fourier > 0_i4 .AND. amp%omega /= 0.0_wp .AND. ALLOCATED(amp%fourier_b)) THEN
        ! Harmonic k uses fourier_a(k+1) and fourier_b(k); clamp to allocated lengths
        nharm = MIN(amp%n_fourier, INT(SIZE(amp%fourier_a), i4) - 1_i4, INT(SIZE(amp%fourier_b), i4))
        IF (nharm >= 1_i4) THEN
          DO k = 1, nharm
            xi    = REAL(k, wp) * amp%omega * t_local
            f_sum = f_sum + amp%fourier_a(k+1) * COS(xi) + amp%fourier_b(k) * SIN(xi)
          END DO
        END IF
      END IF
      value = f_sum; status%status_code = IF_STATUS_OK
    CASE (AMP_SMOOTH)
      value = MD_AmpShared_SmoothStep(amp%smooth_t1, amp%smooth_t2, amp%smooth_a1, amp%smooth_a2, time)
      status%status_code = IF_STATUS_OK
    CASE (AMP_RAMP)
      value = MD_AmpShared_RampUnit(amp%ramp_t_end, time)
      status%status_code = IF_STATUS_OK
    CASE (AMP_DECAY)
      IF (time < amp%decay_t0) THEN
        value = amp%decay_a1
      ELSE IF (amp%decay_td <= 0.0_wp) THEN
        value = amp%decay_a0
      ELSE
        value = amp%decay_a0 + (amp%decay_a1 - amp%decay_a0) * &
                EXP(-(time - amp%decay_t0) / amp%decay_td)
      END IF
      status%status_code = IF_STATUS_OK
    CASE (AMP_MODULATED)
      value = MD_AmpShared_Modulated(amp%mod_carr_amp, amp%mod_carr_freq, amp%mod_carr_phase, &
          amp%mod_fm, amp%mod_depth, time, pi)
      status%status_code = IF_STATUS_OK
    CASE (AMP_USER)
      ! USER: scalar from state (populate via domain %WriteBack / solver); not UAMP here
      value = this%amp_state(idx)%currentValue
      status%status_code = IF_STATUS_OK
    CASE (AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD)
      ! CONTRACT / 非职责: L3 不实现专用谱或求解耦合；中性因子 1 且 OK（Amp_GetFactor 采纳域分支）
      value = 1.0_wp
      status%status_code = IF_STATUS_OK
    CASE DEFAULT
      ! 未在表中登记的 amp_type：数值中性 1.0，但标 INVALID 以区别于显式占位 CASE
      value = 1.0_wp
      status%status_code = IF_STATUS_INVALID
    END SELECT
    END ASSOCIATE
  END SUBROUTINE EvalAtTime

  SUBROUTINE WriteBack(this, idx, currentValue, currentTime, currentIndex, &
       step_idx, incr_idx, status)
    CLASS(MD_Amp_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                INTENT(IN)    :: idx
    REAL(wp),                   INTENT(IN)    :: currentValue
    REAL(wp),                   INTENT(IN)    :: currentTime
    INTEGER(i4),                INTENT(IN)    :: currentIndex
    INTEGER(i4),                INTENT(IN), OPTIONAL :: step_idx, incr_idx
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_amplitudes) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    this%amp_state(idx)%currentValue = currentValue
    this%amp_state(idx)%currentTime  = currentTime
    this%amp_state(idx)%currentIndex = currentIndex
    IF (PRESENT(step_idx)) this%amp_state(idx)%inc%step_idx = step_idx
    IF (PRESENT(incr_idx)) this%amp_state(idx)%inc%incr_idx = incr_idx
    status%status_code = IF_STATUS_OK
  END SUBROUTINE WriteBack

  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Amp_Domain),        INTENT(IN)    :: this
    TYPE(MD_Amp_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%summary = "Amplitude Domain: not initialized"
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A)') &
      "Amplitude Summary: n_amplitudes=", this%n_amplitudes, &
      ", capacity=", this%capacity, " (initialized)"
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE GetSummary

  !=============================================================================
  ! SIO: MD_Amp_Apply_*_Arg — Harness / L3 ↔ MD_Amp_Domain TBP (Principle #14)
  !=============================================================================

  !> **`arg%desc` [IN]** -> **`dom%AddAmplitude`**; **[OUT]** `arg%amp_idx` = new 1-based index on OK.
  SUBROUTINE MD_Amp_Apply_Add_Arg(amp_dom, arg)
    CLASS(MD_Amp_Domain), INTENT(INOUT) :: amp_dom
    TYPE(MD_Amp_Add_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    arg%amp_idx = 0_i4
    CALL amp_dom%AddAmplitude(arg%desc, arg%status)
    IF (arg%status%status_code == IF_STATUS_OK) arg%amp_idx = amp_dom%n_amplitudes
  END SUBROUTINE MD_Amp_Apply_Add_Arg

  !> **`amp_idx` [IN]** -> **`dom%GetAmplitude`** -> **`arg%desc` [OUT]**.
  SUBROUTINE MD_Amp_Apply_Get_Arg(amp_dom, amp_idx, arg)
    CLASS(MD_Amp_Domain), INTENT(IN) :: amp_dom
    INTEGER(i4), INTENT(IN) :: amp_idx
    TYPE(MD_Amp_Get_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    CALL amp_dom%GetAmplitude(amp_idx, arg%desc, arg%status)
  END SUBROUTINE MD_Amp_Apply_Get_Arg

  !> **`arg%time` [IN]** -> **`dom%EvalAtTime`** -> **`arg%value` [OUT]**（`arg%status`）。
  !> **WriteBack**：若需与 **`MD_Amp_Idx`** 相同，请在调用方在 OK 后显式调用 **`dom%WriteBack`**。
  SUBROUTINE MD_Amp_Apply_EvalAtTime_Arg(amp_dom, amp_idx, arg)
    CLASS(MD_Amp_Domain), INTENT(IN) :: amp_dom
    INTEGER(i4), INTENT(IN) :: amp_idx
    TYPE(MD_Amp_EvalAtTime_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    CALL amp_dom%EvalAtTime(amp_idx, arg%time, arg%value, arg%status)
  END SUBROUTINE MD_Amp_Apply_EvalAtTime_Arg

  !> **`dom%GetSummary`** -> **`arg%summary` [OUT]**（`arg%status`）。
  SUBROUTINE MD_Amp_Apply_GetSummary_Arg(amp_dom, arg)
    CLASS(MD_Amp_Domain), INTENT(IN) :: amp_dom
    TYPE(MD_Amp_GetSummary_Arg), INTENT(INOUT) :: arg

    CALL amp_dom%GetSummary(arg)
  END SUBROUTINE MD_Amp_Apply_GetSummary_Arg

  !===========================================================================
  ! Pilot views — logical cfg/itr slices on flat MD_Amp_Desc (see module header).
  !===========================================================================

  PURE FUNCTION MD_Amp_Desc_Get_Cfg_View(d) RESULT(v)
    TYPE(MD_Amp_Desc),          INTENT(IN) :: d
    TYPE(MD_Amp_Desc_Cfg_View)              :: v

    v%name = d%name
    v%amp_id = d%amp_id
    v%amp_type = d%amp_type
    v%definition = d%definition
    v%n_points = d%n_points
    v%smooth = d%smooth
    v%tabular_extrapolate = d%tabular_extrapolate
    v%interp_method = d%interp_method
  END FUNCTION MD_Amp_Desc_Get_Cfg_View

  PURE FUNCTION MD_Amp_Desc_Get_Itr_View(d) RESULT(v)
    TYPE(MD_Amp_Desc),          INTENT(IN) :: d
    TYPE(MD_Amp_Desc_Itr_View)              :: v

    v%omega = d%omega
    v%periodic_t0 = d%periodic_t0
    v%n_fourier = d%n_fourier
    v%decay_a0 = d%decay_a0
    v%decay_a1 = d%decay_a1
    v%decay_t0 = d%decay_t0
    v%decay_td = d%decay_td
    v%mod_carr_freq = d%mod_carr_freq
    v%mod_carr_amp = d%mod_carr_amp
    v%mod_carr_phase = d%mod_carr_phase
    v%mod_fm = d%mod_fm
    v%mod_depth = d%mod_depth
    v%smooth_t1 = d%smooth_t1
    v%smooth_t2 = d%smooth_t2
    v%smooth_a1 = d%smooth_a1
    v%smooth_a2 = d%smooth_a2
    v%ramp_t_end = d%ramp_t_end
  END FUNCTION MD_Amp_Desc_Get_Itr_View

  PURE FUNCTION MD_Amp_Desc_Get_Pilot_Views(d) RESULT(pv)
    TYPE(MD_Amp_Desc),            INTENT(IN) :: d
    TYPE(MD_Amp_Desc_Pilot_Views)              :: pv

    pv%cfg = MD_Amp_Desc_Get_Cfg_View(d)
    pv%itr = MD_Amp_Desc_Get_Itr_View(d)
  END FUNCTION MD_Amp_Desc_Get_Pilot_Views

  PURE SUBROUTINE MD_Amp_Desc_Apply_Cfg_View(d, v)
    TYPE(MD_Amp_Desc),          INTENT(INOUT) :: d
    TYPE(MD_Amp_Desc_Cfg_View), INTENT(IN)    :: v

    d%name = v%name
    d%amp_id = v%amp_id
    d%amp_type = v%amp_type
    d%definition = v%definition
    d%n_points = v%n_points
    d%smooth = v%smooth
    d%tabular_extrapolate = v%tabular_extrapolate
    d%interp_method = v%interp_method
  END SUBROUTINE MD_Amp_Desc_Apply_Cfg_View

  PURE SUBROUTINE MD_Amp_Desc_Apply_Itr_View(d, v)
    TYPE(MD_Amp_Desc),          INTENT(INOUT) :: d
    TYPE(MD_Amp_Desc_Itr_View), INTENT(IN)    :: v

    d%omega = v%omega
    d%periodic_t0 = v%periodic_t0
    d%n_fourier = v%n_fourier
    d%decay_a0 = v%decay_a0
    d%decay_a1 = v%decay_a1
    d%decay_t0 = v%decay_t0
    d%decay_td = v%decay_td
    d%mod_carr_freq = v%mod_carr_freq
    d%mod_carr_amp = v%mod_carr_amp
    d%mod_carr_phase = v%mod_carr_phase
    d%mod_fm = v%mod_fm
    d%mod_depth = v%mod_depth
    d%smooth_t1 = v%smooth_t1
    d%smooth_t2 = v%smooth_t2
    d%smooth_a1 = v%smooth_a1
    d%smooth_a2 = v%smooth_a2
    d%ramp_t_end = v%ramp_t_end
  END SUBROUTINE MD_Amp_Desc_Apply_Itr_View

  PURE SUBROUTINE MD_Amp_Desc_Apply_Pilot_Views(d, pv)
    TYPE(MD_Amp_Desc),             INTENT(INOUT) :: d
    TYPE(MD_Amp_Desc_Pilot_Views), INTENT(IN)    :: pv

    CALL MD_Amp_Desc_Apply_Cfg_View(d, pv%cfg)
    CALL MD_Amp_Desc_Apply_Itr_View(d, pv%itr)
  END SUBROUTINE MD_Amp_Desc_Apply_Pilot_Views

END MODULE MD_Amp_Def
