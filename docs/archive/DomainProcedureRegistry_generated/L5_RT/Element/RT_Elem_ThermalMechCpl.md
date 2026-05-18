# `RT_Elem_ThermalMechCpl.f90`

- **Source**: `L5_RT/Element/RT_Elem_ThermalMechCpl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_ThermalMechCpl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_ThermalMechCpl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem_ThermalMechCpl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_ThermalMechCpl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Thermal_Load` (lines 37–54)

```fortran
  TYPE, PUBLIC :: RT_Thermal_Load
    !-- Temperature field (from MD/PH layer)
    REAL(wp), POINTER :: temperature(:) => NULL()  ! [n_nodes] temp field
    REAL(wp) :: ref_temp = 293.15_wp         ! Reference temp (K)
    
    !-- Material reference (pointer to MD registry)
    INTEGER(i4) :: material_id = 0           ! Material ID in registry
    
    !-- Output (computed by L4_PH kernels)
    REAL(wp), ALLOCATABLE :: thermal_strain(:) ! [6] Voigt: exx,eyy,ezz,gxy,gyz,gxz
    REAL(wp), ALLOCATABLE :: f_thermal(:)      ! Thermal force vector [n_dof]
    REAL(wp), ALLOCATABLE :: stress_thermal(:) ! Thermal stress [6]
    
    !-- Metadata
    LOGICAL :: is_isotropic = .TRUE.     ! Isotropic thermal expansion
    INTEGER(i4) :: n_integ_points = 0    ! Number of integration points
    
  END TYPE RT_Thermal_Load
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Thermal_Compute_Strain_Route` | 68 | `SUBROUTINE RT_Thermal_Compute_Strain_Route(thermal_load, ph_ctx, status)` |
| SUBROUTINE | `RT_Thermal_Assemble_Force_Route` | 122 | `SUBROUTINE RT_Thermal_Assemble_Force_Route(elem_desc, elem_state, elem_algo, &` |
| SUBROUTINE | `RT_Thermal_Update_Stress_Route` | 177 | `SUBROUTINE RT_Thermal_Update_Stress_Route(ph_state, thermal_load, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
