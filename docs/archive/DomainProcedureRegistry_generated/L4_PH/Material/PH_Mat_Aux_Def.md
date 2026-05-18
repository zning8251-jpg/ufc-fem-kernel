# `PH_Mat_Aux_Def.f90`

- **Source**: `L4_PH/Material/PH_Mat_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Aux_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Cfg_Init_Desc` (lines 24–27)

```fortran
  TYPE, PUBLIC :: PH_Mat_Cfg_Init_Desc
    INTEGER(i4) :: matId    = 0_i4            ! 全局材料ID
    INTEGER(i4) :: matModel = PH_MAT_UNKNOWN  ! 族enum
  END TYPE PH_Mat_Cfg_Init_Desc
```

### `PH_Mat_Pop_Vld_Desc` (lines 30–32)

```fortran
  TYPE, PUBLIC :: PH_Mat_Pop_Vld_Desc
    INTEGER(i4) :: mat_model_id = 0_i4        ! 离散模型ID (101..1102)
  END TYPE PH_Mat_Pop_Vld_Desc
```

### `PH_Mat_Inc_Evo_Ctx` (lines 36–40)

```fortran
  TYPE, PUBLIC :: PH_Mat_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! 当前步
    INTEGER(i4) :: incr_idx = 0_i4   ! 当前增量
    REAL(wp)    :: dt       = 0.0_wp ! 时间增量
  END TYPE PH_Mat_Inc_Evo_Ctx
```

### `PH_Mat_Lcl_Comp_Ctx` (lines 43–47)

```fortran
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_Ctx
    REAL(wp) :: temperature = 0.0_wp  ! 温度 [K]
    REAL(wp) :: strain_rate = 0.0_wp  ! 等效应变速率 [1/s]
    REAL(wp) :: dstrain(6) = 0.0_wp    ! 应变增量 Voigt（Populate/Element 写入）
  END TYPE PH_Mat_Lcl_Comp_Ctx
```

### `PH_Mat_Lcl_Comp_State` (lines 51–54)

```fortran
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_State
    REAL(wp), ALLOCATABLE :: C_tan(:,:)   ! 算法切线 [ntens x ntens]
    REAL(wp), ALLOCATABLE :: stress(:)    ! 当前应力 (Voigt)
  END TYPE PH_Mat_Lcl_Comp_State
```

### `PH_Mat_Lcl_Evo_State` (lines 57–60)

```fortran
  TYPE, PUBLIC :: PH_Mat_Lcl_Evo_State
    REAL(wp), ALLOCATABLE :: stateVars(:)    ! SDVs at n+1
    REAL(wp), ALLOCATABLE :: stateVars_n(:)  ! SDVs at n (converged)
  END TYPE PH_Mat_Lcl_Evo_State
```

### `PH_Mat_Stp_Ctl_Algo` (lines 64–69)

```fortran
  TYPE, PUBLIC :: PH_Mat_Stp_Ctl_Algo
    REAL(wp)    :: tol_yield    = 1.0e-6_wp ! 屈服容差
    REAL(wp)    :: tol_residual = 1.0e-8_wp ! NR残差容差
    INTEGER(i4) :: max_iter     = 20_i4     ! 最大局部NR迭代
    INTEGER(i4) :: integ_scheme = 1_i4      ! 1=BE, 2=MP
  END TYPE PH_Mat_Stp_Ctl_Algo
```

### `PH_Mat_Lcl_Comp_ArgIn` (lines 73–79)

```fortran
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgIn
    INTEGER(i4) :: nprops  = 0_i4
    INTEGER(i4) :: ntens   = 6_i4
    INTEGER(i4) :: nsdv    = 0_i4
    REAL(wp), ALLOCATABLE :: strain(:)      ! 总应变
    REAL(wp), ALLOCATABLE :: d_strain(:)    ! 应变增量
  END TYPE PH_Mat_Lcl_Comp_ArgIn
```

### `PH_Mat_Lcl_Comp_ArgOut` (lines 82–85)

```fortran
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgOut
    REAL(wp), ALLOCATABLE :: stress_new(:)  ! 更新应力
    REAL(wp), ALLOCATABLE :: tangent(:,:)   ! 切线模量
  END TYPE PH_Mat_Lcl_Comp_ArgOut
```

### `PH_Mat_Krnl_Ctx` (lines 88–90)

```fortran
  TYPE, PUBLIC :: PH_Mat_Krnl_Ctx
    REAL(wp) :: dstran(6) = 0.0_wp
  END TYPE PH_Mat_Krnl_Ctx
```

### `PH_Mat_Krnl_Algo` (lines 93–101)

```fortran
  TYPE, PUBLIC :: PH_Mat_Krnl_Algo
    INTEGER(i4) :: max_iter   = 100_i4
    REAL(wp)    :: tolerance  = 1.0e-8_wp
    REAL(wp)    :: abs_tol    = 1.0e-12_wp
    REAL(wp)    :: pnewdt_min = 0.1_wp
    REAL(wp)    :: pnewdt_max = 1.5_wp
    LOGICAL     :: auto_cut   = .TRUE.
    LOGICAL     :: line_search = .FALSE.
  END TYPE PH_Mat_Krnl_Algo
```

### `PH_Mat_Slot_PhaseIdx` (lines 104–109)

```fortran
  TYPE, PUBLIC :: PH_Mat_Slot_PhaseIdx
    LOGICAL :: cfg_ready = .FALSE.
    LOGICAL :: pop_ready = .FALSE.
    LOGICAL :: stp_ready = .FALSE.
    LOGICAL :: lcl_ready = .FALSE.
  END TYPE PH_Mat_Slot_PhaseIdx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
