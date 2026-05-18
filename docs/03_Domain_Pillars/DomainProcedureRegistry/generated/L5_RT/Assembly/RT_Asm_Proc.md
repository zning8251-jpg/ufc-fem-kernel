# `RT_Asm_Proc.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Proc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Asm_Init_In` (lines 45–53)

```fortran
  TYPE :: RT_Asm_Init_In
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_dofs_per_node = 3_i4
    LOGICAL     :: assemble_K = .TRUE.
    LOGICAL     :: assemble_M = .FALSE.
    LOGICAL     :: assemble_C = .FALSE.
    LOGICAL     :: assemble_f = .TRUE.
  END TYPE RT_Asm_Init_In
```

### `RT_Asm_Init_Out` (lines 55–58)

```fortran
  TYPE :: RT_Asm_Init_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: initialized = .FALSE.
  END TYPE RT_Asm_Init_Out
```

### `RT_Asm_BuildPattern_In` (lines 67–71)

```fortran
  TYPE :: RT_Asm_BuildPattern_In
    INTEGER(i4) :: nEq = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4) :: renum_method = 1_i4  ! RCM default
  END TYPE RT_Asm_BuildPattern_In
```

### `RT_Asm_BuildPattern_Out` (lines 73–76)

```fortran
  TYPE :: RT_Asm_BuildPattern_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: pattern_built = .FALSE.
  END TYPE RT_Asm_BuildPattern_Out
```

### `RT_Asm_AssembleK_In` (lines 85–91)

```fortran
  TYPE :: RT_Asm_AssembleK_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Ke(:,:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: use_scaling = .FALSE.
    REAL(wp)    :: scale_factor = 1.0_wp
  END TYPE RT_Asm_AssembleK_In
```

### `RT_Asm_AssembleK_Out` (lines 93–97)

```fortran
  TYPE :: RT_Asm_AssembleK_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: K_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleK_Out
```

### `RT_Asm_AssembleM_In` (lines 106–111)

```fortran
  TYPE :: RT_Asm_AssembleM_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Me(:,:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: consistent = .TRUE.  ! .T.=consistent, .F.=lumped
  END TYPE RT_Asm_AssembleM_In
```

### `RT_Asm_AssembleM_Out` (lines 113–117)

```fortran
  TYPE :: RT_Asm_AssembleM_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: M_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleM_Out
```

### `RT_Asm_AssembleF_In` (lines 126–131)

```fortran
  TYPE :: RT_Asm_AssembleF_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Fe(:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: is_internal = .FALSE.  ! .T.=internal force, .F.=external
  END TYPE RT_Asm_AssembleF_In
```

### `RT_Asm_AssembleF_Out` (lines 133–137)

```fortran
  TYPE :: RT_Asm_AssembleF_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: f_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleF_Out
```

### `RT_Asm_ApplyConstraints_In` (lines 146–151)

```fortran
  TYPE :: RT_Asm_ApplyConstraints_In
    INTEGER(i4), POINTER :: dof_indices(:) => NULL()
    INTEGER(i4), POINTER :: constraint_types(:) => NULL()
    REAL(wp), POINTER    :: constraint_values(:) => NULL()
    INTEGER(i4) :: n_constraints = 0_i4
  END TYPE RT_Asm_ApplyConstraints_In
```

### `RT_Asm_ApplyConstraints_Out` (lines 153–157)

```fortran
  TYPE :: RT_Asm_ApplyConstraints_Out
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: n_applied = 0_i4
    LOGICAL     :: constraints_applied = .FALSE.
  END TYPE RT_Asm_ApplyConstraints_Out
```

### `RT_Asm_ComputeResidual_In` (lines 166–170)

```fortran
  TYPE :: RT_Asm_ComputeResidual_In
    REAL(wp), POINTER :: f_external(:) => NULL()
    REAL(wp), POINTER :: f_internal(:) => NULL()
    LOGICAL     :: use_norm = .TRUE.
  END TYPE RT_Asm_ComputeResidual_In
```

### `RT_Asm_ComputeResidual_Out` (lines 172–177)

```fortran
  TYPE :: RT_Asm_ComputeResidual_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: res_norm = 0.0_wp
    REAL(wp), ALLOCATABLE :: residual(:)
    LOGICAL     :: converged = .FALSE.
  END TYPE RT_Asm_ComputeResidual_Out
```

### `RT_Asm_Finalize_In` (lines 186–188)

```fortran
  TYPE :: RT_Asm_Finalize_In
    LOGICAL     :: keep_pattern = .FALSE.
  END TYPE RT_Asm_Finalize_In
```

### `RT_Asm_Finalize_Out` (lines 190–193)

```fortran
  TYPE :: RT_Asm_Finalize_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: finalized = .FALSE.
  END TYPE RT_Asm_Finalize_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_Init` | 205 | `SUBROUTINE RT_Asm_Init(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_BuildPattern` | 217 | `SUBROUTINE RT_Asm_BuildPattern(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_AssembleK` | 231 | `SUBROUTINE RT_Asm_AssembleK(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_AssembleM` | 245 | `SUBROUTINE RT_Asm_AssembleM(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_AssembleF` | 258 | `SUBROUTINE RT_Asm_AssembleF(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_ApplyConstraints` | 271 | `SUBROUTINE RT_Asm_ApplyConstraints(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_ComputeResidual` | 284 | `SUBROUTINE RT_Asm_ComputeResidual(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Asm_Finalize` | 299 | `SUBROUTINE RT_Asm_Finalize(desc, state, algo, ctx, inp, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 60–62 | `INTERFACE RT_Asm_Init` |
| 78–80 | `INTERFACE RT_Asm_BuildPattern` |
| 99–101 | `INTERFACE RT_Asm_AssembleK` |
| 119–121 | `INTERFACE RT_Asm_AssembleM` |
| 139–141 | `INTERFACE RT_Asm_AssembleF` |
| 159–161 | `INTERFACE RT_Asm_ApplyConstraints` |
| 179–181 | `INTERFACE RT_Asm_ComputeResidual` |
| 195–197 | `INTERFACE RT_Asm_Finalize` |
