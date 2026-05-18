# `PH_Mat_Therm_Iso_Core.f90`

- **Source**: `L4_PH/Material/Thermal/PH_Mat_Therm_Iso_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Therm_Iso_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Therm_Iso_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Therm_Iso`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Thermal/PH_Mat_Therm_Iso_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Therm_Cfg_Elastic` (lines 66–70)

```fortran
  TYPE, PUBLIC :: PH_Therm_Cfg_Elastic
    REAL(wp) :: E_ref    = 0.0_wp     ! Young's modulus at T_ref [Pa]
    REAL(wp) :: nu       = 0.0_wp     ! Poisson's ratio [-] (assumed T-independent)
    REAL(wp) :: T_ref    = 293.0_wp   ! Reference temperature [K]
  END TYPE PH_Therm_Cfg_Elastic
```

### `PH_Therm_Cfg_Expansion` (lines 72–76)

```fortran
  TYPE, PUBLIC :: PH_Therm_Cfg_Expansion
    REAL(wp) :: alpha_iso = 0.0_wp    ! Isotropic CTE [1/K]
    REAL(wp) :: alpha_ortho(3) = 0.0_wp ! Orthotropic CTE [α1, α2, α3] [1/K]
    LOGICAL  :: is_orthotropic = .FALSE.
  END TYPE PH_Therm_Cfg_Expansion
```

### `PH_Therm_Cfg_TempDep_Lin` (lines 78–80)

```fortran
  TYPE, PUBLIC :: PH_Therm_Cfg_TempDep_Lin
    REAL(wp) :: dE_dT    = 0.0_wp     ! dE/dT slope [Pa/K] (typically negative)
  END TYPE PH_Therm_Cfg_TempDep_Lin
```

### `PH_Therm_Cfg_TempDep_Table` (lines 82–87)

```fortran
  TYPE, PUBLIC :: PH_Therm_Cfg_TempDep_Table
    LOGICAL  :: use_table = .FALSE.
    INTEGER(i4) :: n_table = 0_i4     ! Number of table entries
    REAL(wp) :: T_table(PH_THERM_MAX_TABLE) = 0.0_wp  ! Temperature points [K]
    REAL(wp) :: E_table(PH_THERM_MAX_TABLE) = 0.0_wp  ! E at each T point [Pa]
  END TYPE PH_Therm_Cfg_TempDep_Table
```

### `PH_Therm_Props` (lines 89–95)

```fortran
  TYPE, PUBLIC :: PH_Therm_Props
    TYPE(PH_Therm_Cfg_Elastic)       :: elastic
    TYPE(PH_Therm_Cfg_Expansion)     :: expansion
    TYPE(PH_Therm_Cfg_TempDep_Lin)   :: tempdep_lin
    TYPE(PH_Therm_Cfg_TempDep_Table) :: tempdep_table
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Therm_Props
```

### `PH_Therm_St_Stress` (lines 101–104)

```fortran
  TYPE, PUBLIC :: PH_Therm_St_Stress
    REAL(wp) :: stress(6)     = 0.0_wp  ! Mechanical stress [Pa]
    REAL(wp) :: strain_th(6)  = 0.0_wp  ! Thermal strain [-]
  END TYPE PH_Therm_St_Stress
```

### `PH_Therm_St_Temp` (lines 106–109)

```fortran
  TYPE, PUBLIC :: PH_Therm_St_Temp
    REAL(wp) :: E_current     = 0.0_wp  ! Current modulus at T [Pa]
    REAL(wp) :: T_current     = 293.0_wp ! Current temperature [K]
  END TYPE PH_Therm_St_Temp
```

### `PH_Therm_St_Tangent` (lines 111–113)

```fortran
  TYPE, PUBLIC :: PH_Therm_St_Tangent
    REAL(wp) :: C_tan(6,6)    = 0.0_wp  ! Current tangent [Pa]
  END TYPE PH_Therm_St_Tangent
```

### `PH_Therm_State` (lines 115–120)

```fortran
  TYPE, PUBLIC :: PH_Therm_State
    TYPE(PH_Therm_St_Stress)  :: stress
    TYPE(PH_Therm_St_Temp)    :: temp
    TYPE(PH_Therm_St_Tangent) :: tangent
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Therm_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Therm_Validate_Params` | 127 | `SUBROUTINE PH_Mat_Therm_Validate_Params(props, ierr)` |
| SUBROUTINE | `PH_Mat_Therm_Init` | 160 | `SUBROUTINE PH_Mat_Therm_Init(props, state, ierr)` |
| SUBROUTINE | `PH_Mat_Therm_Get_Modulus` | 183 | `SUBROUTINE PH_Mat_Therm_Get_Modulus(props, T_curr, E_curr, ierr)` |
| SUBROUTINE | `PH_Mat_Therm_Compute_ThermalStrain` | 232 | `SUBROUTINE PH_Mat_Therm_Compute_ThermalStrain(props, T_curr, strain_th, ierr)` |
| SUBROUTINE | `PH_Mat_Therm_Compute_Stress` | 264 | `SUBROUTINE PH_Mat_Therm_Compute_Stress(props, strain_total, T_curr, &` |
| SUBROUTINE | `PH_Mat_Therm_Compute_Tangent` | 320 | `SUBROUTINE PH_Mat_Therm_Compute_Tangent(props, T_curr, C_tangent, ierr)` |
| SUBROUTINE | `PH_Mat_Therm_Update_State` | 354 | `SUBROUTINE PH_Mat_Therm_Update_State(props, stress, C_tangent, state, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
