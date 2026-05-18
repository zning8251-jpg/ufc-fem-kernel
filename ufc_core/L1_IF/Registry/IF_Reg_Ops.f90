!===============================================================================
! MODULE: IF_Reg_Ctx
! LAYER:  L1_IF
! DOMAIN: Registry
! ROLE:   _Ctx
! BRIEF:  Registry state management - query, statistics, health monitoring.
!===============================================================================
!
! Contents (A-Z):
!   IF_Reg_State_CheckComponentHealth [P2] Check component health
!   IF_Reg_State_ClearCache           [P0] Clear cache statistics
!   IF_Reg_State_GetCacheStats        [P3] Get cache performance stats
!   IF_Reg_State_GetComponentCount    [P3] Get component count by type
!   IF_Reg_State_GetPluginCount       [P3] Get plugin count by type
!   IF_Reg_State_GetRegistryStatus    [P3] Get full registry state
!   IF_Reg_State_GetSolverCount       [P3] Get solver count by type
!   IF_Reg_State_Init                 [P0] Initialize registry state
!   IF_Reg_State_PrintSummary         [P3] Print registry summary
!
! Status: Active | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Reg_Ops
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Reg_Core, ONLY: ModelRegistry, QueryModelRegistry, &
                           BenchmarkModel, CheckModelDegradation
  USE IF_Reg_Def, ONLY: IF_Reg_Registry_State, &
                            REG_COMP_ELEMENT, REG_COMP_MATERIAL, REG_COMP_BC, &
                            REG_SOLVER_STD, REG_SOLVER_EXP, &
                            REG_PLUGIN_UEL, REG_PLUGIN_UMAT
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_Reg_State_Init
  PUBLIC :: IF_Reg_State_GetRegistryStatus
  PUBLIC :: IF_Reg_State_GetComponentCount
  PUBLIC :: IF_Reg_State_GetSolverCount
  PUBLIC :: IF_Reg_State_GetPluginCount
  PUBLIC :: IF_Reg_State_GetCacheStats
  PUBLIC :: IF_Reg_State_CheckComponentHealth
  PUBLIC :: IF_Reg_State_ClearCache
  PUBLIC :: IF_Reg_State_PrintSummary

  ! 全局注册表状态
  TYPE(IF_Reg_Registry_State), SAVE, TARGET :: g_registry_state

CONTAINS

  !=============================================================================
  ! [P0] IF_Reg_State_Init
  !=============================================================================
  SUBROUTINE IF_Reg_State_Init(status)
    !! 初始化注册表状态管理器
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 初始化状态
    g_registry_state%n_components = 0
    g_registry_state%n_solvers = 0
    g_registry_state%n_plugins = 0
    g_registry_state%n_total_registrations = 0
    
    g_registry_state%n_queries = 0
    g_registry_state%n_hits = 0
    g_registry_state%n_misses = 0
    g_registry_state%cache_hit_rate = 0.0_wp
    
    g_registry_state%is_initialized = .TRUE.
    g_registry_state%is_locked = .FALSE.
    g_registry_state%has_degraded_components = .FALSE.
    
    g_registry_state%n_errors = 0
    g_registry_state%last_error = ''
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_Reg_State_Init: 注册表状态初始化成功'
    
  END SUBROUTINE IF_Reg_State_Init

  !=============================================================================
  ! [P3] IF_Reg_State_GetRegistryStatus
  !=============================================================================
  SUBROUTINE IF_Reg_State_GetRegistryStatus(state, status)
    !! 获取注册表完整状态
    !!
    !! 参数:
    !!   state: 注册表状态(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_Reg_Registry_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_GetRegistryStatus: 注册表未初始化'
      RETURN
    END IF
    
    ! 复制状态
    state = g_registry_state
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_GetRegistryStatus

  !=============================================================================
  ! [P3] IF_Reg_State_GetComponentCount
  !=============================================================================
  SUBROUTINE IF_Reg_State_GetComponentCount(comp_type, count, status)
    !! 获取指定类型的组件数量
    !!
    !! 参数:
    !!   comp_type: 组件类型(IN)
    !!   count: 组件数量(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: comp_type
    INTEGER(i4), INTENT(OUT) :: count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_GetComponentCount: 注册表未初始化'
      RETURN
    END IF
    
    ! 根据类型返回计数(简化实现,实际应查询注册表)
    SELECT CASE (comp_type)
    CASE (REG_COMP_ELEMENT)
      count = g_registry_state%n_components / 3  ! 假设均匀分布
    CASE (REG_COMP_MATERIAL)
      count = g_registry_state%n_components / 3
    CASE (REG_COMP_BC)
      count = g_registry_state%n_components - 2*(g_registry_state%n_components / 3)
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Reg_State_GetComponentCount: 无效组件类型'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_GetComponentCount

  !=============================================================================
  ! [P3] IF_Reg_State_GetSolverCount
  !=============================================================================
  SUBROUTINE IF_Reg_State_GetSolverCount(solver_type, count, status)
    !! 获取指定类型的求解器数量
    !!
    !! 参数:
    !!   solver_type: 求解器类型(IN)
    !!   count: 求解器数量(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: solver_type
    INTEGER(i4), INTENT(OUT) :: count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_GetSolverCount: 注册表未初始化'
      RETURN
    END IF
    
    ! 简化实现
    IF (solver_type == REG_SOLVER_STD .OR. solver_type == REG_SOLVER_EXP) THEN
      count = g_registry_state%n_solvers
    ELSE
      count = 0
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_GetSolverCount

  !=============================================================================
  ! [P3] IF_Reg_State_GetPluginCount
  !=============================================================================
  SUBROUTINE IF_Reg_State_GetPluginCount(plugin_type, count, status)
    !! 获取指定类型的插件数量
    !!
    !! 参数:
    !!   plugin_type: 插件类型(IN)
    !!   count: 插件数量(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: plugin_type
    INTEGER(i4), INTENT(OUT) :: count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_GetPluginCount: 注册表未初始化'
      RETURN
    END IF
    
    ! 简化实现
    IF (plugin_type == REG_PLUGIN_UEL .OR. plugin_type == REG_PLUGIN_UMAT) THEN
      count = g_registry_state%n_plugins
    ELSE
      count = 0
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_GetPluginCount

  !=============================================================================
  ! [P3] IF_Reg_State_GetCacheStats
  !=============================================================================
  SUBROUTINE IF_Reg_State_GetCacheStats(n_queries, n_hits, n_misses, hit_rate, status)
    !! 获取缓存性能统计
    !!
    !! 参数:
    !!   n_queries: 查询总数(OUT)
    !!   n_hits: 命中数(OUT)
    !!   n_misses: 未命中数(OUT)
    !!   hit_rate: 命中率(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(OUT) :: n_queries, n_hits, n_misses
    REAL(wp), INTENT(OUT) :: hit_rate
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_GetCacheStats: 注册表未初始化'
      RETURN
    END IF
    
    n_queries = g_registry_state%n_queries
    n_hits = g_registry_state%n_hits
    n_misses = g_registry_state%n_misses
    
    ! 计算命中率
    IF (n_queries > 0) THEN
      hit_rate = REAL(n_hits, wp) / REAL(n_queries, wp)
    ELSE
      hit_rate = 0.0_wp
    END IF
    
    g_registry_state%cache_hit_rate = hit_rate
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_GetCacheStats

  !=============================================================================
  ! [P2] IF_Reg_State_CheckComponentHealth
  !=============================================================================
  SUBROUTINE IF_Reg_State_CheckComponentHealth(is_healthy, n_degraded, status)
    !! 检查注册表组件健康状态
    !!
    !! 参数:
    !!   is_healthy: 是否健康(OUT)
    !!   n_degraded: 降级组件数(OUT)
    !!   status: 错误状态(OUT)
    
    LOGICAL, INTENT(OUT) :: is_healthy
    INTEGER(i4), INTENT(OUT) :: n_degraded
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_CheckComponentHealth: 注册表未初始化'
      RETURN
    END IF
    
    ! 检查是否有降级组件
    is_healthy = .NOT. g_registry_state%has_degraded_components
    n_degraded = 0
    
    ! 简化实现: 如果有错误则认为不健康
    IF (g_registry_state%n_errors > 0) THEN
      is_healthy = .FALSE.
      n_degraded = g_registry_state%n_errors
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_CheckComponentHealth

  !=============================================================================
  ! [P0] IF_Reg_State_ClearCache
  !=============================================================================
  SUBROUTINE IF_Reg_State_ClearCache(status)
    !! 清空注册表缓存
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_ClearCache: 注册表未初始化'
      RETURN
    END IF
    
    ! 重置缓存统计
    g_registry_state%n_queries = 0
    g_registry_state%n_hits = 0
    g_registry_state%n_misses = 0
    g_registry_state%cache_hit_rate = 0.0_wp
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_Reg_State_ClearCache: 缓存已清空'
    
  END SUBROUTINE IF_Reg_State_ClearCache

  !=============================================================================
  ! [P3] IF_Reg_State_PrintSummary
  !=============================================================================
  SUBROUTINE IF_Reg_State_PrintSummary(status)
    !! 打印注册表状态摘要
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_registry_state%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_Reg_State_PrintSummary: 注册表未初始化'
      RETURN
    END IF
    
    ! 打印摘要信息
    PRINT '(A)', '========================================'
    PRINT '(A)', 'UFC Registry State Summary'
    PRINT '(A)', '========================================'
    PRINT '(A, I6)', 'Components:      ', g_registry_state%n_components
    PRINT '(A, I6)', 'Solvers:         ', g_registry_state%n_solvers
    PRINT '(A, I6)', 'Plugins:         ', g_registry_state%n_plugins
    PRINT '(A, I6)', 'Total Registrations: ', g_registry_state%n_total_registrations
    PRINT '(A)', '----------------------------------------'
    PRINT '(A, I6)', 'Queries:         ', g_registry_state%n_queries
    PRINT '(A, I6)', 'Cache Hits:      ', g_registry_state%n_hits
    PRINT '(A, I6)', 'Cache Misses:    ', g_registry_state%n_misses
    PRINT '(A, F6.2)', 'Hit Rate:        ', g_registry_state%cache_hit_rate * 100.0_wp
    PRINT '(A)', '----------------------------------------'
    PRINT '(A, L6)', 'Initialized:     ', g_registry_state%is_initialized
    PRINT '(A, L6)', 'Locked:          ', g_registry_state%is_locked
    PRINT '(A, L6)', 'Has Degraded:    ', g_registry_state%has_degraded_components
    PRINT '(A, I6)', 'Errors:          ', g_registry_state%n_errors
    PRINT '(A)', '========================================'
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Reg_State_PrintSummary

END MODULE IF_Reg_Ops
