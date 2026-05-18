# `PH_Elem_AcousticSuite.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AcousticSuite.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AcousticSuite`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AcousticSuite`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AcousticSuite`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AcousticSuite.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Acoustic_Diagnose` | 45 | `SUBROUTINE PH_Acoustic_Diagnose(ctx, Mass, Damping, Stiffness, &` |
| FUNCTION | `check_symmetry` | 107 | `FUNCTION check_symmetry(A) RESULT(is_sym)` |
| FUNCTION | `TRACE` | 125 | `FUNCTION TRACE(A) RESULT(tr)` |
| FUNCTION | `power_iteration_max` | 136 | `FUNCTION power_iteration_max(K, M) RESULT(lambda_max)` |
| FUNCTION | `power_iteration_min` | 158 | `FUNCTION power_iteration_min(K, M) RESULT(lambda_min)` |
| SUBROUTINE | `PH_Acoustic_Verify_Matrices` | 170 | `SUBROUTINE PH_Acoustic_Verify_Matrices(Mass, Damping, Stiffness, &` |
| FUNCTION | `is_symmetric` | 206 | `FUNCTION is_symmetric(A, tol) RESULT(res)` |
| FUNCTION | `all_positive_diag` | 223 | `FUNCTION all_positive_diag(A) RESULT(res)` |
| SUBROUTINE | `PH_Acoustic_Check_Consistency` | 242 | `SUBROUTINE PH_Acoustic_Check_Consistency(ctx, material, status)` |
| SUBROUTINE | `PH_Acoustic_Init_Unified_Ctx` | 294 | `SUBROUTINE PH_Acoustic_Init_Unified_Ctx(ctx, density, bulk_modulus, &` |
| SUBROUTINE | `PH_Acoustic_Select_Analysis_Type` | 346 | `SUBROUTINE PH_Acoustic_Select_Analysis_Type(ctx, analysis_type, &` |
| SUBROUTINE | `PH_Acoustic_Compute_Eigenvalues` | 380 | `SUBROUTINE PH_Acoustic_Compute_Eigenvalues(Mass, Stiffness, &` |
| FUNCTION | `power_iter_eigenvalue` | 414 | `FUNCTION power_iter_eigenvalue(K, M, shift) RESULT(lambda)` |
| FUNCTION | `PH_Acoustic_Estimate_CFL` | 447 | `FUNCTION PH_Acoustic_Estimate_CFL(c, dx, dt) RESULT(cfl)` |
| SUBROUTINE | `PH_Acoustic_Time_To_Frequency` | 463 | `SUBROUTINE PH_Acoustic_Time_To_Frequency(p_time, t_array, &` |
| FUNCTION | `DFT_point` | 506 | `FUNCTION DFT_point(signal, t, freq) RESULT(value)` |
| SUBROUTINE | `PH_Acoustic_Frequency_To_Time` | 527 | `SUBROUTINE PH_Acoustic_Frequency_To_Time(p_freq, f_array, &` |
| FUNCTION | `iDFT_point` | 562 | `FUNCTION iDFT_point(spectrum, f, t) RESULT(value)` |
| SUBROUTINE | `PH_Acoustic_Map_Material_To_Context` | 586 | `SUBROUTINE PH_Acoustic_Map_Material_To_Context(material, ctx, status)` |
| SUBROUTINE | `PH_Acoustic_Biot_Wave_Speeds` | 620 | `SUBROUTINE PH_Acoustic_Biot_Wave_Speeds(material, c_p1, c_p2, c_s, status)` |
| SUBROUTINE | `PH_Acoustic_Compute_Impedance` | 696 | `SUBROUTINE PH_Acoustic_Compute_Impedance(ctx, omega, Z, status)` |
| SUBROUTINE | `porous_impedance` | 722 | `SUBROUTINE porous_impedance(rho, c, w, Z_pml)` |
| SUBROUTINE | `PH_Acoustic_Temperature_Dependent_c` | 751 | `SUBROUTINE PH_Acoustic_Temperature_Dependent_c(ctx, T, c_T, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
