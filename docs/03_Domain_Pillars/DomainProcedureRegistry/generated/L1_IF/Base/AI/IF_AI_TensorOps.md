# `IF_AI_TensorOps.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_TensorOps.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_AI_TensorOps`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_TensorOps`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI_TensorOps`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_TensorOps.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Tensor_MatMul` | 30 | `PURE SUBROUTINE IF_AI_Tensor_MatMul(A, B, C, M, N, K_DIM)` |
| SUBROUTINE | `IF_AI_Tensor_Conv2D` | 69 | `SUBROUTINE IF_AI_Tensor_Conv2D(input, kernel, output, &` |
| SUBROUTINE | `IF_AI_Tensor_ReLU` | 134 | `PURE SUBROUTINE IF_AI_Tensor_ReLU(x, y, n)` |
| SUBROUTINE | `IF_AI_Tensor_Sigmoid` | 158 | `PURE SUBROUTINE IF_AI_Tensor_Sigmoid(x, y, n)` |
| SUBROUTINE | `IF_AI_Tensor_Softmax` | 186 | `PURE SUBROUTINE IF_AI_Tensor_Softmax(x, y, n)` |
| SUBROUTINE | `IF_AI_Tensor_AddBias` | 223 | `PURE SUBROUTINE IF_AI_Tensor_AddBias(x, bias, y, n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
