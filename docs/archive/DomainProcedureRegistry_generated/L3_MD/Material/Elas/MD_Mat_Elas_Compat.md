# `MD_Mat_Elas_Compat.f90`

- **Source**: `L3_MD/Material/Elas/MD_Mat_Elas_Compat.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Compat`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Compat`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas_Compat`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Elas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Elas/MD_Mat_Elas_Compat.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Iso_Desc_Compat` (lines 48–56)

```fortran
  TYPE, PUBLIC :: MD_Mat_Iso_Desc_Compat
    TYPE(MD_Mat_Elas_Desc) :: new_desc  ! Internal: new architecture descriptor
    REAL(wp) :: E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: rho = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
  END TYPE MD_Mat_Iso_Desc_Compat
```

### `IsoElastic_MatDesc_Compat` (lines 59–67)

```fortran
  TYPE, PUBLIC :: IsoElastic_MatDesc_Compat
    TYPE(MD_Mat_Elas_Desc) :: new_desc
    REAL(wp) :: E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  END TYPE IsoElastic_MatDesc_Compat
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Ela_Iso_InitFromProps_Compat` | 87 | `SUBROUTINE MD_Ela_Iso_InitFromProps_Compat(compat_desc, nprops, props, status)` |
| SUBROUTINE | `UF_IsoElas_L3_InitFromProps_Compat` | 124 | `SUBROUTINE UF_IsoElas_L3_InitFromProps_Compat(compat_desc, nprops, props, status)` |
| SUBROUTINE | `MD_Ela_Iso_ValidateProps_Compat` | 161 | `SUBROUTINE MD_Ela_Iso_ValidateProps_Compat(nprops, props, status)` |
| SUBROUTINE | `UF_IsoElas_L3_ValidateProps_Compat` | 194 | `SUBROUTINE UF_IsoElas_L3_ValidateProps_Compat(nprops, props, status)` |
| FUNCTION | `Get_New_Desc_From_Iso_Compat` | 206 | `FUNCTION Get_New_Desc_From_Iso_Compat(compat_desc) RESULT(new_desc)` |
| FUNCTION | `Get_New_Desc_From_IsoElastic_Compat` | 212 | `FUNCTION Get_New_Desc_From_IsoElastic_Compat(compat_desc) RESULT(new_desc)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
