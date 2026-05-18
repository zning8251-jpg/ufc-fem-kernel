# `MD_Constr_Prop.f90`

- **Source**: `L3_MD/Constraint/MD_Constr_Prop.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Constr_Prop`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Constr_Prop`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Constr_Prop`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Constraint/MD_Constr_Prop.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_ContactPropertyDef` (lines 36–45)

```fortran
    TYPE :: UF_ContactPropertyDef
        CHARACTER(LEN=MAX_CONTACT_NAME) :: name = ""
        INTEGER(i4) :: id = 0
        REAL(wp)    :: mu_s = 0.0_wp        ! Static friction coefficient
        REAL(wp)    :: mu_k = 0.0_wp        ! Kinetic friction coefficient
        REAL(wp)    :: penalty_scale = 10.0_wp ! Penalty scaling factor
        REAL(wp)    :: penalty_n = 0.0_wp   ! F2.2: Normal penalty (0 => use scale*E/h)
        REAL(wp)    :: penalty_t = 0.0_wp   ! F2.2: Tangential penalty (0 => use ratio*penalty_n)
        REAL(wp)    :: adjust = 0.0_wp       ! Initial clearance adjustment
    END TYPE UF_ContactPropertyDef
```

### `UF_ContactPropertyDB` (lines 50–60)

```fortran
    TYPE :: UF_ContactPropertyDB
        INTEGER(i4) :: num_props = 0
        TYPE(UF_ContactPropertyDef), ALLOCATABLE :: props(:)
    CONTAINS
        PROCEDURE :: init          => cpdb_init
        PROCEDURE :: add_property  => cpdb_add_property
        PROCEDURE :: find_by_name  => cpdb_find_by_name
        PROCEDURE :: find_by_id    => cpdb_find_by_id
        PROCEDURE :: get_property  => cpdb_get_property
        PROCEDURE :: clear         => cpdb_clear
    END TYPE UF_ContactPropertyDB
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `cpdb_init` | 67 | `SUBROUTINE cpdb_init(this, capacity)` |
| SUBROUTINE | `cpdb_add_property` | 83 | `SUBROUTINE cpdb_add_property(this, prop)` |
| FUNCTION | `cpdb_get_property` | 134 | `FUNCTION cpdb_get_property(this, idx) RESULT(prop_ptr)` |
| SUBROUTINE | `cpdb_clear` | 149 | `SUBROUTINE cpdb_clear(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
