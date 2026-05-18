# `NM_Base_Norms.f90`

- **Source**: `L2_NM/Base/NM_Base_Norms.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Base_Norms`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Base_Norms`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Base_Norms`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/NM_Base_Norms.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Norm_L2_Arg` (lines 26–29)

```fortran
  TYPE :: Norm_L2_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_L2_Arg
```

### `Norm_L1_Arg` (lines 34–37)

```fortran
  TYPE :: Norm_L1_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_L1_Arg
```

### `Norm_Inf_Arg` (lines 42–45)

```fortran
  TYPE :: Norm_Inf_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_Inf_Arg
```

### `Norm_Fro_Arg` (lines 50–53)

```fortran
  TYPE :: Norm_Fro_Arg
    ! [IN] mat - Input matrix
    REAL(wp), ALLOCATABLE :: mat(:,:)
  END TYPE Norm_Fro_Arg
```

### `Normalize_Arg` (lines 58–63)

```fortran
  TYPE :: Normalize_Arg
    ! [IN]  vec      - Input vector
    ! [OUT] unit_vec - Unit vector (same shape as vec)
    REAL(wp), ALLOCATABLE :: vec(:)
    REAL(wp), ALLOCATABLE :: unit_vec(:)
  END TYPE Normalize_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `Norm_L2` | 71 | `PURE FUNCTION Norm_L2(vec) RESULT(norm)` |
| SUBROUTINE | `Norm_L2_Proc` | 84 | `SUBROUTINE Norm_L2_Proc(arg, norm)` |
| FUNCTION | `Norm_L1` | 97 | `PURE FUNCTION Norm_L1(vec) RESULT(norm)` |
| SUBROUTINE | `Norm_L1_Proc` | 114 | `SUBROUTINE Norm_L1_Proc(arg, norm)` |
| FUNCTION | `Norm_Inf` | 132 | `PURE FUNCTION Norm_Inf(vec) RESULT(norm)` |
| SUBROUTINE | `Norm_Inf_Proc` | 149 | `SUBROUTINE Norm_Inf_Proc(arg, norm)` |
| FUNCTION | `Norm_Fro` | 167 | `PURE FUNCTION Norm_Fro(mat) RESULT(norm)` |
| SUBROUTINE | `Norm_Fro_Proc` | 184 | `SUBROUTINE Norm_Fro_Proc(arg, norm)` |
| FUNCTION | `Normalize` | 200 | `PURE FUNCTION Normalize(vec) RESULT(unit_vec)` |
| SUBROUTINE | `Normalize_Proc` | 220 | `SUBROUTINE Normalize_Proc(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
