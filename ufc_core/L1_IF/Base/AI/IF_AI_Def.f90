!===============================================================================
! MODULE: IF_AI_Def
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Def — four-type TYPEs (Desc / State / Algo / Ctx)
! BRIEF:  AI model descriptor, inference state, algorithm params, call context.
!===============================================================================

MODULE IF_AI_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC TYPES - 四类TYPE体系
  !=============================================================================

  !> AI模型描述符(Desc) - 只读配置
    TYPE, PUBLIC :: IF_AI_Model_Desc_Path
    CHARACTER(LEN=256) :: model_path        ! model file path
    CHARACTER(LEN=64)  :: model_name        ! model name
    CHARACTER(LEN=64)  :: model_version     ! model version
  END TYPE IF_AI_Model_Desc_Path

  TYPE, PUBLIC :: IF_AI_Model_Desc_Format
    CHARACTER(LEN=64)  :: format            ! format(ONNX/PT)
  END TYPE IF_AI_Model_Desc_Format

  TYPE, PUBLIC :: IF_AI_Model_Desc_Dim
    INTEGER(i4) :: input_dim                ! input dimension
    INTEGER(i4) :: output_dim               ! output dimension
  END TYPE IF_AI_Model_Desc_Dim

  TYPE, PUBLIC :: IF_AI_Model_Desc_Params
    INTEGER(i4) :: n_parameters             ! parameter count
  END TYPE IF_AI_Model_Desc_Params

  TYPE, PUBLIC :: IF_AI_Model_Desc_Flags
    LOGICAL :: is_quantized                 ! quantized flag(INT8/FP16)
  END TYPE IF_AI_Model_Desc_Flags

  TYPE, PUBLIC :: IF_AI_Model_Desc
    TYPE(IF_AI_Model_Desc_Path)   :: path
    TYPE(IF_AI_Model_Desc_Format) :: fmt
    TYPE(IF_AI_Model_Desc_Dim)    :: dim
    TYPE(IF_AI_Model_Desc_Params) :: params
    TYPE(IF_AI_Model_Desc_Flags)  :: flags
  END TYPE IF_AI_Model_Desc

  !> AI推理状态(State) - 运行时更新
    TYPE, PUBLIC :: IF_AI_Infer_State_Count
    INTEGER(i4) :: n_inferences             ! inference count
  END TYPE IF_AI_Infer_State_Count

  TYPE, PUBLIC :: IF_AI_Infer_State_Timing
    REAL(wp) :: last_inference_time_ms      ! last inference time(ms)
    REAL(wp) :: avg_inference_time_ms       ! avg inference time(ms)
  END TYPE IF_AI_Infer_State_Timing

  TYPE, PUBLIC :: IF_AI_Infer_State_Cache
    INTEGER(i4) :: cache_hits               ! cache hits
    INTEGER(i4) :: cache_misses             ! cache misses
    REAL(wp) :: cache_hit_rate              ! cache hit rate
  END TYPE IF_AI_Infer_State_Cache

  TYPE, PUBLIC :: IF_AI_Infer_State_Flags
    LOGICAL :: is_ready                     ! ready flag
  END TYPE IF_AI_Infer_State_Flags

  TYPE, PUBLIC :: IF_AI_Infer_State_Err
    INTEGER(i4) :: error_count              ! error count
  END TYPE IF_AI_Infer_State_Err

  TYPE, PUBLIC :: IF_AI_Infer_State
    TYPE(IF_AI_Infer_State_Count)  :: count
    TYPE(IF_AI_Infer_State_Timing) :: timing
    TYPE(IF_AI_Infer_State_Cache)  :: cache
    TYPE(IF_AI_Infer_State_Flags)  :: flags
    TYPE(IF_AI_Infer_State_Err)    :: err
  END TYPE IF_AI_Infer_State

  !> AI推理算法参数(Algo) - 只读
  TYPE, PUBLIC :: IF_AI_Infer_Algo_Provider
    CHARACTER(LEN=64)  :: execution_provider ! 执行提供者(CPU/CUDA/TensorRT)
  END TYPE IF_AI_Infer_Algo_Provider

  TYPE, PUBLIC :: IF_AI_Infer_Algo_Batch
    INTEGER(i4) :: batch_size               ! 批量大小
  END TYPE IF_AI_Infer_Algo_Batch

  TYPE, PUBLIC :: IF_AI_Infer_Algo_Cache
    LOGICAL :: use_cache                    ! 是否启用缓存
    INTEGER(i4) :: cache_capacity           ! 缓存容量
  END TYPE IF_AI_Infer_Algo_Cache

  TYPE, PUBLIC :: IF_AI_Infer_Algo_Config
    REAL(wp) :: confidence_threshold        ! 置信度阈值
    LOGICAL :: enable_fp16                  ! 是否启用FP16推理
    INTEGER(i4) :: n_threads                ! 线程数
  END TYPE IF_AI_Infer_Algo_Config

  TYPE, PUBLIC :: IF_AI_Infer_Algo
    TYPE(IF_AI_Infer_Algo_Provider) :: provider
    TYPE(IF_AI_Infer_Algo_Batch) :: batch
    TYPE(IF_AI_Infer_Algo_Cache) :: cache
    TYPE(IF_AI_Infer_Algo_Config) :: config
  END TYPE IF_AI_Infer_Algo

  !> AI推理上下文(Ctx) - 调用级
  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Session
    INTEGER(i4) :: session_idx              ! 会话索引
  END TYPE IF_AI_Infer_Ctx_Session

  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Buffers
    REAL(wp), ALLOCATABLE :: input_buffer(:)  ! 输入缓冲区
    REAL(wp), ALLOCATABLE :: output_buffer(:) ! 输出缓冲区
  END TYPE IF_AI_Infer_Ctx_Buffers

  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Timing
    REAL(wp) :: start_time                  ! 开始时间
    REAL(wp) :: end_time                    ! 结束时间
    LOGICAL :: use_batch_mode               ! 是否批量模式
  END TYPE IF_AI_Infer_Ctx_Timing

  TYPE, PUBLIC :: IF_AI_Infer_Ctx
    TYPE(IF_AI_Infer_Ctx_Session) :: session
    TYPE(IF_AI_Infer_Ctx_Buffers) :: buffers
    TYPE(IF_AI_Infer_Ctx_Timing) :: timing
  END TYPE IF_AI_Infer_Ctx

  !=============================================================================
  ! PUBLIC TYPES - 辅助TYPE
  !=============================================================================

  !> AI插槽类型枚举
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_STEPCTR = 1     ! 切步控制器
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_CONVPREDICT = 2 ! 收敛预测器
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_MATINTEG = 3    ! 本构代理
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_CONTACTLAW = 4  ! 接触律代理
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_PRECOND = 5     ! 预条件器
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_SLOT_SPARSESLV = 6   ! 稀疏求解器

  !> AI执行提供者枚举
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_EXEC_CPU = 1
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_EXEC_CUDA = 2
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_EXEC_TENSORRT = 3

  !> AI归一化方法枚举
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_NORM_MINMAX = 1
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_NORM_ZSCORE = 2

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_AI_Model_Desc_Init
  PUBLIC :: IF_AI_Infer_State_Init
  PUBLIC :: IF_AI_Infer_Algo_Init
  PUBLIC :: IF_AI_Infer_Ctx_Init

CONTAINS

  !=============================================================================
  ! IF_AI_Model_Desc_Init - 初始化模型描述符
  !=============================================================================
  SUBROUTINE IF_AI_Model_Desc_Init(desc, model_path, model_name, input_dim, output_dim)
    !! 初始化模型描述符
    !!
    !! 参数:
    !!   desc: 模型描述符(INOUT)
    !!   model_path: 模型路径(IN)
    !!   model_name: 模型名称(IN)
    !!   input_dim: 输入维度(IN)
    !!   output_dim: 输出维度(IN)
    
    TYPE(IF_AI_Model_Desc), INTENT(INOUT) :: desc
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    CHARACTER(LEN=*), INTENT(IN) :: model_name
    INTEGER(i4), INTENT(IN) :: input_dim
    INTEGER(i4), INTENT(IN) :: output_dim

    desc%path%model_path = model_path
    desc%path%model_name = model_name
    desc%path%model_version = 'v1.0'
    desc%fmt%format = 'ONNX'
    desc%dim%input_dim = input_dim
    desc%dim%output_dim = output_dim
    desc%params%n_parameters = 0
    desc%flags%is_quantized = .FALSE.

  END SUBROUTINE IF_AI_Model_Desc_Init

  !=============================================================================
  ! IF_AI_Infer_State_Init - 初始化推理状态
  !=============================================================================
  SUBROUTINE IF_AI_Infer_State_Init(state)
    !! 初始化推理状态
    !!
    !! 参数:
    !!   state: 推理状态(INOUT)
    
    TYPE(IF_AI_Infer_State), INTENT(INOUT) :: state

    state%count%n_inferences = 0
    state%timing%last_inference_time_ms = 0.0_wp
    state%timing%avg_inference_time_ms = 0.0_wp
    state%cache%cache_hits = 0
    state%cache%cache_misses = 0
    state%cache%cache_hit_rate = 0.0_wp
    state%flags%is_ready = .FALSE.
    state%err%error_count = 0

  END SUBROUTINE IF_AI_Infer_State_Init

  !=============================================================================
  ! IF_AI_Infer_Algo_Init - 初始化推理算法参数
  !=============================================================================
  SUBROUTINE IF_AI_Infer_Algo_Init(algo, exec_provider, batch_size)
    !! 初始化推理算法参数
    !!
    !! 参数:
    !!   algo: 算法参数(INOUT)
    !!   exec_provider: 执行提供者(IN)
    !!   batch_size: 批量大小(IN)
    
    TYPE(IF_AI_Infer_Algo), INTENT(INOUT) :: algo
    CHARACTER(LEN=*), INTENT(IN) :: exec_provider
    INTEGER(i4), INTENT(IN) :: batch_size
    
    algo%provider%execution_provider = exec_provider
    algo%batch%batch_size = batch_size
    algo%cache%use_cache = .TRUE.
    algo%cache%cache_capacity = 1000
    algo%config%confidence_threshold = 0.95_wp
    algo%config%enable_fp16 = .FALSE.
    algo%config%n_threads = 1
    
  END SUBROUTINE IF_AI_Infer_Algo_Init

  !=============================================================================
  ! IF_AI_Infer_Ctx_Init - 初始化推理上下文
  !=============================================================================
  SUBROUTINE IF_AI_Infer_Ctx_Init(ctx, session_idx)
    !! 初始化推理上下文
    !!
    !! 参数:
    !!   ctx: 推理上下文(INOUT)
    !!   session_idx: 会话索引(IN)
    
    TYPE(IF_AI_Infer_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: session_idx
    
    ctx%session%session_idx = session_idx
    ctx%timing%use_batch_mode = .FALSE.
    ctx%timing%start_time = 0.0_wp
    ctx%timing%end_time = 0.0_wp
    
    ! 缓冲区将由调用方分配
    
  END SUBROUTINE IF_AI_Infer_Ctx_Init

END MODULE IF_AI_Def
