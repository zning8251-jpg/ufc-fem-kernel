# `IF_Log_Def.f90`

- **Source**: `L1_IF/Log/IF_Log_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Log_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Log_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Log`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Log`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Log/IF_Log_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Log_Desc` (lines 25–29)

```fortran
  TYPE, PUBLIC :: IF_Log_Desc
    INTEGER(i4)       :: log_level = IF_LOG_INFO
    INTEGER(i4)       :: log_unit  = 6    ! stdout
    CHARACTER(LEN=32) :: prefix    = "[UFC] "
  END TYPE IF_Log_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
