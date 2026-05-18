# `PH_Constr_MPC.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_MPC.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Constr_MPC`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_MPC`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr_MPC`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_MPC.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_MPCCore_PenaltyArgs` (lines 53–59)

```fortran
  TYPE :: PH_Constr_MPCCore_PenaltyArgs
    TYPE(PH_Constr_MPC_Def), POINTER :: mpc     => NULL()  !! MPC
    INTEGER(i4) :: n_dof_total = 0_i4  ! total constraint DoFs
    REAL(wp)    :: kappa       = 1.0e6_wp  !! κ
    REAL(wp), POINTER :: K(:,:) => NULL()  !! INOUT
    REAL(wp), POINTER :: R(:)   => NULL()  !! INOUT
  END TYPE PH_Constr_MPCCore_PenaltyArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_MPCCore_AssembleLagrangeBlock` | 63 | `SUBROUTINE PH_Constr_MPCCore_AssembleLagrangeBlock(mpc, n_dof_total, C_row)` |
| SUBROUTINE | `PH_Constr_MPCCore_AssembleMatrix` | 79 | `SUBROUTINE PH_Constr_MPCCore_AssembleMatrix(constraints, num_constraints, &` |
| SUBROUTINE | `PH_Constr_MPCCore_AssemblePenalty` | 112 | `SUBROUTINE PH_Constr_MPCCore_AssemblePenalty(mpc, n_dof_total, kappa, K, R)` |
| SUBROUTINE | `PH_Constr_MPCCore_CheckConsistency` | 144 | `SUBROUTINE PH_Constr_MPCCore_CheckConsistency(mpc, is_consistent, status)` |
| SUBROUTINE | `PH_Constr_MPCCore_ComputeViolation` | 172 | `SUBROUTINE PH_Constr_MPCCore_ComputeViolation(mpc, u_nodal, violation, status)` |
| SUBROUTINE | `PH_Constr_MPCCore_Opt` | 197 | `SUBROUTINE PH_Constr_MPCCore_Opt(mpc, optimization_level, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
