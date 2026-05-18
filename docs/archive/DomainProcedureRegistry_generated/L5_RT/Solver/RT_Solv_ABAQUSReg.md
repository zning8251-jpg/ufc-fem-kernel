# `RT_Solv_ABAQUSReg.f90`

- **Source**: `L5_RT/Solver/RT_Solv_ABAQUSReg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Solv_ABAQUSReg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_ABAQUSReg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_ABAQUSReg`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_ABAQUSReg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ABAQUS_SolverRegistryEntry` (lines 36–52)

```fortran
    TYPE, PUBLIC :: ABAQUS_SolverRegistryEntry
        INTEGER(i4) :: solver_id = 0
        CHARACTER(LEN=64) :: abaqus_keyword = ""
        CHARACTER(LEN=64) :: abaqus_name = ""
        INTEGER(i4) :: category = 0
        CHARACTER(LEN=256) :: description = ""
        CHARACTER(LEN=128) :: parser_module = ""
        CHARACTER(LEN=128) :: unified_parse_proc = ""
        LOGICAL :: is_linear = .FALSE.
        LOGICAL :: is_dynamic = .FALSE.
        LOGICAL :: supports_nonlinear = .TRUE.
        LOGICAL :: supports_contact = .TRUE.
        LOGICAL :: supports_parallel = .TRUE.
        CHARACTER(LEN=64) :: default_algorithm = ""
        REAL(wp) :: default_tolerance = 1.0e-6_wp
        INTEGER(i4) :: default_max_iterations = 100
    END TYPE ABAQUS_SolverRegistryEntry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `GetSolverById` | 109 | `FUNCTION GetSolverById(solver_id) RESULT(solver_entry)` |
| FUNCTION | `GetSolverByKeyword` | 124 | `FUNCTION GetSolverByKeyword(keyword) RESULT(solver_entry)` |
| SUBROUTINE | `GetSolverCapabilities` | 146 | `SUBROUTINE GetSolverCapabilities(solver_id, is_linear, is_dynamic, supports_nonlinear, supports_contact, supports_parallel)` |
| FUNCTION | `GetSolverCount` | 160 | `FUNCTION GetSolverCount() RESULT(count)` |
| FUNCTION | `LOGICAL_TO_STRING` | 166 | `FUNCTION LOGICAL_TO_STRING(log_val) RESULT(str_val)` |
| SUBROUTINE | `PrintSolverRegistry` | 177 | `SUBROUTINE PrintSolverRegistry(unit)` |
| SUBROUTINE | `to_upper` | 202 | `SUBROUTINE to_upper(str)` |
| SUBROUTINE | `ValidateSolverConfig` | 215 | `SUBROUTINE ValidateSolverConfig(solver_type, tolerance, max_iterations, is_valid, error_msg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
