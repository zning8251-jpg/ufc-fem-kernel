!===============================================================================
! MODULE: IF_AI_Brg
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Brg — unified API bridge for 6 AI inference slots
! BRIEF:  Model load/unload, infer, session mgmt, cache, performance query.
!===============================================================================

MODULE IF_AI_Brg
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_AI_Mgr, ONLY: IF_AI_Domain, IF_AI_SessionConfig, IF_AI_PerfStats, &
                          IF_AI_Domain_Init, IF_AI_Domain_Finalize, &
                          IF_AI_Domain_Infer, IF_AI_Domain_Infer_Batch, &
                          IF_AI_Domain_ClearCache, IF_AI_Domain_GetPerfStats, &
                          IF_AI_Domain_GetSummary
  USE IF_AI_Runtime, ONLY: IF_AI_SessionPool_Init, IF_AI_SessionPool_Acquire, &
                             IF_AI_SessionPool_Release, IF_AI_DestroySession
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! 全局AI域实例(进程级单例)
  !=============================================================================
  TYPE(IF_AI_Domain), SAVE, PUBLIC :: g_ai_domain

  !=============================================================================
  ! PUBLIC INTERFACES - 统一API接口
  !=============================================================================
  PUBLIC :: IF_AI_API_Init
  PUBLIC :: IF_AI_API_Finalize
  PUBLIC :: IF_AI_API_LoadModel
  PUBLIC :: IF_AI_API_UnloadModel
  PUBLIC :: IF_AI_API_Infer
  PUBLIC :: IF_AI_API_Infer_Batch
  PUBLIC :: IF_AI_API_ClearCache
  PUBLIC :: IF_AI_API_GetPerfStats
  PUBLIC :: IF_AI_API_GetVersion
  PUBLIC :: IF_AI_API_GetSummary

CONTAINS

  !=============================================================================
  ! IF_AI_API_Init - 初始化AI API系统
  !=============================================================================
  SUBROUTINE IF_AI_API_Init(max_sessions, cache_capacity, status)
    !! 初始化AI API系统(进程级单次调用)
    !!
    !! 参数:
    !!   max_sessions: 最大并发会话数(IN)
    !!   cache_capacity: 推理缓存容量(IN)
    !!   status: 错误状态(OUT)
    !!
    !! 调用时机: Job初始化阶段(L6_AP→L5_RT→L1_IF)
    !! 线程安全: 是(进程级单次初始化)
    
    INTEGER(i4), INTENT(IN) :: max_sessions
    INTEGER(i4), INTENT(IN) :: cache_capacity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 初始化AI域容器
    CALL IF_AI_Domain_Init(g_ai_domain, max_sessions, cache_capacity, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_Init: AI域初始化失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_API_Init: AI API系统初始化成功'
    
  END SUBROUTINE IF_AI_API_Init

  !=============================================================================
  ! IF_AI_API_Finalize - 释放AI API系统资源
  !=============================================================================
  SUBROUTINE IF_AI_API_Finalize(status)
    !! 释放AI API系统资源(进程级单次调用)
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    !!
    !! 调用时机: Job清理阶段
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 释放AI域容器
    CALL IF_AI_Domain_Finalize(g_ai_domain, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_Finalize: AI域释放失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_API_Finalize: AI API系统资源释放成功'
    
  END SUBROUTINE IF_AI_API_Finalize

  !=============================================================================
  ! IF_AI_API_LoadModel - 加载AI模型
  !=============================================================================
  SUBROUTINE IF_AI_API_LoadModel(model_path, exec_provider, session_idx, status)
    !! 加载AI模型并创建推理会话
    !!
    !! 参数:
    !!   model_path: ONNX模型路径(IN)
    !!   exec_provider: 执行提供者(CPU/CUDA/TensorRT)(IN)
    !!   session_idx: 会话索引(OUT)
    !!   status: 错误状态(OUT)
    !!
    !! 调用时机: 模型预加载阶段/热更新时
    
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    CHARACTER(LEN=*), INTENT(IN) :: exec_provider
    INTEGER(i4), INTENT(OUT) :: session_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(IF_AI_SessionConfig) :: config
    TYPE(ErrorStatusType) :: local_status
    
    CALL init_error_status(status)
    session_idx = -1
    
    ! 检查域初始化状态
    IF (.NOT. g_ai_domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_API_LoadModel: AI域未初始化,请先调用IF_AI_API_Init'
      RETURN
    END IF
    
    ! 配置会话参数
    config%model_path = model_path
    config%execution_provider = exec_provider
    
    ! TODO: 实现会话池动态扩展
    ! 当前为简化实现,假设会话池已预分配
    IF (g_ai_domain%n_active_sessions >= SIZE(g_ai_domain%session_pool%sessions)) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_AI_API_LoadModel: 会话池已满,无法加载新模型'
      RETURN
    END IF
    
    ! 创建会话(简化实现)
    g_ai_domain%n_active_sessions = g_ai_domain%n_active_sessions + 1
    session_idx = g_ai_domain%n_active_sessions
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_API_LoadModel: 模型加载成功'
    
  END SUBROUTINE IF_AI_API_LoadModel

  !=============================================================================
  ! IF_AI_API_UnloadModel - 卸载AI模型
  !=============================================================================
  SUBROUTINE IF_AI_API_UnloadModel(session_idx, status)
    !! 卸载AI模型并释放会话资源
    !!
    !! 参数:
    !!   session_idx: 会话索引(IN)
    !!   status: 错误状态(OUT)
    !!
    !! 调用时机: 模型热更新时/Job清理时
    
    INTEGER(i4), INTENT(IN) :: session_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查域初始化状态
    IF (.NOT. g_ai_domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_API_UnloadModel: AI域未初始化'
      RETURN
    END IF
    
    ! 检查会话索引有效性
    IF (session_idx < 1 .OR. session_idx > g_ai_domain%n_active_sessions) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_API_UnloadModel: 无效会话索引'
      RETURN
    END IF
    
    ! TODO: 释放会话资源
    ! 当前为简化实现
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_API_UnloadModel: 模型卸载成功'
    
  END SUBROUTINE IF_AI_API_UnloadModel

  !=============================================================================
  ! IF_AI_API_Infer - 单样本推理
  !=============================================================================
  SUBROUTINE IF_AI_API_Infer(session_idx, input_buffer, output_buffer, status)
    !! 单样本推理(供AI_StepCtr/AI_MatInteg/AI_ContactLaw调用)
    !!
    !! 参数:
    !!   session_idx: 会话索引(IN)
    !!   input_buffer: 输入特征(IN)
    !!   output_buffer: 输出预测(OUT)
    !!   status: 错误状态(OUT)
    !!
    !! 内存布局: 列优先(Fortran约定)
    !! 64-byte对齐: 缓冲区必须使用UFC_Memory_Align64分配
    
    INTEGER(i4), INTENT(IN) :: session_idx
    REAL(wp), INTENT(IN) :: input_buffer(:)
    REAL(wp), INTENT(OUT) :: output_buffer(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查域初始化状态
    IF (.NOT. g_ai_domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_API_Infer: AI域未初始化'
      RETURN
    END IF
    
    ! 调用域推理接口(带缓存优化)
    CALL IF_AI_Domain_Infer(g_ai_domain, session_idx, input_buffer, output_buffer, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_Infer: 推理失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_API_Infer

  !=============================================================================
  ! IF_AI_API_Infer_Batch - 批量推理
  !=============================================================================
  SUBROUTINE IF_AI_API_Infer_Batch(session_idx, batch_size, input_batch, &
                                    output_batch, status)
    !! 批量推理(供AI_ConvPredict/AI_Preconditioner/AI_SparseSolver调用)
    !!
    !! 参数:
    !!   session_idx: 会话索引(IN)
    !!   batch_size: 批量大小(IN)
    !!   input_batch: 输入特征批次(IN) [input_dim, batch_size]
    !!   output_batch: 输出预测批次(OUT) [output_dim, batch_size]
    !!   status: 错误状态(OUT)
    !!
    !! 性能优化:
    !!   • 单次ONNX调用摊销开销(~0.5ms→~0.05ms/样本)
    !!   • 预期加速比: 10× (batch_size=1000)
    
    INTEGER(i4), INTENT(IN) :: session_idx
    INTEGER(i4), INTENT(IN) :: batch_size
    REAL(wp), INTENT(IN) :: input_batch(:,:)
    REAL(wp), INTENT(OUT) :: output_batch(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查域初始化状态
    IF (.NOT. g_ai_domain%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_API_Infer_Batch: AI域未初始化'
      RETURN
    END IF
    
    ! 调用域批量推理接口(热路径优化)
    CALL IF_AI_Domain_Infer_Batch(g_ai_domain, session_idx, batch_size, &
                                  input_batch, output_batch, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_Infer_Batch: 批量推理失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_API_Infer_Batch

  !=============================================================================
  ! IF_AI_API_ClearCache - 清空推理缓存
  !=============================================================================
  SUBROUTINE IF_AI_API_ClearCache(status)
    !! 清空推理缓存(热更新模型后调用)
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 调用域缓存清理接口
    CALL IF_AI_Domain_ClearCache(g_ai_domain, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_ClearCache: 缓存清理失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_API_ClearCache: 推理缓存已清空'
    
  END SUBROUTINE IF_AI_API_ClearCache

  !=============================================================================
  ! IF_AI_API_GetPerfStats - 获取性能统计
  !=============================================================================
  SUBROUTINE IF_AI_API_GetPerfStats(stats, status)
    !! 获取AI推理性能统计
    !!
    !! 参数:
    !!   stats: 性能统计(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_PerfStats), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 调用域性能统计接口
    CALL IF_AI_Domain_GetPerfStats(g_ai_domain, stats, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_GetPerfStats: 获取性能统计失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_API_GetPerfStats

  !=============================================================================
  ! IF_AI_API_GetVersion - 获取AI API版本号
  !=============================================================================
  SUBROUTINE IF_AI_API_GetVersion(version_str, status)
    !! 获取AI API版本号
    !!
    !! 参数:
    !!   version_str: 版本号字符串(OUT)
    !!   status: 错误状态(OUT)
    
    CHARACTER(LEN=*), INTENT(OUT) :: version_str
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    version_str = 'L1_IF.AI.API.v1.0'
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_API_GetVersion

  !=============================================================================
  ! IF_AI_API_GetSummary - 获取AI API配置摘要
  !=============================================================================
  SUBROUTINE IF_AI_API_GetSummary(summary, status)
    !! 获取AI API配置摘要(调试/诊断用)
    !!
    !! 参数:
    !!   summary: 配置摘要(OUT)
    !!   status: 错误状态(OUT)
    !!
    !! 调用时机: 调试/诊断时调用,热路径禁止调用
    
    CHARACTER(LEN=*), INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 调用域摘要接口
    CALL IF_AI_Domain_GetSummary(g_ai_domain, summary, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_API_GetSummary: 获取配置摘要失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_API_GetSummary

END MODULE IF_AI_Brg
