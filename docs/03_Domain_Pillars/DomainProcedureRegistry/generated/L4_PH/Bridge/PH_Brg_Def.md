# `PH_Brg_Def.f90`

- **Source**: `L4_PH/Bridge/PH_Brg_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Brg_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Brg_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Brg`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/PH_Brg_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Brg_ElemStateUpdate_Desc` (lines 28–32)

```fortran
  TYPE, PUBLIC :: PH_Brg_ElemStateUpdate_Desc
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), ALLOCATABLE :: stress(:,:)  ! (ncomp, nip)
    REAL(wp), ALLOCATABLE :: strain(:,:)  ! (ncomp, nip)
  END TYPE PH_Brg_ElemStateUpdate_Desc
```

### `PH_Brg_MatId_Desc` (lines 35–37)

```fortran
  TYPE, PUBLIC :: PH_Brg_MatId_Desc
    INTEGER(i4) :: mat_id = 0_i4
  END TYPE PH_Brg_MatId_Desc
```

### `PH_Brg_ElemId_Desc` (lines 40–43)

```fortran
  TYPE, PUBLIC :: PH_Brg_ElemId_Desc
    INTEGER(i4) :: elem_id = 0_i4
    INTEGER(i4) :: elem_type = 0_i4
  END TYPE PH_Brg_ElemId_Desc
```

### `PH_Brg_WriteBack_Desc` (lines 46–50)

```fortran
  TYPE, PUBLIC :: PH_Brg_WriteBack_Desc
    INTEGER(i4) :: wb_id = 0_i4
    CHARACTER(LEN=64) :: target_label = ''
    LOGICAL :: active = .TRUE.
  END TYPE PH_Brg_WriteBack_Desc
```

### `PH_Brg_State` (lines 58–64)

```fortran
  TYPE, PUBLIC :: PH_Brg_State
    INTEGER(i4) :: totalCalls     = 0_i4   ! 累计调用次数
    INTEGER(i4) :: failedCalls    = 0_i4   ! 失败调用次数
    INTEGER(i4) :: lastErrorCode  = 0_i4   ! 最近错误码
    REAL(wp)    :: totalBridgeTime  = 0.0_wp  ! 累计桥接耗时 [s]
    REAL(wp)    :: gpuTransferTime  = 0.0_wp  ! GPU传输耗时 [s]
  END TYPE PH_Brg_State
```

### `PH_Brg_WriteBack_State` (lines 67–71)

```fortran
  TYPE, PUBLIC :: PH_Brg_WriteBack_State
    INTEGER(i4) :: total_writes = 0_i4
    INTEGER(i4) :: failed_writes = 0_i4
    LOGICAL     :: last_write_ok = .TRUE.
  END TYPE PH_Brg_WriteBack_State
```

### `PH_Brg_Output_State` (lines 74–78)

```fortran
  TYPE, PUBLIC :: PH_Brg_Output_State
    INTEGER(i4) :: total_outputs = 0_i4
    INTEGER(i4) :: last_output_step = 0_i4
    LOGICAL     :: output_active = .FALSE.
  END TYPE PH_Brg_Output_State
```

### `PH_Brg_Params` (lines 86–93)

```fortran
  TYPE, PUBLIC :: PH_Brg_Params
    LOGICAL     :: enableUEL      = .FALSE.  ! 启用UEL桥接
    LOGICAL     :: enableUMAT     = .FALSE.  ! 启用UMAT桥接
    LOGICAL     :: enableGPU      = .FALSE.  ! 启用GPU加速
    LOGICAL     :: enableExternal = .FALSE.  ! 启用外部库桥接
    INTEGER(i4) :: gpuDeviceId    = 0_i4     ! GPU设备ID
    LOGICAL     :: gpuAsyncTransfer = .FALSE. ! GPU异步传输
  END TYPE PH_Brg_Params
```

### `PH_Brg_Inc_Evo_Ctx` (lines 106–109)

```fortran
  TYPE, PUBLIC :: PH_Brg_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Brg_Inc_Evo_Ctx
```

### `PH_Brg_Ctx` (lines 113–122)

```fortran
  TYPE, PUBLIC :: PH_Brg_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Brg_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx        = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx        = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: nRegisteredLibs = 0_i4   ! 已注册外部库数
    INTEGER(i4) :: nUEL            = 0_i4   ! UEL元素数
    INTEGER(i4) :: nUMAT           = 0_i4   ! UMAT材料数
  END TYPE PH_Brg_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
