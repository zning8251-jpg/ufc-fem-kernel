# `RT_Asm_Mgr.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Mgr`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Asm_AssemStiff_In` (lines 71–74)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemStiff_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemStiff_In
```

### `RT_Asm_AssemStiff_Out` (lines 75–78)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemStiff_Out
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemStiff_Out
```

### `RT_Asm_AssemResid_In` (lines 81–84)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemResid_In
        REAL(wp), ALLOCATABLE :: R_element(:)  ! Element residual vector R_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemResid_In
```

### `RT_Asm_AssemResid_Out` (lines 85–88)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemResid_Out
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Global residual vector R
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemResid_Out
```

### `RT_Asm_AssemMass_In` (lines 91–94)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemMass_In
        REAL(wp), ALLOCATABLE :: M_element(:,:)  ! Element mass matrix M_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemMass_In
```

### `RT_Asm_AssemMass_Out` (lines 95–98)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemMass_Out
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemMass_Out
```

### `RT_Asm_AssemDamp_In` (lines 101–104)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemDamp_In
        REAL(wp), ALLOCATABLE :: C_element(:,:)  ! Element damping matrix C_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemDamp_In
```

### `RT_Asm_AssemDamp_Out` (lines 105–108)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemDamp_Out
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Global damping matrix C
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemDamp_Out
```

### `RT_Asm_AddElemStiff_In` (lines 111–115)

```fortran
    TYPE, PUBLIC :: RT_Asm_AddElemStiff_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K (inout)
    END TYPE RT_Asm_AddElemStiff_In
```

### `RT_Asm_AddElemStiff_Out` (lines 116–119)

```fortran
    TYPE, PUBLIC :: RT_Asm_AddElemStiff_Out
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Updated global stiffness matrix K
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AddElemStiff_Out
```

### `RT_Asm_AddElemResid_In` (lines 122–126)

```fortran
    TYPE, PUBLIC :: RT_Asm_AddElemResid_In
        REAL(wp), ALLOCATABLE :: R_element(:)  ! Element residual vector R_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Global residual vector R (inout)
    END TYPE RT_Asm_AddElemResid_In
```

### `RT_Asm_AddElemResid_Out` (lines 127–130)

```fortran
    TYPE, PUBLIC :: RT_Asm_AddElemResid_Out
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Updated global residual vector R
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AddElemResid_Out
```

### `RT_Asm_GetElemDOF_In` (lines 133–137)

```fortran
    TYPE, PUBLIC :: RT_Asm_GetElemDOF_In
        INTEGER(i4) :: elem_id  ! Element ID
        INTEGER(i4), ALLOCATABLE :: node_ids(:)  ! Node IDs
        INTEGER(i4) :: dof_per_node  ! DOF per node
    END TYPE RT_Asm_GetElemDOF_In
```

### `RT_Asm_GetElemDOF_Out` (lines 138–141)

```fortran
    TYPE, PUBLIC :: RT_Asm_GetElemDOF_Out
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_GetElemDOF_Out
```

### `RT_Asm_ScatterElemToGlob_In` (lines 144–148)

```fortran
    TYPE, PUBLIC :: RT_Asm_ScatterElemToGlob_In
        REAL(wp), ALLOCATABLE :: elem_vec(:)  ! Element vector
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: global_vec(:)  ! Global vector (inout)
    END TYPE RT_Asm_ScatterElemToGlob_In
```

### `RT_Asm_ScatterElemToGlob_Out` (lines 149–152)

```fortran
    TYPE, PUBLIC :: RT_Asm_ScatterElemToGlob_Out
        REAL(wp), ALLOCATABLE :: global_vec(:)  ! Updated global vector
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_ScatterElemToGlob_Out
```

### `RT_Asm_AssemStiffSparse_In` (lines 155–159)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemStiffSparse_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        TYPE(RT_TripletList) :: K_triplets  ! Triplet list (inout)
    END TYPE RT_Asm_AssemStiffSparse_In
```

### `RT_Asm_AssemStiffSparse_Out` (lines 160–163)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemStiffSparse_Out
        TYPE(RT_TripletList) :: K_triplets  ! Updated triplet list
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemStiffSparse_Out
```

### `RT_Asm_AssemMassConsist_In` (lines 166–174)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemMassConsist_In
        REAL(wp), ALLOCATABLE :: N(:)  ! Shape functions
        REAL(wp) :: density  ! Material density ρ
        REAL(wp) :: detJ  ! Determinant of Jacobian |J|
        REAL(wp) :: weight  ! Integration weight
        INTEGER(i4) :: n_gauss  ! Number of Gauss points
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M (inout)
    END TYPE RT_Asm_AssemMassConsist_In
```

### `RT_Asm_AssemMassConsist_Out` (lines 175–178)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemMassConsist_Out
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Updated global mass matrix M
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemMassConsist_Out
```

### `RT_Asm_AssemLoadOpt_In` (lines 181–190)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemLoadOpt_In
        REAL(wp), ALLOCATABLE :: N(:)  ! Shape functions
        REAL(wp), ALLOCATABLE :: load_value(:)  ! Load values
        REAL(wp) :: detJ  ! Determinant of Jacobian |J|
        REAL(wp) :: weight  ! Integration weight
        INTEGER(i4) :: n_gauss  ! Number of Gauss points
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        LOGICAL :: use_vectorized  ! Use vectorized assembly
        REAL(wp), ALLOCATABLE :: F_global(:)  ! Global force vector F (inout)
    END TYPE RT_Asm_AssemLoadOpt_In
```

### `RT_Asm_AssemLoadOpt_Out` (lines 191–194)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemLoadOpt_Out
        REAL(wp), ALLOCATABLE :: F_global(:)  ! Updated global force vector F
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemLoadOpt_Out
```

### `RT_Asm_AssemDampRayleigh_In` (lines 197–203)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemDampRayleigh_In
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K
        REAL(wp) :: alpha  ! Rayleigh damping coefficient α
        REAL(wp) :: beta  ! Rayleigh damping coefficient β
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Global damping matrix C (inout)
    END TYPE RT_Asm_AssemDampRayleigh_In
```

### `RT_Asm_AssemDampRayleigh_Out` (lines 204–207)

```fortran
    TYPE, PUBLIC :: RT_Asm_AssemDampRayleigh_Out
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Updated global damping matrix C = αM + βK
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemDampRayleigh_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_AssemStiff_Structured` | 268 | `SUBROUTINE RT_Asm_AssemStiff_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemResid_Structured` | 317 | `SUBROUTINE RT_Asm_AssemResid_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AddElemStiff_Structured` | 361 | `SUBROUTINE RT_Asm_AddElemStiff_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AddElemResid_Structured` | 409 | `SUBROUTINE RT_Asm_AddElemResid_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AddElemStiff_Atomic` | 444 | `SUBROUTINE RT_Asm_AddElemStiff_Atomic(K_global, K_element, elem_dof, &` |
| SUBROUTINE | `RT_Asm_AddElemStiff_InPlace` | 472 | `SUBROUTINE RT_Asm_AddElemStiff_InPlace(K_global, K_element, elem_dof, &` |
| SUBROUTINE | `RT_Asm_ScatterResid_Atomic` | 500 | `SUBROUTINE RT_Asm_ScatterResid_Atomic(R_global, R_element, elem_dof, &` |
| SUBROUTINE | `RT_Asm_AddElemResid` | 527 | `SUBROUTINE RT_Asm_AddElemResid(R_global, R_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_AddElemStiff` | 548 | `SUBROUTINE RT_Asm_AddElemStiff(K_global, K_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_As_Optimized` | 568 | `SUBROUTINE RT_Asm_As_Optimized(F_global, N, load_value, detJ, &` |
| SUBROUTINE | `RT_Asm_AssemMass_Structured` | 613 | `SUBROUTINE RT_Asm_AssemMass_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemDamp_Structured` | 642 | `SUBROUTINE RT_Asm_AssemDamp_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemDampRayleigh_Structured` | 671 | `SUBROUTINE RT_Asm_AssemDampRayleigh_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemMassConsist_Structured` | 720 | `SUBROUTINE RT_Asm_AssemMassConsist_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemLoadOpt_Structured` | 775 | `SUBROUTINE RT_Asm_AssemLoadOpt_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemStiffSparse_Structured` | 827 | `SUBROUTINE RT_Asm_AssemStiffSparse_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_GetElemDOF_Structured` | 875 | `SUBROUTINE RT_Asm_GetElemDOF_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_ScatterElemToGlob_Structured` | 914 | `SUBROUTINE RT_Asm_ScatterElemToGlob_Structured(in, out)` |
| SUBROUTINE | `RT_Asm_AssemDamp` | 961 | `SUBROUTINE RT_Asm_AssemDamp(C_global, C_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_AssemDampRayleigh` | 980 | `SUBROUTINE RT_Asm_AssemDampRayleigh(C_global, M_global, K_global, &` |
| SUBROUTINE | `RT_Asm_AssemMass` | 1005 | `SUBROUTINE RT_Asm_AssemMass(M_global, M_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_AssemMassConsist` | 1024 | `SUBROUTINE RT_Asm_AssemMassConsist(M_global, N, density, detJ, &` |
| SUBROUTINE | `RT_Asm_AssemResid` | 1053 | `SUBROUTINE RT_Asm_AssemResid(R_global, R_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_AssemStiff` | 1072 | `SUBROUTINE RT_Asm_AssemStiff(K_global, K_element, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_AssemStiffSparse` | 1091 | `SUBROUTINE RT_Asm_AssemStiffSparse(K_triplets, K_element, elem_dof, &` |
| SUBROUTINE | `RT_Asm_GetElemDOF` | 1112 | `SUBROUTINE RT_Asm_GetElemDOF(elem_id, node_ids, dof_per_node, elem_dof, status)` |
| SUBROUTINE | `RT_Asm_ScatterElemToGlob` | 1132 | `SUBROUTINE RT_Asm_ScatterElemToGlob(elem_vec, elem_dof, global_vec, status)` |
| SUBROUTINE | `RT_Asm_AssemLoadOpt` | 1153 | `SUBROUTINE RT_Asm_AssemLoadOpt(F_global, N, load_value, detJ, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
