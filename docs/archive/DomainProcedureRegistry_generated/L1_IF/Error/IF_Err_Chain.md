# `IF_Err_Chain.f90`

- **Source**: `L1_IF/Error/IF_Err_Chain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Err_Chain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Err_Chain`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Err_Chain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Error`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Error/IF_Err_Chain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ErrorChainStats` (lines 83–89)

```fortran
  TYPE, PUBLIC :: ErrorChainStats
    INTEGER(i4) :: total_propagated = 0_i4
    INTEGER(i4) :: total_wrapped    = 0_i4
    INTEGER(i4) :: total_halted     = 0_i4
    INTEGER(i4) :: max_severity_seen = IF_ERROR_SEVERITY_INFO
    LOGICAL     :: initialized = .FALSE.
  END TYPE ErrorChainStats
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UFC_Err_Chain_Init` | 98 | `SUBROUTINE UFC_Err_Chain_Init()` |
| SUBROUTINE | `UFC_Err_Propagate` | 122 | `SUBROUTINE UFC_Err_Propagate(source, target, caller_name)` |
| SUBROUTINE | `UFC_Err_Wrap` | 168 | `SUBROUTINE UFC_Err_Wrap(source, target, new_code, wrapper_name, extra_msg)` |
| FUNCTION | `UFC_Err_Gate_Check` | 225 | `FUNCTION UFC_Err_Gate_Check(status, threshold_severity) RESULT(action)` |
| FUNCTION | `UFC_Err_Get_Layer` | 267 | `FUNCTION UFC_Err_Get_Layer(error_code) RESULT(layer_id)` |
| SUBROUTINE | `UFC_Err_Chain_Summary` | 295 | `SUBROUTINE UFC_Err_Chain_Summary(stats)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
