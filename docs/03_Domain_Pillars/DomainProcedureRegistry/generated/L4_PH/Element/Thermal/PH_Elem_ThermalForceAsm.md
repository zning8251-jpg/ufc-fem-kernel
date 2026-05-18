# `PH_Elem_ThermalForceAsm.f90`

- **Source**: `L4_PH/Element/Thermal/PH_Elem_ThermalForceAsm.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_ThermalForceAsm`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_ThermalForceAsm`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_ThermalForceAsm`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Thermal/PH_Elem_ThermalForceAsm.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Thermal_Force_Args` (lines 22–45)

```fortran
  TYPE :: PH_Thermal_Force_Args
    !-- Input: Element topology
    INTEGER(i4)           :: n_nodes = 0_i4            ! Number of nodes
    INTEGER(i4)           :: n_dof_per_node = 3_i4     ! DOFs per node (2D/3D)
    INTEGER(i4)           :: n_integ_pts = 0_i4        ! Integration points
    
    !-- Input: Strain-displacement matrix
    REAL(wp), POINTER     :: B(:,:,:) => NULL()        ! [n_dim, n_nodes, n_ip] B-matrix
    
    !-- Input: Thermal stress
    REAL(wp), POINTER     :: thermal_stress(:) => NULL() ! [6] Voigt thermal stress
    
    !-- Input: Integration data
    REAL(wp), POINTER     :: detJ(:) => NULL()         ! [n_ip] Jacobian determinant
    REAL(wp), POINTER     :: weights(:) => NULL()      ! [n_ip] Integration weights
    
    !-- Output: Thermal force vector
    REAL(wp), ALLOCATABLE :: f_thermal(:)              ! [n_dof] assembled force
    
    !-- Metadata
    INTEGER(i4)           :: elem_type = 0_i4          ! Element type code
    LOGICAL               :: consistent = .TRUE._wp    ! Use consistent formulation
    
  END TYPE PH_Thermal_Force_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ThermalForceAsm_Algo` | 58 | `SUBROUTINE PH_ThermalForceAsm_Algo(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
