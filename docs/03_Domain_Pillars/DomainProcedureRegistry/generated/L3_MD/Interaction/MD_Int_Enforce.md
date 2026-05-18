# `MD_Int_Enforce.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Enforce.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Enforce`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Enforce`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Enforce`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Enforce.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Int_EnforceAugLagr` | 33 | `SUBROUTINE MD_Int_EnforceAugLagr(penalty_n, gap, lambda, &` |
| SUBROUTINE | `MD_Int_EnforceLagrMult` | 65 | `SUBROUTINE MD_Int_EnforceLagrMult(gap, lambda, contact_force, contact_pressur)` |
| SUBROUTINE | `MD_Int_EnforcePenalty` | 86 | `SUBROUTINE MD_Int_EnforcePenalty(penalty_n, gap, contact_force, contact_pressur)` |
| SUBROUTINE | `MD_Int_UpdateMultipliers` | 107 | `SUBROUTINE MD_Int_UpdateMultipliers(lambda, gap, penalty_n, max_iter, tol)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
