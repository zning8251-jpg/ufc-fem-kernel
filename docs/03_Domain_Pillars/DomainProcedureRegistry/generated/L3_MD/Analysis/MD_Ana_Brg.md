# `MD_Ana_Brg.f90`

- **Source**: `L3_MD/Analysis/MD_Ana_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Ana_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Ana_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Ana`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Analysis`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/MD_Ana_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Ana_Brg_Pop_Registry` (lines 61–63)

```fortran
  TYPE, PUBLIC :: MD_Ana_Brg_Pop_Registry
    CHARACTER(LEN=32) :: names(MAX_ANA_SUBDOMAINS) = ""
  END TYPE MD_Ana_Brg_Pop_Registry
```

### `MD_Ana_Brg_Cfg_State` (lines 69–72)

```fortran
  TYPE, PUBLIC :: MD_Ana_Brg_Cfg_State
    INTEGER(i4) :: n_registered = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE MD_Ana_Brg_Cfg_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Ana_Brg_InitCompat` | 86 | `SUBROUTINE MD_Ana_Brg_InitCompat(status)` |
| SUBROUTINE | `MD_Ana_Brg_Register` | 109 | `SUBROUTINE MD_Ana_Brg_Register(name, status)` |
| SUBROUTINE | `MD_Ana_Brg_Lookup` | 128 | `SUBROUTINE MD_Ana_Brg_Lookup(name, idx, status)` |
| SUBROUTINE | `MD_Ana_Brg_Iterate` | 152 | `SUBROUTINE MD_Ana_Brg_Iterate(names, n_count, status)` |
| SUBROUTINE | `MD_Ana_Brg_Finalize` | 172 | `SUBROUTINE MD_Ana_Brg_Finalize(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
