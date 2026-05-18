# `MD_Sect_Mgr.f90`

- **Source**: `L3_MD/Section/MD_Sect_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MatDesc` (lines 37–66)

```fortran
    TYPE, PUBLIC :: MatDesc
        ! === Mat identification (dual representation) ===
        INTEGER(i4)        :: type     = 0     ! Integer Mat code (for UEL)
        CHARACTER(LEN=80)  :: cmname      = ''    ! Character Mat name (for UMAT)
        
        ! === Deformation mode ===
        INTEGER(i4)        :: Formul = 0     ! 0=small, 1=TL, 2=UL
        
        ! === Section association ===
        INTEGER(i4)        :: section_id  = 0     ! Section ID for props
        
        ! === Element family (topo) ===
        INTEGER(i4)        :: element_family = 0     ! 0=unknown,1=continuum,2=truss,3=beam,4=shell,5=membrane
        
        ! === Tensor layout (sigma/strain components) ===
        INTEGER(i4)        :: dim         = 3     ! Geometric dimension (1,2,3)
        INTEGER(i4)        :: ndi         = 0     ! Number of direct sigma components
        INTEGER(i4)        :: nshr        = 0     ! Number of shear sigma components
        INTEGER(i4)        :: ntens       = 0     ! Total components in Voigt vector
        
        ! === Mat props cache (optional) ===
        INTEGER(i4)        :: nprops      = 0     ! Number of Mat properties
        REAL(wp)           :: props(200)  = 0.0_wp ! Mat props cache
        
        ! === Analysis type ===
        INTEGER(i4)        :: atype       = 4     ! 1=pstrain,2=pstress,3=axisym,4=3D
        
        ! === Validity flag ===
        LOGICAL            :: valid       = .FALSE.
    END TYPE MatDesc
```

### `SectTypeEntry` (lines 72–77)

```fortran
    TYPE, PUBLIC :: SectTypeEntry
        INTEGER(i4)       :: family     = 0_i4
        INTEGER(i4)       :: dim        = 0_i4
        CHARACTER(LEN=16) :: elemPrefix = ""   !! e.g., 'CPE', 'CPS', 'CAX', 'C3D'
        INTEGER(i4)       :: atype      = 0_i4  !! atype in Section truth table
    END TYPE SectTypeEntry
```

### `MD_SectionProps` (lines 317–328)

```fortran
    TYPE, PUBLIC :: MD_SectionProps
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: I11 = 0.0_wp
        REAL(wp) :: I22 = 0.0_wp
        REAL(wp) :: I12 = 0.0_wp
        REAL(wp) :: I33 = 0.0_wp
        REAL(wp) :: centroid(2) = 0.0_wp
        REAL(wp) :: principal_momen(2) = 0.0_wp
        REAL(wp) :: principal_angle = 0.0_wp
        REAL(wp) :: section_modulus(2) = 0.0_wp
        REAL(wp) :: gyration_radius(2) = 0.0_wp
    END TYPE MD_SectionProps
```

### `MD_SectionOrientation` (lines 330–334)

```fortran
    TYPE, PUBLIC :: MD_SectionOrientation
        REAL(wp) :: angle = 0.0_wp
        REAL(wp) :: axis(3) = 0.0_wp
        LOGICAL :: defined = .false.
    END TYPE MD_SectionOrientation
```

### `MD_SectionCompLayer` (lines 336–341)

```fortran
    TYPE, PUBLIC :: MD_SectionCompLayer
        INTEGER(i4) :: id = 0
        REAL(wp) :: thickness = 0.0_wp
        REAL(wp) :: angle = 0.0_wp
        INTEGER(i4) :: integrationpoin = 3
    END TYPE MD_SectionCompLayer
```

### `MD_SectionCompositeProperties` (lines 343–350)

```fortran
    TYPE, PUBLIC :: MD_SectionCompositeProperties
        INTEGER(i4) :: numLayers = 0
        REAL(wp) :: totalThickness = 0.0_wp
        REAL(wp) :: ABD(6,6) = 0.0_wp
        REAL(wp) :: extensional_sti(3,3) = 0.0_wp
        REAL(wp) :: cpl_stiffness(3,3) = 0.0_wp
        REAL(wp) :: bending_stiffne(3,3) = 0.0_wp
    END TYPE MD_SectionCompositeProperties
```

### `UF_SECTION_DATA` (lines 355–361)

```fortran
    TYPE :: UF_SECTION_DATA
        INTEGER(i4) :: section_id       = 0    ! Section ID
        INTEGER(i4) :: type          = 0    ! Mat type code
        INTEGER(i4) :: nprops           = 0    ! Number of section props
        REAL(wp)    :: props(50)        = 0.0_wp  ! Section props (thickness, etc.)
        CHARACTER(LEN=80) :: name       = ''   ! Section name
    END TYPE UF_SECTION_DATA
```

### `UF_ELEM_SECTION_MAP` (lines 366–370)

```fortran
    TYPE :: UF_ELEM_SECTION_MAP
        INTEGER(i4) :: jelem            = 0    ! Element number
        INTEGER(i4) :: section_id       = 0    ! Associated section ID
        INTEGER(i4) :: type          = 0    ! Direct Mat type (for quick access)
    END TYPE UF_ELEM_SECTION_MAP
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Section_Init` | 417 | `SUBROUTINE UF_Section_Init(max_elements)` |
| SUBROUTINE | `UF_Section_Reg` | 476 | `SUBROUTINE UF_Section_Reg(jelem, type, section_id, Formul)` |
| SUBROUTINE | `UF_Section_RegisterBatch` | 519 | `SUBROUTINE UF_Section_RegisterBatch(element_list, n_element, type, section_id, Formul)` |
| SUBROUTINE | `UF_Section_RegisterFull` | 551 | `SUBROUTINE UF_Section_RegisterFull(jelem, type, Formul, section_id, &` |
| FUNCTION | `UF_Section_GetMaterial` | 608 | `FUNCTION UF_Section_GetMaterial(jelem) RESULT(type)` |
| FUNCTION | `UF_Section_GetFormulation` | 630 | `FUNCTION UF_Section_GetFormulation(jelem) RESULT(Formul)` |
| FUNCTION | `UF_Section_GetSectionID` | 651 | `FUNCTION UF_Section_GetSectionID(jelem) RESULT(section_id)` |
| SUBROUTINE | `UF_Section_GetProps` | 672 | `SUBROUTINE UF_Section_GetProps(section_id, props, nprops)` |
| SUBROUTINE | `UF_Section_AddSection` | 695 | `SUBROUTINE UF_Section_AddSection(type, props, nprops, name, section_id)` |
| SUBROUTINE | `UF_Section_Clear` | 736 | `SUBROUTINE UF_Section_Clear()` |
| FUNCTION | `UF_Section_IsInitialized` | 762 | `FUNCTION UF_Section_IsInitialized() RESULT(initialized)` |
| FUNCTION | `UF_Section_GetCount` | 770 | `FUNCTION UF_Section_GetCount() RESULT(count)` |
| SUBROUTINE | `UF_Section_RegMatName` | 783 | `SUBROUTINE UF_Section_RegMatName(type, cmname)` |
| SUBROUTINE | `UF_Section_GetMaterialName` | 809 | `SUBROUTINE UF_Section_GetMaterialName(type, cmname)` |
| FUNCTION | `UF_Section_GetMaterialType` | 829 | `FUNCTION UF_Section_GetMaterialType(cmname) RESULT(type)` |
| SUBROUTINE | `UF_SECTION_GETC` | 849 | `SUBROUTINE UF_SECTION_GETC(jelem, cmname)` |
| FUNCTION | `UF_Section_GetDescriptor` | 873 | `FUNCTION UF_Section_GetDescriptor(jelem) RESULT(desc)` |
| SUBROUTINE | `UF_Se_InitDefaults` | 933 | `SUBROUTINE UF_Se_InitDefaults()` |
| SUBROUTINE | `UF_Section_RegisterAType` | 953 | `SUBROUTINE UF_Section_RegisterAType(family, dim, elemPrefix, atype, status)` |
| SUBROUTINE | `UF_Se_SuggestATypeFromName` | 988 | `SUBROUTINE UF_Se_SuggestATypeFromName(family, dim, elemName, atype)` |
| SUBROUTINE | `UF_Se_SuggestATypeFromFamily` | 1046 | `SUBROUTINE UF_Se_SuggestATypeFromFamily(family, dim, atype)` |
| FUNCTION | `to_upper` | 1081 | `FUNCTION to_upper(str) RESULT(upper_str)` |
| SUBROUTINE | `SectDesc_Init` | 1101 | `SUBROUTINE SectDesc_Init(this, id, name, sectionType)` |
| SUBROUTINE | `SectDesc_RegLayout` | 1112 | `SUBROUTINE SectDesc_RegLayout(this)` |
| SUBROUTINE | `SectDesc_Ensure` | 1137 | `SUBROUTINE SectDesc_Ensure(this)` |
| SUBROUTINE | `SectSta_Init` | 1146 | `SUBROUTINE SectSta_Init(this, id)` |
| SUBROUTINE | `SectSta_RegLayout` | 1153 | `SUBROUTINE SectSta_RegLayout(this)` |
| SUBROUTINE | `SectSta_Ensure` | 1172 | `SUBROUTINE SectSta_Ensure(this)` |
| SUBROUTINE | `SectCtx_Init` | 1181 | `SUBROUTINE SectCtx_Init(this, id)` |
| SUBROUTINE | `SectCtx_RegLayout` | 1189 | `SUBROUTINE SectCtx_RegLayout(this)` |
| SUBROUTINE | `SectCtx_Ensure` | 1204 | `SUBROUTINE SectCtx_Ensure(this)` |
| SUBROUTINE | `SectAssignDesc_Init` | 1213 | `SUBROUTINE SectAssignDesc_Init(this, id, secId, region)` |
| SUBROUTINE | `SectAssignDesc_RegLayout` | 1224 | `SUBROUTINE SectAssignDesc_RegLayout(this)` |
| SUBROUTINE | `SectAssignDesc_Ensure` | 1248 | `SUBROUTINE SectAssignDesc_Ensure(this)` |
| SUBROUTINE | `SolidSectDesc_Init` | 1257 | `SUBROUTINE SolidSectDesc_Init(this, id, name, materialName)` |
| SUBROUTINE | `SolidSectDesc_RegLayout` | 1268 | `SUBROUTINE SolidSectDesc_RegLayout(this)` |
| SUBROUTINE | `SolidSectDesc_Ensure` | 1293 | `SUBROUTINE SolidSectDesc_Ensure(this)` |
| SUBROUTINE | `SolidSectDesc_Valid` | 1302 | `SUBROUTINE SolidSectDesc_Valid(this, status)` |
| SUBROUTINE | `ShellSectDesc_Init` | 1329 | `SUBROUTINE ShellSectDesc_Init(this, id, name, materialName, thickness)` |
| SUBROUTINE | `ShellSectDesc_RegLayout` | 1342 | `SUBROUTINE ShellSectDesc_RegLayout(this)` |
| SUBROUTINE | `ShellSectDesc_Ensure` | 1371 | `SUBROUTINE ShellSectDesc_Ensure(this)` |
| SUBROUTINE | `ShellSectDesc_Valid` | 1380 | `SUBROUTINE ShellSectDesc_Valid(this, status)` |
| SUBROUTINE | `BeamSectDesc_Init` | 1415 | `SUBROUTINE BeamSectDesc_Init(this, id, name, materialName, area, I11, I22, I12)` |
| SUBROUTINE | `BeamSectDesc_RegLayout` | 1431 | `SUBROUTINE BeamSectDesc_RegLayout(this)` |
| SUBROUTINE | `BeamSectDesc_Ensure` | 1472 | `SUBROUTINE BeamSectDesc_Ensure(this)` |
| SUBROUTINE | `BeamSectDesc_Valid` | 1481 | `SUBROUTINE BeamSectDesc_Valid(this, status)` |
| FUNCTION | `SectTree_GetID` | 1536 | `FUNCTION SectTree_GetID(this) RESULT(id)` |
| FUNCTION | `SectTree_GetName` | 1543 | `FUNCTION SectTree_GetName(this) RESULT(name)` |
| FUNCTION | `SectTree_GetType` | 1549 | `FUNCTION SectTree_GetType(this) RESULT(ntype)` |
| FUNCTION | `SectTree_GetParentID` | 1555 | `FUNCTION SectTree_GetParentID(this) RESULT(pid)` |
| FUNCTION | `SectTree_GetByPath` | 1561 | `FUNCTION SectTree_GetByPath(this, path_str) RESULT(obj_ptr)` |
| FUNCTION | `SectTree_GetFullPath` | 1577 | `FUNCTION SectTree_GetFullPath(this) RESULT(path_str)` |
| SUBROUTINE | `SectTree_InitTree` | 1589 | `SUBROUTINE SectTree_InitTree(this, initial_capacit, status)` |
| SUBROUTINE | `SectTree_DestroyTree` | 1599 | `SUBROUTINE SectTree_DestroyTree(this, status)` |
| SUBROUTINE | `SectTree_RebuildIndex` | 1608 | `SUBROUTINE SectTree_RebuildIndex(this, status)` |
| SUBROUTINE | `SectTree_ValidateTree` | 1620 | `SUBROUTINE SectTree_ValidateTree(this, status)` |
| SUBROUTINE | `SectTree_Serialize` | 1633 | `SUBROUTINE SectTree_Serialize(this, serializer)` |
| SUBROUTINE | `SectTree_Deserialize` | 1648 | `SUBROUTINE SectTree_Deserialize(this, deserializer)` |
| SUBROUTINE | `SectTree_BeginBatch` | 1666 | `SUBROUTINE SectTree_BeginBatch(this, max_size)` |
| SUBROUTINE | `SectTree_EndBatch` | 1672 | `SUBROUTINE SectTree_EndBatch(this, rebuild_index, status)` |
| SUBROUTINE | `MD_Section_ComputeProperties` | 1685 | `SUBROUTINE MD_Section_ComputeProperties(section, props, status)` |
| SUBROUTINE | `MD_Section_ComputeInertia` | 1700 | `SUBROUTINE MD_Section_ComputeInertia(section, I11, I22, I12, I33, status)` |
| SUBROUTINE | `MD_Section_ComputeModulus` | 1716 | `SUBROUTINE MD_Section_ComputeModulus(section, I11, I22, modulus)` |
| SUBROUTINE | `MD_Se_ComputeGyrationRadius` | 1735 | `SUBROUTINE MD_Se_ComputeGyrationRadius(section, area, I11, I22, radius)` |
| FUNCTION | `MD_Section_GetArea` | 1748 | `FUNCTION MD_Section_GetArea(section) RESULT(area)` |
| FUNCTION | `MD_Section_GetThickness` | 1755 | `FUNCTION MD_Section_GetThickness(section) RESULT(thickness)` |
| FUNCTION | `MD_Section_GetSectionType` | 1762 | `FUNCTION MD_Section_GetSectionType(section) RESULT(sectionType)` |
| SUBROUTINE | `MD_Section_GetCentroid` | 1773 | `SUBROUTINE MD_Section_GetCentroid(section, centroid)` |
| SUBROUTINE | `MD_Section_GetPrincipalAxes` | 1780 | `SUBROUTINE MD_Section_GetPrincipalAxes(I11, I22, I12, principal_momen, principal_angle)` |
| SUBROUTINE | `MD_Section_Orientation_Init` | 1796 | `SUBROUTINE MD_Section_Orientation_Init(orientation, angle, axis)` |
| SUBROUTINE | `MD_Section_SetOrientation` | 1809 | `SUBROUTINE MD_Section_SetOrientation(section, orientation, status)` |
| SUBROUTINE | `MD_Section_CompProps` | 1824 | `SUBROUTINE MD_Section_CompProps(layers, numLayers, thickness, props, status)` |
| SUBROUTINE | `MD_Section_ValidateGeometry` | 1879 | `SUBROUTINE MD_Section_ValidateGeometry(section, valid, status, errorMessage)` |
| SUBROUTINE | `CohesiveSectDesc_Init` | 1921 | `SUBROUTINE CohesiveSectDesc_Init(this, id, name, materialName, thickness, response, nIntPts, initialGap)` |
| SUBROUTINE | `CohesiveSectDesc_RegLayout` | 1937 | `SUBROUTINE CohesiveSectDesc_RegLayout(this)` |
| SUBROUTINE | `CohesiveSectDesc_Ensure` | 1988 | `SUBROUTINE CohesiveSectDesc_Ensure(this)` |
| SUBROUTINE | `GasketSectDesc_Init` | 2001 | `SUBROUTINE GasketSectDesc_Init(this, id, name, materialName, initialThickness, initialGap, nodal_thickness, nDirections)` |
| SUBROUTINE | `GasketSectDesc_RegLayout` | 2017 | `SUBROUTINE GasketSectDesc_RegLayout(this)` |
| SUBROUTINE | `GasketSectDesc_Ensure` | 2068 | `SUBROUTINE GasketSectDesc_Ensure(this)` |
| SUBROUTINE | `ConnectorSectDesc_Init` | 2081 | `SUBROUTINE ConnectorSectDesc_Init(this, id, name, connectorType, behaviorName)` |
| SUBROUTINE | `ConnectorSectDesc_RegLayout` | 2093 | `SUBROUTINE ConnectorSectDesc_RegLayout(this)` |
| SUBROUTINE | `ConnectorSectDesc_Ensure` | 2129 | `SUBROUTINE ConnectorSectDesc_Ensure(this)` |
| SUBROUTINE | `SurfaceSectDesc_Init` | 2142 | `SUBROUTINE SurfaceSectDesc_Init(this, id, name, density, thickness, fluidBehavior)` |
| SUBROUTINE | `SurfaceSectDesc_RegLayout` | 2156 | `SUBROUTINE SurfaceSectDesc_RegLayout(this)` |
| SUBROUTINE | `SurfaceSectDesc_Ensure` | 2196 | `SUBROUTINE SurfaceSectDesc_Ensure(this)` |
| SUBROUTINE | `MemSectDesc_Init` | 2209 | `SUBROUTINE MemSectDesc_Init(this, id, name, materialName, thickness, nIntPts, noCompression)` |
| SUBROUTINE | `MemSectDesc_RegLayout` | 2225 | `SUBROUTINE MemSectDesc_RegLayout(this)` |
| SUBROUTINE | `MemSectDesc_Ensure` | 2270 | `SUBROUTINE MemSectDesc_Ensure(this)` |
| SUBROUTINE | `UF_So_GetStatistics` | 2288 | `SUBROUTINE UF_So_GetStatistics(section, stats, status)` |
| SUBROUTINE | `UF_So_ComputeVolume` | 2304 | `SUBROUTINE UF_So_ComputeVolume(section, element_volume, total_volume, status)` |
| SUBROUTINE | `UF_Sh_GetStatistics` | 2323 | `SUBROUTINE UF_Sh_GetStatistics(section, stats, status)` |
| SUBROUTINE | `UF_ShellSection_ComputeArea` | 2340 | `SUBROUTINE UF_ShellSection_ComputeArea(section, element_area, total_area, status)` |
| SUBROUTINE | `UF_Sh_ComputeVolume` | 2355 | `SUBROUTINE UF_Sh_ComputeVolume(section, element_area, total_volume, status)` |
| SUBROUTINE | `UF_BeamSection_GetStatistics` | 2374 | `SUBROUTINE UF_BeamSection_GetStatistics(section, stats, status)` |
| SUBROUTINE | `UF_Be_ComputeTorsionalConsta` | 2393 | `SUBROUTINE UF_Be_ComputeTorsionalConsta(section, J, status)` |
| SUBROUTINE | `UF_Be_ComputeShearArea` | 2408 | `SUBROUTINE UF_Be_ComputeShearArea(section, A_shear, status)` |
| SUBROUTINE | `UF_Me_GetStatistics` | 2427 | `SUBROUTINE UF_Me_GetStatistics(section, stats, status)` |
| SUBROUTINE | `UF_Me_ComputeArea` | 2446 | `SUBROUTINE UF_Me_ComputeArea(section, element_area, total_area, status)` |
| SUBROUTINE | `UF_Co_ComputeEffectiveProper` | 2465 | `SUBROUTINE UF_Co_ComputeEffectiveProper(composite_props, n_layers, &` |
| SUBROUTINE | `UF_Se_GetStatistics` | 2508 | `SUBROUTINE UF_Se_GetStatistics(section_tree, stats, status)` |
| SUBROUTINE | `UF_SectionLibrary_FindByType` | 2527 | `SUBROUTINE UF_SectionLibrary_FindByType(section_tree, section_type, section_list, n_found, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
