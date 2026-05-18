!===============================================================================
! MODULE: IF_Sym_Brg
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Brg — unified symbol query / conversion / validation API
! BRIEF:  Query by name/index, SI-to-engineering unit conversion, dimension check,
!         cross-layer symbol mapping (MD/RT/PH).
!===============================================================================

MODULE IF_Sym_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Sym_Mgr, ONLY: IF_Sym_Init
  USE IF_Sym_Stress, ONLY: IF_Sym_Stress_Init, N_STRESS_3D, N_STRESS_INV
  USE IF_Sym_Strain, ONLY: IF_Sym_Strain_Init, N_STRAIN_3D, N_STRAIN_INV
  USE IF_Sym_Stiffness, ONLY: IF_Sym_Stiffness_Init, N_MAT_STIFF_PARAMS
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_Sym_API_Init
  PUBLIC :: IF_Sym_API_GetStressComponentName
  PUBLIC :: IF_Sym_API_GetStrainComponentName
  PUBLIC :: IF_Sym_API_GetMaterialParamName
  PUBLIC :: IF_Sym_API_ConvertStressUnit
  PUBLIC :: IF_Sym_API_ConvertStrainUnit
  PUBLIC :: IF_Sym_API_ValidateStressIndex
  PUBLIC :: IF_Sym_API_ValidateStrainIndex

CONTAINS

  !=============================================================================
  ! IF_Sym_API_Init - 初始化Symbol域
  !=============================================================================
  SUBROUTINE IF_Sym_API_Init(status)
    !! 初始化Symbol域所有子模块
    !!
    !! 参数:
    !!   status: 错误状态(OUT)
    
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! 初始化所有符号子模块
    CALL IF_Sym_Init()
    CALL IF_Sym_Stress_Init()
    CALL IF_Sym_Strain_Init()
    CALL IF_Sym_Stiffness_Init()
    
    status%status_code = IF_STATUS_OK
    status%message = 'IF_Sym_API_Init: Symbol域初始化成功'
    
  END SUBROUTINE IF_Sym_API_Init

  !=============================================================================
  ! IF_Sym_API_GetStressComponentName - 获取应力分量名称
  !=============================================================================
  SUBROUTINE IF_Sym_API_GetStressComponentName(idx, name, status)
    !! 获取应力分量名称
    !!
    !! 参数:
    !!   idx: 应力分量索引(IN)
    !!   name: 应力分量名称(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: idx
    CHARACTER(LEN=*), INTENT(OUT) :: name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    SELECT CASE (idx)
    CASE (1)
      name = 'σ_xx'
    CASE (2)
      name = 'σ_yy'
    CASE (3)
      name = 'σ_zz'
    CASE (4)
      name = 'τ_xy'
    CASE (5)
      name = 'τ_yz'
    CASE (6)
      name = 'τ_xz'
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_GetStressComponentName: 无效应力索引'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_GetStressComponentName

  !=============================================================================
  ! IF_Sym_API_GetStrainComponentName - 获取应变分量名称
  !=============================================================================
  SUBROUTINE IF_Sym_API_GetStrainComponentName(idx, name, status)
    !! 获取应变分量名称
    !!
    !! 参数:
    !!   idx: 应变分量索引(IN)
    !!   name: 应变分量名称(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: idx
    CHARACTER(LEN=*), INTENT(OUT) :: name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    SELECT CASE (idx)
    CASE (1)
      name = 'ε_xx'
    CASE (2)
      name = 'ε_yy'
    CASE (3)
      name = 'ε_zz'
    CASE (4)
      name = 'γ_xy'
    CASE (5)
      name = 'γ_yz'
    CASE (6)
      name = 'γ_xz'
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_GetStrainComponentName: 无效应变索引'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_GetStrainComponentName

  !=============================================================================
  ! IF_Sym_API_GetMaterialParamName - 获取材料参数名称
  !=============================================================================
  SUBROUTINE IF_Sym_API_GetMaterialParamName(idx, name, status)
    !! 获取材料参数名称
    !!
    !! 参数:
    !!   idx: 材料参数索引(IN)
    !!   name: 材料参数名称(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: idx
    CHARACTER(LEN=*), INTENT(OUT) :: name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    SELECT CASE (idx)
    CASE (1)
      name = 'E (弹性模量)'
    CASE (2)
      name = 'G (剪切模量)'
    CASE (3)
      name = 'K (体积模量)'
    CASE (4)
      name = 'ν (泊松比)'
    CASE (5)
      name = 'λ (Lamé第一参数)'
    CASE (6)
      name = 'μ (Lamé第二参数)'
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_GetMaterialParamName: 无效材料参数索引'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_GetMaterialParamName

  !=============================================================================
  ! IF_Sym_API_ConvertStressUnit - 应力单位转换
  !=============================================================================
  SUBROUTINE IF_Sym_API_ConvertStressUnit(value, from_unit, to_unit, result, status)
    !! 应力单位转换
    !!
    !! 参数:
    !!   value: 输入值(IN)
    !!   from_unit: 源单位(IN) - 1=Pa, 2=MPa, 3=GPa
    !!   to_unit: 目标单位(IN) - 1=Pa, 2=MPa, 3=GPa
    !!   result: 转换结果(OUT)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: value
    INTEGER(i4), INTENT(IN) :: from_unit, to_unit
    REAL(wp), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: factor_from, factor_to
    
    CALL init_error_status(status)
    
    ! 转换因子(相对于Pa)
    SELECT CASE (from_unit)
    CASE (1)
      factor_from = 1.0_wp        ! Pa
    CASE (2)
      factor_from = 1.0E6_wp      ! MPa
    CASE (3)
      factor_from = 1.0E9_wp      ! GPa
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ConvertStressUnit: 无效源单位'
      RETURN
    END SELECT
    
    SELECT CASE (to_unit)
    CASE (1)
      factor_to = 1.0_wp          ! Pa
    CASE (2)
      factor_to = 1.0E6_wp        ! MPa
    CASE (3)
      factor_to = 1.0E9_wp        ! GPa
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ConvertStressUnit: 无效目标单位'
      RETURN
    END SELECT
    
    ! 转换
    result = value * factor_from / factor_to
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_ConvertStressUnit

  !=============================================================================
  ! IF_Sym_API_ConvertStrainUnit - 应变单位转换
  !=============================================================================
  SUBROUTINE IF_Sym_API_ConvertStrainUnit(value, from_unit, to_unit, result, status)
    !! 应变单位转换
    !!
    !! 参数:
    !!   value: 输入值(IN)
    !!   from_unit: 源单位(IN) - 1=无量纲, 2=微应变(με)
    !!   to_unit: 目标单位(IN) - 1=无量纲, 2=微应变(με)
    !!   result: 转换结果(OUT)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: value
    INTEGER(i4), INTENT(IN) :: from_unit, to_unit
    REAL(wp), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: factor_from, factor_to
    
    CALL init_error_status(status)
    
    ! 转换因子(相对于无量纲)
    SELECT CASE (from_unit)
    CASE (1)
      factor_from = 1.0_wp           ! 无量纲
    CASE (2)
      factor_from = 1.0E-6_wp        ! 微应变
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ConvertStrainUnit: 无效源单位'
      RETURN
    END SELECT
    
    SELECT CASE (to_unit)
    CASE (1)
      factor_to = 1.0_wp             ! 无量纲
    CASE (2)
      factor_to = 1.0E-6_wp          ! 微应变
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ConvertStrainUnit: 无效目标单位'
      RETURN
    END SELECT
    
    ! 转换
    result = value * factor_from / factor_to
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_ConvertStrainUnit

  !=============================================================================
  ! IF_Sym_API_ValidateStressIndex - 验证应力索引
  !=============================================================================
  SUBROUTINE IF_Sym_API_ValidateStressIndex(idx, ndim, is_valid, status)
    !! 验证应力索引有效性
    !!
    !! 参数:
    !!   idx: 应力索引(IN)
    !!   ndim: 空间维度(IN) - 1/2/3
    !!   is_valid: 是否有效(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: idx, ndim
    LOGICAL, INTENT(OUT) :: is_valid
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: max_idx
    
    CALL init_error_status(status)
    
    ! 根据维度确定最大索引
    SELECT CASE (ndim)
    CASE (1)
      max_idx = 1
    CASE (2)
      max_idx = 4
    CASE (3)
      max_idx = 6
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ValidateStressIndex: 无效维度'
      is_valid = .FALSE.
      RETURN
    END SELECT
    
    ! 验证索引范围
    is_valid = (idx >= 1 .AND. idx <= max_idx)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_ValidateStressIndex

  !=============================================================================
  ! IF_Sym_API_ValidateStrainIndex - 验证应变索引
  !=============================================================================
  SUBROUTINE IF_Sym_API_ValidateStrainIndex(idx, ndim, is_valid, status)
    !! 验证应变索引有效性
    !!
    !! 参数:
    !!   idx: 应变索引(IN)
    !!   ndim: 空间维度(IN) - 1/2/3
    !!   is_valid: 是否有效(OUT)
    !!   status: 错误状态(OUT)
    
    INTEGER(i4), INTENT(IN) :: idx, ndim
    LOGICAL, INTENT(OUT) :: is_valid
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: max_idx
    
    CALL init_error_status(status)
    
    ! 根据维度确定最大索引
    SELECT CASE (ndim)
    CASE (1)
      max_idx = 1
    CASE (2)
      max_idx = 4
    CASE (3)
      max_idx = 6
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Sym_API_ValidateStrainIndex: 无效维度'
      is_valid = .FALSE.
      RETURN
    END SELECT
    
    ! 验证索引范围
    is_valid = (idx >= 1 .AND. idx <= max_idx)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_Sym_API_ValidateStrainIndex

END MODULE IF_Sym_Brg
