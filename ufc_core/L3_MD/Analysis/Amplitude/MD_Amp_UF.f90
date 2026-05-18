!===============================================================================
! MODULE:   MD_Amp_UF
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Amplitude（域缩 **Amp**）
! ROLE:     _UF / _Impl — **`MD_Amp_Slot_Desc`** / **`MD_Amp_Slot_Ctx`** + **UAMP**
!           **`MD_Amp_Eval_*`** + 外 **`MD_Amp_Ext_Desc`** / **`MD_Amp_FromExt*`**（**不** `USE` **`MD_Amp_Mgr`**）
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**TYPE 声明区** + **`CONTAINS`** 过程；解析核在 **`MD_Amp_Def`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + *_Arg + 主/辅 / 嵌套·并列·主从）
!       — **UAMP 主链（结构化回调）**：**`MD_Amp_Eval_Desc`**、**`MD_Amp_Eval_Algo`**、
!           **`MD_Amp_Eval_Ctx`**、**`MD_Amp_Eval_State`**；**`MD_Amp_Eval_In`** / **`Out`**
!           为 **Arg 捆绑**（**`In` 内嵌** Desc/Algo/Ctx/State — **并列 + 主从**）。
!       — **槽侧建模（输入 / 与域并行）**：**`MD_Amp_Slot_Desc`**（Desc + **`evaluate`**
!           等 TBP）、**`MD_Amp_Slot_Ctx`**（**Ctx** 容器：`amplitudes(:)` + `evaluate`）。
!       — **API 辅 Desc**：**`MD_Amp_Ext_Desc`** — 外 **`MD_Amp_FromExt*`** 导入/装配
!           到 **`MD_Amp_Slot_Desc`** / DB（与 **`MD_Amp_Desc`** 并行语义，非同一 TYPE）。
!       — **命名模板**：**`MD_ | PH_ | RT_<域缩>_<Role>_(Desc|State|Algo|Ctx)`**；UAMP 套
!           件统一 **`MD_Amp_Eval_*`**；槽侧建模 TYPE 为 **`MD_Amp_Slot_*`**（与域 **`MD_Amp_Desc`** 区分）。
!
!   [2] 过程算法（三维度）
!       — **时间维**：**`MD_Amp_Slot_Desc%evaluate`**、**`ampdb_evaluate`**、setter 分支
!           （TABULAR/SMOOTH/RAMP/…）；与 **`MD_Amp_Domain%EvalAtTime`** 数值同核
!           （**`MD_AmpShared_*`** 在 **`MD_Amp_Def`**）。
!       — **空间维**：**`MD_Amp_Eval_Ctx`** 预留坐标/实例字段；槽解析路径仍以 **标量 A(t)** 为主。
!       — **动作维**：DB CRUD（**`ampdb_*`**）、文件 **`load_from_file`**、UAMP 指针绑定、
!           **`MD_Amp_FromExt*`** 映射；**无** 公共 **`Eval_Apply(in,out)`**（CONTRACT）。
!
! **依赖**：**`MD_Amp_Def`**（`MD_AmpShared_*`、`AMP_*`）；**`IF_Err_Brg`**、**`IF_Prec_Core`**。
! **非依赖**：**不** `USE` **`MD_Amp_Mgr`** / **`g_ufc_global`**。
!===============================================================================
!>>> UFC_L3_TAG | layer:L3_MD | domain:Amplitude | role:UF
!>>> UFC_L3_CONTRACT | Amplitude/CONTRACT.md

MODULE MD_Amp_UF
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Amp_Def, ONLY: &
         AMP_TABULAR, AMP_SMOOTH, AMP_PERIODIC, AMP_MODULATED, AMP_DECAY, AMP_USER, &
         AMP_EQUALLY_SPACED, AMP_RAMP, AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD, &
         INTERP_LINEAR, INTERP_SMOOTH, INTERP_STEP, &
         MD_AmpShared_TabularEval, MD_AmpShared_StepEval, MD_AmpShared_SmoothStep, MD_AmpShared_RampUnit, MD_AmpShared_Modulated
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx
    PUBLIC :: MD_Amp_MATH_PI
    PUBLIC :: MAX_AMPLITUDE_NAME, MAX_AMP_POINTS, MAX_AMPLITUDES, AMPDB_INIT_CAP_DEFAULT
    PUBLIC :: TIME_STEP, TIME_TOTAL
    PUBLIC :: MD_Amp_Eval_In, MD_Amp_Eval_Out
    PUBLIC :: MD_Amp_Eval_Desc, MD_Amp_Eval_Algo
    PUBLIC :: MD_Amp_Eval_Ctx, MD_Amp_Eval_State
    PUBLIC :: MD_Amp_Ext_Desc, MD_Amp_FromExt, MD_Amp_FromExt_Def, MD_Amp_FromExt_DB

    INTEGER(i4), PARAMETER :: MAX_AMPLITUDE_NAME = 80_i4
    INTEGER(i4), PARAMETER :: MAX_AMP_POINTS = 10000_i4
    INTEGER(i4), PARAMETER :: MAX_AMPLITUDES = 500_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AMPDB_INIT_CAP_DEFAULT = 50_i4
    REAL(wp), PARAMETER, PUBLIC :: MD_Amp_MATH_PI = 3.1415926535897932384626433832795_wp

    ! Time definition (MD_Amp_Slot_Desc%time_type)
    INTEGER(i4), PARAMETER, PUBLIC :: TIME_STEP = 1_i4   ! Step time (default)
    INTEGER(i4), PARAMETER, PUBLIC :: TIME_TOTAL = 2_i4  ! Total time
    
    !===========================================================================
    ! [B] UAMP 结构化捆绑 — **`MD_Amp_Eval_*`** + **`In`** / **`Out`**（无公共 Eval_Apply）
    !   解析 A(t)：**`MD_Amp_Slot_Desc%evaluate`**（槽）与 **`MD_Amp_Domain%EvalAtTime`**（域）
    !   共享 **`MD_AmpShared_*`**（在 **`MD_Amp_Def`**）；见 **Amplitude/CONTRACT.md**。
    !===========================================================================
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_Desc
    ! KIND:  Desc
    ! DESC:  Descriptor for amplitude evaluation parameters
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_Desc
      CHARACTER(LEN=MAX_AMPLITUDE_NAME) :: name = ""  ! Amplitude name
      INTEGER(i4) :: amp_type = AMP_TABULAR  ! Amplitude type
      INTEGER(i4) :: time_type = TIME_STEP  ! Time type (STEP or TOTAL)
      REAL(wp), ALLOCATABLE :: props(:)  ! User-defined properties array
      INTEGER(i4) :: num_props = 0_i4  ! Number of properties
    END TYPE MD_Amp_Eval_Desc
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_Algo
    ! KIND:  Algo
    ! DESC:  Algorithm parameters for amplitude evaluation
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_Algo
      LOGICAL :: use_smooth_interp = .FALSE.  ! Use smooth interpolation
      LOGICAL :: extrapolate = .FALSE.  ! Allow extrapolation beyond data range
      INTEGER(i4) :: interpolation_method = 1_i4  ! Interpolation method (1=linear, 2=hermite)
    END TYPE MD_Amp_Eval_Algo
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_Ctx
    ! KIND:  Ctx
    ! DESC:  Context for amplitude evaluation (instance, coords, step/incr indices)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_Ctx
      CHARACTER(LEN=256) :: instance_name = ""  ! Instance name
      REAL(wp), ALLOCATABLE :: coords(:)  ! Coordinate array (spatial-dependent amplitudes)
      INTEGER(i4) :: num_coords = 0_i4  ! Number of coordinates
      INTEGER(i4) :: increment = 0_i4  ! Increment number (legacy UAMP-style)
      INTEGER(i4) :: step_idx = 0_i4    ! Step index (align md_layer%step)
      INTEGER(i4) :: incr_idx = 0_i4    ! Substep / increment index
    END TYPE MD_Amp_Eval_Ctx
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_State
    ! KIND:  State
    ! DESC:  Runtime state for amplitude evaluation
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_State
      REAL(wp) :: time = 0.0_wp  ! Current time t (input)
      REAL(wp) :: amp_value = 0.0_wp  ! Amplitude value A(t) (output)
    END TYPE MD_Amp_Eval_State
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_In
    ! KIND:  Arg
    ! DESC:  Input argument bundle for amplitude evaluation
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_In
      TYPE(MD_Amp_Eval_Desc) :: desc
      TYPE(MD_Amp_Eval_Algo) :: algo
      TYPE(MD_Amp_Eval_Ctx) :: ctx
      TYPE(MD_Amp_Eval_State) :: state
    END TYPE MD_Amp_Eval_In
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Eval_Out
    ! KIND:  Arg
    ! DESC:  Output argument bundle for amplitude evaluation
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Eval_Out
      TYPE(MD_Amp_Eval_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Amp_Eval_Out

    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Ext_Desc
    ! KIND:  Desc
    ! DESC:  External amplitude description for API import/export
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Amp_Ext_Desc
      INTEGER(i4) :: amplitudeId = 0_i4
      CHARACTER(LEN=64) :: name = ""
      INTEGER(i4) :: amp_type = 1_i4
      REAL(wp), ALLOCATABLE :: time_points(:)
      REAL(wp), ALLOCATABLE :: amplitude_value(:)
      LOGICAL :: smooth = .FALSE.
      LOGICAL :: extrapolate = .FALSE.
      REAL(wp) :: smooth_t1 = 0.0_wp
      REAL(wp) :: smooth_t2 = 1.0_wp
      REAL(wp) :: smooth_a1 = 0.0_wp
      REAL(wp) :: smooth_a2 = 1.0_wp
      REAL(wp) :: ramp_t_end = 1.0_wp
      REAL(wp) :: periodic_freq = 1.0_wp
      REAL(wp) :: periodic_amp = 1.0_wp
      REAL(wp) :: periodic_phase = 0.0_wp
      REAL(wp) :: periodic_offset = 0.0_wp
      REAL(wp) :: decay_a0 = 1.0_wp
      REAL(wp) :: decay_rate = 1.0_wp
      REAL(wp) :: modulated_freq = 0.1_wp
      REAL(wp) :: modulated_depth = 0.5_wp
    END TYPE MD_Amp_Ext_Desc
    
    !> @brief User subroutine interface using structured types
    ABSTRACT INTERFACE
        SUBROUTINE Amp_User_IF_Structured(in, out)
            USE IF_Prec_Core, ONLY: wp, i4
            IMPORT :: MD_Amp_Eval_In, MD_Amp_Eval_Out
            TYPE(MD_Amp_Eval_In), INTENT(IN) :: in
            TYPE(MD_Amp_Eval_Out), INTENT(OUT) :: out
        END SUBROUTINE Amp_User_IF_Structured
    END INTERFACE
    
    !> @brief Legacy user subroutine interface (ABAQUS UAMP Compatible)
    !! @deprecated Use Amp_User_IF_Structured instead
    ABSTRACT INTERFACE
        SUBROUTINE Amp_User_IF(amp_value, time, amp_name, num_props, props, &
                               num_coords, coords, instance_name, increment)
            USE IF_Prec_Core, ONLY: wp, i4
            REAL(wp), INTENT(OUT) :: amp_value  ! Computed amplitude value A(t)
            REAL(wp), INTENT(IN) :: time  ! Current time t
            CHARACTER(LEN=*), INTENT(IN) :: amp_name  ! Amplitude name
            INTEGER(i4), INTENT(IN) :: num_props  ! Number of user properties
            REAL(wp), INTENT(IN) :: props(*)  ! User properties array
            INTEGER(i4), INTENT(IN) :: num_coords  ! Number of coordinates
            REAL(wp), INTENT(IN) :: coords(*)  ! Coordinate array
            CHARACTER(LEN=*), INTENT(IN) :: instance_name  ! Instance name
            INTEGER(i4), INTENT(IN) :: increment  ! Increment number
        END SUBROUTINE Amp_User_IF
    END INTERFACE
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Slot_Desc
    ! KIND:  Desc
    ! DESC:  Amplitude definition for time-dependent scaling factors A(t)
    !---------------------------------------------------------------------------
    TYPE :: MD_Amp_Slot_Desc
        CHARACTER(LEN=MAX_AMPLITUDE_NAME) :: name = ""  ! Amplitude name
        INTEGER(i4) :: id = 0_i4  ! Amplitude ID
        INTEGER(i4) :: amp_type = AMP_TABULAR  ! Amplitude type
        INTEGER(i4) :: time_type = TIME_STEP  ! Time type (STEP or TOTAL)
        
        ! Tabular data: (t_i, A_i) pairs for A(t) = linear interpolation
        INTEGER(i4) :: num_points = 0_i4  ! Number of data points
        REAL(wp), ALLOCATABLE :: time(:)  ! Time array t_i
        REAL(wp), ALLOCATABLE :: value(:)  ! Value array A_i
        
        ! Smooth step (Hermite): xi=(t-t1)/(t2-t1), s=xi^2*(3-2*xi), A=A1+s*(A2-A1)
        REAL(wp) :: smooth_t1 = 0.0_wp  ! Start time t1
        REAL(wp) :: smooth_t2 = 1.0_wp  ! End time t2
        REAL(wp) :: smooth_a1 = 0.0_wp  ! Start amplitude A1
        REAL(wp) :: smooth_a2 = 1.0_wp  ! End amplitude A2
        
        ! Periodic: A(t) = offset + amp*sin(2*pi*f*t + phase)
        REAL(wp) :: periodic_freq = 1.0_wp  ! Frequency f (Hz)
        REAL(wp) :: periodic_phase = 0.0_wp  ! Phase (radians)
        REAL(wp) :: periodic_amp = 1.0_wp  ! Sine amplitude
        REAL(wp) :: periodic_offset = 0.0_wp  ! DC offset
        
        ! Decay: A(t) = decay_a0 * exp(-decay_rate * t)
        REAL(wp) :: decay_a0 = 1.0_wp  ! Initial scale
        REAL(wp) :: decay_rate = 1.0_wp  ! Rate lambda
        ! Modulated: carrier * [1 + m*sin(2*pi*fm*t)]; align MD_Amp_Desc in MD_Amp_Def
        REAL(wp) :: modulated_freq = 0.1_wp   ! Modulation frequency f_m (Hz)
        REAL(wp) :: modulated_depth = 0.5_wp  ! Modulation depth m (often in [0,1])

        ! Ramp: A(t) = t/t_end in [0,t_end], then 1.0 (linear 0->1 in step)
        REAL(wp) :: ramp_t_end = 1.0_wp  ! Time at which ramp reaches 1.0
        
        ! Default value (before first time point)
        REAL(wp) :: default_value = 0.0_wp
        ! Tabular: linear extrapolation outside [t_1, t_N] when .true.; else clamp to endpoints
        LOGICAL :: tabular_extrapolate = .FALSE.
        
        ! INPUT file support (ABAQUS INPUT= parameter)
        CHARACTER(LEN=256) :: input_file = ""  ! External data file path
        LOGICAL :: from_input_file = .FALSE.  ! Data loaded from file?
        
        ! USER subroutine support (ABAQUS DEFINITION=USER)
        PROCEDURE(Amp_User_IF), POINTER, NOPASS :: user_subroutine => NULL()  ! Legacy interface
        PROCEDURE(Amp_User_IF_Structured), POINTER, NOPASS :: user_subroutine_structured => NULL()  ! Structured interface
        REAL(wp) :: user_props(20) = 0.0_wp  ! User-defined properties
        INTEGER(i4) :: num_user_props = 0_i4  ! Number of user properties
        LOGICAL :: is_user_defined = .FALSE.  ! Using USER subroutine?
        LOGICAL :: use_structured_interface = .FALSE.  ! Use structured interface?
        
    CONTAINS
        PROCEDURE :: init => amplitude_init
        PROCEDURE :: add_point => amplitude_add_point
        PROCEDURE :: set_tabular => amplitude_set_tabular
        PROCEDURE :: set_smooth_step => amplitude_set_smooth_step
        PROCEDURE :: set_periodic => amplitude_set_periodic
        PROCEDURE :: set_modulated => amplitude_set_modulated
        PROCEDURE :: set_ramp => amplitude_set_ramp
        PROCEDURE :: load_from_file => amplitude_load_from_file
        PROCEDURE :: set_user_subroutine => amplitude_set_user_sub
        PROCEDURE :: evaluate => amplitude_evaluate
        PROCEDURE :: clear => amplitude_clear
    END TYPE MD_Amp_Slot_Desc
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Amp_Slot_Ctx
    ! KIND:  Ctx
    ! DESC:  Amplitude database container for multiple definitions
    !---------------------------------------------------------------------------
    TYPE :: MD_Amp_Slot_Ctx
        INTEGER(i4) :: num_amplitudes = 0_i4  ! Number of amplitudes in database
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)  ! Array of amplitude definitions
    CONTAINS
        PROCEDURE :: init => ampdb_init
        PROCEDURE :: add_amplitude => ampdb_add_amplitude
        PROCEDURE :: find_by_name => ampdb_find_by_name
        PROCEDURE :: get_amplitude => ampdb_get_amplitude
        PROCEDURE :: evaluate => ampdb_evaluate
        PROCEDURE :: clear => ampdb_clear
    END TYPE MD_Amp_Slot_Ctx

CONTAINS

    !===========================================================================
    ! [P] `CONTAINS` — **`ampdb_*`** / **`amplitude_*`** / **`MD_Amp_FromExt*`**
    !===========================================================================

    SUBROUTINE ampdb_add_amplitude(this, amp)
        CLASS(MD_Amp_Slot_Ctx), INTENT(INOUT) :: this
        TYPE(MD_Amp_Slot_Desc), INTENT(IN) :: amp  ! Amplitude definition
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: temp(:)

        IF (.NOT. ALLOCATED(this%amplitudes)) CALL this%init()

        IF (this%num_amplitudes >= SIZE(this%amplitudes)) THEN
            ALLOCATE(temp(SIZE(this%amplitudes) * 2))
            temp(1:this%num_amplitudes) = this%amplitudes(1:this%num_amplitudes)
            CALL MOVE_ALLOC(temp, this%amplitudes)
        END IF

        this%num_amplitudes = this%num_amplitudes + 1_i4
        this%amplitudes(this%num_amplitudes) = amp
        this%amplitudes(this%num_amplitudes)%cfg%id = this%num_amplitudes

    END SUBROUTINE ampdb_add_amplitude

    !> @brief Clear amplitude database
    SUBROUTINE ampdb_clear(this)
        CLASS(MD_Amp_Slot_Ctx), INTENT(INOUT) :: this
        this%num_amplitudes = 0_i4
        IF (ALLOCATED(this%amplitudes)) DEALLOCATE(this%amplitudes)
    END SUBROUTINE ampdb_clear

    !> @brief Evaluate amplitude by name at given time: A(t)
    FUNCTION ampdb_evaluate(this, name, t) RESULT(val)
        CLASS(MD_Amp_Slot_Ctx), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name  ! Amplitude name
        REAL(wp), INTENT(IN) :: t  ! Time t
        REAL(wp) :: val  ! Amplitude value A(t)
        INTEGER(i4) :: idx

        val = 1.0_wp  ! Default
        idx = this%find_by_name(name)
        IF (idx > 0) val = this%amplitudes(idx)%evaluate(t)

    END FUNCTION ampdb_evaluate

    !> @brief Find amplitude by name in database
    FUNCTION ampdb_find_by_name(this, name) RESULT(idx)
        CLASS(MD_Amp_Slot_Ctx), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name  ! Amplitude name
        INTEGER(i4) :: idx  ! Amplitude index (or -1 if not found)
        INTEGER(i4) :: i

        idx = -1
        DO i = 1, this%num_amplitudes
            IF (TRIM(this%amplitudes(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO

    END FUNCTION ampdb_find_by_name

    !> @brief Get amplitude definition pointer by index
    FUNCTION ampdb_get_amplitude(this, idx) RESULT(amp_ptr)
        CLASS(MD_Amp_Slot_Ctx), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: idx  ! Amplitude index
        TYPE(MD_Amp_Slot_Desc), POINTER :: amp_ptr  ! Pointer to amplitude definition

        NULLIFY(amp_ptr)
        IF (idx >= 1 .AND. idx <= this%num_amplitudes) THEN
            amp_ptr => this%amplitudes(idx)
        END IF

    END FUNCTION ampdb_get_amplitude

    !> @brief Initialize amplitude database
    SUBROUTINE ampdb_init(this, capacity)
        CLASS(MD_Amp_Slot_Ctx), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap

        cap = AMPDB_INIT_CAP_DEFAULT
        IF (PRESENT(capacity)) cap = capacity

        this%num_amplitudes = 0_i4
        IF (ALLOCATED(this%amplitudes)) DEALLOCATE(this%amplitudes)
        ALLOCATE(this%amplitudes(cap))

    END SUBROUTINE ampdb_init

    !===========================================================================
    ! MD_Amp_Slot_Desc — TBP 实现族（**`amplitude_*`**；时间维主入口 **`evaluate`**）
    !===========================================================================
    !> @brief Initialize amplitude definition
    SUBROUTINE amplitude_init(this, name, amp_type)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name  ! Amplitude name
        INTEGER(i4), INTENT(IN), OPTIONAL :: amp_type  ! Amplitude type
        
        this%name = TRIM(name)
        this%amp_type = AMP_TABULAR
        IF (PRESENT(amp_type)) this%amp_type = amp_type
        
        this%num_points = 0_i4
        IF (ALLOCATED(this%time)) DEALLOCATE(this%time)
        IF (ALLOCATED(this%value)) DEALLOCATE(this%value)
        ALLOCATE(this%time(MAX_AMP_POINTS))
        ALLOCATE(this%value(MAX_AMP_POINTS))
        this%time = 0.0_wp
        this%value = 0.0_wp
        
    END SUBROUTINE amplitude_init

    !> @brief Add a (time, value) point to tabular amplitude
    SUBROUTINE amplitude_add_point(this, t, val)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: t  ! Time t
        REAL(wp), INTENT(IN) :: val  ! Amplitude value A(t)

        IF (.NOT. ALLOCATED(this%time)) CALL this%init(this%name)
        IF (this%num_points >= SIZE(this%time)) RETURN

        this%num_points = this%num_points + 1_i4
        this%time(this%num_points) = t
        this%value(this%num_points) = val

    END SUBROUTINE amplitude_add_point

    SUBROUTINE amplitude_clear(this)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        this%num_points = 0_i4
        this%tabular_extrapolate = .FALSE.
        IF (ALLOCATED(this%time)) DEALLOCATE(this%time)
        IF (ALLOCATED(this%value)) DEALLOCATE(this%value)
    END SUBROUTINE amplitude_clear

    !> @brief Load amplitude data from external file
    SUBROUTINE amplitude_load_from_file(this, filename, success)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: filename
        LOGICAL, INTENT(OUT) :: success
        
        INTEGER(i4) :: unit, ios, line_count
        REAL(wp) :: t_val, a_val
        CHARACTER(LEN=512) :: line
        CHARACTER(LEN=256) :: trimmed_line
        
        success = .FALSE.
        line_count = 0
        
        ! Initialize amplitude if not already done
        IF (.NOT. ALLOCATED(this%time)) THEN
            CALL this%init(this%name, AMP_TABULAR)
        END IF
        
        ! Open external file
        OPEN(NEWUNIT=unit, FILE=TRIM(filename), STATUS='OLD', &
             ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) THEN
            ! File open failed
            RETURN
        END IF
        
        ! Read data pairs (time, amplitude) from file
        DO
            READ(unit, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT  ! End of file or read error
            
            ! Trim leading/trailing whitespace
            trimmed_line = ADJUSTL(line)
            
            ! Skip empty lines
            IF (LEN_TRIM(trimmed_line) == 0) CYCLE
            
            ! Skip comment lines (starting with *, #, or !)
            IF (trimmed_line(1:1) == '*' .OR. &
                trimmed_line(1:1) == '#' .OR. &
                trimmed_line(1:1) == '!') CYCLE
            
            ! Parse data: expect two real numbers (time, value)
            READ(trimmed_line, *, IOSTAT=ios) t_val, a_val
            IF (ios == 0) THEN
                CALL this%add_point(t_val, a_val)
                line_count = line_count + 1
            END IF
            
            ! Prevent overflow
            IF (line_count >= MAX_AMP_POINTS) EXIT
        END DO
        
        CLOSE(unit)
        
        ! Mark as loaded from file
        IF (line_count > 0) THEN
            this%from_input_file = .TRUE.
            this%input_file = TRIM(filename)
            this%amp_type = AMP_TABULAR
            success = .TRUE.
        END IF
        
    END SUBROUTINE amplitude_load_from_file

    !> @brief Set periodic (AMP_PERIODIC): offset + amp*sin(2*pi*f*t + phase).
    SUBROUTINE amplitude_set_periodic(this, freq, amp, phase, offset)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: freq  ! Frequency f (Hz)
        REAL(wp), INTENT(IN) :: amp  ! Amplitude A
        REAL(wp), INTENT(IN), OPTIONAL :: phase  ! Phase (radians)
        REAL(wp), INTENT(IN), OPTIONAL :: offset  ! DC offset

        this%amp_type = AMP_PERIODIC
        this%periodic_freq = freq
        this%periodic_amp = amp
        this%periodic_phase = 0.0_wp
        IF (PRESENT(phase)) this%periodic_phase = phase
        this%periodic_offset = 0.0_wp
        IF (PRESENT(offset)) this%periodic_offset = offset

    END SUBROUTINE amplitude_set_periodic

    !> @brief Set ramp: A(t)=t/t_end in [0,t_end], then 1.0 (linear 0->1 in step)
    SUBROUTINE amplitude_set_ramp(this, t_end)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: t_end  ! Time at which amplitude reaches 1.0

        this%amp_type = AMP_RAMP
        this%ramp_t_end = MAX(t_end, TINY(1.0_wp))

    END SUBROUTINE amplitude_set_ramp

    !> @brief Set modulated (AMP_MODULATED): carrier sine times [1 + m*sin(2*pi*fm*t)].
    SUBROUTINE amplitude_set_modulated(this, carrier_freq, carrier_amp, phase, mod_freq, mod_depth)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: carrier_freq  ! Carrier frequency f_c (Hz)
        REAL(wp), INTENT(IN) :: carrier_amp   ! Carrier amplitude A
        REAL(wp), INTENT(IN), OPTIONAL :: phase  ! Initial phase (radians)
        REAL(wp), INTENT(IN), OPTIONAL :: mod_freq   ! Modulation frequency f_m (Hz)
        REAL(wp), INTENT(IN), OPTIONAL :: mod_depth   ! Modulation depth m (often [0,1])

        this%amp_type = AMP_MODULATED
        this%periodic_freq = carrier_freq
        this%periodic_amp = carrier_amp
        this%periodic_phase = 0.0_wp
        IF (PRESENT(phase)) this%periodic_phase = phase
        this%modulated_freq = 0.1_wp
        IF (PRESENT(mod_freq)) this%modulated_freq = mod_freq
        this%modulated_depth = 0.5_wp
        IF (PRESENT(mod_depth)) this%modulated_depth = mod_depth

    END SUBROUTINE amplitude_set_modulated

    !> @brief Set smooth step (AMP_SMOOTH): Hermite blend from (t1,a1) to (t2,a2).
    SUBROUTINE amplitude_set_smooth_step(this, t1, t2, a1, a2)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: t1  ! Start time t1
        REAL(wp), INTENT(IN) :: t2  ! End time t2
        REAL(wp), INTENT(IN) :: a1  ! Start amplitude A1
        REAL(wp), INTENT(IN) :: a2  ! End amplitude A2

        this%amp_type = AMP_SMOOTH
        this%smooth_t1 = t1
        this%smooth_t2 = t2
        this%smooth_a1 = a1
        this%smooth_a2 = a2

    END SUBROUTINE amplitude_set_smooth_step

    !> @brief Set tabular amplitude data: (t_i, A_i) pairs
    SUBROUTINE amplitude_set_tabular(this, times, values)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: times(:)  ! Time array t_i
        REAL(wp), INTENT(IN) :: values(:)  ! Value array A_i
        INTEGER(i4) :: i, n

        this%amp_type = AMP_TABULAR
        n = MIN(SIZE(times), SIZE(values))

        CALL this%init(this%name, AMP_TABULAR)
        DO i = 1, n
            CALL this%add_point(times(i), values(i))
        END DO

    END SUBROUTINE amplitude_set_tabular

    !> @brief Set user-defined subroutine for amplitude evaluation
    SUBROUTINE amplitude_set_user_sub(this, user_sub, props, num_props)
        CLASS(MD_Amp_Slot_Desc), INTENT(INOUT) :: this
        PROCEDURE(Amp_User_IF), POINTER :: user_sub  ! User subroutine pointer
        REAL(wp), INTENT(IN), OPTIONAL :: props(:)  ! User properties array
        INTEGER(i4), INTENT(IN), OPTIONAL :: num_props  ! Number of properties

        this%amp_type = AMP_USER
        this%is_user_defined = .TRUE.
        this%user_subroutine => user_sub

        ! Copy user properties
        IF (PRESENT(props) .AND. PRESENT(num_props)) THEN
            this%num_user_props = MIN(num_props, SIZE(this%user_props))
            this%user_props(1:this%num_user_props) = props(1:this%num_user_props)
        ELSE IF (PRESENT(props)) THEN
            this%num_user_props = MIN(SIZE(props), SIZE(this%user_props))
            this%user_props(1:this%num_user_props) = props(1:this%num_user_props)
        ELSE
            this%num_user_props = 0_i4
        END IF

    END SUBROUTINE amplitude_set_user_sub

    !> @brief Evaluate amplitude at given time
    !! @param[in] this Amplitude definition
    !! @param[in] t Time t
    !! @return Amplitude value A(t)
    !! Theory (MD_Amp_Slot_Desc%evaluate; align Amplitude/CONTRACT.md):
    !!   TABULAR: piecewise linear; optional endpoint slope extrapolation.
    !!   SMOOTH: Hermite step A1->A2 on [t1,t2].
    !!   PERIODIC: offset + amp*sin(2*pi*f*t + phase).
    !!   DECAY: decay_a0*exp(-decay_rate*t).
    !!   USER / placeholders / unknown: neutral 1.0_wp (see Amplitude/CONTRACT.md USER + Amp_GetFactor).

    FUNCTION amplitude_evaluate(this, t) RESULT(val)
        CLASS(MD_Amp_Slot_Desc), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: t
        REAL(wp) :: val
        INTEGER(i4) :: i
        TYPE(MD_Amp_Eval_In) :: in_struct
        TYPE(MD_Amp_Eval_Out) :: out_struct
        REAL(wp) :: coords_stub(1)

        val = this%default_value
        coords_stub(1) = 0.0_wp

        ! USER subroutine (highest priority)
        IF (this%amp_type == AMP_USER .AND. this%is_user_defined) THEN
            ! Try structured interface first
            IF (this%use_structured_interface .AND. ASSOCIATED(this%user_subroutine_structured)) THEN
                ! Build structured input
                in_struct%desc%name = this%name
                in_struct%desc%amp_type = this%amp_type
                in_struct%desc%time_type = this%time_type
                in_struct%desc%num_props = this%num_user_props
                IF (.NOT. ALLOCATED(in_struct%desc%props)) THEN
                    ALLOCATE(in_struct%desc%props(this%num_user_props))
                END IF
                in_struct%desc%props = this%user_props(1:this%num_user_props)
                in_struct%state%time = t

                ! Call structured user subroutine
                CALL this%user_subroutine_structured(in_struct, out_struct)
                val = out_struct%state%amp_value
                RETURN
            ELSE IF (ASSOCIATED(this%user_subroutine)) THEN
                ! Call legacy user-defined subroutine (UAMP interface)
                CALL this%user_subroutine( &
                    val, &
                    t, &
                    this%name, &
                    this%num_user_props, &
                    this%user_props, &
                    0_i4, &
                    coords_stub, &
                    '', &
                    0_i4)
                RETURN
            ELSE
                ! USER declared (is_user_defined) but no procedure: neutral 1 (CONTRACT USER row)
                val = 1.0_wp
                RETURN
            END IF
        END IF

        SELECT CASE (this%amp_type)
        CASE (AMP_TABULAR)
            ! Tabular: shared kernel with domain (half-open segments; UF tabular = piecewise linear only)
            IF (this%num_points == 0) RETURN
            IF (this%num_points == 1) THEN
                val = this%value(1)
                RETURN
            END IF
            i = MIN(this%num_points, INT(SIZE(this%time), i4), INT(SIZE(this%value), i4))
            val = MD_AmpShared_TabularEval(i, this%time, this%value, this%tabular_extrapolate, &
                .FALSE., t)

        CASE (AMP_SMOOTH)
            val = MD_AmpShared_SmoothStep(this%smooth_t1, this%smooth_t2, this%smooth_a1, this%smooth_a2, t)

        CASE (AMP_PERIODIC)
            ! Periodic: offset + amp*sin(2*pi*f*t + phase)
            val = this%periodic_offset + &
                  this%periodic_amp * SIN(2.0_wp * MD_Amp_MATH_PI * this%periodic_freq * t + &
                                         this%periodic_phase)

        CASE (AMP_MODULATED)
            val = MD_AmpShared_Modulated(this%periodic_amp, this%periodic_freq, this%periodic_phase, &
                this%modulated_freq, this%modulated_depth, t, MD_Amp_MATH_PI)

        CASE (AMP_DECAY)
            ! Exponential decay: decay_a0 * exp(-decay_rate * t)
            val = this%decay_a0 * EXP(-this%decay_rate * t)

        CASE (AMP_RAMP)
            val = MD_AmpShared_RampUnit(this%ramp_t_end, t)

        CASE (AMP_USER)
            ! amp_type USER but is_user_defined .false. (no set_user_sub): neutral 1
            val = 1.0_wp

        CASE (AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD)
            ! CONTRACT: L3 非职责占位；与域 EvalAtTime 一致 — 中性因子 1（非 default_value）
            val = 1.0_wp

        CASE DEFAULT
            ! 未知 amp_type：与域 DEFAULT 数值一致（1.0）；域侧另标 IF_STATUS_INVALID
            val = 1.0_wp
        END SELECT

    END FUNCTION amplitude_evaluate

    !===========================================================================
    ! **`MD_Amp_FromExt*`** — API：**`MD_Amp_Ext_Desc`** → **`MD_Amp_Slot_Desc`** / **`MD_Amp_Slot_Ctx`**（动作维）
    !===========================================================================
    SUBROUTINE MD_Amp_FromExt(desc_amp, md_amplitude, status)
        TYPE(MD_Amp_Ext_Desc), INTENT(IN), TARGET :: desc_amp
        TYPE(MD_Amp_Slot_Desc), INTENT(INOUT) :: md_amplitude
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        CALL MD_Amp_FromExt_Def(desc_amp, md_amplitude, status)
    END SUBROUTINE MD_Amp_FromExt

    SUBROUTINE MD_Amp_FromExt_Def(desc_amp, md_ampdef, status)
        TYPE(MD_Amp_Ext_Desc), INTENT(IN) :: desc_amp
        TYPE(MD_Amp_Slot_Desc), INTENT(INOUT) :: md_ampdef
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n, ktype

        CALL init_error_status(status)
        ktype = desc_amp%amp_type
        IF (ktype < AMP_TABULAR .OR. ktype > AMP_PSD) ktype = AMP_TABULAR

        CALL md_ampdef%init(TRIM(desc_amp%name), ktype)
        md_ampdef%cfg%id = desc_amp%amplitudeId

        SELECT CASE (ktype)
        CASE (AMP_TABULAR)
            md_ampdef%tabular_extrapolate = desc_amp%extrapolate
            IF (ALLOCATED(desc_amp%time_points)) THEN
                n = SIZE(desc_amp%time_points)
                IF (.NOT. ALLOCATED(desc_amp%amplitude_value)) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "MD_Amp_FromExt_Def: time_points without amplitude_value"
                    RETURN
                END IF
                IF (SIZE(desc_amp%amplitude_value) < n) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "MD_Amp_FromExt_Def: amplitude_value shorter than time_points"
                    RETURN
                END IF
                DO i = 1, n
                    CALL md_ampdef%add_point(desc_amp%time_points(i), desc_amp%amplitude_value(i))
                END DO
            END IF
        CASE (AMP_SMOOTH)
            CALL md_ampdef%set_smooth_step(desc_amp%smooth_t1, desc_amp%smooth_t2, &
                desc_amp%smooth_a1, desc_amp%smooth_a2)
        CASE (AMP_RAMP)
            CALL md_ampdef%set_ramp(desc_amp%ramp_t_end)
        CASE (AMP_PERIODIC)
            CALL md_ampdef%set_periodic(desc_amp%periodic_freq, desc_amp%periodic_amp, &
                desc_amp%periodic_phase, desc_amp%periodic_offset)
        CASE (AMP_DECAY)
            md_ampdef%amp_type = AMP_DECAY
            md_ampdef%decay_a0 = desc_amp%decay_a0
            md_ampdef%decay_rate = desc_amp%decay_rate
        CASE (AMP_MODULATED)
            CALL md_ampdef%set_modulated(desc_amp%periodic_freq, desc_amp%periodic_amp, &
                phase=desc_amp%periodic_phase, mod_freq=desc_amp%modulated_freq, &
                mod_depth=desc_amp%modulated_depth)
        CASE (AMP_USER)
            md_ampdef%amp_type = AMP_USER
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Amp_FromExt_Def: USER amplitude requires pointer binding outside API"
            RETURN
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Amp_FromExt_Def: unsupported amp_type for Desc import"
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Amp_FromExt_Def

    SUBROUTINE MD_Amp_FromExt_DB(desc_amps, md_ampdb, status)
        TYPE(MD_Amp_Ext_Desc), INTENT(IN), TARGET :: desc_amps(:)
        TYPE(MD_Amp_Slot_Ctx), INTENT(INOUT) :: md_ampdb
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        TYPE(MD_Amp_Slot_Desc) :: amp_def

        CALL init_error_status(status)
        CALL md_ampdb%init()

        DO i = 1, SIZE(desc_amps)
            CALL MD_Amp_FromExt_Def(desc_amps(i), amp_def, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
            CALL md_ampdb%add_amplitude(amp_def)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Amp_FromExt_DB

END MODULE MD_Amp_UF
