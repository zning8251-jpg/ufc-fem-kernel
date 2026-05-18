# `MD_Out_Def.f90`

- **Source**: `L3_MD/Output/MD_Out_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Out_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `OutVarDesc` (lines 143–155)

```fortran
  type, public :: OutVarDesc
    integer(i4) :: var_id = 0_i4
    character(len=16) :: var_name = ''
    character(len=64) :: var_description = ''
    integer(i4) :: location = OUT_LOC_NODE
    integer(i4) :: rank = OUT_RANK_SCALAR
    integer(i4) :: n_components = 1_i4
    logical :: is_tensor = .false.
    logical :: is_vector = .false.
    logical :: is_scalar = .true.
    logical :: support_field = .true.
    logical :: support_history = .true.
  end type OutVarDesc
```

### `FldOutReq` (lines 157–177)

```fortran
  type, public :: FldOutReq
    character(len=64) :: name = ''
    character(len=64) :: region_name = ''
    integer(i4) :: region_type = OUT_REGION_ALL
    integer(i4) :: position = OUT_LOC_NODE
    integer(i4) :: frequency = 1_i4
    integer(i4) :: frequency_type = OUT_FREQ_INCREMENT
    real(wp) :: time_interval = 0.0_wp
    integer(i4) :: num_time_marks = 0_i4
    real(wp), allocatable :: time_marks(:)
    integer(i4) :: nVars = 0_i4
    integer(i4), pointer :: variables(:) => null()
    integer(i4) :: variables_id = -1_i4
    logical :: is_active = .true.
    integer(i4) :: step_id = 0_i4
  contains
    procedure, public :: Init => FldOutReq_Init
    procedure, public :: AddVariable => FldOutReq_AddVariable
    procedure, public :: ShouldOutput => FldOutReq_ShouldOutput
    procedure, public :: Clear => FldOutReq_Clear
  end type FldOutReq
```

### `HistOutReq` (lines 179–198)

```fortran
  type, public :: HistOutReq
    character(len=64) :: name = ''
    character(len=64) :: region_name = ''
    integer(i4) :: region_type = OUT_REGION_ALL
    integer(i4) :: frequency = 1_i4
    integer(i4) :: frequency_type = OUT_FREQ_INCREMENT
    real(wp) :: time_interval = 0.0_wp
    integer(i4) :: num_time_marks = 0_i4
    real(wp), allocatable :: time_marks(:)
    integer(i4) :: nVars = 0_i4
    integer(i4), pointer :: variables(:) => null()
    integer(i4) :: variables_id = -1_i4
    logical :: is_active = .true.
    integer(i4) :: step_id = 0_i4
  contains
    procedure, public :: Init => HistOutReq_Init
    procedure, public :: AddVariable => HistOutReq_AddVariable
    procedure, public :: ShouldOutput => HistOutReq_ShouldOutput
    procedure, public :: Clear => HistOutReq_Clear
  end type HistOutReq
```

### `OutField` (lines 200–209)

```fortran
  type, public :: OutField
    character(len=32) :: var_name = ''
    integer(i4) :: var_id = 0_i4
    integer(i4) :: location = OUT_LOC_NODE
    integer(i4) :: n_components = 0_i4
    integer(i4) :: n_points = 0_i4
    integer(i4), allocatable :: point_ids(:)
    integer(i4), allocatable :: sub_point_ids(:)
    real(wp), allocatable :: data(:,:)
  end type OutField
```

### `OutFrame` (lines 211–217)

```fortran
  type, public :: OutFrame
    integer(i4) :: step_id = 0_i4
    integer(i4) :: increment_id = 0_i4
    real(wp) :: time = 0.0_wp
    integer(i4) :: num_fields = 0_i4
    type(OutField), allocatable :: fields(:)
  end type OutFrame
```

### `RT_HistVarDesc` (lines 271–276)

```fortran
  type, public :: RT_HistVarDesc
    integer(i4) :: kind = 0_i4
    character(len=32) :: name = ''
    integer(i4) :: location = 0_i4
    logical :: is_vector = .false.
  end type RT_HistVarDesc
```

### `RT_HistReq` (lines 278–284)

```fortran
  type, public :: RT_HistReq
    logical :: active = .false.
    integer(i4) :: region_type = 0_i4
    character(len=64) :: region_name = ''
    integer(i4) :: num_vars = 0_i4
    type(RT_HistVarDesc), allocatable :: vars(:)
  end type RT_HistReq
```

### `RT_StepHistCfg` (lines 286–290)

```fortran
  type, public :: RT_StepHistCfg
    integer(i4) :: step_id = 0_i4
    integer(i4) :: num_history = 0_i4
    type(RT_HistReq), allocatable :: histories(:)
  end type RT_StepHistCfg
```

### `NodeSetHistMetaRecord` (lines 300–303)

```fortran
  type, public :: NodeSetHistMetaRecord
    integer(i4) :: nodeSetId
    character(len=NODESET_HISTORY) :: region_name
  end type NodeSetHistMetaRecord
```

### `HistRegionCatalogEntry` (lines 305–311)

```fortran
  type, public :: HistRegionCatalogEntry
    integer(i4) :: nodeSetId
    character(len=NODESET_HISTORY) :: region_name
    character(len=32) :: category
    character(len=32) :: region_kind
    character(len=64) :: source_var
  end type HistRegionCatalogEntry
```

### `HistNodeSetRegionLink` (lines 313–317)

```fortran
  type, public :: HistNodeSetRegionLink
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: catalogIndex
  end type HistNodeSetRegionLink
```

### `StepHistConfigEntry` (lines 319–328)

```fortran
  type, public :: StepHistConfigEntry
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: varIndex
    integer(i4) :: region_type
    integer(i4) :: location
    integer(i4) :: is_vector
    character(len=NODESET_HISTORY) :: region_name
    character(len=32) :: name
  end type StepHistConfigEntry
```

### `ElsetHistScalarEntry` (lines 330–335)

```fortran
  type, public :: ElsetHistScalarEntry
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: varIndex
    real(wp) :: value
  end type ElsetHistScalarEntry
```

### `MD_Out_Desc` (lines 1409–1411)

```fortran
TYPE, PUBLIC :: MD_Out_Desc
  TYPE(OutDesc), POINTER :: inner => NULL()
END TYPE MD_Out_Desc
```

### `MD_Out_State` (lines 1413–1415)

```fortran
TYPE, PUBLIC :: MD_Out_State
  TYPE(OutSta), POINTER :: inner => NULL()
END TYPE MD_Out_State
```

### `MD_Out_Ctx` (lines 1417–1419)

```fortran
TYPE, PUBLIC :: MD_Out_Ctx
  TYPE(OutCtx), POINTER :: inner => NULL()
END TYPE MD_Out_Ctx
```

### `MD_Out_Arg` (lines 1424–1438)

```fortran
TYPE, PUBLIC :: MD_Out_Arg
  ! [IN] output requests
  TYPE(MD_Out_Desc) :: desc             ! [IN]  output descriptor
  TYPE(MD_Out_State) :: state           ! [INOUT] output state
  TYPE(MD_Out_Ctx) :: ctx               ! [INOUT] output context

  ! [IN] field data to output
  INTEGER(i4) :: n_field_vars           ! [IN]  number of field variables
  REAL(wp), ALLOCATABLE :: field_data(:,:) ! [IN]  field data array

  ! [OUT] result
  INTEGER(i4) :: n_frames_written       ! [OUT] number of frames written
  INTEGER(i4) :: status_code            ! [OUT] exit status
  CHARACTER(len=256) :: message         ! [OUT] status message
END TYPE MD_Out_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Out_BindInput` | 339 | `subroutine RT_Out_BindInput(modelDef)` |
| SUBROUTINE | `RT_Out_UpdInput` | 347 | `subroutine RT_Out_UpdInput(modelDef)` |
| SUBROUTINE | `RT_Out_RecordHist` | 366 | `subroutine RT_Out_RecordHist(id, incId, time)` |
| SUBROUTINE | `RT_Out_RecordField` | 397 | `subroutine RT_Out_RecordField(id, incId, time)` |
| SUBROUTINE | `RT_Out_RecordAll` | 415 | `subroutine RT_Out_RecordAll(id)` |
| SUBROUTINE | `RT_Out_RecordNodeSetHist` | 444 | `subroutine RT_Out_RecordNodeSetHist(id, incId, time)` |
| SUBROUTINE | `RT_Out_PEEQ_DP` | 476 | `subroutine RT_Out_PEEQ_DP(id)` |
| SUBROUTINE | `RT_EnsureModelStateHistory` | 492 | `subroutine RT_EnsureModelStateHistory(nSteps, status)` |
| SUBROUTINE | `RT_UpdateModelStateHistory` | 513 | `subroutine RT_UpdateModelStateHistory(id, values)` |
| SUBROUTINE | `RT_EnsureNodeSetHistoryU` | 530 | `subroutine RT_EnsureNodeSetHistoryU(nSteps, nodeSetIds, status)` |
| SUBROUTINE | `RT_UpdateNodeSetHistoryU` | 548 | `subroutine RT_UpdateNodeSetHistoryU(id, nodeSetId, uAvg, uMax, uMin)` |
| SUBROUTINE | `RT_EnsureNodeSetHistoryMeta` | 570 | `subroutine RT_EnsureNodeSetHistoryMeta(nSteps, nodeSetIds, status)` |
| SUBROUTINE | `RT_UpdateNodeSetHistoryMeta` | 596 | `subroutine RT_UpdateNodeSetHistoryMeta(nodeSetId, regionName)` |
| SUBROUTINE | `RT_BuildNodeSetHistoryRegion` | 629 | `subroutine RT_BuildNodeSetHistoryRegion(catalog, nEntries)` |
| SUBROUTINE | `RT_BuildHistoryNodeSetRegion` | 637 | `subroutine RT_BuildHistoryNodeSetRegion(links, nLinks)` |
| SUBROUTINE | `RT_DumpStepHistoryConfig` | 645 | `subroutine RT_DumpStepHistoryConfig(configs, nSteps)` |
| SUBROUTINE | `RT_EnsureElsetHistoryScalar` | 676 | `subroutine RT_EnsureElsetHistoryScalar(nEntries, status)` |
| SUBROUTINE | `RT_UpdateElsetHistoryScalar` | 708 | `subroutine RT_UpdateElsetHistoryScalar(id, histIndex, varIndex, value)` |
| SUBROUTINE | `RT_BuildElsetHistoryRegionCa` | 745 | `subroutine RT_BuildElsetHistoryRegionCa(catalog, nEntries)` |
| SUBROUTINE | `RT_BuildElsetHistoryRegionLi` | 753 | `subroutine RT_BuildElsetHistoryRegionLi(links, nLinks)` |
| SUBROUTINE | `RT_Out_RecordScalarVariable` | 765 | `subroutine RT_Out_RecordScalarVariable(step_id, hist_id, var_id, inc_id, time)` |
| SUBROUTINE | `RT_Out_RecordVectorVariable` | 804 | `subroutine RT_Out_RecordVectorVariable(step_id, hist_id, var_id, inc_id, time)` |
| SUBROUTINE | `RT_Out_RecordFieldFrame` | 842 | `subroutine RT_Out_RecordFieldFrame(step_id, increment_id, time, frame, status)` |
| SUBROUTINE | `RT_Out_RecordHistoryFrame` | 872 | `subroutine RT_Out_RecordHistoryFrame(step_id, increment_id, time, var_id, values, status)` |
| FUNCTION | `RT_Out_ShouldOutputField` | 897 | `function RT_Out_ShouldOutputField(field_req, increment_id, time, last_output_tim) result(should_output)` |
| FUNCTION | `RT_Out_ShouldOutputHistory` | 911 | `function RT_Out_ShouldOutputHistory(hist_req, increment_id, time, last_output_tim) result(should_output)` |
| SUBROUTINE | `OutDesc_Init` | 925 | `subroutine OutDesc_Init(this, outputId, name, outputType)` |
| SUBROUTINE | `OutDesc_RegLayout` | 935 | `subroutine OutDesc_RegLayout(this)` |
| SUBROUTINE | `OutDesc_Ensure` | 960 | `subroutine OutDesc_Ensure(this)` |
| SUBROUTINE | `OutDesc_Valid` | 969 | `subroutine OutDesc_Valid(this, status)` |
| SUBROUTINE | `OutSta_Init` | 996 | `subroutine OutSta_Init(this, outputId)` |
| SUBROUTINE | `OutSta_RegLayout` | 1003 | `subroutine OutSta_RegLayout(this)` |
| SUBROUTINE | `OutSta_Ensure` | 1022 | `subroutine OutSta_Ensure(this)` |
| SUBROUTINE | `OutCtx_Init` | 1031 | `subroutine OutCtx_Init(this, outputId)` |
| SUBROUTINE | `OutCtx_RegLayout` | 1038 | `subroutine OutCtx_RegLayout(this)` |
| SUBROUTINE | `OutCtx_Ensure` | 1053 | `subroutine OutCtx_Ensure(this)` |
| SUBROUTINE | `FieldOutDesc_Init` | 1062 | `subroutine FieldOutDesc_Init(this, outputId, name, frequency, frequencyType)` |
| SUBROUTINE | `FieldOutDesc_RegLayout` | 1073 | `subroutine FieldOutDesc_RegLayout(this)` |
| SUBROUTINE | `FieldOutDesc_Ensure` | 1102 | `subroutine FieldOutDesc_Ensure(this)` |
| SUBROUTINE | `FldOutDesc_Valid` | 1111 | `subroutine FldOutDesc_Valid(this, status)` |
| SUBROUTINE | `HistoryOutDesc_Init` | 1138 | `subroutine HistoryOutDesc_Init(this, outputId, name, frequency, frequencyType)` |
| SUBROUTINE | `HistoryOutDesc_RegLayout` | 1149 | `subroutine HistoryOutDesc_RegLayout(this)` |
| SUBROUTINE | `HistoryOutDesc_Ensure` | 1178 | `subroutine HistoryOutDesc_Ensure(this)` |
| SUBROUTINE | `HistOutDesc_Valid` | 1187 | `subroutine HistOutDesc_Valid(this, status)` |
| SUBROUTINE | `FldOutReq_Init` | 1215 | `subroutine FldOutReq_Init(this, name, region_name, region_type, position, frequency, frequency_type)` |
| SUBROUTINE | `FldOutReq_AddVariable` | 1229 | `subroutine FldOutReq_AddVariable(this, var_id)` |
| FUNCTION | `FldOutReq_ShouldOutput` | 1258 | `function FldOutReq_ShouldOutput(this, increment_id, time, last_output_tim) result(should_output)` |
| SUBROUTINE | `FldOutReq_Clear` | 1287 | `subroutine FldOutReq_Clear(this)` |
| SUBROUTINE | `HistOutReq_Init` | 1310 | `subroutine HistOutReq_Init(this, name, region_name, region_type, frequency, frequency_type)` |
| SUBROUTINE | `HistOutReq_AddVariable` | 1323 | `subroutine HistOutReq_AddVariable(this, var_id)` |
| FUNCTION | `HistOutReq_ShouldOutput` | 1352 | `function HistOutReq_ShouldOutput(this, increment_id, time, last_output_tim) result(should_output)` |
| SUBROUTINE | `HistOutReq_Clear` | 1381 | `subroutine HistOutReq_Clear(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
