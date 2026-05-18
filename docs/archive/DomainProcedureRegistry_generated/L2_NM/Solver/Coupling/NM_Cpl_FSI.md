# `NM_Cpl_FSI.f90`

- **Source**: `L2_NM/Solver/Coupling/NM_Cpl_FSI.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Cpl_FSI`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Cpl_FSI`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Cpl_FSI`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Coupling/NM_Cpl_FSI.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Coupling_FSI_Init` | 31 | `SUBROUTINE NM_Coupling_FSI_Init(fluid_params, struct_params, interface, fsi_ctx, status)` |
| SUBROUTINE | `NM_Coupling_FSI_Solv` | 60 | `SUBROUTINE NM_Coupling_FSI_Solv(struct_disp, struct_vel, struct_accel, &` |
| SUBROUTINE | `NM_Coupling_FSI_Fluid_Solv` | 91 | `SUBROUTINE NM_Coupling_FSI_Fluid_Solv(fluid_vel, fluid_pres, interface, dt, status)` |
| SUBROUTINE | `NM_Coupling_FSI_Struct_Solv` | 105 | `SUBROUTINE NM_Coupling_FSI_Struct_Solv(struct_disp, struct_vel, struct_accel, interface, dt, status)` |
| SUBROUTINE | `NM_Coupling_FSI_FluidForce_Calc` | 119 | `SUBROUTINE NM_Coupling_FSI_FluidForce_Calc(fluid_vel, fluid_pres, interface, fluid_force, status)` |
| SUBROUTINE | `NM_Coupling_FSI_Interface_Transfer` | 136 | `SUBROUTINE NM_Coupling_FSI_Interface_Transfer(struct_disp, fluid_vel, interface, status)` |
| SUBROUTINE | `NM_Coupling_FSI_CheckConv` | 153 | `SUBROUTINE NM_Coupling_FSI_CheckConv(struct_disp, fluid_vel, interface, params, status)` |
| SUBROUTINE | `NM_Coupling_FSI_Cleanup` | 169 | `SUBROUTINE NM_Coupling_FSI_Cleanup(fsi_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
