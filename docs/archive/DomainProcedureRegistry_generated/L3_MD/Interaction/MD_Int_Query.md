# `MD_Int_Query.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Query.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Int_Query`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Query`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Query`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Query.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `contact_find_Elem_index` | 96 | `FUNCTION contact_find_Elem_index(part, id) RESULT(idx)` |
| FUNCTION | `contact_find_node_index_in_part` | 117 | `FUNCTION contact_find_node_index_in_part(part, nodeIdFind) RESULT(idx)` |
| FUNCTION | `contact_find_node_state_index` | 137 | `FUNCTION contact_find_node_state_index(nodeStates, nodeIdFind) RESULT(idx)` |
| FUNCTION | `contact_get_node_coord_curr` | 156 | `FUNCTION contact_get_node_coord_curr(part, nodeStates, id) RESULT(x)` |
| FUNCTION | `contact_dot3` | 178 | `FUNCTION contact_dot3(a, b) RESULT(val)` |
| SUBROUTINE | `UF_Contact_ApplyConstraint` | 187 | `SUBROUTINE UF_Contact_ApplyConstraint(contact_node, penalty_stiffness, &` |
| SUBROUTINE | `UF_Co_ComputeNormalForce_node` | 208 | `SUBROUTINE UF_Co_ComputeNormalForce_node(contact_node, penalty_stiffness, &` |
| SUBROUTINE | `UF_Co_ComputeNormalForce_scalar` | 228 | `SUBROUTINE UF_Co_ComputeNormalForce_scalar(penetration, penalty_stiffness, &` |
| SUBROUTINE | `UF_Contact_ComputeStiffness` | 246 | `SUBROUTINE UF_Contact_ComputeStiffness(contact_node, penalty_stiffness, &` |
| SUBROUTINE | `UF_Contact_ComputeTotalForce` | 273 | `SUBROUTINE UF_Contact_ComputeTotalForce(force_result, total_force, status)` |
| SUBROUTINE | `UF_Co_GetOutputStatistics` | 302 | `SUBROUTINE UF_Co_GetOutputStatistics(contact_pair, stats, status)` |
| SUBROUTINE | `UF_Co_Se_GetStatistics` | 319 | `SUBROUTINE UF_Co_Se_GetStatistics(search_result, stats, status)` |
| SUBROUTINE | `UF_Contact_UpdateState` | 334 | `SUBROUTINE UF_Contact_UpdateState(contact_node, new_coords, new_gap, &` |
| SUBROUTINE | `UF_ContactState_UpdateState` | 359 | `SUBROUTINE UF_ContactState_UpdateState(contact_node, gap, penetration, &` |
| SUBROUTINE | `UF_Co_ComputeTotalForce` | 385 | `SUBROUTINE UF_Co_ComputeTotalForce(normal_force, friction_force, &` |
| SUBROUTINE | `UF_Co_GetContactPressure` | 403 | `SUBROUTINE UF_Co_GetContactPressure(contact_node, contact_area, &` |
| SUBROUTINE | `UF_Co_GetSlipDistance` | 423 | `SUBROUTINE UF_Co_GetSlipDistance(contact_node, slip_distance, status)` |
| SUBROUTINE | `UF_Co_GetStatistics` | 437 | `SUBROUTINE UF_Co_GetStatistics(search_algorithm, n_candidates, &` |
| SUBROUTINE | `UF_Co_ComputePenaltyStiffnes` | 469 | `SUBROUTINE UF_Co_ComputePenaltyStiffnes(penalty_stiffness, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 46–48 | `INTERFACE UF_Contact_ComputeNormalForce` |
| 51–53 | `INTERFACE UF_ContactForce_ComputeNormalForce` |
| 56–58 | `INTERFACE UF_ContactForce_ComputeTotalForce` |
| 61–63 | `INTERFACE UF_Contact_GetOutputStatistics` |
| 66–68 | `INTERFACE UF_Contact_Search_GetStatistics` |
| 71–73 | `INTERFACE UF_ContactOutput_GetContactPressure` |
| 76–78 | `INTERFACE UF_ContactOutput_GetSlipDistance` |
| 81–83 | `INTERFACE UF_ContactSearch_GetStatistics` |
| 86–88 | `INTERFACE UF_ContactStiffness_ComputePenaltyStiffness` |
