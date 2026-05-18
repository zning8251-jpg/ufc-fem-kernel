# `PH_Elem_C3D8EAS.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D8EAS.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D8EAS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D8EAS`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D8EAS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D8EAS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_C3D8_EAS_Ctx` (lines 47–67)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_Ctx
    ! Enhanced strain parameters (static condensation)
    REAL(wp) :: alpha(PH_ELEM_EAS_NPARAM) = 0.0_wp
    
    ! G matrix at each Gauss point (6 strain components n_param)
    REAL(wp), ALLOCATABLE :: G_matrix(:,:,:)  ! (n_gp, 6, PH_ELEM_EAS_NPARAM)
    
    ! Static condensation matrices
    REAL(wp) :: K_alpha_alpha(PH_ELEM_EAS_NPARAM, PH_ELEM_EAS_NPARAM) = 0.0_wp
    REAL(wp) :: K_u_alpha(24, PH_ELEM_EAS_NPARAM) = 0.0_wp
    REAL(wp) :: K_alpha_u(PH_ELEM_EAS_NPARAM, 24) = 0.0_wp
    
    ! Condensed stiffness matrix
    REAL(wp) :: K_condensed(24, 24) = 0.0_wp
    
    ! Flag: whether EAS is active
    LOGICAL :: is_active = .FALSE.
    
    ! Number of Gauss points
    INTEGER(i4) :: n_gp = 8_i4
  END TYPE PH_Elem_C3D8_EAS_Ctx
```

### `PH_Elem_C3D8_EAS_InitCtx_Arg` (lines 76–80)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_InitCtx_Arg
    INTEGER(i4) :: n_gp  ! Number of Gauss points (Algo)                   ! [IN]
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! Initialized EAS context (Ctx)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_InitCtx_Arg
```

### `PH_Elem_C3D8_EAS_ComputeGMatrix_Arg` (lines 86–89)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_ComputeGMatrix_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_ComputeGMatrix_Arg
```

### `PH_Elem_C3D8_EAS_UpdateAlpha_Arg` (lines 95–98)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_UpdateAlpha_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_UpdateAlpha_Arg
```

### `PH_Elem_C3D8_EAS_CondenseStiffness_Arg` (lines 104–107)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_CondenseStiffness_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_CondenseStiffness_Arg
```

### `PH_Elem_C3D8_EAS_Stiffness_Arg` (lines 113–116)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_Stiffness_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_Stiffness_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `InvertMatrix` | 121 | `SUBROUTINE InvertMatrix(n, A, info)` |
| SUBROUTINE | `InvertSmallMatrix` | 137 | `SUBROUTINE InvertSmallMatrix(n, A, info)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_ComputeGMatrix` | 190 | `SUBROUTINE PH_Elem_C3D8_EAS_ComputeGMatrix(in, out)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_CondenseStiffness` | 255 | `SUBROUTINE PH_Elem_C3D8_EAS_CondenseStiffness(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_InitCtx` | 291 | `SUBROUTINE PH_Elem_C3D8_EAS_InitCtx(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_Stiffness` | 319 | `SUBROUTINE PH_Elem_C3D8_EAS_Stiffness(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_UpdateAlpha` | 380 | `SUBROUTINE PH_Elem_C3D8_EAS_UpdateAlpha(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_EAS_Material_Update_Routed` | 415 | `SUBROUTINE PH_Elem_C3D8_EAS_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
