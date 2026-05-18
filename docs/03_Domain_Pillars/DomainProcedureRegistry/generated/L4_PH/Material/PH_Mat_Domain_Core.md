# `PH_Mat_Domain_Core.f90`

- **Source**: `L4_PH/Material/PH_Mat_Domain_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Domain_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Domain_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Domain`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Domain_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Desc` (lines 61–66)

```fortran
  TYPE, PUBLIC :: PH_Mat_Desc
    TYPE(PH_Mat_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Pop_Vld_Desc)  :: pop
    REAL(wp), ALLOCATABLE :: props(:) ! [Phase:Pop|Verb:Brg]
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Desc
```

### `PH_Mat_Ctx` (lines 71–75)

```fortran
  TYPE, PUBLIC :: PH_Mat_Ctx
    TYPE(PH_Mat_Inc_Evo_Ctx)  :: inc
    TYPE(PH_Mat_Lcl_Comp_Ctx) :: lcl
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Ctx
```

### `PH_Mat_State` (lines 80–84)

```fortran
  TYPE, PUBLIC :: PH_Mat_State
    TYPE(PH_Mat_Lcl_Comp_State) :: comp
    TYPE(PH_Mat_Lcl_Evo_State)  :: evo
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_State
```

### `PH_Mat_Eval_Arg` (lines 89–93)

```fortran
  TYPE, PUBLIC :: PH_Mat_Eval_Arg
    TYPE(PH_Mat_Lcl_Comp_ArgIn)  :: inp
    TYPE(PH_Mat_Lcl_Comp_ArgOut) :: out
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Eval_Arg
```

### `PH_Mat_Algo` (lines 111–115)

```fortran
  TYPE, PUBLIC :: PH_Mat_Algo
    TYPE(PH_Mat_Stp_Ctl_Algo) :: stp
    PROCEDURE(PH_Mat_Constitutive_Ifc), POINTER, NOPASS :: constitutive => NULL()
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Algo
```

### `PH_Mat_Slot` (lines 120–127)

```fortran
  TYPE, PUBLIC :: PH_Mat_Slot
    TYPE(PH_Mat_Desc)  :: desc
    TYPE(PH_Mat_Ctx)   :: ctx
    TYPE(PH_Mat_State)  :: state
    TYPE(PH_Mat_Algo)  :: algo
    TYPE(PH_Mat_Slot_PhaseIdx) :: phase   ! Phase tracking flags (semantic only)
    LOGICAL             :: active = .FALSE.
  END TYPE PH_Mat_Slot
```

### `PH_Mat_Init_Arg` (lines 132–136)

```fortran
  TYPE, PUBLIC :: PH_Mat_Init_Arg
    INTEGER(i4)           :: stepId     = 0_i4
    INTEGER(i4)           :: mat_pt_idx = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_Init_Arg
```

### `PH_Mat_GetCtx_Arg` (lines 141–144)

```fortran
  TYPE, PUBLIC :: PH_Mat_GetCtx_Arg
    TYPE(PH_Mat_Ctx)      :: ctx
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_GetCtx_Arg
```

### `PH_Mat_GetState_Arg` (lines 146–149)

```fortran
  TYPE, PUBLIC :: PH_Mat_GetState_Arg
    TYPE(PH_Mat_State)    :: state
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_GetState_Arg
```

### `PH_Mat_SetCtx_Arg` (lines 151–153)

```fortran
  TYPE, PUBLIC :: PH_Mat_SetCtx_Arg
    TYPE(PH_Mat_Ctx) :: ctx
  END TYPE PH_Mat_SetCtx_Arg
```

### `PH_Mat_SetState_Arg` (lines 155–157)

```fortran
  TYPE, PUBLIC :: PH_Mat_SetState_Arg
    TYPE(PH_Mat_State) :: state
  END TYPE PH_Mat_SetState_Arg
```

### `PH_Mat_Domain` (lines 162–171)

```fortran
  TYPE, PUBLIC :: PH_Mat_Domain
    TYPE(PH_Mat_Slot), ALLOCATABLE :: slot_pool(:)
    INTEGER(i4) :: pool_count = 0_i4
    INTEGER(i4) :: step_idx   = 0_i4
    INTEGER(i4) :: incr_idx   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => PH_Mat_Domain_Init
    PROCEDURE :: Finalize => PH_Mat_Domain_Finalize
  END TYPE PH_Mat_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Constitutive_Ifc` | 99 | `SUBROUTINE PH_Mat_Constitutive_Ifc(desc, state, arg, status)` |
| SUBROUTINE | `PH_Mat_Domain_Init` | 175 | `SUBROUTINE PH_Mat_Domain_Init(this, stepId, status)` |
| SUBROUTINE | `PH_Mat_Domain_Finalize` | 189 | `SUBROUTINE PH_Mat_Domain_Finalize(this)` |
| SUBROUTINE | `PH_Mat_Clear_Slot` | 204 | `SUBROUTINE PH_Mat_Clear_Slot(slot)` |
| SUBROUTINE | `PH_Mat_State_DualWrite_Stress6` | 218 | `SUBROUTINE PH_Mat_State_DualWrite_Stress6(st, s6)` |
| SUBROUTINE | `PH_Mat_State_DualWrite_Ctan66` | 226 | `SUBROUTINE PH_Mat_State_DualWrite_Ctan66(st, d66)` |
| SUBROUTINE | `PH_Mat_State_DualWrite_StateVars` | 235 | `SUBROUTINE PH_Mat_State_DualWrite_StateVars(st, nsdv, sdv_pack)` |
| SUBROUTINE | `PH_Mat_AllocSlot_Idx` | 252 | `SUBROUTINE PH_Mat_AllocSlot_Idx(dom, mat_pt_idx, status)` |
| SUBROUTINE | `PH_Mat_Apply_Init_Arg` | 275 | `SUBROUTINE PH_Mat_Apply_Init_Arg(dom, arg)` |
| SUBROUTINE | `PH_Mat_GetCtx_Idx` | 288 | `SUBROUTINE PH_Mat_GetCtx_Idx(dom, mat_pt_idx, arg)` |
| SUBROUTINE | `PH_Mat_GetState_Idx` | 308 | `SUBROUTINE PH_Mat_GetState_Idx(dom, mat_pt_idx, arg)` |
| SUBROUTINE | `PH_Mat_SetCtx_Idx` | 328 | `SUBROUTINE PH_Mat_SetCtx_Idx(dom, mat_pt_idx, arg)` |
| SUBROUTINE | `PH_Mat_SetState_Idx` | 338 | `SUBROUTINE PH_Mat_SetState_Idx(dom, mat_pt_idx, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
