# `MD_Mat_Registry.f90`

- **Source**: `L3_MD/Material/Registry/MD_Mat_Registry.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Registry`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Registry`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Registry`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Registry/MD_Mat_Registry.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Registry_Entry` (lines 32–38)

```fortran
  TYPE, PUBLIC :: MD_Mat_Registry_Entry
    INTEGER(i4) :: mat_id                    ! Material ID (unique)
    INTEGER(i4) :: family_type               ! Family type (ELASTIC/PLASTIC/etc.)
    INTEGER(i4) :: sub_type                  ! Sub-type within family
    CLASS(MD_Mat_Desc), POINTER :: desc      ! Polymorphic pointer to descriptor
    LOGICAL :: is_active                     ! Entry is active
  END TYPE MD_Mat_Registry_Entry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Registry_Init` | 65 | `SUBROUTINE MD_Mat_Registry_Init(status)` |
| SUBROUTINE | `MD_Mat_Registry_Finalize` | 96 | `SUBROUTINE MD_Mat_Registry_Finalize(status)` |
| SUBROUTINE | `MD_Mat_Registry_Register` | 129 | `SUBROUTINE MD_Mat_Registry_Register(mat_id, family_type, sub_type, &` |
| SUBROUTINE | `MD_Mat_Registry_Lookup` | 190 | `SUBROUTINE MD_Mat_Registry_Lookup(mat_id, slot, status)` |
| SUBROUTINE | `MD_Mat_Registry_Remove` | 229 | `SUBROUTINE MD_Mat_Registry_Remove(mat_id, status)` |
| SUBROUTINE | `MD_Mat_Registry_Get_Count` | 259 | `SUBROUTINE MD_Mat_Registry_Get_Count(count)` |
| SUBROUTINE | `MD_Mat_Registry_Access_Desc` | 269 | `SUBROUTINE MD_Mat_Registry_Access_Desc(mat_id, dptr, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
