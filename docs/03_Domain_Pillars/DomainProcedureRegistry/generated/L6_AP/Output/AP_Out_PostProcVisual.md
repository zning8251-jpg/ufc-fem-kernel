# `AP_Out_PostProcVisual.f90`

- **Source**: `L6_AP/Output/AP_Out_PostProcVisual.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Out_PostProcVisual`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_PostProcVisual`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out_PostProcVisual`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_PostProcVisual.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `VisualizationManagerType` (lines 33–78)

```fortran
    TYPE :: VisualizationManagerType
        !  
        CHARACTER(LEN=256) :: job_name = ""                !  
        CHARACTER(LEN=256) :: odb_file = ""                ! ODB 
        LOGICAL :: auto_scale = .TRUE.                      !  
        LOGICAL :: show_legend = .TRUE.                     !  
        LOGICAL :: show_axes = .TRUE.                        !  
        CHARACTER(LEN=20) :: color_scheme = "RAINBOW"        !  
        REAL(wp) :: deformation_scale = 1.0d0            !  
        
        !  
        INTEGER(i4) :: num_viewports = 1                 !  
        TYPE(ViewportType), ALLOCATABLE :: viewports(:)      !  
        INTEGER(i4) :: active_viewport = 1               !  
        
        !  
        TYPE(PlotConfigType) :: plot_config                 !  
        TYPE(ContourConfigType) :: contour_config           !  value 
        TYPE(VectorConfigType) :: vector_config              !  
        TYPE(DeformedConfigType) :: deformed_config          !  
        
        !  
        TYPE(AnimationConfigType) :: animation_config        !  
        LOGICAL :: animation_enabled = .FALSE.                !  
        INTEGER(i4) :: total_frames = 0                  !  
        
        ! output 
        CHARACTER(LEN=20) :: output_format = "PNG"          ! output  (PNG/JPG/SVG)
        INTEGER(i4) :: output_resolution_x = 1920        ! output X
        INTEGER(i4) :: output_resolution_y = 1080        ! output Y
        REAL(wp) :: output_dpi = 300.0d0                ! outputDPI
        
        ! status 
        LOGICAL :: visualization_initialized = .FALSE.      !  init
        INTEGER(i4) :: current_frame = 0                 !  
        
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: CreateViewport
        PROCEDURE :: PlotField
        PROCEDURE :: PlotContour
        PROCEDURE :: PlotVector
        PROCEDURE :: PlotDeformedShape
        PROCEDURE :: CreateAnimation
        PROCEDURE :: ExportResults
    END TYPE VisualizationManagerType
```

### `ViewportType` (lines 81–104)

```fortran
    TYPE :: ViewportType
        INTEGER(i4) :: viewport_id = 0                    !  ID
        CHARACTER(LEN=100) :: title = ""                     !  
        REAL(wp) :: view_center(3) = 0.0d0              !  
        REAL(wp) :: view_scale = 1.0d0                  !  
        REAL(wp) :: rotation_angles(3) = 0.0d0          !  
        LOGICAL :: is_visible = .TRUE.                       ! whether 
        
        !  set
        LOGICAL :: show_mesh = .TRUE.                        !  
        LOGICAL :: show_deformed = .FALSE.                   !  
        LOGICAL :: show_field_output = .TRUE.                !  output
        CHARACTER(LEN=50) :: active_field = ""                !  
        INTEGER(i4) :: contour_levels = 20                !  value -grade 
        
        !  
        REAL(wp) :: x_min = -1.0d0                       ! X value
        REAL(wp) :: x_max = 1.0d0                        ! X value
        REAL(wp) :: y_min = -1.0d0                       ! Y value
        REAL(wp) :: y_max = 1.0d0                        ! Y value
        REAL(wp) :: z_min = -1.0d0                       ! Z value
        REAL(wp) :: z_max = 1.0d0                        ! Z value
        
    END TYPE ViewportType
```

### `PlotConfigType` (lines 107–115)

```fortran
    TYPE :: PlotConfigType
        CHARACTER(LEN=50) :: plot_type = ""                  !  
        CHARACTER(LEN=50) :: variable_name = ""              !  
        INTEGER(i4) :: component = 1                      !  
        REAL(wp) :: min_value = 0.0d0                    !  value
        REAL(wp) :: max_value = 1.0d0                    !  value
        LOGICAL :: auto_range = .TRUE.                       !  
        CHARACTER(LEN=20) :: interpolation = "LINEAR"        !  value 
    END TYPE PlotConfigType
```

### `ContourConfigType` (lines 118–125)

```fortran
    TYPE :: ContourConfigType
        INTEGER(i4) :: num_levels = 20                    !  value -grade 
        REAL(wp), ALLOCATABLE :: levels(:)               !  value value
        LOGICAL :: show_labels = .TRUE.                     !  
        CHARACTER(LEN=20) :: line_style = "SOLID"            !  
        REAL(wp) :: line_width = 1.0d0                   !  
        LOGICAL :: fill_contours = .TRUE.                    !  value 
    END TYPE ContourConfigType
```

### `VectorConfigType` (lines 128–135)

```fortran
    TYPE :: VectorConfigType
        CHARACTER(LEN=20) :: vector_type = "ARROW"            !   (ARROW/NEEDLE)
        REAL(wp) :: scale_factor = 1.0d0                  !  
        REAL(wp) :: max_length = 0.1d0                   !  length
        LOGICAL :: normalize_vectors = .FALSE.               !  
        LOGICAL :: show_magnitude = .TRUE.                   !  
        CHARACTER(LEN=20) :: color_by = "MAGNITUDE"          !  
    END TYPE VectorConfigType
```

### `DeformedConfigType` (lines 138–145)

```fortran
    TYPE :: DeformedConfigType
        REAL(wp) :: deformation_scale = 1.0d0            !  
        LOGICAL :: show_undeformed = .TRUE.                  !  
        LOGICAL :: show_deformed = .TRUE.                    !  
        CHARACTER(LEN=20) :: undeformed_color = "GRAY"       !  
        CHARACTER(LEN=20) :: deformed_color = "BLACK"        !  
        REAL(wp) :: undeformed_opacity = 0.5d0           !  
    END TYPE DeformedConfigType
```

### `AnimationConfigType` (lines 148–157)

```fortran
    TYPE :: AnimationConfigType
        LOGICAL :: enable_animation = .FALSE.                !  
        REAL(wp) :: frame_rate = 30.0d0                  !  
        INTEGER(i4) :: start_frame = 1                    !  
        INTEGER(i4) :: end_frame = 100                    !  
        REAL(wp) :: time_scale = 1.0d0                   ! time 
        LOGICAL :: loop_animation = .FALSE.                  !  
        CHARACTER(LEN=256) :: output_file = "animation"      ! output 
        CHARACTER(LEN=20) :: output_format = "MP4"            ! output 
    END TYPE AnimationConfigType
```

### `FieldOutputDataType` (lines 160–169)

```fortran
    TYPE :: FieldOutputDataType
        CHARACTER(LEN=50) :: variable_name = ""               !  
        INTEGER(i4) :: step_number = 0                    !  
        REAL(wp) :: step_time = 0.0d0                    !  time
        INTEGER(i4) :: num_points = 0                     !  
        INTEGER(i4) :: num_components = 0                 !  
        REAL(wp), ALLOCATABLE :: values(:,:)             !  value
        INTEGER(i4), ALLOCATABLE :: point_ids(:)          !  ID
        CHARACTER(LEN=20) :: location = ""                    !  
    END TYPE FieldOutputDataType
```

### `DeformationDataType` (lines 172–178)

```fortran
    TYPE :: DeformationDataType
        INTEGER(i4) :: num_nodes = 0                      ! node 
        REAL(wp), ALLOCATABLE :: undeformed_coords(:,:)   !  
        REAL(wp), ALLOCATABLE :: deformed_coords(:,:)     !  
        REAL(wp), ALLOCATABLE :: displacement(:,:)       ! displacement
        REAL(wp) :: max_displacement = 0.0d0             !  displacement
    END TYPE DeformationDataType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Visualization_Init` | 183 | `SUBROUTINE AP_Visualization_Init(this, config, status)` |
| SUBROUTINE | `AP_Vi_CreateViewport` | 234 | `SUBROUTINE AP_Vi_CreateViewport(this, viewport_config, status)` |
| SUBROUTINE | `AP_Visualization_PlotField` | 271 | `SUBROUTINE AP_Visualization_PlotField(this, viewport_id, field_data, status)` |
| SUBROUTINE | `AP_Visualization_PlotContour` | 312 | `SUBROUTINE AP_Visualization_PlotContour(this, viewport_id, field_data, status)` |
| SUBROUTINE | `AP_Visualization_PlotVector` | 347 | `SUBROUTINE AP_Visualization_PlotVector(this, viewport_id, field_data, status)` |
| SUBROUTINE | `AP_Vi_PlotDeformedShape` | 383 | `SUBROUTINE AP_Vi_PlotDeformedShape(this, viewport_id, deformation_data, status)` |
| SUBROUTINE | `AP_Vi_CreateAnimation` | 417 | `SUBROUTINE AP_Vi_CreateAnimation(this, animation_config, status)` |
| SUBROUTINE | `AP_Vi_ExportResults` | 459 | `SUBROUTINE AP_Vi_ExportResults(this, export_config, status)` |
| SUBROUTINE | `AP_InitializeViewports` | 493 | `SUBROUTINE AP_InitializeViewports(viewports, config)` |
| SUBROUTINE | `AP_ExpandViewportArray` | 514 | `SUBROUTINE AP_ExpandViewportArray(viewports, new_size)` |
| SUBROUTINE | `AP_CalculateFieldRange` | 536 | `SUBROUTINE AP_CalculateFieldRange(field_data, min_val, max_val)` |
| SUBROUTINE | `AP_SetContourLevels` | 560 | `SUBROUTINE AP_SetContourLevels(config, min_val, max_val)` |
| SUBROUTINE | `AP_InitializePlotConfig` | 578 | `SUBROUTINE AP_InitializePlotConfig(config)` |
| SUBROUTINE | `AP_InitializeContourConfig` | 589 | `SUBROUTINE AP_InitializeContourConfig(config)` |
| SUBROUTINE | `AP_InitializeVectorConfig` | 598 | `SUBROUTINE AP_InitializeVectorConfig(config)` |
| SUBROUTINE | `AP_InitializeDeformedConfig` | 608 | `SUBROUTINE AP_InitializeDeformedConfig(config)` |
| SUBROUTINE | `AP_GenerateFieldPlot` | 619 | `SUBROUTINE AP_GenerateFieldPlot(viewport, field_data, config, status)` |
| SUBROUTINE | `AP_GenerateContourPlot` | 630 | `SUBROUTINE AP_GenerateContourPlot(viewport, field_data, config, status)` |
| SUBROUTINE | `AP_GenerateVectorPlot` | 641 | `SUBROUTINE AP_GenerateVectorPlot(viewport, field_data, config, status)` |
| SUBROUTINE | `AP_GenerateDeformedPlot` | 652 | `SUBROUTINE AP_GenerateDeformedPlot(viewport, deformation_data, config, status)` |
| SUBROUTINE | `AP_GenerateAnimationFrame` | 663 | `SUBROUTINE AP_GenerateAnimationFrame(this, frame_number, status)` |
| SUBROUTINE | `AP_CompileAnimation` | 673 | `SUBROUTINE AP_CompileAnimation(this, status)` |
| SUBROUTINE | `AP_ExportViewport` | 682 | `SUBROUTINE AP_ExportViewport(viewport, export_config, status)` |
| FUNCTION | `AP_IntToString` | 693 | `FUNCTION AP_IntToString(value) RESULT(string)` |
| FUNCTION | `AP_RealToString` | 699 | `FUNCTION AP_RealToString(value) RESULT(string)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
