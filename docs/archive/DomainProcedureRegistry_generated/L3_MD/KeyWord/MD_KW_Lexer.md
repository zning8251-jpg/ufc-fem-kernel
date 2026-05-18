# `MD_KW_Lexer.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Lexer.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KW_Lexer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Lexer`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Lexer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Lexer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `kw_lexer_init` | 31 | `SUBROUTINE kw_lexer_init(state)` |
| SUBROUTINE | `kw_lexer_open_file` | 55 | `SUBROUTINE kw_lexer_open_file(state, filename, success)` |
| SUBROUTINE | `kw_lexer_close` | 95 | `SUBROUTINE kw_lexer_close(state)` |
| SUBROUTINE | `read_next_line` | 110 | `SUBROUTINE read_next_line(state, success)` |
| SUBROUTINE | `skip_whitespace` | 171 | `SUBROUTINE skip_whitespace(state)` |
| FUNCTION | `is_keyword_char` | 187 | `FUNCTION is_keyword_char(ch) RESULT(is_valid)` |
| FUNCTION | `is_value_char` | 204 | `FUNCTION is_value_char(ch) RESULT(is_valid)` |
| SUBROUTINE | `kw_lexer_next_token` | 217 | `SUBROUTINE kw_lexer_next_token(state, token)` |
| SUBROUTINE | `normalize_keyword_name` | 372 | `SUBROUTINE normalize_keyword_name(name)` |
| SUBROUTINE | `kw_lexer_peek_token` | 407 | `SUBROUTINE kw_lexer_peek_token(state, token)` |
| SUBROUTINE | `kw_lexer_push_back` | 420 | `SUBROUTINE kw_lexer_push_back(state, token)` |
| FUNCTION | `kw_lexer_get_line_num` | 433 | `FUNCTION kw_lexer_get_line_num(state) RESULT(line_num)` |
| FUNCTION | `kw_lexer_at_eof` | 444 | `FUNCTION kw_lexer_at_eof(state) RESULT(at_eof)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
