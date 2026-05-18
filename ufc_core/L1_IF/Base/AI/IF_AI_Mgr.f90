!===============================================================================
! MODULE: IF_AI_Mgr
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Mgr — core inference engine container (session / batch / device / cache)
! BRIEF:  ONNX model session pool, batch inference, CPU/GPU switch, perf monitor.
!===============================================================================

MODULE IF_AI_Mgr
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_AI_Runtime, ONLY: IF_AI_SessionConfig, IF_AI_RuntimeState, &
                             IF_AI_SessionPool, IF_AI_CreateSession, &
                             IF_AI_RunSession, IF_AI_RunSession_Batch, &
                             IF_AI_DestroySession, IF_AI_SessionPool_Init, &
                             IF_AI_SessionPool_Acquire, IF_AI_SessionPool_Release
  IMPLICIT NONE
  PRIVATE

  ! Re-export types from IF_AI_Runtime for API convenience
  PUBLIC :: IF_AI_SessionConfig, IF_AI_RuntimeState, IF_AI_SessionPool

  !=============================================================================
  ! PUBLIC TYPES
  !=============================================================================

  !> AI推理缓存条目
  TYPE, PUBLIC :: IF_AI_CacheEntry
    INTEGER(i8) :: hash_key           ! 输入特征哈希键
    REAL(wp), ALLOCATABLE :: input(:)  ! 输入特征(用于碰撞检测)
    REAL(wp), ALLOCATABLE :: output(:) ! 输出预测(缓存结果)
    REAL(wp) :: timestamp             ! 缓存时间戳
    LOGICAL :: is_valid               ! 缓存有效性标志
  END TYPE IF_AI_CacheEntry

  !> AI推理缓存管理器
  TYPE, PUBLIC :: IF_AI_CacheManager
    TYPE(IF_AI_CacheEntry), ALLOCATABLE :: entries(:) ! 缓存条目数组
    INTEGER(i4) :: capacity                           ! 缓存容量
    INTEGER(i4) :: n_entries                          ! 当前条目数
    INTEGER(i4) :: hit_count                          ! 缓存命中次数
    INTEGER(i4) :: miss_count                         ! 缓存未命中次数
    REAL(wp) :: hit_rate                              ! 命中率
  END TYPE IF_AI_CacheManager

  !> AI推理性能统计
  TYPE, PUBLIC :: IF_AI_PerfStats
    INTEGER(i4) :: n_inferences           ! 推理次数
    REAL(wp) :: total_time_ms             ! 总耗时(毫秒)
    REAL(wp) :: avg_time_ms               ! 平均耗时(毫秒)
    REAL(wp) :: min_time_ms               ! 最小耗时(毫秒)
    REAL(wp) :: max_time_ms               ! 最大耗时(毫秒)
    REAL(wp) :: throughput_samples_per_s  ! 吞吐量(样本/秒)
    INTEGER(i4) :: n_gpu_inferences       ! GPU推理次数
    INTEGER(i4) :: n_cpu_inferences       ! CPU推理次数
  END TYPE IF_AI_PerfStats

  !> AI推理引擎域容器
  TYPE, PUBLIC :: IF_AI_Domain
    ! 会话管理
    TYPE(IF_AI_SessionPool) :: session_pool      ! 会话池
    INTEGER(i4) :: n_active_sessions             ! 活跃会话数
    
    ! 缓存管理
    TYPE(IF_AI_CacheManager) :: cache_mgr        ! 缓存管理器
    LOGICAL :: cache_enabled                     ! 缓存开关
    
    ! 性能统计
    TYPE(IF_AI_PerfStats) :: perf_stats          ! 性能统计
    LOGICAL :: perf_monitoring_enabled           ! 性能监控开关
    
    ! 域状态
    LOGICAL :: initialized                       ! 初始化标志
    CHARACTER(LEN=128) :: version                ! 版本号
  END TYPE IF_AI_Domain

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_AI_Domain_Init
  PUBLIC :: IF_AI_Domain_Finalize
  PUBLIC :: IF_AI_Domain_Infer
  PUBLIC :: IF_AI_Domain_Infer_Batch
  PUBLIC :: IF_AI_Domain_ClearCache
  PUBLIC :: IF_AI_Domain_GetPerfStats
  PUBLIC :: IF_AI_Domain_GetSummary

CONTAINS

  !=============================================================================
  ! IF_AI_Domain_Init - 初始化AI推理引擎域
  !=============================================================================
  SUBROUTINE IF_AI_Domain_Init(this, max_sessions, cache_capacity, status)
    !! 初始化AI推理引擎域
    !!
    !! 参数:
    !!   this: AI域容器(INOUT)
    !!   max_sessions: 最大会话数(IN)
    !!   cache_capacity: 缓存容量(IN)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: max_sessions
    INTEGER(i4), INTENT(IN) :: cache_capacity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 初始化域状态
    this%initialized = .FALSE.
    this%n_active_sessions = 0
    this%cache_enabled = .TRUE.
    this%perf_monitoring_enabled = .TRUE.
    this%version = 'L1_IF.AI.Core.v1.0'
    
    ! 初始化性能统计
    this%perf_stats%n_inferences = 0
    this%perf_stats%total_time_ms = 0.0_wp
    this%perf_stats%avg_time_ms = 0.0_wp
    this%perf_stats%min_time_ms = HUGE(1.0_wp)
    this%perf_stats%max_time_ms = 0.0_wp
    this%perf_stats%throughput_samples_per_s = 0.0_wp
    this%perf_stats%n_gpu_inferences = 0
    this%perf_stats%n_cpu_inferences = 0
    
    ! 初始化缓存管理器
    this%cache_mgr%capacity = cache_capacity
    this%cache_mgr%n_entries = 0
    this%cache_mgr%hit_count = 0
    this%cache_mgr%miss_count = 0
    this%cache_mgr%hit_rate = 0.0_wp
    ALLOCATE(this%cache_mgr%entries(cache_capacity))
    this%cache_mgr%entries(:)%is_valid = .FALSE.
    
    ! 会话池将由上层调用IF_AI_SessionPool_Init初始化
    ! 此处仅标记域已初始化
    this%initialized = .TRUE.
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_Domain_Init: AI推理引擎域初始化成功'
    
  END SUBROUTINE IF_AI_Domain_Init

  !=============================================================================
  ! IF_AI_Domain_Finalize - 释放AI推理引擎域资源
  !=============================================================================
  SUBROUTINE IF_AI_Domain_Finalize(this, status)
    !! 释放AI推理引擎域资源
    !!
    !! 参数:
    !!   this: AI域容器(INOUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Domain_Finalize: 域未初始化'
      RETURN
    END IF
    
    ! 释放缓存
    IF (ALLOCATED(this%cache_mgr%entries)) THEN
      DEALLOCATE(this%cache_mgr%entries)
    END IF
    
    ! 重置域状态
    this%initialized = .FALSE.
    this%n_active_sessions = 0
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_Domain_Finalize: AI推理引擎域资源释放成功'
    
  END SUBROUTINE IF_AI_Domain_Finalize

  !=============================================================================
  ! IF_AI_Domain_Infer - 单样本推理(带缓存优化)
  !=============================================================================
  SUBROUTINE IF_AI_Domain_Infer(this, session_idx, input_buffer, output_buffer, status)
    !! 单样本推理(带缓存优化)
    !!
    !! 参数:
    !!   this: AI域容器(INOUT)
    !!   session_idx: 会话索引(IN)
    !!   input_buffer: 输入特征(IN)
    !!   output_buffer: 输出预测(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: session_idx
    REAL(wp), INTENT(IN) :: input_buffer(:)
    REAL(wp), INTENT(OUT) :: output_buffer(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    INTEGER(i8) :: hash_key
    LOGICAL :: cache_hit
    
    CALL init_error_status(status)
    
    ! 检查域初始化状态
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Domain_Infer: AI域未初始化'
      RETURN
    END IF
    
    ! 检查缓存(如果启用)
    cache_hit = .FALSE.
    IF (this%cache_enabled) THEN
      ! 计算输入哈希键(简化版:使用第一个元素)
      hash_key = INT(input_buffer(1) * 1000000_i8, i8)
      
      ! 查找缓存
      DO i = 1, this%cache_mgr%n_entries
        IF (this%cache_mgr%entries(i)%is_valid .AND. &
            this%cache_mgr%entries(i)%hash_key == hash_key) THEN
          ! 缓存命中
          output_buffer = this%cache_mgr%entries(i)%output
          cache_hit = .TRUE.
          this%cache_mgr%hit_count = this%cache_mgr%hit_count + 1
          EXIT
        END IF
      END DO
      
      IF (.NOT. cache_hit) THEN
        this%cache_mgr%miss_count = this%cache_mgr%miss_count + 1
      END IF
      
      ! 更新命中率
      IF (this%cache_mgr%hit_count + this%cache_mgr%miss_count > 0) THEN
        this%cache_mgr%hit_rate = REAL(this%cache_mgr%hit_count, wp) / &
                                  REAL(this%cache_mgr%hit_count + this%cache_mgr%miss_count, wp)
      END IF
    END IF
    
    ! 缓存未命中,执行实际推理
    IF (.NOT. cache_hit) THEN
      CALL IF_AI_RunSession(this%session_pool%sessions(session_idx), &
                           input_buffer, output_buffer, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      
      ! 更新缓存(如果启用)
      IF (this%cache_enabled .AND. this%cache_mgr%n_entries < this%cache_mgr%capacity) THEN
        this%cache_mgr%n_entries = this%cache_mgr%n_entries + 1
        i = this%cache_mgr%n_entries
        this%cache_mgr%entries(i)%hash_key = hash_key
        ALLOCATE(this%cache_mgr%entries(i)%input(SIZE(input_buffer)))
        ALLOCATE(this%cache_mgr%entries(i)%output(SIZE(output_buffer)))
        this%cache_mgr%entries(i)%input = input_buffer
        this%cache_mgr%entries(i)%output = output_buffer
        this%cache_mgr%entries(i)%is_valid = .TRUE.
      END IF
    END IF
    
    ! 更新性能统计
    IF (this%perf_monitoring_enabled) THEN
      this%perf_stats%n_inferences = this%perf_stats%n_inferences + 1
      this%perf_stats%n_cpu_inferences = this%perf_stats%n_cpu_inferences + 1
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Domain_Infer

  !=============================================================================
  ! IF_AI_Domain_Infer_Batch - 批量推理(热路径优化)
  !=============================================================================
  SUBROUTINE IF_AI_Domain_Infer_Batch(this, session_idx, batch_size, &
                                       input_batch, output_batch, status)
    !! 批量推理(热路径优化)
    !!
    !! 参数:
    !!   this: AI域容器(INOUT)
    !!   session_idx: 会话索引(IN)
    !!   batch_size: 批量大小(IN)
    !!   input_batch: 输入特征批次(IN)
    !!   output_batch: 输出预测批次(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: session_idx
    INTEGER(i4), INTENT(IN) :: batch_size
    REAL(wp), INTENT(IN) :: input_batch(:,:)
    REAL(wp), INTENT(OUT) :: output_batch(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查域初始化状态
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Domain_Infer_Batch: AI域未初始化'
      RETURN
    END IF
    
    ! 批量推理不使用缓存(输入维度太高,缓存命中率低)
    ! 直接调用底层批量推理接口
    CALL IF_AI_RunSession_Batch(this%session_pool%sessions(session_idx), &
                                batch_size, input_batch, output_batch, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! 更新性能统计
    IF (this%perf_monitoring_enabled) THEN
      this%perf_stats%n_inferences = this%perf_stats%n_inferences + 1
      this%perf_stats%n_cpu_inferences = this%perf_stats%n_cpu_inferences + 1
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Domain_Infer_Batch

  !=============================================================================
  ! IF_AI_Domain_ClearCache - 清空推理缓存
  !=============================================================================
  SUBROUTINE IF_AI_Domain_ClearCache(this, status)
    !! 清空推理缓存
    !!
    !! 参数:
    !!   this: AI域容器(INOUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    ! 释放所有缓存条目
    DO i = 1, this%cache_mgr%n_entries
      IF (ALLOCATED(this%cache_mgr%entries(i)%input)) THEN
        DEALLOCATE(this%cache_mgr%entries(i)%input)
      END IF
      IF (ALLOCATED(this%cache_mgr%entries(i)%output)) THEN
        DEALLOCATE(this%cache_mgr%entries(i)%output)
      END IF
      this%cache_mgr%entries(i)%is_valid = .FALSE.
    END DO
    
    ! 重置缓存统计
    this%cache_mgr%n_entries = 0
    this%cache_mgr%hit_count = 0
    this%cache_mgr%miss_count = 0
    this%cache_mgr%hit_rate = 0.0_wp
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_Domain_ClearCache: 推理缓存已清空'
    
  END SUBROUTINE IF_AI_Domain_ClearCache

  !=============================================================================
  ! IF_AI_Domain_GetPerfStats - 获取性能统计
  !=============================================================================
  SUBROUTINE IF_AI_Domain_GetPerfStats(this, stats, status)
    !! 获取性能统计
    !!
    !! 参数:
    !!   this: AI域容器(IN)
    !!   stats: 性能统计(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(IN) :: this
    TYPE(IF_AI_PerfStats), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    stats = this%perf_stats
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Domain_GetPerfStats

  !=============================================================================
  ! IF_AI_Domain_GetSummary - 获取AI域配置摘要
  !=============================================================================
  SUBROUTINE IF_AI_Domain_GetSummary(this, summary, status)
    !! 获取AI域配置摘要
    !!
    !! 参数:
    !!   this: AI域容器(IN)
    !!   summary: 配置摘要(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_Domain), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(summary, '(A)') 'L1_IF.AI.Domain.Summary:'
    WRITE(summary, '(A,I6)') '  Version: ', LEN(this%version)
    WRITE(summary, '(A,L)') '  Initialized: ', this%initialized
    WRITE(summary, '(A,I6)') '  Active Sessions: ', this%n_active_sessions
    WRITE(summary, '(A,L)') '  Cache Enabled: ', this%cache_enabled
    WRITE(summary, '(A,I6)') '  Cache Capacity: ', this%cache_mgr%capacity
    WRITE(summary, '(A,I6)') '  Cache Entries: ', this%cache_mgr%n_entries
    WRITE(summary, '(A,F8.4)') '  Cache Hit Rate: ', this%cache_mgr%hit_rate
    WRITE(summary, '(A,I8)') '  Total Inferences: ', this%perf_stats%n_inferences
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Domain_GetSummary

END MODULE IF_AI_Mgr