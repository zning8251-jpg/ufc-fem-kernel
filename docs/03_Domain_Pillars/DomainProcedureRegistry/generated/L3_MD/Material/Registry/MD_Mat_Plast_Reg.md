# `MD_Mat_Plast_Reg.f90`

- **Source**: `L3_MD/Material/Registry/MD_Mat_Plast_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Reg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Material/Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Registry/MD_Mat_Plast_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PlastModels_Desc` (lines 31–34)

```fortran
  TYPE, PUBLIC :: PlastModels_Desc
    INTEGER(i4) :: nprops = 0_i4
    REAL(wp)    :: props(MD_MAT_PLAST_MAX_PROPS) = 0.0_wp
  END TYPE PlastModels_Desc
```

### `PlastMatInfo` (lines 38–47)

```fortran
  TYPE, PUBLIC :: PlastMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE PlastMatInfo
```

### `PlastMat_GetInfo_In` (lines 49–51)

```fortran
  TYPE, PUBLIC :: PlastMat_GetInfo_In
    INTEGER(i4) :: material_id = 0
  END TYPE PlastMat_GetInfo_In
```

### `PlastMat_GetInfo_Out` (lines 53–56)

```fortran
  TYPE, PUBLIC :: PlastMat_GetInfo_Out
    TYPE(PlastMatInfo) :: info
    TYPE(ErrorStatusType) :: status
  END TYPE PlastMat_GetInfo_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Plastic_GetMaterialInfo` | 112 | `SUBROUTINE UF_Plastic_GetMaterialInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Plastic_InitReg` | 144 | `SUBROUTINE UF_Plastic_InitReg(status)` |
| SUBROUTINE | `UF_Plastic_RegBuiltInMats` | 184 | `SUBROUTINE UF_Plastic_RegBuiltInMats(status)` |
| SUBROUTINE | `UF_Plastic_RegisterMaterial` | 279 | `SUBROUTINE UF_Plastic_RegisterMaterial(material_id, name, category, &` |
| SUBROUTINE | `UF_Plastic_RegMat_Int` | 296 | `SUBROUTINE UF_Plastic_RegMat_Int(material_id, name, category, &` |
| SUBROUTINE | `UF_Plastic_ValidMatID` | 349 | `SUBROUTINE UF_Plastic_ValidMatID(material_id, status)` |
| SUBROUTINE | `UF_Plastic_RegAllMats` | 370 | `SUBROUTINE UF_Plastic_RegAllMats(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
