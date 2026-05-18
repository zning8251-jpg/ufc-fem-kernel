# `PH_Ldbc_Brg.f90`

- **Source**: `L4_PH/LoadBC/PH_Ldbc_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Ldbc_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Ldbc_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Ldbc`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Ldbc_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Ldbc_CSR_System_Type` (lines 34–37)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_CSR_System_Type
    TYPE(NM_CSR_Type), POINTER :: K_csr => NULL()
    REAL(wp), CONTIGUOUS, POINTER :: F(:) => NULL()
  END TYPE PH_Ldbc_CSR_System_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Ldbc_Apply_Dense_Scalar` | 55 | `SUBROUTINE PH_Ldbc_Apply_Dense_Scalar(K, R, dof_indices, prescribed_values, &` |
| SUBROUTINE | `PH_Ldbc_Apply_Dense_Struct` | 103 | `SUBROUTINE PH_Ldbc_Apply_Dense_Struct(system, desc, ctx, status)` |
| SUBROUTINE | `PH_Ldbc_Apply_Dirichlet_FromDesc` | 180 | `SUBROUTINE PH_Ldbc_Apply_Dirichlet_FromDesc(system, desc, bc_ctx, status)` |
| SUBROUTINE | `PH_Ldbc_Apply_Neumann_FromDesc` | 190 | `SUBROUTINE PH_Ldbc_Apply_Neumann_FromDesc(system, desc, status)` |
| SUBROUTINE | `PH_Ldbc_Apply_Penalty_CSR_FromDesc` | 240 | `SUBROUTINE PH_Ldbc_Apply_Penalty_CSR_FromDesc(system_csr, desc, bc_ctx, status)` |
| SUBROUTINE | `PH_Ldbc_Enforce_Penalty_FromDesc` | 280 | `SUBROUTINE PH_Ldbc_Enforce_Penalty_FromDesc(system, desc, bc_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 48–51 | `INTERFACE PH_Ldbc_Apply` |
