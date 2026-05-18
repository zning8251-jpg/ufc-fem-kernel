# `PH_Field_ComputeTemp.f90`

- **Source**: `L4_PH/Field/PH_Field_ComputeTemp.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Field_ComputeTemp`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_ComputeTemp`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_ComputeTemp`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_ComputeTemp.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Field_Compute_Temperature_Explicit` | 60 | `SUBROUTINE PH_Field_Compute_Temperature_Explicit(desc, algo, arg, status)` |
| SUBROUTINE | `PH_Field_Compute_Temperature_Implicit` | 100 | `SUBROUTINE PH_Field_Compute_Temperature_Implicit(desc, algo, arg, status)` |
| SUBROUTINE | `PH_Field_Assemble_ThermalLaplacian` | 136 | `SUBROUTINE PH_Field_Assemble_ThermalLaplacian(coords, conn, conductivity, &` |
| SUBROUTINE | `PH_Field_Assemble_ThermalMass` | 238 | `SUBROUTINE PH_Field_Assemble_ThermalMass(coords, conn, density, heat_capacity, &` |
| SUBROUTINE | `PH_Field_Assemble_HeatSource` | 359 | `SUBROUTINE PH_Field_Assemble_HeatSource(coords, conn, heat_gen_rate, &` |
| SUBROUTINE | `PH_Field_Apply_ThermalBC_Dirichlet` | 402 | `SUBROUTINE PH_Field_Apply_ThermalBC_Dirichlet(K_global, F_global, &` |
| SUBROUTINE | `PH_Field_Apply_ThermalBC_Neumann` | 457 | `SUBROUTINE PH_Field_Apply_ThermalBC_Neumann(F_global, coords, conn, &` |
| SUBROUTINE | `PH_Field_Apply_ThermalBC_Robin` | 570 | `SUBROUTINE PH_Field_Apply_ThermalBC_Robin(K_global, F_global, coords, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
