# `NM_Solv_TrustRegion.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_TrustRegion.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_TrustRegion`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_TrustRegion`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_TrustRegion`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_TrustRegion.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `TrustRegion_Params` (lines 22–33)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params
    INTEGER(i4) :: max_iterations        !<  iter count
    REAL(DP) :: tol_residual          !<  
    REAL(DP) :: tol_step              !< step 

    REAL(DP) :: delta_init            !< Initialize Δ₀
    REAL(DP) :: delta_max             !<  radius Δ_max
    REAL(DP) :: eta1                  !<  η(  0.25)
    REAL(DP) :: eta2                  !<  η(  0.75)

    LOGICAL  :: verbose               !< whether iteration 
  END TYPE
```

### `TrustRegion_State` (lines 36–48)

```fortran
  TYPE, PUBLIC :: TrustRegion_State
    INTEGER(i4) :: n_dof                 !< DOF count
    INTEGER(i4) :: iteration             !<  iter count

    REAL(DP) :: phi                   !<   Φ(u) = 1/2‖F ?
    REAL(DP) :: phi_new               !<  Φ(u+p)
    REAL(DP) :: residual_norm         !<   ‖F
    REAL(DP) :: step_norm             !< current step size  ‖p
    REAL(DP) :: delta                 !<  Δ
    REAL(DP) :: rho                   !<  / 

    LOGICAL  :: converged             !< converged
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Calc_Cauchy_Step` | 57 | `SUBROUTINE Calc_Cauchy_Step(g, B, delta, p_C)` |
| SUBROUTINE | `Calc_Dogleg_Step` | 87 | `SUBROUTINE Calc_Dogleg_Step(p_C, p_N, delta, p)` |
| SUBROUTINE | `NM_Tr_AdaptiveRadius` | 116 | `SUBROUTINE NM_Tr_AdaptiveRadius(params, state, rho, new_radius, status)` |
| SUBROUTINE | `NM_TrustRegion_GetStatistics` | 145 | `SUBROUTINE NM_TrustRegion_GetStatistics(state, params, stats, status)` |
| SUBROUTINE | `NM_TrustRegion_Solv` | 166 | `SUBROUTINE NM_TrustRegion_Solv(u, Residual_proc, Jacobian_proc, params, state)` |
| SUBROUTINE | `Residual_proc` | 169 | `SUBROUTINE Residual_proc(u, F)` |
| SUBROUTINE | `Jacobian_proc` | 174 | `SUBROUTINE Jacobian_proc(u, J)` |
| SUBROUTINE | `Solv_SPD_System` | 288 | `SUBROUTINE Solv_SPD_System(B, rhs, x)` |
| SUBROUTINE | `Solv_Tau_On_Dogleg` | 314 | `SUBROUTINE Solv_Tau_On_Dogleg(p_C, d, delta, tau)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 168–179 | `INTERFACE` |
