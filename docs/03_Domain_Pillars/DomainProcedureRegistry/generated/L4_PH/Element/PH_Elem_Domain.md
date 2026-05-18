# `PH_Elem_Domain.f90`

- **Source**: `L4_PH/Element/PH_Elem_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Domain`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Domain_Desc` (lines 39–60)

```fortran
  TYPE :: PH_Elem_Domain_Desc
    TYPE(PH_Elem_Desc)  :: desc   ! [index 1] cold path read-only
    TYPE(PH_Elem_State) :: state  ! [index 2] hot path output
    TYPE(PH_Elem_Algo)  :: algo   ! [index 3] step-level config
    TYPE(PH_Elem_Ctx)   :: ctx    ! [index 4] hot path workspace
    INTEGER(i4) :: domain_id = 0
    INTEGER(i4) :: n_elements = 0
    LOGICAL     :: is_initialized = .FALSE.
    ! L3 mesh mirror for assembly / Populate (PH_L4_Populate_Element, RT_Asm_Solv)
    INTEGER(i4), ALLOCATABLE :: elem_to_mat_map(:)
    REAL(wp), ALLOCATABLE :: elem_coords_cache(:, :, :)
    INTEGER(i4), ALLOCATABLE :: elem_npe_cache(:)
    INTEGER(i4), ALLOCATABLE :: elem_ndim_cache(:)
    INTEGER(i4), ALLOCATABLE :: elem_type_cache(:)
    LOGICAL :: coords_cached = .FALSE.
  CONTAINS
    ! L4 layer / L5 assembly 金线（与 PH_Mat_Domain Init/Finalize 对称）
    PROCEDURE :: Init        => Desc_Init
    PROCEDURE :: Finalize    => Desc_Finalize
    PROCEDURE :: Compute_Ke  => Desc_Compute_Ke
    PROCEDURE :: Compute_Fe  => Desc_Compute_Fe
  END TYPE PH_Elem_Domain_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 68 | `SUBROUTINE Desc_Init(this, stepId, status)` |
| SUBROUTINE | `Desc_Finalize` | 82 | `SUBROUTINE Desc_Finalize(this)` |
| SUBROUTINE | `Desc_Compute_Ke` | 88 | `SUBROUTINE Desc_Compute_Ke(this, arg)` |
| SUBROUTINE | `Desc_Compute_Fe` | 184 | `SUBROUTINE Desc_Compute_Fe(this, arg)` |
| SUBROUTINE | `PH_Elem_Domain_Init` | 297 | `SUBROUTINE PH_Elem_Domain_Init(domain, elem_type_id, family_id, n_nodes, &` |
| SUBROUTINE | `PH_Elem_Domain_Populate` | 336 | `SUBROUTINE PH_Elem_Domain_Populate(domain, registry_entry, status)` |
| SUBROUTINE | `PH_Elem_Domain_Validate` | 367 | `SUBROUTINE PH_Elem_Domain_Validate(domain, status)` |
| SUBROUTINE | `PH_Elem_Domain_Finalize` | 400 | `SUBROUTINE PH_Elem_Domain_Finalize(domain, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
