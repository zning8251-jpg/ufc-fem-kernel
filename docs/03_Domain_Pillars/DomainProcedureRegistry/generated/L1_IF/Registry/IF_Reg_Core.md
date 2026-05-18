# `IF_Reg_Core.f90`

- **Source**: `L1_IF/Registry/IF_Reg_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Reg_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Reg_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Reg`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Registry/IF_Reg_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ModelEntry` (lines 68–80)

```fortran
  TYPE :: ModelEntry
    INTEGER(i8)              :: model_id = 0
    CHARACTER(IF_MAX_NAME_LEN)     :: model_name = ''
    CHARACTER(IF_MAX_NAME_LEN)     :: model_type = ''      ! AI, Classic, User
    CHARACTER(32)               :: version = '0.0.0'
    INTEGER(i4) :: version_count = 0
    REAL(wp)                    :: benchmark_score = 0.0_wp
    REAL(wp)                    :: baseline_score = 0.0_wp
    LOGICAL                     :: active = .FALSE.
    INTEGER(i8)              :: created_time = 0
    INTEGER(i8)              :: updated_time = 0
    CHARACTER(IF_MAX_NAME_LEN)     :: version_history(IF_MAX_VERSION_HISTORY)
  END TYPE ModelEntry
```

### `AuditLogEntry` (lines 86–95)

```fortran
  TYPE :: AuditLogEntry
    INTEGER(i8)              :: entry_id = 0
    INTEGER(i8)              :: model_id = 0
    CHARACTER(32)               :: operation = ''       ! REGISTER, UPDATE, ROLLBACK
    CHARACTER(32)               :: old_version = ''
    CHARACTER(32)               :: new_version = ''
    CHARACTER(256)              :: description = ''
    INTEGER(i8)              :: timestamp = 0
    REAL(wp)                    :: performance_delta = 0.0_wp
  END TYPE AuditLogEntry
```

### `ModelRegistry` (lines 101–107)

```fortran
  TYPE :: ModelRegistry
    TYPE(ModelEntry)            :: models(IF_MAX_MODELS)
    INTEGER(i4) :: n_models = 0
    TYPE(AuditLogEntry)         :: audit_log(IF_MAX_AUDIT_ENTRIES)
    INTEGER(i4) :: n_audit_entries = 0
    LOGICAL                     :: initialized = .FALSE.
  END TYPE ModelRegistry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Governance_Init` | 116 | `SUBROUTINE Governance_Init()` |
| SUBROUTINE | `Governance_Finalize` | 123 | `SUBROUTINE Governance_Finalize()` |
| FUNCTION | `RegisterModel` | 129 | `FUNCTION RegisterModel(model_name, model_type, benchmark_score) RESULT(model_id)` |
| SUBROUTINE | `UnregisterModel` | 161 | `SUBROUTINE UnregisterModel(model_id)` |
| FUNCTION | `QueryModelRegistry` | 169 | `FUNCTION QueryModelRegistry(model_name) RESULT(model_id)` |
| SUBROUTINE | `IncrementModelVersion` | 183 | `SUBROUTINE IncrementModelVersion(model_id, new_benchmark)` |
| SUBROUTINE | `RollbackModelVersion` | 210 | `SUBROUTINE RollbackModelVersion(model_id, target_version)` |
| SUBROUTINE | `GetModelHistory` | 226 | `SUBROUTINE GetModelHistory(model_id, history, n_versions)` |
| FUNCTION | `CheckModelDegradation` | 242 | `FUNCTION CheckModelDegradation(model_id, threshold) RESULT(is_degraded)` |
| SUBROUTINE | `BenchmarkModel` | 262 | `SUBROUTINE BenchmarkModel(model_id, score)` |
| SUBROUTINE | `AlertDegradation` | 271 | `SUBROUTINE AlertDegradation(model_id, message)` |
| SUBROUTINE | `ModelAuditLog` | 287 | `SUBROUTINE ModelAuditLog(model_id, operation, old_version, new_version, description)` |
| SUBROUTINE | `QueryAuditLog` | 308 | `SUBROUTINE QueryAuditLog(model_id, entries, n_entries)` |
| SUBROUTINE | `ExportAuditReport` | 329 | `SUBROUTINE ExportAuditReport(filename)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
