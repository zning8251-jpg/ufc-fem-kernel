# `RT_Solv_ContResidual.f90`

- **Source**: `L5_RT/Solver/RT_Solv_ContResidual.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Solv_ContResidual`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_ContResidual`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_ContResidual`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_ContResidual.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_ContactData` (lines 40–47)

```fortran
  TYPE, PUBLIC :: RT_ContactData
    INTEGER(i4) :: slave_node_id       ! Slave node ID
    INTEGER(i4) :: master_node_id      ! Master node ID (or surface ID)
    REAL(wp) :: penetration_depth = 0.0_wp  ! Current penetration
    REAL(wp) :: contact_normal(3) = [0.0_wp, 0.0_wp, 0.0_wp]  ! Contact normal direction
    REAL(wp) :: penalty_stiffness = 0.0_wp  ! Penalty stiffness for this pair
    LOGICAL :: is_active = .FALSE.     ! Active contact flag
  END TYPE RT_ContactData
```

### `RT_Solver_State` (lines 50–61)

```fortran
  TYPE, PUBLIC :: RT_Solver_State
    INTEGER(i4) :: n_dofs              ! Total degrees of freedom
    REAL(wp), ALLOCATABLE :: displacement(:)  ! Displacement field [n_dofs]
    REAL(wp), ALLOCATABLE :: velocity(:)      ! Velocity field [n_dofs]
    REAL(wp), ALLOCATABLE :: acceleration(:)  ! Acceleration field [n_dofs]
    REAL(wp), ALLOCATABLE :: reference_coords(:)  ! Reference coordinates [n_dofs]
    
    ! CSR matrix storage
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)
    INTEGER(i4), ALLOCATABLE :: col_idx(:)
    REAL(wp), ALLOCATABLE :: values(:)
  END TYPE RT_Solver_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Solv_Cont_AssembleGlobalResidual` | 74 | `SUBROUTINE RT_Solv_Cont_AssembleGlobalResidual( &` |
| SUBROUTINE | `RT_Solv_Cont_UpdateContactState` | 208 | `SUBROUTINE RT_Solv_Cont_UpdateContactState(solver_state, contact_data, &` |
| SUBROUTINE | `RT_Solv_Cont_CheckConvergence` | 291 | `SUBROUTINE RT_Solv_Cont_CheckConvergence(contact_data, n_contacts, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
