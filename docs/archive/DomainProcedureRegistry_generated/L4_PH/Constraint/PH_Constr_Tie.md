# `PH_Constr_Tie.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Tie.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Constr_Tie`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Tie`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr_Tie`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Tie.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_TieCore_FindNearestArgs` (lines 52–65)

```fortran
  TYPE :: PH_Constr_TieCore_FindNearestArgs
    ! ---- ----
    TYPE(Tie_Constraint_Params), POINTER :: params => NULL()  ! parameter / descriptor ptr

    ! ---- ----
    REAL(wp) :: slave_pos(3) = 0.0_wp  ! slave node position
    REAL(wp), POINTER :: master_coords(:,:) => NULL()  !! (3, n_nodes)
    INTEGER(i4), POINTER :: connectivity(:,:) => NULL()  !! (nodes_per_elem, n_elem)

    ! ---- ----
    INTEGER(i4) :: nearest_elem       = 0_i4        !! ID
    REAL(wp)    :: projection_coords(3) = 0.0_wp  ! projected master coordinates
    REAL(wp)    :: distance             = 0.0_wp  ! closest-point distance
  END TYPE PH_Constr_TieCore_FindNearestArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_TieCore_BuildNodePair` | 69 | `SUBROUTINE PH_Constr_TieCore_BuildNodePair(slave_id, master_elem, connectivity, &` |
| SUBROUTINE | `PH_Constr_TieCore_CalcElemCenterDistance` | 100 | `SUBROUTINE PH_Constr_TieCore_CalcElemCenterDistance(point, coords, elem_nodes, &` |
| SUBROUTINE | `PH_Constr_TieCore_CalcWeights` | 128 | `SUBROUTINE PH_Constr_TieCore_CalcWeights(params, surface_pair)` |
| SUBROUTINE | `PH_Constr_TieCore_ComputeViolation` | 160 | `SUBROUTINE PH_Constr_TieCore_ComputeViolation(node_pair, u_slave, u_master, violation, status)` |
| SUBROUTINE | `PH_Constr_TieCore_FindNearestMasterElem` | 185 | `SUBROUTINE PH_Constr_TieCore_FindNearestMasterElem(params, slave_pos, master_coords, &` |
| SUBROUTINE | `PH_Constr_TieCore_UpdateWeights` | 221 | `SUBROUTINE PH_Constr_TieCore_UpdateWeights(node_pair, params, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
