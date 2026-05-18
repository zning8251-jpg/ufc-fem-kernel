# `MD_Out_VarReg.f90`

- **Source**: `L3_MD/Output/MD_Out_VarReg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Out_VarReg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_VarReg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out_VarReg`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_VarReg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `OutVarRegistry` (lines 40–51)

```fortran
  type, public :: OutVarRegistry
    type(OutVarDesc), allocatable :: vars(:)
    integer(i4) :: num_vars = 0_i4
    LOGICAL :: init = .false.
  contains
    procedure, public :: Init => OutVarReg_Init
    procedure, public :: GetVarDesc => OutVarReg_GetVarDesc
    procedure, public :: GetVarName => OutVarReg_GetVarName
    procedure, public :: IsValidVar => OutVarReg_IsValidVar
    procedure, public :: GetVarLocation => OutVarReg_GetVarLocation
    procedure, public :: GetVarRank => OutVarReg_GetVarRank
  end type OutVarRegistry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `OutVarReg_Init` | 61 | `subroutine OutVarReg_Init(this, status)` |
| SUBROUTINE | `RegisterVar` | 112 | `subroutine RegisterVar(reg, var_id, var_name, var_desc, location, rank, n_comp, support_field, support_history)` |
| FUNCTION | `OutVarReg_GetVarDesc` | 147 | `function OutVarReg_GetVarDesc(this, var_id) result(var_desc)` |
| FUNCTION | `OutVarReg_GetVarName` | 168 | `function OutVarReg_GetVarName(this, var_id) result(var_name)` |
| FUNCTION | `OutVarReg_IsValidVar` | 185 | `function OutVarReg_IsValidVar(this, var_id) result(is_valid)` |
| FUNCTION | `OutVarReg_GetVarLocation` | 202 | `function OutVarReg_GetVarLocation(this, var_id) result(location)` |
| FUNCTION | `OutVarReg_GetVarRank` | 219 | `function OutVarReg_GetVarRank(this, var_id) result(rank)` |
| SUBROUTINE | `OutVarReg_Init` | 236 | `subroutine OutVarReg_Init(status)` |
| FUNCTION | `OutVarReg_GetVarDesc` | 241 | `function OutVarReg_GetVarDesc(var_id) result(var_desc)` |
| FUNCTION | `OutVarReg_GetVarName` | 247 | `function OutVarReg_GetVarName(var_id) result(var_name)` |
| FUNCTION | `OutVarReg_IsValidVar` | 253 | `function OutVarReg_IsValidVar(var_id) result(is_valid)` |
| FUNCTION | `OutVarReg_GetVarLocation` | 259 | `function OutVarReg_GetVarLocation(var_id) result(location)` |
| FUNCTION | `OutVarReg_GetVarRank` | 265 | `function OutVarReg_GetVarRank(var_id) result(rank)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
