!===============================================================================
! MODULE: IF_Sym_Def
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Def — symbol table / unit system / dimension TYPEs
! BRIEF:  IF_Sym_Table_Desc, IF_Sym_UnitSystem_Desc, IF_Sym_Dimension_Desc,
!         IF_Sym_Query_State.
!===============================================================================

MODULE IF_Sym_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! TYPE 1: IF_Sym_Table_Desc - 符号表描述符(Desc - 只读配置)
  !=============================================================================
  !
  ! 用途: 存储符号表的配置信息
  ! 生命周期: 全局唯一,初始化后只读
  !
  TYPE, PUBLIC :: IF_Sym_Table_Desc
    ! 基本信息
    CHARACTER(LEN=64) :: table_name       ! 符号表名称
    CHARACTER(LEN=128) :: description     ! 描述
    CHARACTER(LEN=32) :: version          ! 版本号
    
    ! 容量信息
    INTEGER(i4) :: n_stress_symbols       ! 应力符号数量
    INTEGER(i4) :: n_strain_symbols       ! 应变符号数量
    INTEGER(i4) :: n_stiffness_symbols    ! 刚度符号数量
    INTEGER(i4) :: n_bc_symbols           ! 边界条件符号数量
    INTEGER(i4) :: n_dof_symbols          ! 自由度符号数量
    INTEGER(i4) :: n_total_symbols        ! 总符号数量
    
    ! 配置标志
    LOGICAL :: is_case_sensitive          ! 是否区分大小写
    LOGICAL :: is_unit_system_defined     ! 是否已定义单位系统
    
  END TYPE IF_Sym_Table_Desc

  !=============================================================================
  ! TYPE 2: IF_Sym_UnitSystem_Desc - 单位系统描述符(Desc - 只读配置)
  !=============================================================================
  !
  ! 用途: 定义单位系统(SI/工程单位制)
  ! 生命周期: 全局唯一,初始化后只读
  !
  TYPE, PUBLIC :: IF_Sym_UnitSystem_Desc
    ! 单位系统标识
    CHARACTER(LEN=32) :: system_name      ! 单位系统名称(SI/CGS/工程)
    INTEGER(i4) :: system_id              ! 单位系统ID
    
    ! 基本单位
    CHARACTER(LEN=16) :: unit_length      ! 长度单位(m/cm/mm)
    CHARACTER(LEN=16) :: unit_mass        ! 质量单位(kg/g)
    CHARACTER(LEN=16) :: unit_time        ! 时间单位(s)
    CHARACTER(LEN=16) :: unit_force       ! 力单位(N/kN)
    CHARACTER(LEN=16) :: unit_stress      ! 应力单位(Pa/MPa/GPa)
    CHARACTER(LEN=16) :: unit_energy      ! 能量单位(J/kJ)
    CHARACTER(LEN=16) :: unit_temp        ! 温度单位(K/C)
    
    ! 转换因子(相对于SI单位)
    REAL(wp) :: factor_length             ! 长度转换因子
    REAL(wp) :: factor_mass               ! 质量转换因子
    REAL(wp) :: factor_force              ! 力转换因子
    REAL(wp) :: factor_stress             ! 应力转换因子
    
    ! 标志
    LOGICAL :: is_consistent              ! 单位系统是否自洽
    
  END TYPE IF_Sym_UnitSystem_Desc

  !=============================================================================
  ! TYPE 3: IF_Sym_Dimension_Desc - 量纲描述符(Desc - 只读配置)
  !=============================================================================
  !
  ! 用途: 定义物理量的量纲
  ! 理论: 量纲分析 [M]^a[L]^b[T]^c[Θ]^d
  !
  TYPE, PUBLIC :: IF_Sym_Dimension_Desc
    ! 量纲名称
    CHARACTER(LEN=64) :: dim_name         ! 量纲名称
    
    ! 基本量纲指数
    INTEGER(i4) :: mass_exp               ! 质量指数 [M]^a
    INTEGER(i4) :: length_exp             ! 长度指数 [L]^b
    INTEGER(i4) :: time_exp               ! 时间指数 [T]^c
    INTEGER(i4) :: temp_exp               ! 温度指数 [Θ]^d
    
    ! 量纲字符串表示
    CHARACTER(LEN=128) :: dim_string      ! 量纲字符串(如"ML^-1T^-2")
    
    ! 标志
    LOGICAL :: is_dimensionless           ! 是否无量纲
    
  END TYPE IF_Sym_Dimension_Desc

  !=============================================================================
  ! TYPE 4: IF_Sym_Query_State - 符号查询状态(State - 读写状态)
  !=============================================================================
  !
  ! 用途: 符号查询的运行时状态
  ! 生命周期: 每次查询创建,查询结束后销毁
  !
  TYPE, PUBLIC :: IF_Sym_Query_State
    ! 查询结果
    INTEGER(i4) :: symbol_id              ! 符号ID
    CHARACTER(LEN=128) :: symbol_name     ! 符号名称
    REAL(wp) :: symbol_value              ! 符号值(如有)
    CHARACTER(LEN=128) :: symbol_unit     ! 符号单位
    
    ! 查询状态
    LOGICAL :: is_found                   ! 是否找到符号
    INTEGER(i4) :: n_queries              ! 查询次数统计
    INTEGER(i4) :: last_query_time_ms     ! 最后一次查询耗时(毫秒)
    
    ! 缓存信息
    LOGICAL :: is_cached                  ! 是否命中缓存
    INTEGER(i4) :: cache_hits             ! 缓存命中次数
    
  END TYPE IF_Sym_Query_State

  !=============================================================================
  ! 初始化子程序(API一致性)
  !=============================================================================
  PUBLIC :: IF_Sym_Types_Init

CONTAINS

  !=============================================================================
  ! IF_Sym_Types_Init - 模块初始化
  !=============================================================================
  SUBROUTINE IF_Sym_Types_Init()
    !! Symbol域TYPE定义初始化
    !! 说明: TYPE定义无需运行时初始化
    !! 存在目的: 与其他UFC模块API保持一致
    
    RETURN
    
  END SUBROUTINE IF_Sym_Types_Init

END MODULE IF_Sym_Def
