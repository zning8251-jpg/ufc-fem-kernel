# `NM_L2_Layer.f90`

- **Source**: `L2_NM/NM_L2_Layer.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_L2_Layer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_L2_Layer`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_L2_Layer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/_root/NM_L2_Layer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_L2_LayerContainer` (lines 51–62)

```fortran
  TYPE, PUBLIC :: NM_L2_LayerContainer
    TYPE(NM_Base_Domain)    :: base
    TYPE(NM_LinAlg_Domain)  :: linAlg
    TYPE(NM_Solver_Domain)  :: solver
    TYPE(NM_Eigen_Domain)   :: eigen
    TYPE(NM_TimeInt_Domain) :: timeInt
    TYPE(NM_Bridge_Domain)  :: bridge
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => NM_L2_Init
    PROCEDURE :: Finalize => NM_L2_Finalize
  END TYPE NM_L2_LayerContainer
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_L2_Finalize` | 69 | `SUBROUTINE NM_L2_Finalize(this)` |
| SUBROUTINE | `NM_L2_Init` | 88 | `SUBROUTINE NM_L2_Init(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
