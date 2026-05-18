# `PH_Mat_Geo_MohrCoulomb_Core.f90`

- **Source**: `L4_PH/Material/Geo/PH_Mat_Geo_MohrCoulomb_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Geo_MohrCoulomb_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Geo_MohrCoulomb_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Geo_MohrCoulomb`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Geo/PH_Mat_Geo_MohrCoulomb_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MohrCoulomb_MatDesc` (lines 40–51)

```fortran
  TYPE :: MohrCoulomb_MatDesc
    REAL(wp) :: c = 0.0_wp
    REAL(wp) :: phi = 0.0_wp
    REAL(wp) :: psi = 0.0_wp
    REAL(wp) :: H_c = 0.0_wp
    REAL(wp) :: H_phi = 0.0_wp
    REAL(wp) :: H_psi = 0.0_wp
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
  END TYPE MohrCoulomb_MatDesc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_MohrCoulomb_L3_InitFromProps` | 61 | `SUBROUTINE UF_MohrCoulomb_L3_InitFromProps(desc, nprops, props, status)` |
| SUBROUTINE | `MohrCoulomb_UpdateStress` | 89 | `SUBROUTINE MohrCoulomb_UpdateStress(in, out)` |
| SUBROUTINE | `UF_MohrCoulomb_UMAT` | 199 | `SUBROUTINE UF_MohrCoulomb_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `mc_compute_stress_invariants_pq` | 253 | `SUBROUTINE mc_compute_stress_invariants_pq(stress, ntens, p, q, s_dev)` |
| SUBROUTINE | `mc_compute_tangent` | 282 | `SUBROUTINE mc_compute_tangent(D_elastic, K, mu, sin_phi, sin_psi, &` |
| SUBROUTINE | `PH_Mat_Geo_MC_Eval_Wrapper` | 314 | `SUBROUTINE PH_Mat_Geo_MC_Eval_Wrapper(desc, state, algo, strain, stress, ddsdde, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
