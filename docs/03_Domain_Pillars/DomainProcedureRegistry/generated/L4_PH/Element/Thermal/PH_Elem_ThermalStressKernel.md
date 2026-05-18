# `PH_Elem_ThermalStressKernel.f90`

- **Source**: `L4_PH/Element/Thermal/PH_Elem_ThermalStressKernel.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_ThermalStressKernel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_ThermalStressKernel`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_ThermalStressKernel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Thermal/PH_Elem_ThermalStressKernel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Thermal_Stress_Args` (lines 22–39)

```fortran
  TYPE :: PH_Thermal_Stress_Args
    !-- Input: Material properties
    INTEGER(i4)           :: material_id = 0_i4        ! Material ID in registry
    REAL(wp)              :: young_mod = 0.0_wp        ! Young's modulus E (Pa)
    REAL(wp)              :: poisson_ratio = 0.0_wp    ! Poisson's ratio ν
    REAL(wp), POINTER     :: D(:,:) => NULL()          ! [6x6] Stiffness matrix (optional)
    
    !-- Input: Thermal strain
    REAL(wp), POINTER     :: thermal_strain(:) => NULL() ! [6] Voigt thermal strain
    
    !-- Input: Initial stress state (optional)
    REAL(wp), POINTER     :: initial_stress(:) => NULL() ! [6] Pre-existing stress
    
    !-- Output: Thermal stress
    REAL(wp), ALLOCATABLE :: thermal_stress(:)         ! [6] Voigt thermal stress
    LOGICAL               :: compute_total = .FALSE._wp ! Include initial stress flag
    
  END TYPE PH_Thermal_Stress_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ThermalStressKernel_Algo` | 52 | `SUBROUTINE PH_ThermalStressKernel_Algo(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
