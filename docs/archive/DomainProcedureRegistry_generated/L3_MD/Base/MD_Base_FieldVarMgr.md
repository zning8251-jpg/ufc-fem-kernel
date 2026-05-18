# `MD_Base_FieldVarMgr.f90`

- **Source**: `L3_MD/Base/MD_Base_FieldVarMgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Base_FieldVarMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_FieldVarMgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_FieldVarMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_FieldVarMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `InitVars` | 137 | `SUBROUTINE InitVars(mName, ctx, maxVars)` |
| SUBROUTINE | `DestroyVars` | 185 | `SUBROUTINE DestroyVars(ctx)` |
| SUBROUTINE | `RegField` | 220 | `SUBROUTINE RegField(ctx, name, location, dType, rank, dims, is_history, is_persistent)` |
| FUNCTION | `FindField` | 336 | `FUNCTION FindField(ctx, name) RESULT(idx)` |
| SUBROUTINE | `GetFieldId` | 352 | `SUBROUTINE GetFieldId(ctx, name, varName)` |
| SUBROUTINE | `EnsureFields` | 366 | `SUBROUTINE EnsureFields(ctx)` |
| SUBROUTINE | `GetR1D` | 386 | `SUBROUTINE GetR1D(ctx, name, arr)` |
| SUBROUTINE | `GetR2D` | 424 | `SUBROUTINE GetR2D(ctx, name, arr)` |
| SUBROUTINE | `GetI1D` | 462 | `SUBROUTINE GetI1D(ctx, name, arr)` |
| SUBROUTINE | `GetI2D` | 500 | `SUBROUTINE GetI2D(ctx, name, arr)` |
| SUBROUTINE | `GetL1D` | 538 | `SUBROUTINE GetL1D(ctx, name, arr)` |
| SUBROUTINE | `ViewR1D` | 576 | `SUBROUTINE ViewR1D(ctx, name, view)` |
| SUBROUTINE | `ViewR2D` | 613 | `SUBROUTINE ViewR2D(ctx, name, view)` |
| SUBROUTINE | `ViewI1D` | 651 | `SUBROUTINE ViewI1D(ctx, name, view)` |
| SUBROUTINE | `ViewI2D` | 688 | `SUBROUTINE ViewI2D(ctx, name, view)` |
| SUBROUTINE | `RegViewR1D` | 730 | `SUBROUTINE RegViewR1D(ctx, name, location, dim1, view, is_history)` |
| SUBROUTINE | `RegViewI1D` | 745 | `SUBROUTINE RegViewI1D(ctx, name, location, dim1, view, is_history)` |
| SUBROUTINE | `RegViewR2D` | 760 | `SUBROUTINE RegViewR2D(ctx, name, location, dim1, dim2, view, is_history)` |
| SUBROUTINE | `RegViewI2D` | 776 | `SUBROUTINE RegViewI2D(ctx, name, location, dim1, dim2, view, is_history)` |
| SUBROUTINE | `Core_Init` | 796 | `SUBROUTINE Core_Init()` |
| SUBROUTINE | `Core_Free` | 816 | `SUBROUTINE Core_Free()` |
| FUNCTION | `Core_HasErr` | 829 | `FUNCTION Core_HasErr() RESULT(res)` |
| SUBROUTINE | `Dof_Ensure` | 834 | `SUBROUTINE Dof_Ensure(dof_system)` |
| SUBROUTINE | `Dof_Build` | 855 | `SUBROUTINE Dof_Build(dof_system)` |
| SUBROUTINE | `Model_Init` | 880 | `SUBROUTINE Model_Init(model_system)` |
| SUBROUTINE | `Model_BuildDof` | 897 | `SUBROUTINE Model_BuildDof(model_system)` |
| SUBROUTINE | `Model_SetupUIF` | 917 | `SUBROUTINE Model_SetupUIF(model_system)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 572–574 | `INTERFACE GetVar` |
| 726–728 | `INTERFACE ViewVar` |
| 792–794 | `INTERFACE RegViewVar` |
