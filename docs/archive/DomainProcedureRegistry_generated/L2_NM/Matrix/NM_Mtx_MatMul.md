# `NM_Mtx_MatMul.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_MatMul.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Mtx_MatMul`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_MatMul`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx_MatMul`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_MatMul.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DGEMM` | 20 | `SUBROUTINE DGEMM(TRANSA, TRANSB, M, N, K, ALPHA, A, LDA, B, LDB, BETA, C, LDC) &` |
| SUBROUTINE | `NM_MatMul_Dense` | 37 | `SUBROUTINE NM_MatMul_Dense(A, B, C, transa, transb, alpha, beta)` |
| SUBROUTINE | `NM_MatMul_Add` | 107 | `SUBROUTINE NM_MatMul_Add(A, B, D, C, alpha)` |
| SUBROUTINE | `NM_MatMul_Sparse_CSR` | 135 | `SUBROUTINE NM_MatMul_Sparse_CSR(A, B, C, alpha, beta)` |
| SUBROUTINE | `NM_SpMV_CSR` | 184 | `SUBROUTINE NM_SpMV_CSR(A, x, y, alpha, beta)` |
| SUBROUTINE | `NM_SpMV_Transpose_CSR` | 234 | `SUBROUTINE NM_SpMV_Transpose_CSR(A, x, y, alpha, beta)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 19–29 | `INTERFACE` |
