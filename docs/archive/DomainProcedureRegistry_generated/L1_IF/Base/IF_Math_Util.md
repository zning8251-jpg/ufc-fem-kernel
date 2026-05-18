# `IF_Math_Util.f90`

- **Source**: `L1_IF/Base/IF_Math_Util.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Math_Util`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Math_Util`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Math`
- **第四段角色（四段式）**: `_Util`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Math_Util.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `IF_Math_Clamp` | 49 | `FUNCTION IF_Math_Clamp(x, min_val, max_val) RESULT(clamped)` |
| FUNCTION | `IF_Math_CrossProduct` | 55 | `FUNCTION IF_Math_CrossProduct(a, b) RESULT(cross)` |
| FUNCTION | `IF_Math_DotProduct` | 64 | `FUNCTION IF_Math_DotProduct(a, b) RESULT(dot)` |
| FUNCTION | `IF_Math_IsEqual` | 82 | `FUNCTION IF_Math_IsEqual(a, b, tolerance) RESULT(is_equal)` |
| FUNCTION | `IF_Math_IsFinite` | 98 | `FUNCTION IF_Math_IsFinite(x) RESULT(is_finite)` |
| FUNCTION | `IF_Math_IsInf` | 104 | `FUNCTION IF_Math_IsInf(x) RESULT(is_inf)` |
| FUNCTION | `IF_Math_IsNaN` | 110 | `FUNCTION IF_Math_IsNaN(x) RESULT(is_nan)` |
| FUNCTION | `IF_Math_IsZero` | 116 | `FUNCTION IF_Math_IsZero(x, tolerance) RESULT(is_zero)` |
| FUNCTION | `IF_Math_Lerp` | 132 | `FUNCTION IF_Math_Lerp(a, b, t) RESULT(lerped)` |
| FUNCTION | `IF_Math_Norm` | 138 | `FUNCTION IF_Math_Norm(vec) RESULT(norm_val)` |
| FUNCTION | `IF_Math_Sign` | 152 | `FUNCTION IF_Math_Sign(x) RESULT(sign_val)` |
| SUBROUTINE | `IF_Math_Mtx_Determinant` | 169 | `SUBROUTINE IF_Math_Mtx_Determinant(A, det, status)` |
| SUBROUTINE | `IF_Math_Mtx_Determinant_3x3` | 194 | `SUBROUTINE IF_Math_Mtx_Determinant_3x3(A, det, status)` |
| SUBROUTINE | `IF_Math_Mtx_Inverse` | 209 | `SUBROUTINE IF_Math_Mtx_Inverse(A, A_inverse, status)` |
| SUBROUTINE | `IF_Math_Mtx_Inverse_3x3` | 240 | `SUBROUTINE IF_Math_Mtx_Inverse_3x3(A, A_inverse, status)` |
| SUBROUTINE | `IF_Math_Mtx_Multiply` | 280 | `SUBROUTINE IF_Math_Mtx_Multiply(A, B, C, status)` |
| FUNCTION | `IF_Math_Mtx_Transpose` | 311 | `FUNCTION IF_Math_Mtx_Transpose(A) RESULT(At)` |
| SUBROUTINE | `IF_Math_Normalize` | 324 | `SUBROUTINE IF_Math_Normalize(vec, status)` |
| SUBROUTINE | `IF_Math_SafeDivide` | 343 | `SUBROUTINE IF_Math_SafeDivide(numerator, denominator, result, status)` |
| SUBROUTINE | `IF_Math_SafeLog` | 361 | `SUBROUTINE IF_Math_SafeLog(x, result, status)` |
| SUBROUTINE | `IF_Math_SafeSqrt` | 379 | `SUBROUTINE IF_Math_SafeSqrt(x, result, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
