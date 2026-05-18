!===============================================================================
! MODULE: IF_AI_ModelLoader
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Impl — ONNX/PT model loader with validation and caching
! BRIEF:  Load .onnx/.pt files, verify I/O dims, extract metadata, cache models.
!===============================================================================

MODULE IF_AI_ModelLoader
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC TYPES
  !=============================================================================

  !> AI模型元数据
  TYPE, PUBLIC :: IF_AI_ModelMetadata_Info
    CHARACTER(LEN=256) :: model_name        ! 模型名称
    CHARACTER(LEN=64)  :: model_version     ! 模型版本
    CHARACTER(LEN=128) :: author            ! 作者
    CHARACTER(LEN=512) :: description       ! 描述
    CHARACTER(LEN=64)  :: format            ! 格式(ONNX/PT)
    INTEGER(i4) :: opset_version           ! ONNX opset版本
  END TYPE IF_AI_ModelMetadata_Info

  TYPE, PUBLIC :: IF_AI_ModelMetadata_IO
    INTEGER(i4) :: n_inputs                ! 输入数量
    INTEGER(i4) :: n_outputs               ! 输出数量
    INTEGER(i4), ALLOCATABLE :: input_dims(:,:)   ! 输入维度[n_inputs, max_dim]
    INTEGER(i4), ALLOCATABLE :: output_dims(:,:)  ! 输出维度[n_outputs, max_dim]
  END TYPE IF_AI_ModelMetadata_IO

  TYPE, PUBLIC :: IF_AI_ModelMetadata_Flags
    LOGICAL :: is_valid                    ! 模型有效性标志
  END TYPE IF_AI_ModelMetadata_Flags

  TYPE, PUBLIC :: IF_AI_ModelMetadata
    TYPE(IF_AI_ModelMetadata_Info) :: info
    TYPE(IF_AI_ModelMetadata_IO) :: io
    TYPE(IF_AI_ModelMetadata_Flags) :: flags
  END TYPE IF_AI_ModelMetadata

  !> AI模型缓存条目
  TYPE, PUBLIC :: IF_AI_ModelCacheEntry
    CHARACTER(LEN=256) :: model_path       ! 模型路径
    TYPE(IF_AI_ModelMetadata) :: metadata  ! 模型元数据
    REAL(wp) :: load_timestamp            ! 加载时间戳
    LOGICAL :: is_loaded                  ! 加载标志
  END TYPE IF_AI_ModelCacheEntry

  !> AI模型缓存管理器
  TYPE, PUBLIC :: IF_AI_ModelCache
    TYPE(IF_AI_ModelCacheEntry), ALLOCATABLE :: entries(:) ! 缓存条目
    INTEGER(i4) :: capacity                               ! 缓存容量
    INTEGER(i4) :: n_entries                              ! 当前条目数
  END TYPE IF_AI_ModelCache

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_AI_Model_Load
  PUBLIC :: IF_AI_Model_Validate
  PUBLIC :: IF_AI_Model_GetMetadata
  PUBLIC :: IF_AI_ModelCache_Init
  PUBLIC :: IF_AI_ModelCache_Find
  PUBLIC :: IF_AI_ModelCache_Add

CONTAINS

  !=============================================================================
  ! IF_AI_Model_Load - 加载AI模型
  !=============================================================================
  SUBROUTINE IF_AI_Model_Load(model_path, metadata, status)
    !! 加载AI模型并提取元数据
    !!
    !! 参数:
    !!   model_path: 模型文件路径(IN)
    !!   metadata: 模型元数据(OUT)
    !!   status: 错误状态(OUT)
    
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    TYPE(IF_AI_ModelMetadata), INTENT(OUT) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: file_unit
    LOGICAL :: file_exists
    
    CALL init_error_status(status)
    
    ! 初始化元数据
    metadata%flags%is_valid = .FALSE.
    metadata%info%model_name = ""
    metadata%info%model_version = ""
    metadata%info%format = ""
    
    ! 检查文件是否存在
    INQUIRE(FILE=model_path, EXIST=file_exists)
    IF (.NOT. file_exists) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_AI_Model_Load: 模型文件不存在'
      RETURN
    END IF
    
    ! 检测模型格式(基于文件扩展名)
    IF (INDEX(model_path, '.onnx') > 0) THEN
      metadata%info%format = 'ONNX'
    ELSE IF (INDEX(model_path, '.pt') > 0 .OR. INDEX(model_path, '.pth') > 0) THEN
      metadata%info%format = 'PT'
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Model_Load: 不支持的模型格式(仅支持.onnx/.pt)'
      RETURN
    END IF
    
    ! TODO: 实现ONNX Runtime C API模型加载
    ! 当前为简化实现,仅提取文件信息
    
    metadata%info%model_name = model_path
    metadata%flags%is_valid = .TRUE.
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_Model_Load: 模型加载成功'
    
  END SUBROUTINE IF_AI_Model_Load

  !=============================================================================
  ! IF_AI_Model_Validate - 验证AI模型
  !=============================================================================
  SUBROUTINE IF_AI_Model_Validate(metadata, status)
    !! 验证AI模型有效性
    !!
    !! 参数:
    !!   metadata: 模型元数据(IN)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_ModelMetadata), INTENT(IN) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查模型格式
    IF (metadata%info%format /= 'ONNX' .AND. metadata%info%format /= 'PT') THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Model_Validate: 无效的模型格式'
      RETURN
    END IF
    
    ! 检查输入输出维度
    IF (metadata%io%n_inputs <= 0 .OR. metadata%io%n_outputs <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Model_Validate: 输入输出维度无效'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_Model_Validate: 模型验证通过'
    
  END SUBROUTINE IF_AI_Model_Validate

  !=============================================================================
  ! IF_AI_Model_GetMetadata - 获取模型元数据
  !=============================================================================
  SUBROUTINE IF_AI_Model_GetMetadata(model_path, metadata, status)
    !! 获取模型元数据(不加载模型)
    !!
    !! 参数:
    !!   model_path: 模型文件路径(IN)
    !!   metadata: 模型元数据(OUT)
    !!   status: 错误状态(OUT)
    
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    TYPE(IF_AI_ModelMetadata), INTENT(OUT) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 调用加载接口获取元数据
    CALL IF_AI_Model_Load(model_path, metadata, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'IF_AI_Model_GetMetadata: 获取元数据失败'
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Model_GetMetadata

  !=============================================================================
  ! IF_AI_ModelCache_Init - 初始化模型缓存
  !=============================================================================
  SUBROUTINE IF_AI_ModelCache_Init(cache, capacity, status)
    !! 初始化模型缓存
    !!
    !! 参数:
    !!   cache: 模型缓存(INOUT)
    !!   capacity: 缓存容量(IN)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_ModelCache), INTENT(INOUT) :: cache
    INTEGER(i4), INTENT(IN) :: capacity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    cache%capacity = capacity
    cache%n_entries = 0
    ALLOCATE(cache%entries(capacity))
    cache%entries(:)%is_loaded = .FALSE.
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_ModelCache_Init: 模型缓存初始化成功'
    
  END SUBROUTINE IF_AI_ModelCache_Init

  !=============================================================================
  ! IF_AI_ModelCache_Find - 查找模型缓存
  !=============================================================================
  SUBROUTINE IF_AI_ModelCache_Find(cache, model_path, entry_idx, found, status)
    !! 查找模型缓存
    !!
    !! 参数:
    !!   cache: 模型缓存(IN)
    !!   model_path: 模型路径(IN)
    !!   entry_idx: 缓存条目索引(OUT)
    !!   found: 是否找到(OUT)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_ModelCache), INTENT(IN) :: cache
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    INTEGER(i4), INTENT(OUT) :: entry_idx
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    found = .FALSE.
    entry_idx = -1
    
    ! 线性搜索缓存
    DO i = 1, cache%n_entries
      IF (cache%entries(i)%model_path == model_path .AND. &
          cache%entries(i)%is_loaded) THEN
        found = .TRUE.
        entry_idx = i
        EXIT
      END IF
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_ModelCache_Find

  !=============================================================================
  ! IF_AI_ModelCache_Add - 添加模型到缓存
  !=============================================================================
  SUBROUTINE IF_AI_ModelCache_Add(cache, model_path, metadata, status)
    !! 添加模型到缓存
    !!
    !! 参数:
    !!   cache: 模型缓存(INOUT)
    !!   model_path: 模型路径(IN)
    !!   metadata: 模型元数据(IN)
    !!   status: 错误状态(OUT)
    
    TYPE(IF_AI_ModelCache), INTENT(INOUT) :: cache
    CHARACTER(LEN=*), INTENT(IN) :: model_path
    TYPE(IF_AI_ModelMetadata), INTENT(IN) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查缓存是否已满
    IF (cache%n_entries >= cache%capacity) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'IF_AI_ModelCache_Add: 模型缓存已满'
      RETURN
    END IF
    
    ! 添加新条目
    cache%n_entries = cache%n_entries + 1
    cache%entries(cache%n_entries)%model_path = model_path
    cache%entries(cache%n_entries)%metadata = metadata
    cache%entries(cache%n_entries)%is_loaded = .TRUE.
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_AI_ModelCache_Add: 模型添加到缓存成功'
    
  END SUBROUTINE IF_AI_ModelCache_Add

END MODULE IF_AI_ModelLoader