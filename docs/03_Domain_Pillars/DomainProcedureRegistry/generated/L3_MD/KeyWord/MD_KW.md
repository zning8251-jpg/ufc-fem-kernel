# `MD_KW.f90`

- **Source**: `L3_MD/KeyWord/MD_KW.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_Coverage_Type`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `KW_Coverage_Report` (lines 44–63)

```fortran
  type, public :: KW_Coverage_Report
    integer(i4) :: n_p0_total = 0_i4              ! P0 total keywords n_p0_total  ? ?
    integer(i4) :: n_p0_covered = 0_i4            ! P0 covered keywords n_p0_covered  ? ?
    integer(i4) :: n_p1_total = 0_i4              ! P1 total keywords n_p1_total  ? ?
    integer(i4) :: n_p1_covered = 0_i4            ! P1 covered keywords n_p1_covered  ? ?
    integer(i4) :: n_p2_total = 0_i4              ! P2 total keywords n_p2_total  ? ?
    integer(i4) :: n_p2_covered = 0_i4            ! P2 covered keywords n_p2_covered  ? ?
    
    character(len=64), allocatable :: p0_missing(:)  ! Missing P0 keywords
    character(len=64), allocatable :: p1_missing(:)  ! Missing P1 keywords
    
    logical :: p0_complete = .false.              ! P0 complete flag
    real(wp) :: p0_coverage = 0.0_wp              ! P0 coverage percentage  ?[0,100]  ? ?
    real(wp) :: p1_coverage = 0.0_wp              ! P1 coverage percentage  ?[0,100]  ? ?
    real(wp) :: total_coverage = 0.0_wp            ! Total coverage percentage  ?[0,100]  ? ?
    
  CONTAINS
    PROCEDURE, PUBLIC :: ComputeCoverage => KW_Coverage_Calc
    PROCEDURE, PUBLIC :: Print => KW_Coverage_Print
  END TYPE KW_Coverage_Report
```

### `KW_Priority_Check` (lines 68–73)

```fortran
  TYPE, PUBLIC :: KW_Priority_Check
    character(len=32) :: keyword = ""             ! Keyword name
    integer(i4) :: priority = KW_PRIORITY_P0       ! Priority level  ? ?
    logical :: is_covered = .false.                ! Coverage flag
    character(len=128) :: notes = ""               ! Notes
  END TYPE KW_Priority_Check
```

### `KW_MetadataType` (lines 452–463)

```fortran
    TYPE, PUBLIC :: KW_MetadataType
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name (without *)
        INTEGER(i4) :: category = 0                              ! Keyword category  ? ?
        INTEGER(i4) :: priority = KW_PRIORITY_P0                ! Priority (P0/P1/P2)  ? ?
        CHARACTER(LEN=KW_MAX_DESC_LEN) :: description = ""      ! Keyword description
        LOGICAL :: is_macro = .FALSE.                           ! Is macro command flag
        LOGICAL :: is_registered = .FALSE.                      ! Is registered flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_module = ""     ! Parse module name
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_proc = ""       ! Parse procedure name
        LOGICAL :: has_validate = .FALSE.                      ! Has validation function flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: validate_proc = ""    ! Validation procedure name
    END TYPE KW_MetadataType
```

### `KW_HashTableType` (lines 475–484)

```fortran
    TYPE, PUBLIC :: KW_HashTableType
        INTEGER(i4), ALLOCATABLE :: buckets(:)    ! Hash buckets array
        INTEGER(i4) :: size = 0                    ! Hash table size  ? ?
        LOGICAL :: is_initialized = .FALSE.        ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => HashTable_Init
        PROCEDURE, PUBLIC :: Insert => HashTable_Insert
        PROCEDURE, PUBLIC :: Find => HashTable_Find
        PROCEDURE, PUBLIC :: Clear => HashTable_Clear
    END TYPE KW_HashTableType
```

### `KW_RegistryType` (lines 490–503)

```fortran
    TYPE, PUBLIC :: KW_RegistryType
        INTEGER(i4) :: count = 0                   ! Keyword count n_keywords  ? ?
        TYPE(KW_MetadataType), ALLOCATABLE :: keywords(:)  ! Keyword metadata array
        LOGICAL :: is_initialized = .FALSE.         ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => KW_Registry_Init
        PROCEDURE, PUBLIC :: Reg => KW_Registry_Reg
        PROCEDURE, PUBLIC :: Find => KW_Registry_Find
        PROCEDURE, PUBLIC :: GetAllKeywords => KW_Registry_GetAllKeywords
        PROCEDURE, PUBLIC :: GetKeywordsByCategory => KW_Registry_GetKeywordsByCategory
        PROCEDURE, PUBLIC :: GetKeywordsByPriority => KW_Registry_GetKeywordsByPriority
        PROCEDURE, PUBLIC :: GetMacroCommands => KW_Registry_GetMacroCommands
        PROCEDURE, PUBLIC :: CheckCoverage => KW_Registry_CheckCoverage
    END TYPE KW_RegistryType
```

### `KW_Reg_Desc` (lines 532–542)

```fortran
    TYPE, PUBLIC :: KW_Reg_Desc
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name
        INTEGER(i4) :: category = 0                              ! Category  ? ?
        INTEGER(i4) :: priority = KW_PRIORITY_P0                ! Priority  ? ?
        CHARACTER(LEN=KW_MAX_DESC_LEN) :: description = ""      ! Description
        LOGICAL :: is_macro = .FALSE.                           ! Is macro flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_module = ""     ! Parse module name
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_proc = ""       ! Parse procedure name
        LOGICAL :: has_validate = .FALSE.                      ! Has validation flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: validate_proc = ""    ! Validation procedure name
    END TYPE KW_Reg_Desc
```

### `KW_Registry_Ctx` (lines 546–549)

```fortran
    TYPE, PUBLIC :: KW_Registry_Ctx
        TYPE(KW_RegistryType), POINTER :: registry => null()   ! Registry pointer
        LOGICAL :: use_optimized = .FALSE.                      ! Use optimized registry flag
    END TYPE KW_Registry_Ctx
```

### `KW_CoverageAudit_Desc` (lines 553–556)

```fortran
    TYPE, PUBLIC :: KW_CoverageAudit_Desc
        CHARACTER(LEN=64), ALLOCATABLE :: covered_keywords(:)   ! Covered keywords array
        INTEGER(i4) :: n_keywords = 0_i4                        ! Number of keywords n_keywords  ? ?
    END TYPE KW_CoverageAudit_Desc
```

### `MD_KW_CoverageReportOut_Type` (lines 561–570)

```fortran
    TYPE, PUBLIC :: MD_KW_CoverageReportOut_Type
        INTEGER(i4) :: p0_count = 0_i4                          ! P0 total n_p0_total  ? ?
        INTEGER(i4) :: p0_covered = 0_i4                        ! P0 covered n_p0_covered  ? ?
        INTEGER(i4) :: p1_count = 0_i4                          ! P1 total n_p1_total  ? ?
        INTEGER(i4) :: p1_covered = 0_i4                        ! P1 covered n_p1_covered  ? ?
        INTEGER(i4) :: p2_count = 0_i4                          ! P2 total n_p2_total  ? ?
        INTEGER(i4) :: p2_covered = 0_i4                        ! P2 covered n_p2_covered  ? ?
        INTEGER(i4) :: macro_count = 0_i4                       ! Macro total n_macro  ? ?
        INTEGER(i4) :: macro_covered = 0_i4                    ! Macro covered n_macro_covered  ? ?
    END TYPE MD_KW_CoverageReportOut_Type
```

### `KW_Find_Desc` (lines 574–576)

```fortran
    TYPE, PUBLIC :: KW_Find_Desc
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name to find
    END TYPE KW_Find_Desc
```

### `KW_Find_State` (lines 580–584)

```fortran
    TYPE, PUBLIC :: KW_Find_State
        INTEGER(i4) :: index = 0_i4                             ! Keyword index idx  ? ?(0 if not found)
        TYPE(KW_MetadataType), POINTER :: metadata => null()    ! Keyword metadata pointer
        LOGICAL :: found = .FALSE.                              ! Found flag
    END TYPE KW_Find_State
```

### `KW_ExtensionPluginType` (lines 2027–2039)

```fortran
    TYPE, PUBLIC :: KW_ExtensionPluginType
        CHARACTER(LEN=64) :: plugin_name = ""                      ! Plugin name
        CHARACTER(LEN=256) :: plugin_version = ""                  ! Plugin version
        CHARACTER(LEN=256) :: plugin_description = ""              ! Plugin description
        INTEGER(i4) :: keyword_count = 0                            ! Keyword count n_keywords  ? ?
        TYPE(KW_MetadataType), ALLOCATABLE :: keywords(:)           ! Keyword array
        LOGICAL :: is_loaded = .FALSE.                              ! Loaded flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Plugin_Init
        PROCEDURE, PUBLIC :: AddKeyword => Plugin_AddKeyword
        PROCEDURE, PUBLIC :: Reg => Plugin_Reg
        PROCEDURE, PUBLIC :: Unregister => Plugin_Unregister
    END TYPE KW_ExtensionPluginType
```

### `KW_ExtensionManagerType` (lines 2047–2057)

```fortran
    TYPE, PUBLIC :: KW_ExtensionManagerType
        INTEGER(i4) :: plugin_count = 0                            ! Plugin count n_plugins  ? ?
        TYPE(KW_ExtensionPluginType), ALLOCATABLE :: plugins(:)      ! Plugin array
        LOGICAL :: is_initialized = .FALSE.                          ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Init_Mgr
        PROCEDURE, PUBLIC :: LoadPlugin => LoadPlugin_Mgr
        PROCEDURE, PUBLIC :: UnloadPlugin => UnloadPlugin_Mgr
        PROCEDURE, PUBLIC :: ListPlugins => ListPlugins_Mgr
        PROCEDURE, PUBLIC :: GetPlugin => GetPlugin_Mgr
    END TYPE KW_ExtensionManagerType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `KW_Audit_P0_Must` | 117 | `SUBROUTINE KW_Audit_P0_Must(covered_kws, report, status)` |
| SUBROUTINE | `KW_Audit_P1_Important` | 180 | `SUBROUTINE KW_Audit_P1_Important(covered_kws, report, status)` |
| SUBROUTINE | `KW_Audit_P2_Optional` | 232 | `SUBROUTINE KW_Audit_P2_Optional(covered_kws, report, status)` |
| SUBROUTINE | `KW_Generate_Report` | 283 | `SUBROUTINE KW_Generate_Report(covered_kws, report, status)` |
| SUBROUTINE | `KW_Coverage_Calc` | 330 | `subroutine KW_Coverage_Calc(this)` |
| SUBROUTINE | `KW_Coverage_Print` | 356 | `subroutine KW_Coverage_Print(this)` |
| SUBROUTINE | `KW_Registry_Init` | 615 | `SUBROUTINE KW_Registry_Init(this, status)` |
| SUBROUTINE | `KW_Registry_Reg` | 650 | `SUBROUTINE KW_Registry_Reg(this, keyword_name, category, priority, &` |
| FUNCTION | `KW_Registry_Find` | 726 | `FUNCTION KW_Registry_Find(this, keyword_name) RESULT(idx)` |
| SUBROUTINE | `KW_Registry_GetAllKeywords` | 749 | `SUBROUTINE KW_Registry_GetAllKeywords(this, keywords, count)` |
| SUBROUTINE | `KW_Registry_GetKeywordsByCategory` | 773 | `SUBROUTINE KW_Registry_GetKeywordsByCategory(this, category, keywords, count)` |
| SUBROUTINE | `KW_Registry_GetKeywordsByPriority` | 811 | `SUBROUTINE KW_Registry_GetKeywordsByPriority(this, priority, keywords, count)` |
| SUBROUTINE | `KW_Registry_GetMacroCommands` | 840 | `SUBROUTINE KW_Registry_GetMacroCommands(this, keywords, count)` |
| SUBROUTINE | `KW_Registry_CheckCoverage` | 884 | `SUBROUTINE KW_Registry_CheckCoverage(this, p0_count, p0_covered, &` |
| SUBROUTINE | `to_upper` | 933 | `SUBROUTINE to_upper(str)` |
| SUBROUTINE | `KW_Registry_InitGlobal` | 948 | `SUBROUTINE KW_Registry_InitGlobal(status)` |
| SUBROUTINE | `KW_Registry_RegisterAllKeywords` | 965 | `SUBROUTINE KW_Registry_RegisterAllKeywords(status)` |
| FUNCTION | `KW_Registry_FindKeyword` | 1442 | `FUNCTION KW_Registry_FindKeyword(keyword_name) RESULT(idx)` |
| SUBROUTINE | `KW_Registry_GetCoverageReport_Scalar` | 1468 | `SUBROUTINE KW_Registry_GetCoverageReport_Scalar(p0_count, p0_covered, p1_count, &` |
| SUBROUTINE | `KW_Registry_GetCoverageReport_Out` | 1490 | `SUBROUTINE KW_Registry_GetCoverageReport_Out(report_out, status)` |
| FUNCTION | `hash_keyword` | 1507 | `FUNCTION hash_keyword(keyword_name) RESULT(hash)` |
| SUBROUTINE | `HashTable_Init` | 1529 | `SUBROUTINE HashTable_Init(this, size, status)` |
| SUBROUTINE | `HashTable_Insert` | 1550 | `SUBROUTINE HashTable_Insert(this, keyword_name, index, status)` |
| FUNCTION | `HashTable_Find` | 1574 | `FUNCTION HashTable_Find(this, keyword_name) RESULT(idx)` |
| SUBROUTINE | `HashTable_Clear` | 1593 | `SUBROUTINE HashTable_Clear(this)` |
| SUBROUTINE | `Reg_InitOptimized` | 1610 | `SUBROUTINE Reg_InitOptimized(this, status)` |
| SUBROUTINE | `Reg_RegisterOptimized` | 1627 | `SUBROUTINE Reg_RegisterOptimized(this, keyword_name, category, priority, &` |
| FUNCTION | `Reg_FindOptimized` | 1660 | `FUNCTION Reg_FindOptimized(this, keyword_name) RESULT(idx)` |
| SUBROUTINE | `Reg_BuildHashTable` | 1687 | `SUBROUTINE Reg_BuildHashTable(this, status)` |
| SUBROUTINE | `KW_Registry_InitOptimizedGlobal` | 1712 | `SUBROUTINE KW_Registry_InitOptimizedGlobal(status)` |
| FUNCTION | `KW_Registry_FindKeywordFast` | 1739 | `FUNCTION KW_Registry_FindKeywordFast(keyword_name) RESULT(idx)` |
| SUBROUTINE | `KW_Registry_BuildHashTable` | 1753 | `SUBROUTINE KW_Registry_BuildHashTable(status)` |
| SUBROUTINE | `KW_Mapper_GetParseProc` | 1807 | `SUBROUTINE KW_Mapper_GetParseProc(keyword_name, parse_module, parse_proc, status)` |
| SUBROUTINE | `KW_Mapper_GetValidateProc` | 1847 | `SUBROUTINE KW_Mapper_GetValidateProc(keyword_name, validate_proc, has_validate, status)` |
| SUBROUTINE | `KW_Mapper_CheckAllKeywordsMapped` | 1880 | `SUBROUTINE KW_Mapper_CheckAllKeywordsMapped(unmapped_keywords, unmapped_count, status)` |
| SUBROUTINE | `KW_Mapper_GenerateMappingReport` | 1914 | `SUBROUTINE KW_Mapper_GenerateMappingReport(status)` |
| SUBROUTINE | `Plugin_Init` | 2078 | `SUBROUTINE Plugin_Init(this, name, version, description, status)` |
| SUBROUTINE | `Plugin_AddKeyword` | 2101 | `SUBROUTINE Plugin_AddKeyword(this, keyword_name, category, priority, &` |
| SUBROUTINE | `Plugin_Reg` | 2151 | `SUBROUTINE Plugin_Reg(this, status)` |
| SUBROUTINE | `Plugin_Unregister` | 2188 | `SUBROUTINE Plugin_Unregister(this, status)` |
| SUBROUTINE | `Init_Mgr` | 2204 | `SUBROUTINE Init_Mgr(this, status)` |
| SUBROUTINE | `LoadPlugin_Mgr` | 2223 | `SUBROUTINE LoadPlugin_Mgr(this, plugin, status)` |
| SUBROUTINE | `UnloadPlugin_Mgr` | 2260 | `SUBROUTINE UnloadPlugin_Mgr(this, plugin_name, status)` |
| SUBROUTINE | `ListPlugins_Mgr` | 2301 | `SUBROUTINE ListPlugins_Mgr(this, plugin_names, count)` |
| SUBROUTINE | `GetPlugin_Mgr` | 2320 | `SUBROUTINE GetPlugin_Mgr(this, plugin_name, plugin_out, found)` |
| SUBROUTINE | `KW_Extension_InitGlobal` | 2341 | `SUBROUTINE KW_Extension_InitGlobal(status)` |
| SUBROUTINE | `KW_Extension_RegisterKeyword` | 2354 | `SUBROUTINE KW_Extension_RegisterKeyword(keyword_name, category, priority, &` |
| SUBROUTINE | `KW_Extension_CreatePlugin` | 2374 | `SUBROUTINE KW_Extension_CreatePlugin(name, version, description, plugin, status)` |
| SUBROUTINE | `KW_Extension_LoadPlugin` | 2385 | `SUBROUTINE KW_Extension_LoadPlugin(plugin, status)` |
| SUBROUTINE | `KW_Extension_UnloadPlugin` | 2400 | `SUBROUTINE KW_Extension_UnloadPlugin(plugin_name, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 595–597 | `INTERFACE KW_Registry_GetCoverageReport` |
