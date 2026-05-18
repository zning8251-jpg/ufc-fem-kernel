# `MD_Model_Lib_Core.f90`

- **Source**: `L3_MD/Model/MD_Model_Lib_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Model_Lib_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Lib_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model_Lib`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Lib_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Desc_Model` (lines 130–135)

```fortran
    TYPE, PUBLIC :: Desc_Model
        INTEGER(i4) :: model_id = 0_i4
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=128) :: description = ""
        INTEGER(i4) :: dimension = 3_i4
    END TYPE Desc_Model
```

### `MD_Model_Init_Desc` (lines 144–148)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_Desc
      CHARACTER(LEN=64) :: name = ""  ! Model name
      CHARACTER(LEN=256) :: input_file = ""  ! Input file path
      INTEGER(i4) :: dimension = 3  ! Spatial dimension ??{2, 3}
    END TYPE MD_Model_Init_Desc
```

### `MD_Model_Init_Algo` (lines 151–155)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_Algo
      LOGICAL :: initialize_dof_mgr = .TRUE.  ! Initialize DOF manager
      LOGICAL :: initialize_field_mgr = .TRUE.  ! Initialize field state manager
      INTEGER(i4) :: max_dof_per_node = 6  ! Max DOFs per node
    END TYPE MD_Model_Init_Algo
```

### `MD_Model_Init_Ctx` (lines 158–161)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_Ctx
      LOGICAL :: verbose = .FALSE.  ! Verbose output flag
      INTEGER(i4) :: log_level = 0_i4  ! Logging level (0=silent, 1=info, 2=debug)
    END TYPE MD_Model_Init_Ctx
```

### `MD_Model_Init_State` (lines 164–168)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_State
      LOGICAL :: initialized = .FALSE.  ! Initialization success status
      INTEGER(i4) :: num_parts = 0_i4  ! Number of parts initialized
      INTEGER(i4) :: num_materials = 0_i4  ! Number of materials initialized
    END TYPE MD_Model_Init_State
```

### `MD_Model_Init_In` (lines 171–176)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_In
      TYPE(MD_Model_Init_Desc) :: desc
      TYPE(MD_Model_Init_Algo) :: algo
      TYPE(MD_Model_Init_Ctx) :: ctx
      TYPE(MD_Model_Init_State) :: state
    END TYPE MD_Model_Init_In
```

### `MD_Model_Init_Out` (lines 179–182)

```fortran
    TYPE, PUBLIC :: MD_Model_Init_Out
      TYPE(MD_Model_Init_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_Init_Out
```

### `MD_Model_AddPart_In` (lines 185–187)

```fortran
    TYPE, PUBLIC :: MD_Model_AddPart_In
      TYPE(UF_PartDef) :: part  ! Part definition to add
    END TYPE MD_Model_AddPart_In
```

### `MD_Model_AddPart_Out` (lines 190–193)

```fortran
    TYPE, PUBLIC :: MD_Model_AddPart_Out
      INTEGER(i4) :: part_id = 0  ! Assigned part ID
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_AddPart_Out
```

### `MD_Model_AddMaterial_In` (lines 196–198)

```fortran
    TYPE, PUBLIC :: MD_Model_AddMaterial_In
      TYPE(UF_MaterialDef) :: material  ! Material definition to add
    END TYPE MD_Model_AddMaterial_In
```

### `MD_Model_AddMaterial_Out` (lines 201–204)

```fortran
    TYPE, PUBLIC :: MD_Model_AddMaterial_Out
      INTEGER(i4) :: material_id = 0  ! Assigned material ID
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_AddMaterial_Out
```

### `MD_Model_ApplyBC_In` (lines 207–210)

```fortran
    TYPE, PUBLIC :: MD_Model_ApplyBC_In
      INTEGER(i4) :: step_index = 0  ! Step index
      REAL(wp) :: time = 0.0_wp  ! Current time t
    END TYPE MD_Model_ApplyBC_In
```

### `MD_Model_ApplyBC_Out` (lines 213–216)

```fortran
    TYPE, PUBLIC :: MD_Model_ApplyBC_Out
      INTEGER(i4) :: num_bcs_applied = 0  ! Number of BCs applied
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_ApplyBC_Out
```

### `MD_Model_ApplyLoads_In` (lines 219–223)

```fortran
    TYPE, PUBLIC :: MD_Model_ApplyLoads_In
      INTEGER(i4) :: step_index = 0  ! Step index
      REAL(wp) :: time = 0.0_wp  ! Current time t
      REAL(wp), ALLOCATABLE :: F_ext(:)  ! External force F_ext(ndof), will be modified
    END TYPE MD_Model_ApplyLoads_In
```

### `MD_Model_ApplyLoads_Out` (lines 226–229)

```fortran
    TYPE, PUBLIC :: MD_Model_ApplyLoads_Out
      INTEGER(i4) :: num_loads_applied = 0  ! Number of loads applied
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_ApplyLoads_Out
```

### `UF_ModelDef` (lines 237–271)

```fortran
    TYPE :: UF_ModelDef
        CHARACTER(LEN=64) :: name = "Model-1"
        CHARACTER(LEN=256) :: input_file = ""
        INTEGER(i4) :: dimension = 3
        TYPE(UF_AssemblyDef) :: assembly
        TYPE(UF_MaterialDB) :: material_db
        TYPE(UF_SectionDBType) :: section_db
        TYPE(UF_ContactPropertyDB) :: contact_db
        TYPE(UF_StepManager) :: step_mgr

        TYPE(MD_FieldMgr_Type) :: field_mgr
        TYPE(UF_DOFManagerType), POINTER :: dof_mgr => NULL()  ! DOF manager: eqn = f(node_id, dof_local)
        TYPE(UF_DOFLabelMapType) :: dof_label_map  ! DOF label map: label ??slot (1..MAX_DOF_PER_NODE)
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)

        INTEGER(i4) :: num_amplitudes = 0
        
        TYPE(UF_PartDef), ALLOCATABLE :: parts(:)

        INTEGER(i4) :: num_parts = 0
        INTEGER(i4), ALLOCATABLE :: part_ids(:)  ! Index tree: part IDs for Domain lookup (Phase C)
    CONTAINS
        PROCEDURE :: initialize => model_initialize
        PROCEDURE :: add_part => model_add_part
        PROCEDURE :: get_part => model_get_part
        PROCEDURE :: add_material => model_add_material
        PROCEDURE :: get_material => model_get_material
        PROCEDURE :: add_section => model_add_section
        PROCEDURE :: get_section => model_get_section
        PROCEDURE :: add_amplitude => model_add_amplitude
        PROCEDURE :: get_amplitude => model_get_amplitude
        PROCEDURE :: apply_boundary_conditions => model_apply_boundary_conditions
        PROCEDURE :: apply_structural_loads => model_apply_structural_loads
        PROCEDURE :: prepare_analysis => model_prepare_analysis
    END TYPE UF_ModelDef
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `model_add_part` | 284 | `SUBROUTINE model_add_part(this, part)` |
| FUNCTION | `model_get_part` | 311 | `FUNCTION model_get_part(this, name) RESULT(ptr)` |
| SUBROUTINE | `model_initialize` | 338 | `SUBROUTINE model_initialize(this, name)` |
| SUBROUTINE | `model_add_material` | 370 | `SUBROUTINE model_add_material(this, mat)` |
| FUNCTION | `model_get_material` | 392 | `FUNCTION model_get_material(this, name) RESULT(ptr)` |
| SUBROUTINE | `model_add_section` | 408 | `SUBROUTINE model_add_section(this, sec)` |
| FUNCTION | `model_get_section` | 420 | `FUNCTION model_get_section(this, name) RESULT(ptr)` |
| SUBROUTINE | `model_add_amplitude` | 436 | `SUBROUTINE model_add_amplitude(this, amp)` |
| FUNCTION | `model_get_amplitude` | 462 | `FUNCTION model_get_amplitude(this, name) RESULT(ptr)` |
| SUBROUTINE | `model_apply_boundary_conditions` | 489 | `SUBROUTINE model_apply_boundary_conditions(this, step_index)` |
| SUBROUTINE | `model_apply_structural_loads` | 638 | `SUBROUTINE model_apply_structural_loads(this, step_index, F_ext)` |
| SUBROUTINE | `model_prepare_analysis` | 729 | `SUBROUTINE model_prepare_analysis(this)` |
| SUBROUTINE | `MD_Model_CheckConsistency` | 746 | `SUBROUTINE MD_Model_CheckConsistency(model, is_consistent, status)` |
| SUBROUTINE | `MD_Model_Compare` | 756 | `SUBROUTINE MD_Model_Compare(model1, model2, are_equal, status)` |
| FUNCTION | `MD_Model_GetElementCount` | 767 | `FUNCTION MD_Model_GetElementCount(model, status) RESULT(count)` |
| FUNCTION | `MD_Model_GetMaterialCount` | 777 | `FUNCTION MD_Model_GetMaterialCount(model, status) RESULT(count)` |
| FUNCTION | `MD_Model_GetNodeCount` | 787 | `FUNCTION MD_Model_GetNodeCount(model, status) RESULT(count)` |
| SUBROUTINE | `MD_Model_GetStatistics` | 797 | `SUBROUTINE MD_Model_GetStatistics(model, nElems, nNodes, nMats, status)` |
| SUBROUTINE | `MD_Model_Valid` | 812 | `SUBROUTINE MD_Model_Valid(model, status)` |
| SUBROUTINE | `MD_Theory_ExportList` | 820 | `SUBROUTINE MD_Theory_ExportList(unit, status)` |
| SUBROUTINE | `MD_Theory_GetNumModules` | 837 | `SUBROUTINE MD_Theory_GetNumModules(num_modules)` |
| SUBROUTINE | `MD_Theory_QueryByIndex` | 843 | `SUBROUTINE MD_Theory_QueryByIndex(index, theory_name, description, status)` |
| SUBROUTINE | `MD_Theory_Unified_Describe` | 858 | `SUBROUTINE MD_Theory_Unified_Describe(module_id, description, status)` |
| SUBROUTINE | `MD_Theory_Unified_Query` | 883 | `SUBROUTINE MD_Theory_Unified_Query(module_id, theory_name, layer, status)` |
| SUBROUTINE | `Model_FromDesc` | 913 | `SUBROUTINE Model_FromDesc(desc_model, md_model, status)` |
| SUBROUTINE | `Model_FromDesc_Control` | 926 | `SUBROUTINE Model_FromDesc_Control(desc_model, md_control, status)` |
| SUBROUTINE | `Model_FromDesc_State` | 935 | `SUBROUTINE Model_FromDesc_State(desc_model, md_state, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
