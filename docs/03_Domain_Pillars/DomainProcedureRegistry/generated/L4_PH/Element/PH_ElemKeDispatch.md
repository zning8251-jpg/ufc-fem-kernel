# `PH_ElemKeDispatch.f90`

- **Source**: `L4_PH/Element/PH_ElemKeDispatch.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ElemKeDispatch`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ElemKeDispatch`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ElemKeDispatch`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_ElemKeDispatch.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Compute_Ke` | 43 | `SUBROUTINE Compute_Ke(elem_type, coords, mat_props, algo_params, Ke, status, &` |
| SUBROUTINE | `Compute_Ke_C3D4` | 163 | `SUBROUTINE Compute_Ke_C3D4(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_C3D8` | 173 | `SUBROUTINE Compute_Ke_C3D8(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CAX4` | 183 | `SUBROUTINE Compute_Ke_CAX4(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CAX8` | 193 | `SUBROUTINE Compute_Ke_CAX8(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CPE4` | 203 | `SUBROUTINE Compute_Ke_CPE4(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CPE8` | 213 | `SUBROUTINE Compute_Ke_CPE8(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CPS4` | 223 | `SUBROUTINE Compute_Ke_CPS4(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_CPS8` | 233 | `SUBROUTINE Compute_Ke_CPS8(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_S4` | 243 | `SUBROUTINE Compute_Ke_S4(coords, mat_props, Ke, status)` |
| SUBROUTINE | `Compute_Ke_S8` | 253 | `SUBROUTINE Compute_Ke_S8(coords, mat_props, Ke, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
