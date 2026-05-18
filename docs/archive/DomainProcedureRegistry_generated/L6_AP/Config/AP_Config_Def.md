# `AP_Config_Def.f90`

- **Source**: `L6_AP/Config/AP_Config_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Config_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Config_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Config`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Config`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Config/AP_Config_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_ConfigEntry` (lines 23–29)

```fortran
  TYPE :: AP_ConfigEntry
    CHARACTER(LEN=AP_CFG_KEY_LEN) :: key = ""
    INTEGER(i4)    :: int_val  = 0
    REAL(wp)       :: real_val = 0.0_wp
    CHARACTER(LEN=128) :: str_val = ""
    LOGICAL        :: valid = .FALSE.
  END TYPE AP_ConfigEntry
```

### `AP_Config_Desc` (lines 31–33)

```fortran
  TYPE :: AP_Config_Desc
    INTEGER(i4) :: max_entries = AP_CFG_MAX
  END TYPE AP_Config_Desc
```

### `AP_Config_State` (lines 35–38)

```fortran
  TYPE :: AP_Config_State
    TYPE(AP_ConfigEntry) :: entries(AP_CFG_MAX)
    INTEGER(i4)          :: n_entries = 0
  END TYPE AP_Config_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
