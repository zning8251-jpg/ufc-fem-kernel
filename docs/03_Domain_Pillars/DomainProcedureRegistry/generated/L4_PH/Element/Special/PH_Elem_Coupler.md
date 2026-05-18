# `PH_Elem_Coupler.f90`

- **Source**: `L4_PH/Element/Special/PH_Elem_Coupler.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Coupler`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Coupler`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Coupler`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Special`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Special/PH_Elem_Coupler.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Coupler_Desc` (lines 35–41)

```fortran
  TYPE, PUBLIC :: PH_Coupler_Desc
    INTEGER(i4) :: n_nodes      = 2_i4      ! Reference + coupling node
    INTEGER(i4) :: n_dof        = 12_i4     ! 6 DOF per node × 2
    INTEGER(i4) :: coupling_type = 1_i4     ! 1=kinematic, 2=distributing
    REAL(wp)    :: penalty      = DEFAULT_PENALTY  ! Penalty stiffness
    REAL(wp)    :: weights(6)   = 1.0_wp    ! DOF weights (u,v,w,rx,ry,rz)
  END TYPE PH_Coupler_Desc
```

### `PH_Coupler_Ctx` (lines 46–50)

```fortran
  TYPE, PUBLIC :: PH_Coupler_Ctx
    LOGICAL     :: initialized = .FALSE.
    REAL(wp)    :: u_local(12)  = 0.0_wp    ! Local displacement vector
    REAL(wp)    :: f_int(12)    = 0.0_wp    ! Internal force vector
  END TYPE PH_Coupler_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Coupler_Init` | 58 | `SUBROUTINE PH_Elem_Coupler_Init(elem_desc, elem_ctx, ierr)` |
| SUBROUTINE | `PH_Elem_Coupler_Compute_Stiffness` | 76 | `SUBROUTINE PH_Elem_Coupler_Compute_Stiffness(elem_desc, elem_ctx, Ke, ierr)` |
| SUBROUTINE | `PH_Elem_Coupler_Compute_Mass` | 116 | `SUBROUTINE PH_Elem_Coupler_Compute_Mass(elem_desc, elem_ctx, Me, ierr)` |
| SUBROUTINE | `PH_Elem_Coupler_Compute_InternalForce` | 131 | `SUBROUTINE PH_Elem_Coupler_Compute_InternalForce(elem_desc, elem_ctx, fe, ierr)` |
| SUBROUTINE | `PH_Elem_Coupler_Update_State` | 160 | `SUBROUTINE PH_Elem_Coupler_Update_State(elem_desc, elem_ctx, u_local, ierr)` |
| SUBROUTINE | `PH_Elem_Coupler_Finalize` | 179 | `SUBROUTINE PH_Elem_Coupler_Finalize(elem_ctx, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
