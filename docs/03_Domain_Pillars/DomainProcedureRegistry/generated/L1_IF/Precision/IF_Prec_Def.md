# `IF_Prec_Def.f90`

- **Source**: `L1_IF/Precision/IF_Prec_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Prec_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Prec_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Prec`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Precision`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Precision/IF_Prec_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Prec_Desc` (lines 17–20)

```fortran
  TYPE, PUBLIC :: IF_Prec_Desc
    INTEGER(i4) :: wp_bytes  = 8       ! working precision bytes
    LOGICAL     :: is_double = .TRUE.
  END TYPE IF_Prec_Desc
```

### `IF_Precision_Desc` (lines 23–26)

```fortran
  TYPE, PUBLIC :: IF_Precision_Desc
    INTEGER(i4) :: wp_bytes  = 8
    LOGICAL     :: is_double = .TRUE.
  END TYPE IF_Precision_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
