# `AP_Reg_Def.f90`

- **Source**: `L6_AP/Registry/AP_Reg_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Reg_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Reg_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Reg`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Registry/AP_Reg_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_RegEntry` (lines 23–28)

```fortran
  TYPE :: AP_RegEntry
    CHARACTER(LEN=AP_REG_NAME_LEN) :: name = ""
    INTEGER(i4) :: type_id  = 0
    INTEGER(i4) :: category = 0
    LOGICAL     :: valid    = .FALSE.
  END TYPE AP_RegEntry
```

### `AP_Registry_Desc` (lines 30–32)

```fortran
  TYPE :: AP_Registry_Desc
    INTEGER(i4) :: max_entries = AP_REG_MAX_ENTRIES
  END TYPE AP_Registry_Desc
```

### `AP_Registry_State` (lines 34–37)

```fortran
  TYPE :: AP_Registry_State
    TYPE(AP_RegEntry) :: entries(AP_REG_MAX_ENTRIES)
    INTEGER(i4)       :: n_entries = 0
  END TYPE AP_Registry_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
