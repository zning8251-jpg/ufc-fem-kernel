# `PH_Elem_CalcWrapper.f90`

- **Source**: `L4_PH/Element/PH_Elem_CalcWrapper.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_CalcWrapper`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CalcWrapper`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CalcWrapper`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_CalcWrapper.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Calc_Args` (lines 20–49)

```fortran
  TYPE, PUBLIC :: PH_Elem_Calc_Args
    !-- Input: 几何与材料
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)  ! [IN] 参考坐标 (nDim, nNode)
    REAL(wp), ALLOCATABLE :: disp(:,:)        ! [IN] 位移 (nDim, nNode)
    REAL(wp), ALLOCATABLE :: props(:)         ! [IN] 材料参数
    
    !-- Input: 计算控制
    INTEGER(i4) :: calc_mode = 1_i4           ! [IN] 1=线性, 2=非线性TL, 3=非线性UL
    LOGICAL :: compute_stiffness = .TRUE.     ! [IN] 计算Ke
    LOGICAL :: compute_force = .TRUE.         ! [IN] 计算Fe
    LOGICAL :: compute_mass = .FALSE.         ! [IN] 计算Me
    LOGICAL :: compute_damping = .FALSE.      ! [IN] 计算Ce
    LOGICAL :: nlgeom = .FALSE.               ! [IN] 几何非线性开关
    
    !-- Input: 时间参数
    REAL(wp) :: time = 0.0_wp                 ! [IN] 当前时间
    REAL(wp) :: dTime = 1.0_wp                ! [IN] 时间步长
    
    !-- Output: 矩阵结果
    REAL(wp), ALLOCATABLE :: Ke(:,:)          ! [OUT] 刚度矩阵
    REAL(wp), ALLOCATABLE :: Fe(:)            ! [OUT] 残力向量
    REAL(wp), ALLOCATABLE :: Me(:,:)          ! [OUT] 质量矩阵
    REAL(wp), ALLOCATABLE :: Ce(:,:)          ! [OUT] 阻尼矩阵
    
    !-- Output: 状态变量
    REAL(wp), ALLOCATABLE :: svars(:,:)       ! [OUT] 状态变量 (nIP, nSvar)
    REAL(wp) :: energy_internal = 0.0_wp      ! [OUT] 内能
    REAL(wp) :: energy_kinetic = 0.0_wp       ! [OUT] 动能
    REAL(wp) :: stable_dt = 0.0_wp            ! [OUT] 稳定时间步
  END TYPE PH_Elem_Calc_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Calc_Ke` | 67 | `SUBROUTINE PH_Elem_Calc_Ke(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `PH_Elem_Calc_Fe` | 118 | `SUBROUTINE PH_Elem_Calc_Fe(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `PH_Elem_Calc_Me` | 162 | `SUBROUTINE PH_Elem_Calc_Me(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `PH_Elem_Calc_Ce` | 206 | `SUBROUTINE PH_Elem_Calc_Ce(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `PH_Elem_Calc_All` | 243 | `SUBROUTINE PH_Elem_Calc_All(desc, state, algo, ctx, args, status)` |
| FUNCTION | `PH_Elem_Calc_Validate` | 298 | `FUNCTION PH_Elem_Calc_Validate(args, desc) RESULT(is_valid)` |
| SUBROUTINE | `Calc_Ke_Solid3D` | 331 | `SUBROUTINE Calc_Ke_Solid3D(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Fe_Solid3D` | 365 | `SUBROUTINE Calc_Fe_Solid3D(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Me_Solid3D` | 394 | `SUBROUTINE Calc_Me_Solid3D(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Ke_Shell` | 425 | `SUBROUTINE Calc_Ke_Shell(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Fe_Shell` | 455 | `SUBROUTINE Calc_Fe_Shell(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Me_Shell` | 482 | `SUBROUTINE Calc_Me_Shell(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Ke_Beam` | 512 | `SUBROUTINE Calc_Ke_Beam(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Fe_Beam` | 542 | `SUBROUTINE Calc_Fe_Beam(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `Calc_Me_Beam` | 569 | `SUBROUTINE Calc_Me_Beam(desc, state, algo, ctx, args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
