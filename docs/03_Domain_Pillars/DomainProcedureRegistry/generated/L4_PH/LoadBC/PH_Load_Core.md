# `PH_Load_Core.f90`

- **Source**: `L4_PH/LoadBC/PH_Load_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Load_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Load_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Load`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Load_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Geostatic_Algo_Args` (lines 27–51)

```fortran
  TYPE, PUBLIC :: PH_Geostatic_Algo_Args
    INTEGER(i4) :: n_node = 0_i4
    INTEGER(i4) :: n_dof = 0_i4
    INTEGER(i4) :: n_ip = 0_i4
    INTEGER(i4) :: load_type = 0_i4
    INTEGER(i4) :: ctype = 0_i4
    INTEGER(i4) :: idof = 0_i4
    INTEGER(i4) :: face_id = 0_i4
    REAL(wp) :: xi = 0.0_wp
    REAL(wp) :: eta = 0.0_wp
    REAL(wp) :: zeta = 0.0_wp
    REAL(wp) :: penalty = 0.0_wp
    REAL(wp) :: val = 0.0_wp
    REAL(wp) :: tol = 1.0e-12_wp
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp), POINTER :: u_elem(:) => NULL()
    REAL(wp), POINTER :: D(:,:) => NULL()
    REAL(wp), POINTER :: Ke(:,:) => NULL()
    REAL(wp), POINTER :: F_eq(:) => NULL()
    REAL(wp), POINTER :: state(:) => NULL()
    REAL(wp), POINTER :: stress(:) => NULL()
    REAL(wp), POINTER :: strain(:) => NULL()
    REAL(wp), POINTER :: F_def(:,:) => NULL()
    REAL(wp), POINTER :: R_int(:) => NULL()
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Load_Core_Init` | 55 | `SUBROUTINE PH_Load_Core_Init(status)` |
| SUBROUTINE | `PH_Load_Core_Finalize` | 61 | `SUBROUTINE PH_Load_Core_Finalize(status)` |
| SUBROUTINE | `PH_Load_Concentrated_Force` | 67 | `SUBROUTINE PH_Load_Concentrated_Force(value, amp_factor, dof, F_vec, status)` |
| SUBROUTINE | `PH_Load_Distributed_Load` | 80 | `SUBROUTINE PH_Load_Distributed_Load(nn, ndof_per_node, dof_dir, N_shape, &` |
| SUBROUTINE | `PH_Load_Pressure_Load` | 97 | `SUBROUTINE PH_Load_Pressure_Load(nn, ndof_per_node, pressure, N_shape, &` |
| SUBROUTINE | `PH_Load_Body_Force` | 116 | `SUBROUTINE PH_Load_Body_Force(nn, ndof_per_node, N_shape, body_force, &` |
| SUBROUTINE | `PH_Load_Gravity_Load` | 135 | `SUBROUTINE PH_Load_Gravity_Load(nn, ndof_per_node, N_shape, rho, g_vec, &` |
| SUBROUTINE | `PH_Load_Thermal_Load` | 148 | `SUBROUTINE PH_Load_Thermal_Load(D_mat, eps_th, ndof, volume, Fe, status)` |
| SUBROUTINE | `PH_Load_K0Assign` | 172 | `SUBROUTINE PH_Load_K0Assign(k0, rho, g_z, gauss_z, n_gauss, sigma0, status)` |
| SUBROUTINE | `PH_Load_GravityForce` | 202 | `SUBROUTINE PH_Load_GravityForce(rho, g_vec, n_dof, F_grav, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
