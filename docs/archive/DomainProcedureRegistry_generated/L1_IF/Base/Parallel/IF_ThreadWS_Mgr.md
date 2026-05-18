# `IF_ThreadWS_Mgr.f90`

- **Source**: `L1_IF/Base/Parallel/IF_ThreadWS_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_ThreadWS_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_ThreadWS_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_ThreadWS`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Base/Parallel`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/Parallel/IF_ThreadWS_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ThreadWSCriticalSection` (lines 28–31)

```fortran
  TYPE, PUBLIC :: ThreadWSCriticalSection
    INTEGER(i4) :: lock_data(CRITICAL_LOCK_SIZE) = 0
    LOGICAL :: initialized = .FALSE.
  END TYPE ThreadWSCriticalSection
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_ThreadWS_Init` | 39 | `SUBROUTINE IF_ThreadWS_Init(thread_ws, n_threads, n_real_1d, n_real_2d, &` |
| SUBROUTINE | `IF_ThreadWS_Destroy` | 91 | `SUBROUTINE IF_ThreadWS_Destroy(thread_ws)` |
| FUNCTION | `IF_ThreadWS_GetLocalArray` | 113 | `FUNCTION IF_ThreadWS_GetLocalArray(thread_ws, thread_id, array_name, status) RESULT(ptr)` |
| SUBROUTINE | `IF_ThreadWS_AggregateReal1D` | 171 | `SUBROUTINE IF_ThreadWS_AggregateReal1D(thread_ws, array_index, global_array, &` |
| SUBROUTINE | `IF_ThreadWS_RegisterArray` | 223 | `SUBROUTINE IF_ThreadWS_RegisterArray(thread_ws, name, array_type, &` |
| SUBROUTINE | `IF_ThreadWS_ResetAll` | 266 | `SUBROUTINE IF_ThreadWS_ResetAll(thread_ws, status)` |
| SUBROUTINE | `IF_ThreadWS_AtomicAdd` | 301 | `SUBROUTINE IF_ThreadWS_AtomicAdd(value, increment)` |
| SUBROUTINE | `IF_ThreadWS_AtomicAddInt` | 311 | `SUBROUTINE IF_ThreadWS_AtomicAddInt(ivalue, increment)` |
| SUBROUTINE | `IF_ThreadWS_EnterCritical` | 321 | `SUBROUTINE IF_ThreadWS_EnterCritical(lock)` |
| SUBROUTINE | `IF_ThreadWS_ExitCritical` | 330 | `SUBROUTINE IF_ThreadWS_ExitCritical(lock)` |
| SUBROUTINE | `IF_ThreadWS_SetCurrentThread` | 342 | `SUBROUTINE IF_ThreadWS_SetCurrentThread(thread_ws, thread_id, status)` |
| FUNCTION | `IF_ThreadWS_GetCurrentThread` | 364 | `FUNCTION IF_ThreadWS_GetCurrentThread(thread_ws, status) RESULT(thread_id)` |
| FUNCTION | `ITOCHAR` | 386 | `FUNCTION ITOCHAR(i) RESULT(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
