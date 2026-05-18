# `PH_Elem_ThermalStrainKernel.f90`

- **Source**: `L4_PH/Element/Thermal/PH_Elem_ThermalStrainKernel.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_ThermalStrainKernel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_ThermalStrainKernel`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_ThermalStrainKernel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Thermal/PH_Elem_ThermalStrainKernel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Thermal_Strain_Args` (lines 22–41)

```fortran
  TYPE :: PH_Thermal_Strain_Args
    !-- Input: Temperature field
    REAL(wp), POINTER     :: temperature(:) => NULL()  ! [n_nodes] nodal temp
    REAL(wp)              :: ref_temp = 293.15_wp      ! Reference temp (K)
    
    !-- Input: Material properties
    INTEGER(i4)           :: material_id = 0_i4        ! Material ID in registry
    REAL(wp)              :: alpha_iso = 0.0_wp        ! Isotropic CTE (1/K)
    REAL(wp)              :: alpha_ortho(3) = 0.0_wp   ! Orthotropic CTE [α_x, α_y, α_z]
    LOGICAL               :: is_isotropic = .TRUE._wp  ! Isotropic flag
    
    !-- Input: Element topology
    INTEGER(i4)           :: n_nodes = 0_i4            ! Number of nodes
    INTEGER(i4)           :: n_integ_pts = 0_i4        ! Integration points
    
    !-- Output: Thermal strain
    REAL(wp), ALLOCATABLE :: thermal_strain(:)         ! [6] Voigt strain
    REAL(wp), ALLOCATABLE :: delta_temp(:)             ! [n_integ_pts] ΔT per IP
    
  END TYPE PH_Thermal_Strain_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ThermalStrainKernel_Algo` | 55 | `SUBROUTINE PH_ThermalStrainKernel_Algo(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
