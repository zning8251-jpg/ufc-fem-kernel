# `IF_Mon_Core.f90`

- **Source**: `L1_IF/Monitor/IF_Mon_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mon_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mon_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mon`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Monitor`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Monitor/IF_Mon_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Monitor_Domain` (lines 52–59)

```fortran
  TYPE, PUBLIC :: IF_Monitor_Domain
    TYPE(MonitorDesc)  :: desc
    TYPE(MonitorState) :: state
    LOGICAL            :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE IF_Monitor_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `IF_Monitor_GetDomain` | 72 | `FUNCTION IF_Monitor_GetDomain() RESULT(dom)` |
| SUBROUTINE | `Init` | 80 | `SUBROUTINE Init(this, status)` |
| SUBROUTINE | `Finalize` | 98 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Monitor_Init` | 112 | `SUBROUTINE Monitor_Init(trace_level, max_trace_records)` |
| SUBROUTINE | `Monitor_Finalize` | 126 | `SUBROUTINE Monitor_Finalize()` |
| SUBROUTINE | `CollectMetrics` | 133 | `SUBROUTINE CollectMetrics(metric_name, value)` |
| SUBROUTINE | `RecordTrace` | 160 | `SUBROUTINE RecordTrace(data_id, data_name, layer, domain, checksum)` |
| SUBROUTINE | `ExportTrace` | 171 | `SUBROUTINE ExportTrace(filename)` |
| SUBROUTINE | `StartSpan` | 179 | `SUBROUTINE StartSpan(span_name, span_id)` |
| SUBROUTINE | `EndSpan` | 189 | `SUBROUTINE EndSpan(span_id)` |
| SUBROUTINE | `ChainMonitor_Init` | 197 | `SUBROUTINE ChainMonitor_Init()` |
| SUBROUTINE | `ChainMonitor_Record` | 204 | `SUBROUTINE ChainMonitor_Record(chain_type, event_name)` |
| SUBROUTINE | `ChainMonitor_Report` | 212 | `SUBROUTINE ChainMonitor_Report(unit)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
