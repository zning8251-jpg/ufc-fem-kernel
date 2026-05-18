# `NM_Cpl_ThermalStruct.f90`

- **Source**: `L2_NM/Solver/Coupling/NM_Cpl_ThermalStruct.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Cpl_ThermalStruct`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Cpl_ThermalStruct`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Cpl_ThermalStruct`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Coupling/NM_Cpl_ThermalStruct.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Coupling_TS_Init` | 24 | `SUBROUTINE NM_Coupling_TS_Init(thermal_params, struct_params, ts_ctx, status)` |
| SUBROUTINE | `NM_Coupling_TS_Solv` | 37 | `SUBROUTINE NM_Coupling_TS_Solv(temperature, struct_disp, struct_stress, &` |
| SUBROUTINE | `NM_Coupling_TS_Temp_Solv` | 62 | `SUBROUTINE NM_Coupling_TS_Temp_Solv(temperature, params, dt, status)` |
| SUBROUTINE | `NM_Coupling_TS_Struct_Solv` | 76 | `SUBROUTINE NM_Coupling_TS_Struct_Solv(struct_disp, struct_stress, params, dt, status)` |
| SUBROUTINE | `NM_Coupling_TS_ThermalStrain_Calc` | 90 | `SUBROUTINE NM_Coupling_TS_ThermalStrain_Calc(temperature, struct_disp, params, status)` |
| SUBROUTINE | `NM_Coupling_TS_Cleanup` | 106 | `SUBROUTINE NM_Coupling_TS_Cleanup(ts_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
