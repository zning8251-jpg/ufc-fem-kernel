# `MD_Mat_Elas_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Elas_Contract.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Elas_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_CoupledElas_FlattenDataLines` | 38 | `SUBROUTINE MD_CoupledElas_FlattenDataLines(ast_node, vals, nvals, status)` |
| SUBROUTINE | `MD_CoupledElas_ParseThermo108` | 59 | `SUBROUTINE MD_CoupledElas_ParseThermo108(ast_node, E, nu, alpha, t_ref, status)` |
| SUBROUTINE | `MD_CoupledElas_Thermo108_ToProps` | 90 | `SUBROUTINE MD_CoupledElas_Thermo108_ToProps(E, nu, alpha, t_ref, props, nprops, status)` |
| SUBROUTINE | `MD_CoupledElas_ParsePiezo109` | 110 | `SUBROUTINE MD_CoupledElas_ParsePiezo109(ast_node, props, nprops, status)` |
| SUBROUTINE | `MD_CoupledElas_Piezo109_ToProps` | 140 | `SUBROUTINE MD_CoupledElas_Piezo109_ToProps(vals10, props, nprops, status)` |
| SUBROUTINE | `MD_CoupledElas_ParseThermoPiezo110` | 161 | `SUBROUTINE MD_CoupledElas_ParseThermoPiezo110(ast_node, props, nprops, status)` |
| SUBROUTINE | `MD_CoupledElas_ThermoPiezo110_ToProps` | 191 | `SUBROUTINE MD_CoupledElas_ThermoPiezo110_ToProps(vals12, props, nprops, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
