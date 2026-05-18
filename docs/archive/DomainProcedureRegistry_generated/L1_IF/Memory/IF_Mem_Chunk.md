# `IF_Mem_Chunk.f90`

- **Source**: `L1_IF/Memory/IF_Mem_Chunk.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_Chunk`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_Chunk`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_Chunk`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_Chunk.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ChunkMeta_Type` (lines 24–32)

```fortran
    TYPE, PUBLIC :: ChunkMeta_Type
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(KIND=8)    :: file_offset = 0_8
        INTEGER(KIND=8)    :: chunk_size  = 0_8
        INTEGER(i4) :: node_id     = 0
        LOGICAL            :: is_valid    = .FALSE.
    END TYPE ChunkMeta_Type
```

### `GenericChunkMetaType` (lines 34–42)

```fortran
    TYPE, PUBLIC :: GenericChunkMetaType
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(KIND=8)    :: file_offset = 0_8
        INTEGER(KIND=8)    :: chunk_size  = 0_8
        INTEGER(i4) :: node_id     = 0
        LOGICAL            :: is_valid    = .FALSE.
    END TYPE GenericChunkMetaType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Chunk_Init` | 49 | `SUBROUTINE IF_Chunk_Init(status)` |
| SUBROUTINE | `IF_Chunk_Clear` | 56 | `SUBROUTINE IF_Chunk_Clear(status)` |
| SUBROUTINE | `IF_Chunk_Register` | 73 | `SUBROUTINE IF_Chunk_Register(meta, status)` |
| SUBROUTINE | `IF_Chunk_Get` | 90 | `SUBROUTINE IF_Chunk_Get(logical_id, chunks, num_chunks, status)` |
| SUBROUTINE | `gcm_init` | 129 | `SUBROUTINE gcm_init(status)` |
| SUBROUTINE | `gcm_clear` | 133 | `SUBROUTINE gcm_clear(status)` |
| SUBROUTINE | `gcm_register_chunk` | 137 | `SUBROUTINE gcm_register_chunk(meta, status)` |
| SUBROUTINE | `gcm_get_chunks` | 150 | `SUBROUTINE gcm_get_chunks(logical_id, chunks, num_chunks, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
