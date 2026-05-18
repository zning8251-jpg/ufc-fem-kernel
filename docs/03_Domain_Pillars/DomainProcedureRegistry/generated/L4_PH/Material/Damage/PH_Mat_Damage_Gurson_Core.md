# `PH_Mat_Damage_Gurson_Core.f90`

- **Source**: `L4_PH/Material/Damage/PH_Mat_Damage_Gurson_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Damage_Gurson_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Damage_Gurson_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Damage_Gurson`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Damage`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Damage/PH_Mat_Damage_Gurson_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_GTN_UMAT_Args` (lines 40–49)

```fortran
  TYPE, PUBLIC :: PH_GTN_UMAT_Args
    LOGICAL     :: flag_nlgeom   = .FALSE.
    LOGICAL     :: flag_firstinc = .FALSE.
    INTEGER(i4) :: ip_index      = 0_i4
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: pnewdt       = 1.0_wp
    REAL(wp)              :: residual_norm = 0.0_wp
    INTEGER(i4)           :: iterations   = 0_i4
  END TYPE PH_GTN_UMAT_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_GTN_UMAT_API` | 53 | `SUBROUTINE PH_GTN_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &` |
| SUBROUTINE | `PH_GTN_UMAT_Impl` | 75 | `SUBROUTINE PH_GTN_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &` |
| SUBROUTINE | `GTN_Build_D_el` | 143 | `SUBROUTINE GTN_Build_D_el(desc, D)` |
| FUNCTION | `GTN_f_star` | 159 | `PURE FUNCTION GTN_f_star(f, f_c, f_N, q1, q2, q3, eps_p) RESULT(f_star)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
