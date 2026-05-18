# `PH_AI_ContactLaw.f90`

- **Source**: `L4_PH/Contact/AI/PH_AI_ContactLaw.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_AI_ContactLaw`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_AI_ContactLaw`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_AI_ContactLaw`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/AI/PH_AI_ContactLaw.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AI_ContactLaw_Type` (lines 26–48)

```fortran
  TYPE, PUBLIC :: AI_ContactLaw_Type
    !-------------------------------------------------------------------------
    ! Model configuration (冷数据，Write-Once)
    !-------------------------------------------------------------------------
    CHARACTER(LEN=256) :: model_path = ""        ! Path to ONNX model file
    INTEGER(i4) :: contact_model_type = 0        ! 0=Hertz, 1=Friction, 2=Wear
    INTEGER(i4) :: input_dim = 0                 ! Input feature dimension
    INTEGER(i4) :: output_dim = 0                ! Output dimension (pressure + traction)
    
    ! Neural network architecture
    INTEGER(i4) :: num_hidden_layers = 2         ! Number of hidden layers
    INTEGER(i4) :: hidden_layer_dims(8) = 0      ! Hidden layer dimensions
    
    ! Contact physics parameters
    REAL(wp)    :: penalty_stiffness = 1e5_wp    ! Contact penalty stiffness
    REAL(wp)    :: friction_coefficient = 0.3_wp ! Friction coefficient (μ)
    LOGICAL     :: enable_wear = .FALSE.         ! Enable wear prediction
    
    ! Performance metrics
    REAL(wp)    :: inference_time = 0.0_wp       ! Inference time per contact pair
    INTEGER(i4) :: total_predictions = 0         ! Total number of predictions
    
  END TYPE AI_ContactLaw_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AI_ContactLaw_Init` | 56 | `SUBROUTINE AI_ContactLaw_Init(contact_algo, model_path, model_type, status)` |
| SUBROUTINE | `AI_ContactLaw_Finalize` | 87 | `SUBROUTINE AI_ContactLaw_Finalize(contact_algo, status)` |
| SUBROUTINE | `AI_ContactLaw_Predict` | 102 | `SUBROUTINE AI_ContactLaw_Predict(contact_algo, gap, slip, pressure, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
