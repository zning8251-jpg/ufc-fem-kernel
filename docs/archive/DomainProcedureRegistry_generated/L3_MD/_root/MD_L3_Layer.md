# `MD_L3_Layer.f90`

- **Source**: `L3_MD/MD_L3_Layer.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_L3_Layer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_L3_Layer`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_L3_Layer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/_root/MD_L3_Layer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_L3_Material_Block` (lines 18–22)

```fortran
  TYPE, PUBLIC :: MD_L3_Material_Block
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_L3_Material_Init
    PROCEDURE, PUBLIC :: Register => MD_L3_Material_Register
  END TYPE MD_L3_Material_Block
```

### `MD_L3_LayerContainer` (lines 24–26)

```fortran
  TYPE, PUBLIC :: MD_L3_LayerContainer
    TYPE(MD_L3_Material_Block) :: material
  END TYPE MD_L3_LayerContainer
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_L3_Material_Init` | 32 | `SUBROUTINE MD_L3_Material_Init(this, status)` |
| SUBROUTINE | `MD_L3_Material_Register` | 41 | `SUBROUTINE MD_L3_Material_Register(this, mat_desc, mat_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
