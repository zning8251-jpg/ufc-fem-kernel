# `NM_AI_PrecondAlgo.f90`

- **Source**: `L2_NM/Solver/AI/NM_AI_PrecondAlgo.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_AI_PrecondAlgo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_AI_PrecondAlgo`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_AI_PrecondAlgo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/AI/NM_AI_PrecondAlgo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_AI_Precond_Type` (lines 30–52)

```fortran
  TYPE, PUBLIC :: NM_AI_Precond_Type
    !-------------------------------------------------------------------------
    ! Algorithm configuration (冷数据，Write-Once)
    !-------------------------------------------------------------------------
    INTEGER(i4) :: precond_type = 0        ! 0=ILU(0), 1=SA-AMG, 2=AI-GNN
    INTEGER(i4) :: fill_level = 0          ! ILU fill level
    REAL(wp)    :: drop_tolerance = 1e-10_wp ! Drop tolerance for ILU
    
    ! AI model parameters (for GNN-based preconditioner)
    INTEGER(i4) :: gnn_num_layers = 3      ! Number of GNN layers
    INTEGER(i4) :: gnn_hidden_dim = 64     ! Hidden dimension
    REAL(wp), ALLOCATABLE :: gnn_weights(:) ! Neural network weights
    
    ! Graph structure (for AMG coarsening)
    INTEGER(i4) :: num_levels = 0          ! Number of multigrid levels
    INTEGER(i4), ALLOCATABLE :: level_ptr(:) ! Level pointers
    
    ! Performance metrics
    REAL(wp)    :: setup_time = 0.0_wp     ! Setup time (seconds)
    REAL(wp)    :: apply_time = 0.0_wp     ! Apply time per iteration
    INTEGER(i4) :: total_applies = 0       ! Total number of applies
    
  END TYPE NM_AI_Precond_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_AI_Precond_Init` | 60 | `SUBROUTINE NM_AI_Precond_Init(precond, matrix_csr, precond_type, status)` |
| SUBROUTINE | `NM_AI_Precond_Finalize` | 85 | `SUBROUTINE NM_AI_Precond_Finalize(precond, status)` |
| SUBROUTINE | `NM_AI_Precond_Apply` | 108 | `SUBROUTINE NM_AI_Precond_Apply(precond, vec_in, vec_out, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
