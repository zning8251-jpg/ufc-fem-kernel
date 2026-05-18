# `PH_Brg_L3.f90`

- **Source**: `L4_PH/Bridge/PH_Brg_L3.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Brg_L3`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Brg_L3`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Brg_L3`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/PH_Brg_L3.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_BrgL3_ElemStateUpdate_Desc` (lines 40–44)

```fortran
  TYPE, PUBLIC :: PH_BrgL3_ElemStateUpdate_Desc
    INTEGER(i4) :: elem_id = 0
    REAL(wp), ALLOCATABLE :: stress(:,:)
    REAL(wp), ALLOCATABLE :: strain(:,:)
  END TYPE PH_BrgL3_ElemStateUpdate_Desc
```

### `PH_BrgL3_MatId_Desc` (lines 46–48)

```fortran
  TYPE, PUBLIC :: PH_BrgL3_MatId_Desc
    INTEGER(i4) :: mat_id = 0
  END TYPE PH_BrgL3_MatId_Desc
```

### `PH_Brg_Elem_StiffAsm_Arg` (lines 50–54)

```fortran
  TYPE, PUBLIC :: PH_Brg_Elem_StiffAsm_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx                   ! [IN]
    INTEGER(i4) :: elem_idx = 0_i4                ! [IN]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_Elem_StiffAsm_Arg
```

### `PH_Brg_UpdateElemState_Arg` (lines 56–62)

```fortran
  TYPE, PUBLIC :: PH_Brg_UpdateElemState_Arg
    TYPE(MD_Model_Desc) :: model                            ! [IN]
    INTEGER(i4) :: elem_id                          ! [IN]
    REAL(wp), ALLOCATABLE :: stress(:,:)           ! [IN]
    REAL(wp), ALLOCATABLE :: strain(:,:)           ! [IN]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_UpdateElemState_Arg
```

### `PH_Brg_GetMatResp_Arg` (lines 64–70)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetMatResp_Arg
    TYPE(MD_Model_Desc) :: model                            ! [IN]
    INTEGER(i4) :: mat_id                           ! [IN]
    REAL(wp), ALLOCATABLE :: response(:)           ! [OUT]
    INTEGER(i4) :: n_props_filled = 0_i4           ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetMatResp_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Brg_ElementStiffAssembly` | 74 | `SUBROUTINE PH_Brg_ElementStiffAssembly(arg)` |
| SUBROUTINE | `PH_Brg_GetMaterialResponse` | 83 | `SUBROUTINE PH_Brg_GetMaterialResponse(arg)` |
| SUBROUTINE | `PH_Brg_UpdateElementState` | 119 | `SUBROUTINE PH_Brg_UpdateElementState(arg)` |
| SUBROUTINE | `PH_Brg_GetMaterialResponse_Idx` | 125 | `SUBROUTINE PH_Brg_GetMaterialResponse_Idx(mat_idx, arg, status)` |
| SUBROUTINE | `PH_Brg_UpdateElementState_Idx` | 173 | `SUBROUTINE PH_Brg_UpdateElementState_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `PH_Brg_GetAmplitudeValue_Idx` | 189 | `SUBROUTINE PH_Brg_GetAmplitudeValue_Idx(amp_ref, time, value, status)` |
| SUBROUTINE | `PH_Brg_GetNodeCoords_Idx` | 207 | `SUBROUTINE PH_Brg_GetNodeCoords_Idx(node_idx, coords, status)` |
| SUBROUTINE | `PH_Brg_ElementStiffAssembly_Idx` | 218 | `SUBROUTINE PH_Brg_ElementStiffAssembly_Idx(elem_idx, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
