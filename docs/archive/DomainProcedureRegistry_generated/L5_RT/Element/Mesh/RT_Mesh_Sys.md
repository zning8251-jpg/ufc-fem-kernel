# `RT_Mesh_Sys.f90`

- **Source**: `L5_RT/Element/Mesh/RT_Mesh_Sys.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Mesh_Sys`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mesh_Sys`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mesh`
- **第四段角色（四段式）**: `_Sys`
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/Mesh/RT_Mesh_Sys.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mesh_Cfg` (lines 136–145)

```fortran
  type, public :: RT_Mesh_Cfg
    logical :: autoInitElems = .true.
    logical :: autoInitMats = .true.
    logical :: autoInitSects = .true.
    logical :: enableElemReg = .true.
    integer(i4) :: maxElemFam = 10_i4
  contains
    procedure, public :: Init => RT_Mesh_CfgInit
    procedure, public :: Valid => RT_Mesh_CfgValid
  end type RT_Mesh_Cfg
```

### `RT_MeshSys` (lines 150–166)

```fortran
  type, public :: RT_MeshSys
    logical :: inited = .false.
    type(RT_Mesh_Cfg) :: cfg
    type(ErrorStatusType) :: stat
  contains
    procedure, public :: Init => RT_Mesh_SysInitType
    procedure, public :: Clean => RT_Mesh_SysCleanType
    procedure, public :: RegVars => RT_Mesh_SysRegVarsType
    procedure, public :: InitElems => RT_Mesh_SysInitElemsType
    procedure, public :: InitMats => RT_Mesh_SysInitMatsType
    procedure, public :: InitSects => RT_Mesh_SysInitSectsType
    procedure, public :: CompElem => RT_Mesh_SysCompElemType
    procedure, public :: GetElemCnt => RT_Mesh_SysGetElemCntType
    procedure, public :: GetNodeCnt => RT_Mesh_SysGetNodeCntType
    procedure, public :: GetBrg => RT_Mesh_SysGetBrgType
    procedure, public :: GetStat => RT_Mesh_SysGetStatType
  end type RT_MeshSys
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mesh_MgrInit` | 178 | `subroutine RT_Mesh_MgrInit(maxMeshes, status)` |
| SUBROUTINE | `RT_Mesh_MgrClean` | 185 | `subroutine RT_Mesh_MgrClean(status)` |
| SUBROUTINE | `RT_Mesh_MgrReg` | 191 | `subroutine RT_Mesh_MgrReg(model, status)` |
| SUBROUTINE | `RT_Mesh_MgrGetStat` | 198 | `subroutine RT_Mesh_MgrGetStat(nMeshes, totalNodes, totalElems)` |
| SUBROUTINE | `RT_Mesh_CfgInit` | 210 | `subroutine RT_Mesh_CfgInit(this, autoInitElems, autoInitMats, &` |
| FUNCTION | `RT_Mesh_CfgValid` | 240 | `function RT_Mesh_CfgValid(this) result(valid)` |
| SUBROUTINE | `RT_Mesh_SysInitType` | 250 | `subroutine RT_Mesh_SysInitType(this, cfg, status)` |
| SUBROUTINE | `RT_Mesh_SysCleanType` | 298 | `subroutine RT_Mesh_SysCleanType(this, status)` |
| SUBROUTINE | `RT_Mesh_SysRegVarsType` | 327 | `subroutine RT_Mesh_SysRegVarsType(this, model, varCtx, status)` |
| SUBROUTINE | `RT_Mesh_SysInitElemsType` | 354 | `subroutine RT_Mesh_SysInitElemsType(this, status)` |
| SUBROUTINE | `RT_Mesh_SysInitMatsType` | 374 | `subroutine RT_Mesh_SysInitMatsType(this, status)` |
| SUBROUTINE | `RT_Mesh_SysInitSectsType` | 394 | `subroutine RT_Mesh_SysInitSectsType(this, status)` |
| SUBROUTINE | `RT_Mesh_SysCompElemType` | 414 | `subroutine RT_Mesh_SysCompElemType(this, ElemType, Formul, Ctx, state_in, &` |
| FUNCTION | `RT_Mesh_SysGetElemCntType` | 443 | `function RT_Mesh_SysGetElemCntType(this) result(count)` |
| FUNCTION | `RT_Mesh_SysGetNodeCntType` | 450 | `function RT_Mesh_SysGetNodeCntType(this) result(count)` |
| FUNCTION | `RT_Mesh_SysGetBrgType` | 457 | `function RT_Mesh_SysGetBrgType(this) result(bridge)` |
| FUNCTION | `RT_Mesh_SysGetStatType` | 464 | `function RT_Mesh_SysGetStatType(this) result(stat)` |
| SUBROUTINE | `RT_MeshSys_Init` | 474 | `subroutine RT_MeshSys_Init(maxMeshes, status)` |
| SUBROUTINE | `RT_MeshSys_Clean` | 488 | `subroutine RT_MeshSys_Clean(status)` |
| SUBROUTINE | `RT_MeshSys_RegModel` | 500 | `subroutine RT_MeshSys_RegModel(model, varCtx, status)` |
| SUBROUTINE | `RT_Mesh_SysGetStat` | 516 | `subroutine RT_Mesh_SysGetStat(nMeshes, totalNodes, totalElems)` |
| FUNCTION | `RT_MeshSys_Valid` | 524 | `function RT_MeshSys_Valid(model, status) result(valid)` |
| SUBROUTINE | `RT_Mesh_Init` | 544 | `subroutine RT_Mesh_Init(cfg, status)` |
| SUBROUTINE | `RT_Mesh_Clean` | 551 | `subroutine RT_Mesh_Clean(status)` |
| SUBROUTINE | `RT_Mesh_RegVars` | 557 | `subroutine RT_Mesh_RegVars(model, varCtx, status)` |
| SUBROUTINE | `RT_Mesh_InitElems` | 565 | `subroutine RT_Mesh_InitElems(status)` |
| SUBROUTINE | `RT_Mesh_InitMats` | 571 | `subroutine RT_Mesh_InitMats(status)` |
| SUBROUTINE | `RT_Mesh_InitSects` | 577 | `subroutine RT_Mesh_InitSects(status)` |
| SUBROUTINE | `RT_Mesh_CompElem` | 583 | `subroutine RT_Mesh_CompElem(ElemType, Formul, Ctx, state_in, &` |
| FUNCTION | `RT_Mesh_GetElemCnt` | 598 | `function RT_Mesh_GetElemCnt() result(count)` |
| FUNCTION | `RT_Mesh_GetNodeCnt` | 604 | `function RT_Mesh_GetNodeCnt() result(count)` |
| FUNCTION | `RT_Mesh_GetBrg` | 610 | `function RT_Mesh_GetBrg() result(bridge)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
