# `PH_Elem_Contm.f90`

- **Source**: `L4_PH/Element/PH_Elem_Contm.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Contm`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Contm`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Contm`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Contm.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Contm_Args` (lines 51–66)

```fortran
  TYPE :: PH_Contm_Args
    !-- Input: Element type and formulation
    TYPE(UF_ElemType)     :: elem_type                 ! Element type code
    TYPE(UF_ElemFormul)   :: formul                    ! Formulation parameters
    TYPE(UF_ElemCtx)      :: ctx                       ! Element context
    
    !-- Input: Material models
    CLASS(*), POINTER     :: mat_models(:) => NULL()   ! Material models array
    
    !-- Input/Output: Element state (unified)
    CLASS(*), POINTER     :: state => NULL()           ! Element state (in/out unified)
    
    !-- Output: Flags
    CLASS(*), POINTER     :: flags => NULL()           ! Output flags
    
  END TYPE PH_Contm_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Contm_Map_UF_Formul_to_Elem` | 71 | `SUBROUTINE PH_Contm_Map_UF_Formul_to_Elem(uf, ef)` |
| SUBROUTINE | `PH_Contm_Build_UFMM_from_MatProps` | 87 | `SUBROUTINE PH_Contm_Build_UFMM_from_MatProps(mp, ufmm)` |
| SUBROUTINE | `PH_Contm_Assign_Flags_out` | 104 | `SUBROUTINE PH_Contm_Assign_Flags_out(fl, flags)` |
| SUBROUTINE | `Calc_Continuum2D` | 118 | `SUBROUTINE Calc_Continuum2D(args, status)` |
| SUBROUTINE | `Calc_Continuum3D` | 158 | `SUBROUTINE Calc_Continuum3D(args, status)` |
| SUBROUTINE | `CompPoro` | 198 | `SUBROUTINE CompPoro(args, status)` |
| SUBROUTINE | `CompThm` | 244 | `SUBROUTINE CompThm(args, status)` |
| SUBROUTINE | `CompTHM` | 290 | `SUBROUTINE CompTHM(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
