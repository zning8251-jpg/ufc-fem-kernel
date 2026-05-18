# `MD_Model_VarCtx.f90`

- **Source**: `L3_MD/Model/MD_Model_VarCtx.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Model_VarCtx`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_VarCtx`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model_VarCtx`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_VarCtx.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Context_Model_State` (lines 32–42)

```fortran
    TYPE, PUBLIC :: Context_Model_State
        SEQUENCE
        INTEGER(i4) :: nStepsTotal = 0_i4
        INTEGER(i4) :: nStepsCompleted = 0_i4
        INTEGER(i4) :: nIncsTotal = 0_i4
        INTEGER(i4) :: nIncsConverged = 0_i4
        INTEGER(i4) :: totalNewtonIter = 0_i4
        INTEGER(i4) :: maxNewtonIter = 0_i4
        INTEGER(i4) :: totalLinearIter = 0_i4
        INTEGER(i4) :: maxLinearIter = 0_i4
    END TYPE Context_Model_State
```

### `Context_Model` (lines 47–55)

```fortran
    TYPE, PUBLIC :: Context_Model
        SEQUENCE
        INTEGER(i4) :: model_id = 0_i4
        INTEGER(i4) :: step_id = 0_i4
        INTEGER(i4) :: inc_id = 0_i4
        TYPE(Context_Model_State) :: state
    CONTAINS
        PROCEDURE :: EnsureStorage => Context_Model_EnsureStorage
    END TYPE Context_Model
```

### `UF_ModelVarContext` (lines 60–62)

```fortran
    TYPE, PUBLIC :: UF_ModelVarContext
        TYPE(VarCtx) :: ctx
    END TYPE UF_ModelVarContext
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Context_Model_EnsureStorage` | 70 | `SUBROUTINE Context_Model_EnsureStorage(this, status)` |
| SUBROUTINE | `GetCurrentContext` | 76 | `SUBROUTINE GetCurrentContext(ctx, has_ctx)` |
| SUBROUTINE | `GetReal1D` | 83 | `SUBROUTINE GetReal1D(ctx, name, ptr, status)` |
| SUBROUTINE | `MV_GetContextOrUseCurrent` | 100 | `SUBROUTINE MV_GetContextOrUseCurrent(ctx_out, has_ctx, override)` |
| SUBROUTINE | `MV_GetCurrentContext` | 113 | `SUBROUTINE MV_GetCurrentContext(ctx, has_ctx)` |
| SUBROUTINE | `MV_GetReal1D` | 120 | `SUBROUTINE MV_GetReal1D(ctx, name, ptr, status)` |
| SUBROUTINE | `UF_ModelVar_ClearCurrentContext` | 128 | `SUBROUTINE UF_ModelVar_ClearCurrentContext()` |
| SUBROUTINE | `UF_ModelVarContext_RegisterScalar` | 132 | `SUBROUTINE UF_ModelVarContext_RegisterScalar(ctx, name, default_val, ierr)` |
| SUBROUTINE | `UF_ModelVar_InitContext` | 143 | `SUBROUTINE UF_ModelVar_InitContext(ctx, model_name, max_vars)` |
| SUBROUTINE | `UF_ModelVar_RegisterField` | 150 | `SUBROUTINE UF_ModelVar_RegisterField(ctx, name, location, dType, rank, dims, is_persistent, ierr)` |
| SUBROUTINE | `UF_ModelVar_SetCurrentContext` | 166 | `SUBROUTINE UF_ModelVar_SetCurrentContext(ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
