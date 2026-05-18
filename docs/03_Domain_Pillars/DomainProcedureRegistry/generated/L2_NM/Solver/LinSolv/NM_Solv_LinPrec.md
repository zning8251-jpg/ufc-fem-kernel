# `NM_Solv_LinPrec.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinPrec.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinPrec`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinPrec`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinPrec`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinPrec.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Jacobi_Preconditioner` (lines 31–34)

```fortran
  TYPE, PUBLIC :: Jacobi_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    REAL(DP), ALLOCATABLE :: diag_inv(:)  !<  D^{-1}
  END TYPE
```

### `SSOR_Preconditioner` (lines 37–43)

```fortran
  TYPE, PUBLIC :: SSOR_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    REAL(DP) :: omega                     !< relaxation  ω (0,2)
    REAL(DP), ALLOCATABLE :: diag(:)      !<   D
    TYPE(NM_CSR_Type) :: L_lower          !<  
    TYPE(NM_CSR_Type) :: U_upper          !<  
  END TYPE
```

### `NM_ILU_Preconditioner` (lines 46–51)

```fortran
  TYPE, PUBLIC :: NM_ILU_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    INTEGER(i4) :: fill_level                 !<  -grade  k
    TYPE(NM_CSR_Type) :: L_factor         !<  
    TYPE(NM_CSR_Type) :: U_factor         !<  
  END TYPE
```

### `Preconditioner_Params` (lines 54–59)

```fortran
  TYPE, PUBLIC :: Preconditioner_Params
    INTEGER(i4) :: precond_type              !<  
    INTEGER(i4) :: ilu_fill_level            !< ILU -grade 
    REAL(DP) :: ssor_omega                !< SSORrelaxation 
    REAL(DP) :: drop_tolerance            !<  
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_LinSolv_Prec_ComparePreconditioners` | 75 | `SUBROUTINE NM_LinSolv_Prec_ComparePreconditioners(A, precond_types, effectiveness, &` |
| SUBROUTINE | `NM_LinSolv_Prec_GetEffectiveness` | 114 | `SUBROUTINE NM_LinSolv_Prec_GetEffectiveness(A, precond_type, effectiveness, status)` |
| SUBROUTINE | `NM_LinSolv_Prec_GetStatistics` | 159 | `SUBROUTINE NM_LinSolv_Prec_GetStatistics(precond_type, stats, status)` |
| SUBROUTINE | `NM_LinSolv_Prec_ILU0_Build` | 189 | `SUBROUTINE NM_LinSolv_Prec_ILU0_Build(A, precond)` |
| SUBROUTINE | `NM_LinSolv_Prec_ILU_Apply` | 293 | `SUBROUTINE NM_LinSolv_Prec_ILU_Apply(precond, r, z)` |
| SUBROUTINE | `NM_LinSolv_Prec_Jacobi_Apply` | 312 | `SUBROUTINE NM_LinSolv_Prec_Jacobi_Apply(precond, r, z)` |
| SUBROUTINE | `NM_LinSolv_Prec_Jacobi_Build` | 326 | `SUBROUTINE NM_LinSolv_Prec_Jacobi_Build(A, precond)` |
| SUBROUTINE | `NM_LinSolv_Prec_SelectOptimal` | 354 | `SUBROUTINE NM_LinSolv_Prec_SelectOptimal(A, recommended_type, status)` |
| SUBROUTINE | `NM_LinSolv_Prec_SSOR_Apply` | 398 | `SUBROUTINE NM_LinSolv_Prec_SSOR_Apply(precond, r, z)` |
| SUBROUTINE | `NM_LinSolv_Prec_SSOR_Build` | 447 | `SUBROUTINE NM_LinSolv_Prec_SSOR_Build(A, omega, precond)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
