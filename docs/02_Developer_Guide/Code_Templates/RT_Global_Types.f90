!===============================================================================
! Module: RT_Global_Types                                                [v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Global — Unified time bookkeeping and analysis control
!
! Purpose:
!   Centralized runtime state management with SINGLE SOURCE OF TRUTH for:
!   - Time variables (time_current, time_total, dtime)
!   - Increment counters (kstep, kinc, iter)
!   - Analysis type flags
!   - Convergence control
!   - Dynamic integration parameters (Newmark/HHT-α)
!
! Design principles:
!   1. Only ONE instance per analysis (singleton pattern)
!   2. Read-only access from physics layer (L4_PH)
!   3. Updated only by solver layer (L5_RT)
!   4. Zero-copy access via pointer association
!
! Usage:
!   TYPE(RT_Global_Ctx), TARGET :: global_ctx
!   ALLOCATE(global_ctx)
!   CALL global_ctx%Reset(kstep_curr)
!   CALL global_ctx%Update(dtime_curr)
!   
!   ! Access from domain Ctx:
!   time_val = mat_ctx%com_ctx%global_ctx%time_current
!===============================================================================
MODULE RT_Global_Types
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Global_Ctx
  
  !-- Analysis type constants
  INTEGER(i4), PARAMETER :: RT_ANALYSIS_ANALYSIS_STATIC     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER :: RT_ANALYSIS_ANALYSIS_DYNAMIC    = 2_i4  ! migrated
  INTEGER(i4), PARAMETER :: RT_ANALYSIS_ANALYSIS_THERMAL    = 3_i4  ! migrated
  INTEGER(i4), PARAMETER :: RT_ANALYSIS_ANALYSIS_COUPLING   = 4_i4  ! migrated
  
  !-- Default tolerances
  REAL(wp), PARAMETER :: DEFAULT_TOLERANCE = 1.0e-6_wp
  
  !=============================================================================
  ! RT_Global_Ctx — Global Runtime Context (SINGLETON)
  !=============================================================================
  TYPE, PUBLIC :: RT_Global_Ctx
    
    !-- Time bookkeeping (唯一数据源)
    REAL(wp)    :: time_current = 0.0_wp   ! Current time at start of increment
    REAL(wp)    :: time_total   = 0.0_wp   ! Total analysis time
    REAL(wp)    :: dtime        = 0.0_wp   ! Time increment Δt
    
    !-- Increment counters
    INTEGER(i4) :: kstep = 0               ! Step number (1-based)
    INTEGER(i4) :: kinc  = 0               ! Increment number within step
    INTEGER(i4) :: iter  = 0               ! Equilibrium iteration count
    
    !-- Analysis type
    INTEGER(i4) :: analysis_type = RT_ANALYSIS_ANALYSIS_STATIC
    LOGICAL     :: nlgeom = .FALSE.        ! Large deformation flag
    
    !-- Convergence control
    LOGICAL     :: is_converged = .FALSE.
    REAL(wp)    :: residual_norm = 0.0_wp
    REAL(wp)    :: tolerance = DEFAULT_TOLERANCE
    
    !-- Dynamic integration parameters (框架注入)
    !   newmark_params(1) = β  (beta,  default 0.25 → Newmark avg. accel.)
    !   newmark_params(2) = γ  (gamma, default 0.50 → Newmark avg. accel.)
    !   newmark_params(3) = α  (HHT-α, default 0.00 → standard Newmark)
    REAL(wp)    :: newmark_params(3) = [0.25_wp, 0.50_wp, 0.0_wp]
    
  CONTAINS
    
    PROCEDURE, PASS(this) :: Reset => RT_Global_Reset
    PROCEDURE, PASS(this) :: Update => RT_Global_Update
    PROCEDURE, PASS(this) :: GetTime => RT_Global_GetTime
    PROCEDURE, PASS(this) :: GetDtime => RT_Global_GetDtime
    PROCEDURE, PASS(this) :: GetKstep => RT_Global_GetKstep
    PROCEDURE, PASS(this) :: GetKinc => RT_Global_GetKinc
    
  END TYPE RT_Global_Ctx
  
CONTAINS
  
  !=============================================================================
  ! Reset global context for new step
  !=============================================================================
  SUBROUTINE RT_Global_Reset(this, kstep_curr)
    CLASS(RT_Global_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: kstep_curr
    
    this%kstep = kstep_curr
    this%kinc = 0
    this%iter = 0
    this%is_converged = .FALSE.
    this%residual_norm = 0.0_wp
  END SUBROUTINE
  
  !=============================================================================
  ! Update global context for next increment
  !=============================================================================
  SUBROUTINE RT_Global_Update(this, dtime_curr)
    CLASS(RT_Global_Ctx), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: dtime_curr
    
    this%time_current = this%time_current + dtime_curr
    this%time_total = this%time_total + dtime_curr
    this%dtime = dtime_curr
    this%kinc = this%kinc + 1
    this%iter = 0
    this%is_converged = .FALSE.
  END SUBROUTINE
  
  !=============================================================================
  ! Convenience accessors (zero-copy)
  !=============================================================================
  FUNCTION RT_Global_GetTime(this) RESULT(time_val)
    CLASS(RT_Global_Ctx), INTENT(IN) :: this
    REAL(wp) :: time_val
    time_val = this%time_current
  END FUNCTION
  
  FUNCTION RT_Global_GetDtime(this) RESULT(dtime_val)
    CLASS(RT_Global_Ctx), INTENT(IN) :: this
    REAL(wp) :: dtime_val
    dtime_val = this%dtime
  END FUNCTION
  
  FUNCTION RT_Global_GetKstep(this) RESULT(kstep_val)
    CLASS(RT_Global_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: kstep_val
    kstep_val = this%kstep
  END FUNCTION
  
  FUNCTION RT_Global_GetKinc(this) RESULT(kinc_val)
    CLASS(RT_Global_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: kinc_val
    kinc_val = this%kinc
  END FUNCTION
  
END MODULE RT_Global_Types


!===============================================================================
! Module: RT_Com_Base_Types                                          [v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Common — Shared UMAT+UEL base context (Level 2 of 3-tier Ctx)
!
! Three-Tier Ctx Architecture:
!   Level 1: RT_Global_Ctx  (singleton, time/step/convergence)
!   Level 2: RT_Com_Base_Ctx (per-call, LFLAGS/elem_id/gauss, shared by all domains)
!   Level 3: RT_Mat_Ctx / RT_Elem_Ctx ... (domain-specific fields)
!
! Access pattern (zero-copy hot-path):
!   time_now = mat_ctx%com%global_ctx%time_current
!===============================================================================
MODULE RT_Com_Base_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE RT_Global_Types, ONLY: RT_Global_Ctx
  IMPLICIT NONE
  PRIVATE

  ! ----------------------------------------------------------------
  ! LFLAGS 常量（对应Abaqus LFLAGS数组）
  ! ----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LFLAG_LFLAG_GENERAL_STEP   = 1_i4  ! LFLAGS(1): 分析类型  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LFLAG_LFLAG_NLGEOM         = 2_i4  ! LFLAGS(2): 几何非线性  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LFLAG_LFLAG_PERTURBATION   = 4_i4  ! LFLAGS(4): 扰动分析  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LFLAG_LFLAG_STIFFNESS_ONLY = 5_i4  ! LFLAGS(5): 只计算刚度  ! migrated

  ! 增量标识常量
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KINC_KINC_START_STEP   = 0_i4  ! 分析步开始标识  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KINC_KINC_FIRST_INC    = 1_i4  ! 第一个增量  ! migrated

  ! ----------------------------------------------------------------
  !> @type RT_Com_Base_Ctx
  !> @brief 所有域共享的调用上下文（三层架构Level 2）
  !>
  !> 通过 global_ctx 指针访问唯一时间源（零拷贝）。
  !> 不重复定义 time/dtime 字段 — 所有需求通过指针链访问。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_Com_Base_Ctx
    !-- Level 1 指针（非拥有，调用方管理生命周期）
    TYPE(RT_Global_Ctx), POINTER :: global_ctx => NULL()   ! 唯一时间源

    !-- Abaqus 标准 LFLAGS（6个元素）
    INTEGER(i4)  :: lflags(6)     = 0_i4    ! Abaqus LFLAGS数组

    !-- 元素定位信息
    INTEGER(i4)  :: jelem         = 0_i4    ! 元素编号
    INTEGER(i4)  :: npt           = 0_i4    ! 当前标内点号
    INTEGER(i4)  :: layer         = 0_i4    ! 层号（壳/梁）
    INTEGER(i4)  :: kspt          = 0_i4    ! 截面点号
    INTEGER(i4)  :: kstep         = 0_i4    ! 当前步号（从 global_ctx拷贝，快捷访问）
    INTEGER(i4)  :: kinc          = 0_i4    ! 当前增量号

    !-- 分析状态快捷标志（从 global_ctx 派生，阻止热路径查找）
    LOGICAL      :: is_nlgeom     = .FALSE.  ! 几何非线性标志
    LOGICAL      :: is_perturbation = .FALSE. ! 扰动分析标志
    LOGICAL      :: is_first_inc  = .FALSE.  ! 分析内首个增量

    !-- 坐标系信息
    REAL(wp)     :: coords(3)     = 0.0_wp   ! 当前点全局坐标
    REAL(wp)     :: celent        = 0.0_wp   ! 元素特征长度
    REAL(wp)     :: rpl           = 0.0_wp   ! 单位体积热生成率（材料返回）
    REAL(wp)     :: drplde(6)     = 0.0_wp   ! dRPL/dstrain
    REAL(wp)     :: drpldt        = 0.0_wp   ! dRPL/dtemperature

    !-- 状态标志
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Com_Base_Ctx

END MODULE RT_Com_Base_Types
