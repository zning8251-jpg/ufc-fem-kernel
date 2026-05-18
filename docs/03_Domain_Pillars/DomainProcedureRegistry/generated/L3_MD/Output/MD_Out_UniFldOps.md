# `MD_Out_UniFldOps.f90`

- **Source**: `L3_MD/Output/MD_Out_UniFldOps.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Out_UniFldOps`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_UniFldOps`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out_UniFldOps`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_UniFldOps.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_ShapeFuncResult` (lines 126–138)

```fortran
  type, public :: MD_ShapeFuncResult
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nDim = 0_i4

    real(wp), allocatable :: N(:)
    real(wp), allocatable :: dNdxi(:,:)
    real(wp), allocatable :: dNdx(:,:)
    real(wp), allocatable :: d2Ndxi2(:,:,:)
    real(wp), allocatable :: d2Ndx2(:,:,:)
  contains
    procedure, public :: Init => MD_ShapeFuncResult_Init
    procedure, public :: Cleanup => MD_ShapeFuncResult_Cleanup
  end type MD_ShapeFuncResult
```

### `MD_BoundaryCondition` (lines 143–164)

```fortran
  type, public :: MD_BoundaryCondition
    integer(i4) :: bcId = 0_i4
    integer(i4) :: bcType = MD_BC_TYPE_DISP
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: dofIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: amplitudes(:)
    character(len=64) :: amplitudeName = ""

    logical :: isActive = .true.
    logical :: isAmplitude = .false.
    real(wp) :: startTime = 0.0_wp
    real(wp) :: endTime = huge(1.0_wp)
  contains
    procedure, public :: Init => MD_BoundaryCondition_Init
    procedure, public :: SetNodes => MD_BoundaryCondition_SetNodes
    procedure, public :: SetValues => MD_BoundaryCondition_SetValues
    procedure, public :: IsActiveAtTime => MD_BoundaryCondition_IsActiveAtTime
  end type MD_BoundaryCondition
```

### `MD_InitialCondition` (lines 169–185)

```fortran
  type, public :: MD_InitialCondition
    integer(i4) :: icId = 0_i4
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: dofIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: velocities(:)
    real(wp), allocatable :: accelerations(:)

    logical :: isApplied = .false.
  contains
    procedure, public :: Init => MD_InitialCondition_Init
    procedure, public :: SetNodes => MD_InitialCondition_SetNodes
    procedure, public :: SetValues => MD_InitialCondition_SetValues
  end type MD_InitialCondition
```

### `MD_Load` (lines 190–215)

```fortran
  type, public :: MD_Load
    integer(i4) :: loadId = 0_i4
    integer(i4) :: loadType = MD_LOAD_TYPE_CONCENTRATED
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: elementIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: directions(:)
    real(wp), allocatable :: magnitudes(:)

    real(wp), allocatable :: amplitudes(:)
    character(len=64) :: amplitudeName = ""

    logical :: isActive = .true.
    logical :: isAmplitude = .false.
    real(wp) :: startTime = 0.0_wp
    real(wp) :: endTime = huge(1.0_wp)
  contains
    procedure, public :: Init => MD_Load_Init
    procedure, public :: SetNodes => MD_Load_SetNodes
    procedure, public :: SetElements => MD_Load_SetElements
    procedure, public :: SetValues => MD_Load_SetValues
    procedure, public :: IsActiveAtTime => MD_Load_IsActiveAtTime
  end type MD_Load
```

### `MD_OutReq` (lines 220–243)

```fortran
  type, public :: MD_OutReq
    integer(i4) :: outputId = 0_i4
    integer(i4) :: outputType = MD_OUTPUT_FIELD

    integer(i4), allocatable :: fieldIds(:)
    integer(i4), allocatable :: variableIds(:)

    character(len=256) :: fileName = ""
    character(len=64) :: format = "ASCII"

    integer(i4) :: frequency = 1_i4
    integer(i4) :: interval = 1_i4
    real(wp) :: timeInterval = 0.0_wp

    logical :: isActive = .true.
    logical :: isInitialized = .false.
    integer(i4) :: lastOutputStep = 0_i4
    real(wp) :: lastOutputTime = 0.0_wp
  contains
    procedure, public :: Init => MD_OutReq_Init
    procedure, public :: SetFields => MD_OutReq_SetFields
    procedure, public :: SetFrequency => MD_OutReq_SetFrequency
    procedure, public :: ShouldOutput => MD_OutReq_ShouldOutput
  end type MD_OutReq
```

### `MD_PostProcessor` (lines 248–265)

```fortran
  type, public :: MD_PostProcessor
    integer(i4) :: nPoints = 0_i4
    integer(i4) :: nDim = 0_i4

    real(wp), allocatable :: coordinates(:,:)
    real(wp), allocatable :: fieldValues(:,:)
    real(wp), allocatable :: gradients(:,:,:)

    character(len=64) :: contourVariable = ""
    real(wp) :: contourMin = 0.0_wp
    real(wp) :: contourMax = 0.0_wp
    integer(i4) :: nContourLevels = 10_i4
  contains
    procedure, public :: Init => MD_PostProcessor_Init
    procedure, public :: SetPoints => MD_PostProcessor_SetPoints
    procedure, public :: SetContour => MD_PostProcessor_SetContour
    procedure, public :: Cleanup => MD_PostProcessor_Cleanup
  end type MD_PostProcessor
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_ShapeFuncResult_Init` | 272 | `subroutine MD_ShapeFuncResult_Init(this, nNodes, nDim)` |
| SUBROUTINE | `MD_ShapeFuncResult_Cleanup` | 294 | `subroutine MD_ShapeFuncResult_Cleanup(this)` |
| SUBROUTINE | `ComputeShapeFunctions` | 307 | `subroutine ComputeShapeFunctions(result, xi, eta, zeta, ElemType, status)` |
| SUBROUTINE | `ComputeShapeFunc_2DQuad` | 333 | `subroutine ComputeShapeFunc_2DQuad(result, xi, eta)` |
| SUBROUTINE | `ComputeShapeFunc_2DTri` | 358 | `subroutine ComputeShapeFunc_2DTri(result, xi, eta)` |
| SUBROUTINE | `ComputeShapeFunc_3DHex` | 375 | `subroutine ComputeShapeFunc_3DHex(result, xi, eta, zeta)` |
| SUBROUTINE | `ComputeShapeFunc_3DTet` | 416 | `subroutine ComputeShapeFunc_3DTet(result, xi, eta, zeta)` |
| SUBROUTINE | `InterpolateField` | 441 | `subroutine InterpolateField(fieldState, result, values, status)` |
| SUBROUTINE | `ComputeFieldGradient` | 470 | `subroutine ComputeFieldGradient(fieldState, result, jacobian, gradient, status)` |
| SUBROUTINE | `ComputeFieldHessian` | 528 | `subroutine ComputeFieldHessian(fieldState, result, gradient, hessian, status)` |
| SUBROUTINE | `CreateBoundaryCondition` | 557 | `subroutine CreateBoundaryCondition(bc, bcId, bcType, fieldType, status)` |
| SUBROUTINE | `MD_BoundaryCondition_Init` | 568 | `subroutine MD_BoundaryCondition_Init(this, bcId, bcType, fieldType)` |
| SUBROUTINE | `MD_Bo_SetNodes` | 581 | `subroutine MD_Bo_SetNodes(this, nodeIds, dofIds, values)` |
| SUBROUTINE | `MD_Bo_SetValues` | 608 | `subroutine MD_Bo_SetValues(this, values, amplitudes, amplitudeName)` |
| FUNCTION | `MD_BoundaryCondition_IsActiveAtTime` | 630 | `function MD_BoundaryCondition_IsActiveAtTime(this, currentTime) result(isActive)` |
| SUBROUTINE | `ApplyBoundaryCondition` | 638 | `subroutine ApplyBoundaryCondition(fieldState, bc, currentTime, status)` |
| SUBROUTINE | `RemoveBoundaryCondition` | 672 | `subroutine RemoveBoundaryCondition(fieldState, bc, status)` |
| SUBROUTINE | `GetBoundaryCondition` | 694 | `subroutine GetBoundaryCondition(bc, bcId, bcType, fieldType, nodeIds, dofIds, values, status)` |
| SUBROUTINE | `CreateInitialCondition` | 734 | `subroutine CreateInitialCondition(ic, icId, fieldType, status)` |
| SUBROUTINE | `MD_InitialCondition_Init` | 745 | `subroutine MD_InitialCondition_Init(this, icId, fieldType)` |
| SUBROUTINE | `MD_InitialCondition_SetNodes` | 754 | `subroutine MD_InitialCondition_SetNodes(this, nodeIds, dofIds)` |
| SUBROUTINE | `MD_In_SetValues` | 774 | `subroutine MD_In_SetValues(this, values, velocities, accelerations)` |
| SUBROUTINE | `ApplyInitialCondition` | 796 | `subroutine ApplyInitialCondition(fieldState, ic, status)` |
| SUBROUTINE | `GetInitialCondition` | 835 | `subroutine GetInitialCondition(ic, icId, fieldType, nodeIds, dofIds, values, velocities, accelerations, status)` |
| SUBROUTINE | `CreateLoad` | 884 | `subroutine CreateLoad(load, loadId, loadType, fieldType, status)` |
| SUBROUTINE | `MD_Load_Init` | 895 | `subroutine MD_Load_Init(this, loadId, loadType, fieldType)` |
| SUBROUTINE | `MD_Load_SetNodes` | 908 | `subroutine MD_Load_SetNodes(this, nodeIds, values)` |
| SUBROUTINE | `MD_Load_SetElements` | 928 | `subroutine MD_Load_SetElements(this, elementIds, values)` |
| SUBROUTINE | `MD_Load_SetValues` | 948 | `subroutine MD_Load_SetValues(this, values, directions, magnitudes, amplitudes, amplitudeName)` |
| FUNCTION | `MD_Load_IsActiveAtTime` | 982 | `function MD_Load_IsActiveAtTime(this, currentTime) result(isActive)` |
| SUBROUTINE | `ApplyLoad` | 990 | `subroutine ApplyLoad(fieldState, load, currentTime, status)` |
| SUBROUTINE | `RemoveLoad` | 1006 | `subroutine RemoveLoad(fieldState, load, status)` |
| SUBROUTINE | `GetLoad` | 1016 | `subroutine GetLoad(load, loadId, loadType, fieldType, nodeIds, elementIds, values, status)` |
| SUBROUTINE | `CreateOutputRequest` | 1056 | `subroutine CreateOutputRequest(output, outputId, outputType, status)` |
| SUBROUTINE | `MD_OutReq_Init` | 1067 | `subroutine MD_OutReq_Init(this, outputId, outputType)` |
| SUBROUTINE | `MD_OutReq_SetFields` | 1082 | `subroutine MD_OutReq_SetFields(this, fieldIds, variableIds)` |
| SUBROUTINE | `MD_OutReq_SetFrequency` | 1098 | `subroutine MD_OutReq_SetFrequency(this, frequency, interval, timeInterval)` |
| FUNCTION | `MD_OutReq_ShouldOutput` | 1108 | `function MD_OutReq_ShouldOutput(this, currentStep, currentTime) result(shouldOutput)` |
| SUBROUTINE | `SetupOutput` | 1131 | `subroutine SetupOutput(output, fileName, format, status)` |
| SUBROUTINE | `WriteOutput` | 1145 | `subroutine WriteOutput(output, fieldManager, currentStep, currentTime, status)` |
| SUBROUTINE | `FinalizeOutput` | 1166 | `subroutine FinalizeOutput(output, status)` |
| SUBROUTINE | `CreatePostProcessor` | 1180 | `subroutine CreatePostProcessor(postProcessor, nPoints, nDim, status)` |
| SUBROUTINE | `MD_PostProcessor_Init` | 1206 | `subroutine MD_PostProcessor_Init(this, nPoints, nDim)` |
| SUBROUTINE | `MD_PostProcessor_SetPoints` | 1227 | `subroutine MD_PostProcessor_SetPoints(this, coordinates, fieldValues, gradients)` |
| SUBROUTINE | `MD_PostProcessor_SetContour` | 1248 | `subroutine MD_PostProcessor_SetContour(this, variable, minValue, maxValue, nLevels)` |
| SUBROUTINE | `ComputeContourData` | 1263 | `subroutine ComputeContourData(postProcessor, contourLevels, contourValues, status)` |
| SUBROUTINE | `ComputeVectorData` | 1292 | `subroutine ComputeVectorData(postProcessor, vectorData, status)` |
| SUBROUTINE | `ComputeTensorData` | 1311 | `subroutine ComputeTensorData(postProcessor, tensorData, status)` |
| SUBROUTINE | `MD_PostProcessor_Cleanup` | 1334 | `subroutine MD_PostProcessor_Cleanup(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
