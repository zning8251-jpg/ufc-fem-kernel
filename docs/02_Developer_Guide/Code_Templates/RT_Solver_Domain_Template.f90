!===============================================================================
! Module: RT_Solver_Domain_Template                            [Template v3.2]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Solver — Domain 容器参考实现
!
! PURPOSE:
!   演示 RT_Solver 域如何实现 Domain 容器模式，包括：
!   - ABSTRACT BASE TYPE + EXTENDS 多态设计（支持 Standard/Explicit）
!   - Domain 容器与生命周期管理 (Init/Finalize/WriteBack)
!   - 精度统一 (wp, i4) + IF_Err_Brg structured status 基线
!   - 求解器选择路由、约束检查、性能统计
!
! MODIFICATIONS:
!   [Template v3.1] 初始版本
!   [Template v3.2] 新增 Domain 容器、求解器路由、ErrorStatusType 集成
!   [Template v3.2] 注释对齐 IF_Err_Brg + structured status baseline
!===============================================================================
MODULE RT_Solver_Domain_Template
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Solver_Base_Desc, RT_Solver_Standard_Desc, RT_Solver_Explicit_Desc
  PUBLIC :: RT_Solver_State, RT_Solver_Algo, RT_Solver_Ctx
  PUBLIC :: RT_Solver_Domain

  ! ===== CONSTANTS =====
  INTEGER(i4), PARAMETER :: SOLVER_STANDARD = 1_i4
  INTEGER(i4), PARAMETER :: SOLVER_EXPLICIT = 2_i4
  INTEGER(i4), PARAMETER :: SOLVER_FREQUENCY = 3_i4
  INTEGER(i4), PARAMETER :: SOLVER_HEAT = 4_i4

  ! ===============================================================================
  ! ABSTRACT BASE TYPE — 多态设计入口
  ! ===============================================================================
  TYPE, PUBLIC, ABSTRACT :: RT_Solver_Base_Desc
    INTEGER(i4) :: solver_type_id = 0_i4
    CHARACTER(len=32) :: solver_type = "STANDARD"
    INTEGER(i4) :: analysis_proc_id = 0_i4
    INTEGER(i4) :: analysis_group_id = 0_i4
    CHARACTER(len=32) :: solution_method = "DIRECT"
    CHARACTER(len=32) :: preconditioner = "JACOBI"
    LOGICAL :: supports_nonlinear = .TRUE.
    LOGICAL :: supports_contact = .TRUE.
    LOGICAL :: supports_large_deformation = .FALSE.
    LOGICAL :: supports_dynamic = .TRUE.
  END TYPE RT_Solver_Base_Desc

  ! ===============================================================================
  ! 具体扩展类型 1: Standard (隐式) 求解器
  ! ===============================================================================
  TYPE, PUBLIC, EXTENDS(RT_Solver_Base_Desc) :: RT_Solver_Standard_Desc
    CHARACTER(len=32) :: time_integration = "NEWMARK"
    REAL(wp) :: alpha_generalized = -0.1_wp
  END TYPE RT_Solver_Standard_Desc

  ! ===============================================================================
  ! 具体扩展类型 2: Explicit (显式) 求解器
  ! ===============================================================================
  TYPE, PUBLIC, EXTENDS(RT_Solver_Base_Desc) :: RT_Solver_Explicit_Desc
    LOGICAL :: use_adaptive_timestep = .TRUE.
    REAL(wp) :: cfl_factor = 0.9_wp
  END TYPE RT_Solver_Explicit_Desc

  ! ===============================================================================
  ! State 类型 — 求解器状态
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Solver_State
    INTEGER(i4) :: active_solver_type = 0_i4
    LOGICAL :: solver_initialized = .FALSE.
    INTEGER(i4) :: num_linear_iterations = 0_i4
    INTEGER(i4) :: num_newton_iterations = 0_i4
    REAL(wp) :: residual_final = 0.0_wp
    INTEGER(i4) :: num_solver_calls = 0_i4
    REAL(wp) :: total_solver_time = 0.0_wp
    REAL(wp) :: matrix_assembly_time = 0.0_wp
    REAL(wp) :: factorization_time = 0.0_wp
    REAL(wp) :: back_substitution_time = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Solver_State

  ! ===============================================================================
  ! Algo 类型 — 算法控制
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Solver_Algo
    LOGICAL :: auto_select_solver = .TRUE.
    LOGICAL :: allow_solver_switching = .FALSE.
    CHARACTER(len=32) :: time_stepping = "IMPLICIT"
    REAL(wp) :: dt_max = 0.1_wp
    LOGICAL :: use_automatic_substep = .TRUE.
    LOGICAL :: use_penalty_method = .FALSE.
    LOGICAL :: use_lagrange_multipliers = .TRUE.
    LOGICAL :: use_augmented_lagrangian = .FALSE.
    INTEGER(i4) :: max_newton_iters = 100_i4
    REAL(wp) :: newton_tolerance = 1.0e-6_wp
  END TYPE RT_Solver_Algo

  ! ===============================================================================
  ! Ctx 类型 — 运行上下文
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Solver_Ctx
    INTEGER(i4) :: solver_ctx_id = 0_i4
    REAL(wp) :: analysis_total_time = 0.0_wp
    INTEGER(i4) :: num_analyses = 0_i4
    LOGICAL :: trace_solver_selection = .FALSE.
    CHARACTER(len=256) :: solver_log_file = ""
  END TYPE RT_Solver_Ctx

  ! ===============================================================================
  ! Domain 容器 — 求解器集合的生命周期管理
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Solver_Domain
    TYPE(RT_Solver_Base_Desc), POINTER :: desc(:) => NULL()
    TYPE(RT_Solver_State), POINTER :: state(:) => NULL()
    TYPE(RT_Solver_Algo), POINTER :: algo(:) => NULL()
    TYPE(RT_Solver_Ctx), POINTER :: ctx(:) => NULL()
    INTEGER(i4) :: n_solvers = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => RT_Solver_Domain_Init
    PROCEDURE :: Finalize => RT_Solver_Domain_Finalize
    PROCEDURE :: WriteBack => RT_Solver_WriteBack
  END TYPE RT_Solver_Domain

CONTAINS

  ! ===============================================================================
  ! 实现: Domain 初始化
  ! ===============================================================================
  SUBROUTINE RT_Solver_Domain_Init(this, n_solvers, status)
    CLASS(RT_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_solvers
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (n_solvers <= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Solver_Domain_Init: n_solvers 必须 > 0"
      RETURN
    END IF

    ! 释放已有的数组
    IF (ALLOCATED(this%desc)) DEALLOCATE(this%desc)
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo)) DEALLOCATE(this%algo)
    IF (ALLOCATED(this%ctx)) DEALLOCATE(this%ctx)

    ! 分配新数组
    ALLOCATE(this%desc(n_solvers))
    ALLOCATE(this%state(n_solvers))
    ALLOCATE(this%algo(n_solvers))
    ALLOCATE(this%ctx(n_solvers))

    this%n_solvers = n_solvers
    this%initialized = .TRUE.

    status%status_code = IF_STATUS_OK
    status%message = "RT_Solver_Domain 初始化成功"
  END SUBROUTINE RT_Solver_Domain_Init

  ! ===============================================================================
  ! 实现: Domain 清理
  ! ===============================================================================
  SUBROUTINE RT_Solver_Domain_Finalize(this, status)
    CLASS(RT_Solver_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Solver_Domain 未初始化"
      RETURN
    END IF

    ! 释放容器
    IF (ALLOCATED(this%desc)) DEALLOCATE(this%desc)
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo)) DEALLOCATE(this%algo)
    IF (ALLOCATED(this%ctx)) DEALLOCATE(this%ctx)

    this%n_solvers = 0_i4
    this%initialized = .FALSE.

    status%status_code = IF_STATUS_OK
    status%message = "RT_Solver_Domain 清理完成"
  END SUBROUTINE RT_Solver_Domain_Finalize

  ! ===============================================================================
  ! 实现: Domain WriteBack — 将求解器统计信息写回
  ! ===============================================================================
  SUBROUTINE RT_Solver_WriteBack(this, status)
    CLASS(RT_Solver_Domain), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Solver_Domain 未初始化"
      RETURN
    END IF

    ! 演示: 将每个求解器的统计信息写到日志
    DO i = 1_i4, this%n_solvers
      IF (LEN_TRIM(this%ctx(i)%solver_log_file) > 0_i4) THEN
        PRINT *, "WriteBack: 求解器 #", i, " (&
                  & solver_type=", TRIM(this%desc(i)%solver_type), &
                  & ", calls=", this%state(i)%num_solver_calls, &
                  & ", total_time=", this%state(i)%total_solver_time, " 秒)"
      END IF
    END DO

    status%status_code = IF_STATUS_OK
    status%message = "RT_Solver_Domain WriteBack 完成"
  END SUBROUTINE RT_Solver_WriteBack

END MODULE RT_Solver_Domain_Template
