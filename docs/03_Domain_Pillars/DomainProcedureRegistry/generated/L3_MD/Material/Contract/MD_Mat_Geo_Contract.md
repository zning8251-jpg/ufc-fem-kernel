# `MD_Mat_Geo_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Geo_Contract.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Geo_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Geo_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Geo_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Geo_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `DPPropertiesManager` (lines 67–74)

```fortran
    TYPE, PUBLIC :: DPPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(DPProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => DPPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => DPPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => DPPropertiesManager_Clear
    END TYPE DPPropertiesManager
```

### `MCPropertiesManager` (lines 116–123)

```fortran
    TYPE, PUBLIC :: MCPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(MCProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => MCPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => MCPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => MCPropertiesManager_Clear
    END TYPE MCPropertiesManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DPProperties_Init_Base` | 138 | `SUBROUTINE DPProperties_Init_Base(this)` |
| SUBROUTINE | `DPProperties_Init` | 144 | `SUBROUTINE DPProperties_Init(this, beta, kappa, psi, status)` |
| FUNCTION | `DPProperties_Valid_Fn` | 177 | `FUNCTION DPProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `DPProperties_Clear` | 191 | `SUBROUTINE DPProperties_Clear(this)` |
| FUNCTION | `DPProperties_ComputeYieldFunction` | 212 | `FUNCTION DPProperties_ComputeYieldFunction(this, I1, J2) RESULT(f)` |
| SUBROUTINE | `DPPropertiesManager_Add` | 236 | `SUBROUTINE DPPropertiesManager_Add(this, prop, status)` |
| FUNCTION | `DPPropertiesManager_Find` | 261 | `FUNCTION DPPropertiesManager_Find(this, index) RESULT(prop)` |
| SUBROUTINE | `DPProperties_Clear` | 273 | `SUBROUTINE DPProperties_Clear(this)` |
| SUBROUTINE | `md_mat_get_param_value` | 288 | `SUBROUTINE md_mat_get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `MD_Mat_Dr_Un_Configure` | 307 | `SUBROUTINE MD_Mat_Dr_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_Mat_Dr_Un_Parse` | 322 | `SUBROUTINE MD_Mat_Dr_Un_Parse(material_type, ast_node, druckerPrager, material_name, status)` |
| SUBROUTINE | `Parse_DRUCKER_PRAGER_Keyword` | 340 | `SUBROUTINE Parse_DRUCKER_PRAGER_Keyword(ast_node, druckerPrager, material_name, status)` |
| SUBROUTINE | `Va_DR_PR_PhysicalValues` | 450 | `SUBROUTINE Va_DR_PR_PhysicalValues(druckerPrager, status)` |
| SUBROUTINE | `Valid_DRUCKER_PRAGER_Keyword` | 467 | `SUBROUTINE Valid_DRUCKER_PRAGER_Keyword(druckerPrager, material_name, model, status)` |
| SUBROUTINE | `Valid_DRUCKER_PRAGER_Mat` | 494 | `SUBROUTINE Valid_DRUCKER_PRAGER_Mat(material_name, model, status)` |
| SUBROUTINE | `MCProperties_Init_Base` | 508 | `SUBROUTINE MCProperties_Init_Base(this)` |
| SUBROUTINE | `MCProperties_Init` | 514 | `SUBROUTINE MCProperties_Init(this, phi, c, psi, status)` |
| FUNCTION | `MCProperties_Valid_Fn` | 548 | `FUNCTION MCProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `MCProperties_Clear` | 560 | `SUBROUTINE MCProperties_Clear(this)` |
| FUNCTION | `MCProperties_ComputeYieldFunction` | 578 | `FUNCTION MCProperties_ComputeYieldFunction(this, I1, J2, theta) RESULT(f)` |
| SUBROUTINE | `MCPropertiesManager_Add` | 598 | `SUBROUTINE MCPropertiesManager_Add(this, prop, status)` |
| FUNCTION | `MCPropertiesManager_Find` | 623 | `FUNCTION MCPropertiesManager_Find(this, index) RESULT(prop)` |
| SUBROUTINE | `MCPropertiesManager_Clear` | 635 | `SUBROUTINE MCPropertiesManager_Clear(this)` |
| SUBROUTINE | `MD_Mat_Mo_Un_Configure` | 647 | `SUBROUTINE MD_Mat_Mo_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_Mat_Mo_Un_Parse` | 662 | `SUBROUTINE MD_Mat_Mo_Un_Parse(material_type, ast_node, mohrCoulomb, material_name, status)` |
| SUBROUTINE | `Parse_MOHR_COULOMB_Keyword` | 680 | `SUBROUTINE Parse_MOHR_COULOMB_Keyword(ast_node, mohrCoulomb, material_name, status)` |
| SUBROUTINE | `Va_MO_CO_PhysicalValues` | 746 | `SUBROUTINE Va_MO_CO_PhysicalValues(mohrCoulomb, status)` |
| SUBROUTINE | `Valid_MOHR_COULOMB_Keyword` | 768 | `SUBROUTINE Valid_MOHR_COULOMB_Keyword(mohrCoulomb, material_name, model, status)` |
| SUBROUTINE | `Valid_MOHR_COULOMB_Mat` | 795 | `SUBROUTINE Valid_MOHR_COULOMB_Mat(material_name, model, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
