# `MD_Mesh_Mgr.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MeshManager` (lines 36–45)

```fortran
  type, public :: MeshManager
    type(MeshData)                       :: mesh
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: CreateMesh
    procedure :: GetMesh
    procedure :: Valid
  end type MeshManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 57 | `subroutine Init(this, status)` |
| SUBROUTINE | `Clean` | 72 | `subroutine Clean(this)` |
| SUBROUTINE | `CreateMesh` | 79 | `subroutine CreateMesh(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)` |
| SUBROUTINE | `GetMesh` | 93 | `subroutine GetMesh(this, mesh)` |
| SUBROUTINE | `Valid` | 100 | `subroutine Valid(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
