!===============================================================================
! MODULE: IF_Reg_Def
! LAYER:  L1_IF
! DOMAIN: Registry
! ROLE:   _Def
! BRIEF:  Registry domain TYPE definitions - component/solver/plugin registries.
!===============================================================================
!
! TYPE Four-Type Mapping:
!   IF_Reg_Component_Desc   [Desc]  Component registry descriptor
!   IF_Reg_Solver_Desc      [Desc]  Solver registry descriptor
!   IF_Reg_Plugin_Desc      [Desc]  Plugin registry descriptor
!   IF_Reg_Registry_State   [State] Registry runtime state
!
! Constants: REG_COMP_*, REG_SOLVER_*, REG_PLUGIN_*
!
! Status: Active | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Reg_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! TYPE: IF_Reg_Component_Desc  [Desc]
  ! Component registry descriptor (immutable after init).
  !=============================================================================
  !
  TYPE, PUBLIC :: IF_Reg_Component_Desc
    ! 基本信息
    CHARACTER(LEN=64) :: component_type       ! 组件类型(Element/Material/BC)
    CHARACTER(LEN=128) :: registry_name       ! 注册表名称
    CHARACTER(LEN=128) :: description         ! 描述
    CHARACTER(LEN=32) :: version              ! 版本号
    
    ! 容量信息
    INTEGER(i4) :: max_components             ! 最大组件数量
    INTEGER(i4) :: n_registered               ! 已注册组件数
    
    ! 配置标志
    LOGICAL :: allow_duplicates               ! 是否允许重复注册
    LOGICAL :: require_version                ! 是否要求版本号
    LOGICAL :: enable_hot_reload              ! 是否支持热加载
    
  END TYPE IF_Reg_Component_Desc

  !=============================================================================
  ! TYPE: IF_Reg_Solver_Desc  [Desc]
  ! Solver registry descriptor (immutable after init).
  !=============================================================================
  !
  TYPE, PUBLIC :: IF_Reg_Solver_Desc
    ! 基本信息
    CHARACTER(LEN=64) :: solver_type          ! 求解器类型(STD/EXP/CFD/EMF)
    CHARACTER(LEN=128) :: solver_name         ! 求解器名称
    CHARACTER(LEN=128) :: description         ! 描述
    CHARACTER(LEN=32) :: version              ! 版本号
    
    ! 求解器能力
    LOGICAL :: supports_linear                ! 支持线性分析
    LOGICAL :: supports_nonlinear             ! 支持非线性分析
    LOGICAL :: supports_static                ! 支持静力分析
    LOGICAL :: supports_dynamic               ! 支持动力分析
    LOGICAL :: supports_coupled               ! 支持多场耦合
    
    ! 性能指标
    INTEGER(i4) :: max_dofs                   ! 最大自由度数
    INTEGER(i4) :: max_iterations             ! 最大迭代次数
    REAL(wp) :: tolerance_default             ! 默认收敛容差
    
    ! 配置标志
    LOGICAL :: is_default                     ! 是否为默认求解器
    LOGICAL :: is_active                      ! 是否激活
    
  END TYPE IF_Reg_Solver_Desc

  !=============================================================================
  ! TYPE: IF_Reg_Plugin_Desc  [Desc]
  ! Plugin registry descriptor (immutable after init).
  !=============================================================================
  !
  TYPE, PUBLIC :: IF_Reg_Plugin_Desc
    ! 基本信息
    CHARACTER(LEN=64) :: plugin_type          ! 插件类型(UEL/UMAT/Load)
    CHARACTER(LEN=128) :: plugin_name         ! 插件名称
    CHARACTER(LEN=256) :: plugin_path         ! 插件路径
    CHARACTER(LEN=128) :: author              ! 作者
    CHARACTER(LEN=32) :: version              ! 版本号
    
    ! 插件接口
    CHARACTER(LEN=64) :: entry_point          ! 入口函数名
    INTEGER(i4) :: n_required_args            ! 必需参数数量
    INTEGER(i4) :: n_optional_args            ! 可选参数数量
    
    ! 兼容性信息
    CHARACTER(LEN=32) :: min_ufc_version      ! 最低UFC版本要求
    CHARACTER(LEN=32) :: max_ufc_version      ! 最高UFC版本要求
    LOGICAL :: is_thread_safe                 ! 是否线程安全
    
    ! 配置标志
    LOGICAL :: is_loaded                      ! 是否已加载
    LOGICAL :: is_verified                    ! 是否已验证
    LOGICAL :: is_enabled                     ! 是否启用
    
  END TYPE IF_Reg_Plugin_Desc

  !=============================================================================
  ! TYPE: IF_Reg_Registry_State  [State]
  ! Registry runtime state (read-write, dynamically updated).
  !=============================================================================
  !
  TYPE, PUBLIC :: IF_Reg_Registry_State
    ! 注册统计
    INTEGER(i4) :: n_components               ! 已注册组件数
    INTEGER(i4) :: n_solvers                  ! 已注册求解器数
    INTEGER(i4) :: n_plugins                  ! 已注册插件数
    INTEGER(i4) :: n_total_registrations      ! 总注册数
    
    ! 性能统计
    INTEGER(i4) :: n_queries                  ! 查询次数
    INTEGER(i4) :: n_hits                     ! 命中次数
    INTEGER(i4) :: n_misses                   ! 未命中次数
    REAL(wp) :: cache_hit_rate                ! 缓存命中率
    
    ! 运行时标志
    LOGICAL :: is_initialized                 ! 是否已初始化
    LOGICAL :: is_locked                      ! 是否锁定(禁止注册)
    LOGICAL :: has_degraded_components        ! 是否存在降级组件
    
    ! 错误信息
    INTEGER(i4) :: n_errors                   ! 错误计数
    CHARACTER(LEN=256) :: last_error          ! 最后一条错误信息
    
  END TYPE IF_Reg_Registry_State

  !=============================================================================
  ! Constants
  !=============================================================================
  
  ! Component type constants: REG_COMP_*
  INTEGER(i4), PARAMETER, PUBLIC :: &
    REG_COMP_ELEMENT = 1_i4,    & ! 单元组件
    REG_COMP_MATERIAL = 2_i4,   & ! 材料组件
    REG_COMP_BC = 3_i4,         & ! 边界条件组件
    REG_COMP_LOAD = 4_i4,       & ! 载荷组件
    REG_COMP_CONTACT = 5_i4       ! 接触组件

  ! Solver type constants: REG_SOLVER_*
  INTEGER(i4), PARAMETER, PUBLIC :: &
    REG_SOLVER_STD = 1_i4,      & ! 隐式求解器
    REG_SOLVER_EXP = 2_i4,      & ! 显式求解器
    REG_SOLVER_CFD = 3_i4,      & ! CFD求解器
    REG_SOLVER_EMF = 4_i4,      & ! 电磁求解器
    REG_SOLVER_THM = 5_i4,      & ! 热-力耦合求解器
    REG_SOLVER_CPL = 6_i4         ! 通用耦合求解器

  ! Plugin type constants: REG_PLUGIN_*
  INTEGER(i4), PARAMETER, PUBLIC :: &
    REG_PLUGIN_UEL = 1_i4,      & ! 用户单元插件
    REG_PLUGIN_UMAT = 2_i4,     & ! 用户材料插件
    REG_PLUGIN_VUMAT = 3_i4,    & ! 显式用户材料插件
    REG_PLUGIN_LOAD = 4_i4,     & ! 用户载荷插件
    REG_PLUGIN_FIELD = 5_i4       ! 用户场变量插件

  !=============================================================================
  ! [P0] IF_Reg_Types_Init - Module initialization (no-op for TYPE defs)
  !=============================================================================
  PUBLIC :: IF_Reg_Types_Init

CONTAINS

  !=============================================================================
  ! [P0] IF_Reg_Types_Init
  !=============================================================================
  SUBROUTINE IF_Reg_Types_Init()
    !! Registry TYPE definitions initialization (no-op).
    RETURN
  END SUBROUTINE IF_Reg_Types_Init

END MODULE IF_Reg_Def
