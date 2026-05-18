# `RT_Sect_Aux_Def.f90`

- **Source**: `L5_RT/Section/RT_Sect_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Sect_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Sect_Aux_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Sect_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Section/RT_Sect_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Sect_Stp_Ctl_Algo` (lines 44–63)

```fortran
  TYPE, PUBLIC :: RT_Sect_Stp_Ctl_Algo
    ! --- M-S-E compatibility check ---
    INTEGER(i4) :: compat_check_mode = RT_SECT_COMPAT_STRICT
    LOGICAL     :: validate_on_populate = .TRUE.    ! Validate during L3→L5 Populate

    ! --- Integration rule resolution ---
    INTEGER(i4) :: integration_rule_override = RT_SECT_IRULE_USE_L3
    LOGICAL     :: allow_integration_conflict = .FALSE.  ! Allow L3↔Element mismatch

    ! --- Material association ---
    LOGICAL     :: allow_missing_material = .FALSE.  ! Allow sections without material

    ! --- Section query ---
    INTEGER(i4) :: missing_section_policy = RT_SECT_MISSING_ERROR
    LOGICAL     :: section_cache_enabled  = .TRUE.  ! Cache section lookups at L5

    ! --- Override ---
    LOGICAL     :: force_repopulate = .FALSE.  ! Force repopulate even if already populated
    LOGICAL     :: suppress_compat_check = .FALSE.  ! Suppress all compat checks (debug)
  END TYPE RT_Sect_Stp_Ctl_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
