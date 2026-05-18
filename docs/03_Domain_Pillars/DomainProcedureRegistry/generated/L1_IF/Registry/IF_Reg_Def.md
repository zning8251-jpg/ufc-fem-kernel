# `IF_Reg_Def.f90`

- **Source**: `L1_IF/Registry/IF_Reg_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Reg_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Reg_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Reg`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Registry/IF_Reg_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Reg_Component_Desc` (lines 30–46)

```fortran
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
```

### `IF_Reg_Solver_Desc` (lines 53–76)

```fortran
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
```

### `IF_Reg_Plugin_Desc` (lines 83–106)

```fortran
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
```

### `IF_Reg_Registry_State` (lines 113–135)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Reg_Types_Init` | 176 | `SUBROUTINE IF_Reg_Types_Init()` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
