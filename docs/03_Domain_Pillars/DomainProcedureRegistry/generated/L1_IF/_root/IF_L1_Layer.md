# `IF_L1_Layer.f90`

- **Source**: `L1_IF/IF_L1_Layer.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_L1_Layer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_L1_Layer`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_L1_Layer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/_root/IF_L1_Layer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_L1_LayerContainer` (lines 56–68)

```fortran
  TYPE, PUBLIC :: IF_L1_LayerContainer
    TYPE(IF_Error_Domain)       :: error       ! Error handling service
    TYPE(IF_Log_Domain)         :: log         ! Logging service
    TYPE(IF_Monitor_Domain), POINTER :: monitor => NULL()  ! Observability (? g_if_monitor_domain)
    TYPE(IF_IO_Domain)          :: io          ! File IO service
    TYPE(IF_Memory_Domain)    :: memory      ! Memory pool service
    TYPE(IF_Persist_Domain)   :: persist     ! Persistence/backup service
    TYPE(IF_Base_Domain)     :: base        ! Device/math/metadata service
    LOGICAL                   :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE IF_L1_LayerContainer
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 76 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 99 | `SUBROUTINE Init(this, nThreads, workDir, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
