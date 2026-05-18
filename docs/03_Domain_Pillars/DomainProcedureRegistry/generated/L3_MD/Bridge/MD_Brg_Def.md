# `MD_Brg_Def.f90`

- **Source**: `L3_MD/Bridge/MD_Brg_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Brg_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Brg_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Brg`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/MD_Brg_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Brg_Desc` (lines 14–22)

```fortran
  TYPE, PUBLIC :: MD_Brg_Desc
    INTEGER(i4) :: bridge_id = 0             ! Unique bridge identifier
    INTEGER(i4) :: source_layer = 3          ! Source layer ID (3, 4, or 5)
    INTEGER(i4) :: target_layer = 4          ! Target layer ID (3, 4, or 5)
    LOGICAL :: is_active = .FALSE.           ! Whether this bridge is active
  CONTAINS
    PROCEDURE :: Init       => MD_Brg_Desc_Init
    PROCEDURE :: Valid      => MD_Brg_Desc_Valid
  END TYPE MD_Brg_Desc
```

### `MD_Brg_State` (lines 27–33)

```fortran
  TYPE, PUBLIC :: MD_Brg_State
    LOGICAL :: data_ready = .FALSE.          ! Data available for transfer
    INTEGER(i4) :: transfer_count = 0        ! Number of transfers completed
    REAL(wp) :: last_transfer_time = 0.0_wp  ! Timestamp of last transfer
  CONTAINS
    PROCEDURE :: Init       => MD_Brg_State_Init
  END TYPE MD_Brg_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Brg_Desc_Init` | 39 | `SUBROUTINE MD_Brg_Desc_Init(this, status)` |
| SUBROUTINE | `MD_Brg_Desc_Valid` | 49 | `SUBROUTINE MD_Brg_Desc_Valid(this, status)` |
| SUBROUTINE | `MD_Brg_State_Init` | 59 | `SUBROUTINE MD_Brg_State_Init(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
