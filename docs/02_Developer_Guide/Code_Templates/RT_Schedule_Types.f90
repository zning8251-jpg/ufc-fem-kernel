!> @file RT_Schedule_Types.f90
!> @brief L5_RT层 — 子程序调度与热路径控制类型
!>
!> 覆盖：调用记录、域调度表、分发算法控制、热路径Ctx
!> 语义分类：
!>   Record  — 单次子程序调用记录（日志/诊断）
!>   Desc    — 域级调度配置
!>   Algo    — 调度分发算法控制参数
!>   Ctx     — 热路径call-scoped驱动输入
!>
MODULE RT_Schedule_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ----------------------------------------------------------------
  ! 子程序域ID常量（与RT_Domain_Types对齐）
  ! ----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_MAT     = 1_i4   ! 材料域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_ELEM    = 2_i4   ! 单元域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_LOAD    = 3_i4   ! 载荷域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_BC      = 4_i4   ! 边界域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_CONTACT = 5_i4   ! 接触域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_FRIC    = 6_i4   ! 摩擦域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_CONSTR  = 7_i4   ! 约束域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_FIELD   = 8_i4   ! 场域  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_DOM_ANALY   = 9_i4   ! 分析域  ! migrated

  ! 调度优先级常量
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_PRIO_CRIT   = 0_i4   ! 关键路径（不可跳过）  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_PRIO_HIGH   = 1_i4   ! 高优先级  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_PRIO_NORMAL = 2_i4   ! 普通  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SCHED_SCHED_PRIO_LOW    = 3_i4   ! 低优先级（可延迟）  ! migrated

  ! 分发模式常量
  INTEGER(i4), PARAMETER, PUBLIC :: RT_DISPATCH_DISPATCH_SERIAL   = 0_i4   ! 串行分发  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_DISPATCH_DISPATCH_OPENMP   = 1_i4   ! OpenMP并行  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_DISPATCH_DISPATCH_MPI      = 2_i4   ! MPI并行  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_DISPATCH_DISPATCH_HYBRID   = 3_i4   ! 混合并行  ! migrated

  ! ----------------------------------------------------------------
  !> @type RT_SubrCall_Record
  !> @brief 单次子程序调用记录（诊断/性能追踪用）
  !>
  !> 每次子程序调用完成后填充，供RT_Monitor/RT_Error聚合。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_SubrCall_Record
    INTEGER(i4)        :: domain_id    = 0_i4    ! 所属域ID
    INTEGER(i4)        :: subr_id      = 0_i4    ! 子程序标识符
    INTEGER(i4)        :: elem_id      = 0_i4    ! 关联单元ID（无则0）
    INTEGER(i4)        :: mat_id       = 0_i4    ! 关联材料ID（无则0）
    INTEGER(i4)        :: step_id      = 0_i4    ! 当前步号
    INTEGER(i4)        :: inc_id       = 0_i4    ! 当前增量步号
    REAL(wp)           :: wall_time_us = 0.0_wp  ! 本次调用耗时（微秒）
    LOGICAL            :: success      = .TRUE.  ! 是否成功
    INTEGER(i4)        :: err_code     = 0_i4    ! 错误码（成功时0）
    TYPE(ErrorStatusType) :: status
  END TYPE RT_SubrCall_Record

  ! ----------------------------------------------------------------
  !> @type RT_Domain_Schedule
  !> @brief 域级调度描述——记录某域下所有子程序的调度顺序与配置
  !>
  !> 在分析初始化阶段填充，分析期只读。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_Domain_Schedule
    INTEGER(i4)          :: domain_id       = 0_i4   ! 域ID
    INTEGER(i4)          :: n_subrs         = 0_i4   ! 该域注册的子程序数
    INTEGER(i4), ALLOCATABLE :: subr_ids(:)          ! 子程序ID列表，shape(n_subrs)
    INTEGER(i4), ALLOCATABLE :: subr_prio(:)         ! 每个子程序优先级，shape(n_subrs)
    LOGICAL,     ALLOCATABLE :: subr_enabled(:)      ! 是否启用，shape(n_subrs)
    INTEGER(i4)          :: dispatch_mode   = DISPATCH_SERIAL  ! 并行模式
    INTEGER(i4)          :: thread_count    = 1_i4   ! OpenMP线程数（如适用）
    LOGICAL              :: allow_reorder   = .FALSE. ! 允许运行时重排序
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Domain_Schedule

  ! ----------------------------------------------------------------
  !> @type RT_Dispatch_Algo
  !> @brief 调度分发算法控制参数（Algo类）
  !>
  !> 控制子程序分发时的负载均衡、批量大小及调度策略。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_Dispatch_Algo
    INTEGER(i4)  :: batch_size       = 64_i4    ! 每批次单元/积分点数
    INTEGER(i4)  :: min_batch_omp    = 8_i4     ! OpenMP最小批量阈值
    LOGICAL      :: dynamic_sched    = .TRUE.   ! 动态调度（vs 静态）
    INTEGER(i4)  :: omp_chunk        = 4_i4     ! OMP SCHEDULE chunk大小
    LOGICAL      :: prefetch_data    = .FALSE.  ! 预取数据到缓存
    LOGICAL      :: profile_enabled  = .FALSE.  ! 启用性能剖析记录
    INTEGER(i4)  :: max_call_records = 1024_i4  ! 最大调用记录数（环形缓冲）
    REAL(wp)     :: hot_threshold_us = 100.0_wp ! 热路径时间阈值（微秒）
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Dispatch_Algo

  ! ----------------------------------------------------------------
  !> @type RT_HotPath_Ctx
  !> @brief 热路径call-scoped驱动输入（Ctx类）
  !>
  !> 在单次迭代最内层循环传递，避免重复查找开销。
  !> 所有指针为非拥有（non-owning），由调用方管理生命周期。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_HotPath_Ctx
    INTEGER(i4)          :: domain_id    = 0_i4   ! 当前处理域
    INTEGER(i4)          :: subr_id      = 0_i4   ! 当前子程序ID
    INTEGER(i4)          :: n_pts        = 0_i4   ! 本批次积分点/单元数
    INTEGER(i4)          :: start_idx    = 0_i4   ! 批次起始索引
    INTEGER(i4)          :: end_idx      = 0_i4   ! 批次结束索引（含）
    LOGICAL              :: is_vectorized= .FALSE. ! 是否向量化路径（VUMAT等）
    LOGICAL              :: first_call   = .FALSE. ! 分析内首次调用标志
    REAL(wp)             :: step_time    = 0.0_wp  ! 当前步总时间
    REAL(wp)             :: inc_time     = 0.0_wp  ! 当前增量步时间
    REAL(wp)             :: dtime        = 0.0_wp  ! 本增量步时间增量
    TYPE(ErrorStatusType) :: status
  END TYPE RT_HotPath_Ctx

END MODULE RT_Schedule_Types
