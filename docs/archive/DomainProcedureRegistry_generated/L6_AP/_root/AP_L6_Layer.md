# `AP_L6_Layer.f90`

- **Source**: `L6_AP/AP_L6_Layer.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_L6_Layer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_L6_Layer`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_L6_Layer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/_root/AP_L6_Layer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_L6_LayerContainer` (lines 22–35)

```fortran
  TYPE, PUBLIC :: AP_L6_LayerContainer
    ! --- Domain instances (only available ones) ---
    TYPE(AP_Base_Domain)      :: base
    TYPE(AP_Input_Domain)     :: input
    TYPE(AP_Registry_Domain)  :: registry
    ! Note: Other domains temporarily excluded due to dependencies
    ! --- Layer-level metadata ---
    CHARACTER(LEN=256) :: jobName     = ' '
    REAL(wp)           :: jobStartTime = 0.0_wp
    LOGICAL            :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE AP_L6_LayerContainer
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_L6_Finalize` | 39 | `SUBROUTINE AP_L6_Finalize(this)` |
| SUBROUTINE | `AP_L6_Init` | 52 | `SUBROUTINE AP_L6_Init(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
