# `MD_LBCPH_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L4/MD_LBCPH_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LBCPH_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBCPH_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBCPH`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L4`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L4/MD_LBCPH_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_LoadBC_StepBCsOut_Type` (lines 73–76)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_StepBCsOut_Type
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: ph_bc_cache(:)        ! PH BC
  END TYPE MD_LoadBC_StepBCsOut_Type
```

### `MD_LoadBC_StepLoadsOut_Type` (lines 83–86)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_StepLoadsOut_Type
    INTEGER(i4) :: nLoads = 0_i4
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: ph_load_cache(:)    ! PH Load
  END TYPE MD_LoadBC_StepLoadsOut_Type
```

### `MD_LoadBC_BuildStepBCs_Ctx_Type` (lines 93–98)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_BuildStepBCs_Ctx_Type
    TYPE(MD_LoadBC_Ctrl_Type) :: md_loadbc_ctrl
    TYPE(MD_LoadBC_StepCtx_Type) :: step_ctx
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: ph_bc_cache(:)
  END TYPE MD_LoadBC_BuildStepBCs_Ctx_Type
```

### `MD_LoadBC_BuildStepLoads_Ctx_Type` (lines 105–110)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_BuildStepLoads_Ctx_Type
    TYPE(MD_LoadBC_Ctrl_Type) :: md_loadbc_ctrl
    TYPE(MD_LoadBC_StepCtx_Type) :: step_ctx
    INTEGER(i4) :: nLoads = 0_i4
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: ph_load_cache(:)
  END TYPE MD_LoadBC_BuildStepLoads_Ctx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `LoadBC_FromDesc` | 142 | `SUBROUTINE LoadBC_FromDesc(desc_loadbc, md_loadbc, status)` |
| SUBROUTINE | `BC_FromDesc` | 165 | `SUBROUTINE BC_FromDesc(desc_bc, md_bc, status)` |
| SUBROUTINE | `Load_FromDesc` | 186 | `SUBROUTINE Load_FromDesc(desc_cload, md_load, status)` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepBCs` | 216 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs(ctx)` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepLoads` | 261 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads(ctx)` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepBCs_FromDomain` | 312 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_FromDomain(md_layer, step_idx, current_time, &` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepLoads_FromDomain` | 353 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_FromDomain(md_layer, step_idx, current_time, &` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepBCs_Idx` | 400 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_Idx(step_idx, current_time, &` |
| SUBROUTINE | `MD_LoadBC_PH_Brg_BuildStepLoads_Idx` | 443 | `SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_Idx(step_idx, current_time, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
