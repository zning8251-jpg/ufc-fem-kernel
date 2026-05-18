# `AP_StorageCfg_Brg.f90`

- **Source**: `L6_AP/Bridge/AP_StorageCfg_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_StorageCfg_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_StorageCfg_Brg`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_StorageCfg`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Bridge/AP_StorageCfg_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `StorageCfgBundle` (lines 23–28)

```fortran
  TYPE :: StorageCfgBundle
    INTEGER(i4) :: pool_size_mb     = 256_i4
    REAL(wp)    :: spill_threshold  = 0.85_wp
    INTEGER(i4) :: lru_window       = 64_i4
    INTEGER(i4) :: checkpoint_interval = 0_i4
  END TYPE StorageCfgBundle
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_StorageCfg_Inject` | 32 | `SUBROUTINE AP_StorageCfg_Inject(cfg_state, bundle, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
