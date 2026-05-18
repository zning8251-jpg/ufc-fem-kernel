# `MD_Hash_Table.f90`

- **Source**: `L3_MD/Interaction/MD_Hash_Table.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Hash_Table`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Hash_Table`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Hash_Table`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Hash_Table.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `HashTableEntry` (lines 50–55)

```fortran
  TYPE :: HashTableEntry
    CHARACTER(len=MAX_KEY_LENGTH) :: key = ""
    INTEGER(i4) :: value = 0
    LOGICAL :: occupied = .FALSE.
    LOGICAL :: deleted = .FALSE.
  END TYPE HashTableEntry
```

### `HashTableType` (lines 58–64)

```fortran
  TYPE :: HashTableType
    TYPE(HashTableEntry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: table_size = 0
    INTEGER(i4) :: num_entries = 0
    INTEGER(i4) :: num_active = 0
    REAL(wp) :: max_load_factor = DEFAULT_LOAD_FACTOR
  END TYPE HashTableType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init_HashTable` | 123 | `SUBROUTINE Init_HashTable(table, initial_size, max_load, status)` |
| SUBROUTINE | `Destroy_HashTable` | 174 | `SUBROUTINE Destroy_HashTable(table, status)` |
| SUBROUTINE | `HashTable_Insert` | 194 | `SUBROUTINE HashTable_Insert(table, key, value, status)` |
| SUBROUTINE | `HashTable_Lookup` | 252 | `SUBROUTINE HashTable_Lookup(table, key, value, found, status)` |
| SUBROUTINE | `HashTable_Remove` | 293 | `SUBROUTINE HashTable_Remove(table, key, status)` |
| SUBROUTINE | `HashTable_Clear` | 332 | `SUBROUTINE HashTable_Clear(table, status)` |
| SUBROUTINE | `Resize_HashTable` | 394 | `SUBROUTINE Resize_HashTable(table, new_size, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
