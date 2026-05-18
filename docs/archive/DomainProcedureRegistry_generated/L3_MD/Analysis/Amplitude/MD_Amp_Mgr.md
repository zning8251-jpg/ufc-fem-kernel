# `MD_Amp_Mgr.f90`

- **Source**: `L3_MD/Analysis/Amplitude/MD_Amp_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Amp_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Amp_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Amp`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Amplitude`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Amplitude/MD_Amp_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Amplitude_Apply_AddAmplitude_MDL` | 69 | `SUBROUTINE MD_Amplitude_Apply_AddAmplitude_MDL(md_layer, arg)` |
| FUNCTION | `Amp_GetFactor` | 94 | `FUNCTION Amp_GetFactor(amplitudes, amplitudeId, time, amp_dom) RESULT(fac)` |
| FUNCTION | `MD_Amp_GetFactor` | 138 | `FUNCTION MD_Amp_GetFactor(amplitudeDB, amplitudeName, time) RESULT(factor)` |
| SUBROUTINE | `amp_md_desc_dealloc_arrays` | 150 | `SUBROUTINE amp_md_desc_dealloc_arrays(d)` |
| FUNCTION | `amp_md_pilot_views_match_flat` | 160 | `PURE FUNCTION amp_md_pilot_views_match_flat(pv, d) RESULT(ok)` |
| SUBROUTINE | `amp_md_pilot_mismatch_hook` | 192 | `SUBROUTINE amp_md_pilot_mismatch_hook()` |
| SUBROUTINE | `MD_Amplitude_UF_To_MD_Desc` | 196 | `SUBROUTINE MD_Amplitude_UF_To_MD_Desc(uf_amp, md_desc)` |
| SUBROUTINE | `MD_Amplitude_SyncFromLegacy` | 319 | `SUBROUTINE MD_Amplitude_SyncFromLegacy(model_def, md_layer, status)` |
| FUNCTION | `MD_Amplitude_ResolveName` | 367 | `PURE FUNCTION MD_Amplitude_ResolveName(md_layer, name) RESULT(amp_ref)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
