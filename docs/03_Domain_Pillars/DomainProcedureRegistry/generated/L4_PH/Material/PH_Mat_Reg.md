# `PH_Mat_Reg.f90`

- **Source**: `L4_PH/Material/PH_Mat_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Reg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Kernel_Entry` (lines 74–77)

```fortran
  TYPE, PUBLIC :: PH_Mat_Kernel_Entry
    INTEGER(i4) :: family_marker = 0_i4
    INTEGER(i4) :: default_mat_id = 0_i4
  END TYPE PH_Mat_Kernel_Entry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Init_AllKernels` | 109 | `SUBROUTINE PH_Mat_Init_AllKernels()` |
| SUBROUTINE | `PH_Mat_GetKernel` | 117 | `SUBROUTINE PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)` |
| SUBROUTINE | `PH_Kern_Build_D_iso6` | 143 | `PURE SUBROUTINE PH_Kern_Build_D_iso6(E, nu, D)` |
| SUBROUTINE | `PH_Kern_ElasIso_update` | 159 | `SUBROUTINE PH_Kern_ElasIso_update(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_ElasIso_ctm` | 181 | `SUBROUTINE PH_Kern_ElasIso_ctm(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_ElasIso_init_sdv` | 197 | `SUBROUTINE PH_Kern_ElasIso_init_sdv(this, sdv, nsdv, istat)` |
| SUBROUTINE | `PH_Kern_PlJ2_update` | 206 | `SUBROUTINE PH_Kern_PlJ2_update(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_PlJ2_ctm` | 275 | `SUBROUTINE PH_Kern_PlJ2_ctm(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_PlJ2_init_sdv` | 288 | `SUBROUTINE PH_Kern_PlJ2_init_sdv(this, sdv, nsdv, istat)` |
| SUBROUTINE | `PH_Kern_GenIso_update` | 297 | `SUBROUTINE PH_Kern_GenIso_update(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_GenIso_ctm` | 309 | `SUBROUTINE PH_Kern_GenIso_ctm(this, uarg, istat)` |
| SUBROUTINE | `PH_Kern_GenIso_init_sdv` | 316 | `SUBROUTINE PH_Kern_GenIso_init_sdv(this, sdv, nsdv, istat)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
