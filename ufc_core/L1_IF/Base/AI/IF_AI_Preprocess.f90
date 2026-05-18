!===============================================================================
! MODULE: IF_AI_Preprocess
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Proc — data pre/post-processing (normalize, feature extract, map)
! BRIEF:  Min-Max/Z-Score normalization, feature extraction, inverse mapping.
!===============================================================================

MODULE IF_AI_Preprocess
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC TYPES
  !=============================================================================

  !> 归一化参数
  TYPE, PUBLIC :: IF_AI_NormalizationParams
    REAL(wp), ALLOCATABLE :: min_vals(:)    ! 最小值(Min-Max归一化)
    REAL(wp), ALLOCATABLE :: max_vals(:)    ! 最大值(Min-Max归一化)
    REAL(wp), ALLOCATABLE :: mean(:)        ! 均值(Z-Score标准化)
    REAL(wp), ALLOCATABLE :: std(:)         ! 标准差(Z-Score标准化)
    INTEGER(i4) :: method                   ! 方法: 1=Min-Max, 2=Z-Score
  END TYPE IF_AI_NormalizationParams

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_AI_Preprocess_Normalize
  PUBLIC :: IF_AI_Preprocess_Denormalize
  PUBLIC :: IF_AI_Preprocess_ExtractFeatures
  PUBLIC :: IF_AI_Preprocess_MapToPhysical
  PUBLIC :: IF_AI_Preprocess_ValidateInput

CONTAINS

  !=============================================================================
  ! IF_AI_Preprocess_Normalize - 数据归一化
  !=============================================================================
  SUBROUTINE IF_AI_Preprocess_Normalize(input, output, params, n, status)
    !! 数据归一化(Min-Max或Z-Score)
    !!
    !! 参数:
    !!   input: 输入数据(IN)
    !!   output: 归一化数据(OUT)
    !!   params: 归一化参数(IN)
    !!   n: 数据长度(IN)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: input(n)
    REAL(wp), INTENT(OUT) :: output(n)
    TYPE(IF_AI_NormalizationParams), INTENT(IN) :: params
    INTEGER(i4), INTENT(IN) :: n
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    REAL(wp) :: eps
    
    CALL init_error_status(status)
    eps = 1.0E-10_wp
    
    ! 检查归一化方法
    SELECT CASE (params%method)
    CASE (1)
      ! Min-Max归一化: y = (x - min) / (max - min)
      DO i = 1, n
        IF (params%max_vals(i) - params%min_vals(i) > eps) THEN
          output(i) = (input(i) - params%min_vals(i)) / &
                      (params%max_vals(i) - params%min_vals(i))
        ELSE
          output(i) = 0.0_wp
        END IF
      END DO
      
    CASE (2)
      ! Z-Score标准化: y = (x - mean) / std
      DO i = 1, n
        IF (params%std(i) > eps) THEN
          output(i) = (input(i) - params%mean(i)) / params%std(i)
        ELSE
          output(i) = 0.0_wp
        END IF
      END DO
      
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Preprocess_Normalize: 无效的归一化方法'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Preprocess_Normalize

  !=============================================================================
  ! IF_AI_Preprocess_Denormalize - 数据反归一化
  !=============================================================================
  SUBROUTINE IF_AI_Preprocess_Denormalize(input, output, params, n, status)
    !! 数据反归一化(AI输出→原始物理量)
    !!
    !! 参数:
    !!   input: 归一化数据(IN)
    !!   output: 反归一化数据(OUT)
    !!   params: 归一化参数(IN)
    !!   n: 数据长度(IN)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: input(n)
    REAL(wp), INTENT(OUT) :: output(n)
    TYPE(IF_AI_NormalizationParams), INTENT(IN) :: params
    INTEGER(i4), INTENT(IN) :: n
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    REAL(wp) :: eps
    
    CALL init_error_status(status)
    eps = 1.0E-10_wp
    
    ! 检查归一化方法
    SELECT CASE (params%method)
    CASE (1)
      ! Min-Max反归一化: x = y * (max - min) + min
      DO i = 1, n
        output(i) = input(i) * (params%max_vals(i) - params%min_vals(i)) + &
                    params%min_vals(i)
      END DO
      
    CASE (2)
      ! Z-Score反标准化: x = y * std + mean
      DO i = 1, n
        output(i) = input(i) * params%std(i) + params%mean(i)
      END DO
      
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Preprocess_Denormalize: 无效的归一化方法'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Preprocess_Denormalize

  !=============================================================================
  ! IF_AI_Preprocess_ExtractFeatures - 特征提取
  !=============================================================================
  SUBROUTINE IF_AI_Preprocess_ExtractFeatures(physical_inputs, features, &
                                               n_physical, n_features, status)
    !! 特征提取(物理量→AI特征向量)
    !!
    !! 参数:
    !!   physical_inputs: 物理量输入(IN)
    !!   features: AI特征向量(OUT)
    !!   n_physical: 物理量数量(IN)
    !!   n_features: 特征数量(IN)
    !!   status: 错误状态(OUT)
    !!
    !! 说明: 当前为简化实现(恒等映射),后续可扩展为复杂特征工程
    
    REAL(wp), INTENT(IN) :: physical_inputs(n_physical)
    REAL(wp), INTENT(OUT) :: features(n_features)
    INTEGER(i4), INTENT(IN) :: n_physical, n_features
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    ! 检查维度匹配
    IF (n_features /= n_physical) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Preprocess_ExtractFeatures: 特征维度不匹配'
      RETURN
    END IF
    
    ! 简化实现: 恒等映射
    features = physical_inputs
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Preprocess_ExtractFeatures

  !=============================================================================
  ! IF_AI_Preprocess_MapToPhysical - AI输出映射到物理量
  !=============================================================================
  SUBROUTINE IF_AI_Preprocess_MapToPhysical(ai_outputs, physical_outputs, &
                                             n_outputs, n_physical, status)
    !! AI输出映射到物理量
    !!
    !! 参数:
    !!   ai_outputs: AI输出向量(IN)
    !!   physical_outputs: 物理量输出(OUT)
    !!   n_outputs: AI输出数量(IN)
    !!   n_physical: 物理量数量(IN)
    !!   status: 错误状态(OUT)
    !!
    !! 说明: 当前为简化实现(恒等映射),后续可扩展为复杂物理量映射
    
    REAL(wp), INTENT(IN) :: ai_outputs(n_outputs)
    REAL(wp), INTENT(OUT) :: physical_outputs(n_physical)
    INTEGER(i4), INTENT(IN) :: n_outputs, n_physical
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 检查维度匹配
    IF (n_physical /= n_outputs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_AI_Preprocess_MapToPhysical: 物理量维度不匹配'
      RETURN
    END IF
    
    ! 简化实现: 恒等映射
    physical_outputs = ai_outputs
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Preprocess_MapToPhysical

  !=============================================================================
  ! IF_AI_Preprocess_ValidateInput - 验证输入数据
  !=============================================================================
  SUBROUTINE IF_AI_Preprocess_ValidateInput(data, n, is_valid, status)
    !! 验证输入数据有效性(NaN/Inf检测)
    !!
    !! 参数:
    !!   data: 输入数据(IN)
    !!   n: 数据长度(IN)
    !!   is_valid: 是否有效(OUT)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: data(n)
    INTEGER(i4), INTENT(IN) :: n
    LOGICAL, INTENT(OUT) :: is_valid
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    is_valid = .TRUE.
    
    ! 检查NaN和Inf
    DO i = 1, n
      IF (data(i) /= data(i)) THEN
        ! NaN检测: NaN不等于自身
        is_valid = .FALSE.
        status%status_code = IF_STATUS_INVALID
        status%message = 'IF_AI_Preprocess_ValidateInput: 检测到NaN值'
        RETURN
      END IF
      
      IF (ABS(data(i)) > HUGE(1.0_wp) * 0.99_wp) THEN
        ! Inf检测: 接近最大值
        is_valid = .FALSE.
        status%status_code = IF_STATUS_INVALID
        status%message = 'IF_AI_Preprocess_ValidateInput: 检测到Inf值'
        RETURN
      END IF
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Preprocess_ValidateInput

END MODULE IF_AI_Preprocess