# `RT_Cont_AugLagSolv.f90`

- **Source**: `L5_RT/Contact/RT_Cont_AugLagSolv.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_AugLagSolv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_AugLagSolv`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont_AugLagSolv`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_AugLagSolv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Cont_AugLag_In` (lines 57–68)

```fortran
  TYPE, PUBLIC :: RT_Cont_AugLag_In
    !-- Geometry (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()   !< [3, n_nodes]  current coords
    REAL(wp), POINTER :: node_disp(:,:)   => NULL()   !< [3, n_nodes]  incremental disp
    !-- Gap function values from last search (NON_OWNING_PTR)
    REAL(wp), POINTER :: gap(:) => NULL()             !< [n_pairs]  gap < 0 => penetration
    !-- Global residual norm from last NR solve (scalar pass-back)
    REAL(wp) :: nr_residual_norm = 0.0_wp
    !-- Flags
    LOGICAL :: compute_tangent = .TRUE.
    LOGICAL :: is_first_uzawa  = .FALSE.  !< .TRUE. on first call per increment
  END TYPE RT_Cont_AugLag_In
```

### `RT_Cont_AugLag_Out` (lines 74–84)

```fortran
  TYPE, PUBLIC :: RT_Cont_AugLag_Out
    TYPE(ErrorStatusType) :: status
    !-- Uzawa convergence result
    LOGICAL     :: uzawa_converged   = .FALSE.  !< .TRUE. if ||delta_lambda|| < tol_aug
    REAL(wp)    :: delta_lambda_norm = 0.0_wp   !< ||lambda_trial - lambda_n||_inf
    INTEGER(i4) :: uzawa_iters_done  = 0_i4     !< Number of Uzawa iters completed
    !-- Aggregate contact info
    INTEGER(i4) :: n_active_pairs    = 0_i4     !< Number of pairs in contact
    REAL(wp)    :: max_lambda        = 0.0_wp   !< Max Lagrange multiplier (diagnostics)
    CHARACTER(LEN=256) :: message    = ''
  END TYPE RT_Cont_AugLag_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Cont_AugLag_Solve` | 106 | `SUBROUTINE RT_Cont_AugLag_Solve(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_AugLag_UpdateLambda` | 184 | `SUBROUTINE RT_Cont_AugLag_UpdateLambda(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_AugLag_CheckConv` | 236 | `SUBROUTINE RT_Cont_AugLag_CheckConv(desc, state, algo, ctx, inp, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
