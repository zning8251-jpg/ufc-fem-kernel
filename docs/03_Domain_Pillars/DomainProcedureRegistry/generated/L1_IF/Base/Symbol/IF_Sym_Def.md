# `IF_Sym_Def.f90`

- **Source**: `L1_IF/Base/Symbol/IF_Sym_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Sym_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Sym_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Sym`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base/Symbol`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/Symbol/IF_Sym_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Sym_Table_Desc` (lines 22–40)

```fortran
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
```

### `IF_Sym_UnitSystem_Desc` (lines 49–72)

```fortran
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
```

### `IF_Sym_Dimension_Desc` (lines 81–97)

```fortran
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
```

### `IF_Sym_Query_State` (lines 106–122)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Sym_Types_Init` | 134 | `SUBROUTINE IF_Sym_Types_Init()` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
