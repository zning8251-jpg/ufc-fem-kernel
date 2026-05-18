# `PH_Cont_CSR.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_CSR.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_CSR`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_CSR`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_CSR`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_CSR.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ContCSR_AssembleStiffness` | 41 | `SUBROUTINE PH_ContCSR_AssembleStiffness(n_contacts, node_ids, normals, &` |
| SUBROUTINE | `PH_ContCSR_AssembleStiffnessWithFriction` | 155 | `SUBROUTINE PH_ContCSR_AssembleStiffnessWithFriction(n_contacts, node_ids, normals, &` |
| SUBROUTINE | `PH_ContCSR_AssembleResidual` | 296 | `SUBROUTINE PH_ContCSR_AssembleResidual(n_contacts, node_ids, normals, &` |
| SUBROUTINE | `PH_ContCSR_ComputeTangentStiffness` | 367 | `SUBROUTINE PH_ContCSR_ComputeTangentStiffness(normal, penalty_stiffness, &` |
| SUBROUTINE | `PH_ContCSR_ComputeContactForceVector` | 399 | `SUBROUTINE PH_ContCSR_ComputeContactForceVector(normal, penetration, &` |
| SUBROUTINE | `PH_ContCSR_AssembleStiffness_Parallel` | 431 | `SUBROUTINE PH_ContCSR_AssembleStiffness_Parallel(n_contacts, node_ids, normals, &` |
| SUBROUTINE | `PH_ContCSR_AssembleResidual_Parallel` | 537 | `SUBROUTINE PH_ContCSR_AssembleResidual_Parallel(n_contacts, node_ids, normals, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
