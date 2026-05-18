# `RT_AI_ConvPredictAlgo.f90`

- **Source**: `L5_RT/Solver/RT_AI_ConvPredictAlgo.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_AI_ConvPredictAlgo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_AI_ConvPredictAlgo`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_AI_ConvPredictAlgo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_AI_ConvPredictAlgo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AI_ConvPredict_Type` (lines 36–62)

```fortran
  TYPE, PUBLIC :: AI_ConvPredict_Type
    !-------------------------------------------------------------------------
    ! Algorithm configuration (冷数据，Write-Once)
    !-------------------------------------------------------------------------
    INTEGER(i4) :: predictor_type = 0        ! 0=Aitken, 1=Krylov, 2=AI-RNN
    REAL(wp)    :: tolerance = 1e-6_wp       ! Convergence tolerance
    INTEGER(i4) :: max_iterations = 100      ! Maximum Newton iterations
    
    ! Residual history (fixed-size array, AP-8 compliant)
    INTEGER(i4) :: history_window = 10       ! Number of stored residuals
    REAL(wp)    :: res_history(32) = 0.0_wp  ! Fixed-size residual history
    INTEGER(i4) :: history_index = 0         ! Current position in history
    
    ! AI model parameters (for RNN-based predictor)
    INTEGER(i4) :: rnn_hidden_dim = 32       ! RNN hidden dimension
    REAL(wp), ALLOCATABLE :: rnn_weights(:)  ! RNN weights (if AI-RNN)
    
    ! Aitken relaxation parameters
    REAL(wp)    :: aitken_relax_factor = 1.0_wp ! Aitken relaxation factor
    LOGICAL     :: use_adaptive_relax = .TRUE.  ! Enable adaptive relaxation
    
    ! Performance metrics
    REAL(wp)    :: prediction_time = 0.0_wp  ! Prediction time per iteration
    INTEGER(i4) :: total_predictions = 0     ! Total number of predictions
    INTEGER(i4) :: successful_predictions = 0 ! Successful predictions
    
  END TYPE AI_ConvPredict_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AI_ConvPredict_Init` | 70 | `SUBROUTINE AI_ConvPredict_Init(conv_algo, tolerance, max_iter, status)` |
| SUBROUTINE | `AI_ConvPredict_Finalize` | 102 | `SUBROUTINE AI_ConvPredict_Finalize(conv_algo, status)` |
| SUBROUTINE | `AI_ConvPredict_Update` | 120 | `SUBROUTINE AI_ConvPredict_Update(conv_algo, residual_norm, iteration, status)` |
| SUBROUTINE | `AI_ConvPredict_Predict` | 144 | `SUBROUTINE AI_ConvPredict_Predict(conv_algo, will_converge, predicted_iters, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
