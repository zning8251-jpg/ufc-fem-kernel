# `PH_Elem_C3D8FBar.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D8FBar.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D8FBar`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D8FBar`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D8FBar`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D8FBar.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_C3D8_FBar_Ctx` (lines 40–61)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_Ctx
    ! Average volumetric strain (J )
    REAL(wp) :: J_bar = 1.0_wp
    
    ! Element volume
    REAL(wp) :: volume = 0.0_wp
    
    ! Deformation gradient at each Gauss point
    REAL(wp), ALLOCATABLE :: F_gp(:,:,:)  ! (n_gp, 3, 3)
    
    ! Modified deformation gradient F at each Gauss point
    REAL(wp), ALLOCATABLE :: F_bar_gp(:,:,:)  ! (n_gp, 3, 3)
    
    ! Determinant of F at each Gauss point
    REAL(wp), ALLOCATABLE :: det_F_gp(:)  ! (n_gp)
    
    ! Flag: whether F-bar is active
    LOGICAL :: is_active = .FALSE.
    
    ! Number of Gauss points
    INTEGER(i4) :: n_gp = 8_i4
  END TYPE PH_Elem_C3D8_FBar_Ctx
```

### `PH_Elem_C3D8_FBar_InitCtx_Arg` (lines 70–74)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_InitCtx_Arg
    INTEGER(i4) :: n_gp  ! Number of Gauss points (Algo)                   ! [IN]
    TYPE(PH_Elem_C3D8_FBar_Ctx) :: ctx  ! Initialized F-bar context (Ctx)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_FBar_InitCtx_Arg
```

### `PH_Elem_C3D8_FBar_ComputeVolumetricStrain_Arg` (lines 80–83)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_ComputeVolumetricStrain_Arg
    TYPE(PH_Elem_C3D8_FBar_Ctx) :: ctx  ! F-bar context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_FBar_ComputeVolumetricStrain_Arg
```

### `PH_Elem_C3D8_FBar_SplitDeviatoric_Arg` (lines 89–92)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_SplitDeviatoric_Arg
    TYPE(PH_Elem_C3D8_FBar_Ctx) :: ctx  ! F-bar context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_FBar_SplitDeviatoric_Arg
```

### `PH_Elem_C3D8_FBar_AssembleStiffness_Arg` (lines 98–101)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_AssembleStiffness_Arg
    TYPE(PH_Elem_C3D8_FBar_Ctx) :: ctx  ! F-bar context (Ctx)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_FBar_AssembleStiffness_Arg
```

### `PH_Elem_C3D8_FBar_Stiffness_Arg` (lines 107–110)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_FBar_Stiffness_Arg
    TYPE(PH_Elem_C3D8_FBar_Ctx) :: ctx  ! F-bar context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_FBar_Stiffness_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `Det3x3` | 115 | `FUNCTION Det3x3(A) RESULT(det)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_AssembleStiffness` | 125 | `SUBROUTINE PH_Elem_C3D8_FBar_AssembleStiffness(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_ComputeVolumetricStrain` | 155 | `SUBROUTINE PH_Elem_C3D8_FBar_ComputeVolumetricStrain(in, out)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_InitCtx` | 209 | `SUBROUTINE PH_Elem_C3D8_FBar_InitCtx(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_SplitDeviatoric` | 252 | `SUBROUTINE PH_Elem_C3D8_FBar_SplitDeviatoric(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_Stiffness` | 295 | `SUBROUTINE PH_Elem_C3D8_FBar_Stiffness(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_FBar_Material_Update_Routed` | 359 | `SUBROUTINE PH_Elem_C3D8_FBar_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
