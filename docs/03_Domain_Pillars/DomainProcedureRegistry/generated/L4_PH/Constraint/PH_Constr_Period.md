# `PH_Constr_Period.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Period.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Constr_Period`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Period`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr_Period`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Period.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_PeriodCore_BoundaryArgs` (lines 49–56)

```fortran
  TYPE :: PH_Constr_PeriodCore_BoundaryArgs
    REAL(wp), POINTER :: coords(:,:) => NULL()  !! (3, nNodes)
    INTEGER(i4) :: nNodes    = 0_i4  ! periodic BC node count
    INTEGER(i4) :: direction = 1_i4   !! 1=x, 2=y, 3=z
    TYPE(Period_BC_Params), POINTER :: params => NULL()  ! parameter / descriptor ptr
    INTEGER(i4), POINTER :: minus_nodes(:) => NULL()  !! ALLOCATABLE
    INTEGER(i4), POINTER :: plus_nodes(:)  => NULL()  !! ALLOCATABLE
  END TYPE PH_Constr_PeriodCore_BoundaryArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_PeriodCore_ComputeMacroStrain` | 64 | `SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStrain(params, element_strains, element_volumes, &` |
| SUBROUTINE | `PH_Constr_PeriodCore_ComputeMacroStress` | 97 | `SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStress(params, element_stresses, element_volumes, &` |
| SUBROUTINE | `PH_Constr_PeriodCore_IdentifyBoundaryNodes` | 127 | `SUBROUTINE PH_Constr_PeriodCore_IdentifyBoundaryNodes(coords, nNodes, params, direction, &` |
| SUBROUTINE | `PH_Constr_PeriodCore_ResizeNodePairsArray` | 174 | `SUBROUTINE PH_Constr_PeriodCore_ResizeNodePairsArray(node_pairs, new_size)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
