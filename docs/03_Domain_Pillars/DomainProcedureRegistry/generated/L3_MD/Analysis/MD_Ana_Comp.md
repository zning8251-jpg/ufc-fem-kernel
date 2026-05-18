# `MD_Ana_Comp.f90`

- **Source**: `L3_MD/Analysis/MD_Ana_Comp.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Ana_Comp`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Ana_Comp`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Ana_Comp`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Analysis`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/MD_Ana_Comp.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Ana_Comp_Cfg_Proc_Desc` (lines 104–108)

```fortran
  TYPE, PUBLIC :: MD_Ana_Comp_Cfg_Proc_Desc
    INTEGER(i4) :: proc_id    = 0_i4
    LOGICAL     :: needs_aux  = .FALSE.
    INTEGER(i4) :: aux_solver = 0_i4
  END TYPE MD_Ana_Comp_Cfg_Proc_Desc
```

### `MD_Ana_Comp_Stp_Triple_Desc` (lines 115–119)

```fortran
  TYPE, PUBLIC :: MD_Ana_Comp_Stp_Triple_Desc
    INTEGER(i4) :: solver   = 0_i4   ! RT_SOLVER_* (1-8)
    INTEGER(i4) :: coupling = 0_i4   ! AC_CPL_* (1-4)
    INTEGER(i4) :: physics  = 0_i4   ! AC_PHYS_* (1-12)
  END TYPE MD_Ana_Comp_Stp_Triple_Desc
```

### `MD_Ana_Comp_Pop_Group_Desc` (lines 126–128)

```fortran
  TYPE, PUBLIC :: MD_Ana_Comp_Pop_Group_Desc
    INTEGER(i4) :: group = 0_i4      ! AC_GROUP_* (1-9, G1-G9)
  END TYPE MD_Ana_Comp_Pop_Group_Desc
```

### `MD_Ana_Comp_Group_Desc` (lines 136–140)

```fortran
  TYPE, PUBLIC :: MD_Ana_Comp_Group_Desc
    TYPE(MD_Ana_Comp_Cfg_Proc_Desc)  :: cfg
    TYPE(MD_Ana_Comp_Stp_Triple_Desc) :: stp
    TYPE(MD_Ana_Comp_Pop_Group_Desc)  :: pop
  END TYPE MD_Ana_Comp_Group_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Ana_Comp_Init` | 227 | `SUBROUTINE MD_Ana_Comp_Init()` |
| SUBROUTINE | `MD_Ana_Comp_CheckTriple` | 292 | `SUBROUTINE MD_Ana_Comp_CheckTriple(solver, coupling, physics, status)` |
| FUNCTION | `MD_Ana_Comp_CheckGroupMat` | 320 | `PURE FUNCTION MD_Ana_Comp_CheckGroupMat(group, mat_fam) RESULT(ok)` |
| FUNCTION | `MD_Ana_Comp_CheckGroupElem` | 333 | `PURE FUNCTION MD_Ana_Comp_CheckGroupElem(group, elem_cat) RESULT(ok)` |
| FUNCTION | `MD_Ana_Comp_PhysToGroup` | 346 | `PURE FUNCTION MD_Ana_Comp_PhysToGroup(solver, coupling, physics) RESULT(group)` |
| SUBROUTINE | `MD_Ana_Comp_ProcToGroup` | 385 | `SUBROUTINE MD_Ana_Comp_ProcToGroup(proc_id, desc)` |
| SUBROUTINE | `MD_Ana_Comp_ValidateStep` | 519 | `SUBROUTINE MD_Ana_Comp_ValidateStep(proc_id, compat_status, &` |
| SUBROUTINE | `MD_Ana_Comp_ValidateGroupMat` | 553 | `SUBROUTINE MD_Ana_Comp_ValidateGroupMat(proc_id, mat_fam, is_ok, status)` |
| SUBROUTINE | `MD_Ana_Comp_ValidateGroupElem` | 582 | `SUBROUTINE MD_Ana_Comp_ValidateGroupElem(proc_id, elem_cat, is_ok, status)` |
| SUBROUTINE | `MD_Ana_Comp_FullCheck` | 611 | `SUBROUTINE MD_Ana_Comp_FullCheck(proc_id, mat_fam, elem_cat, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
