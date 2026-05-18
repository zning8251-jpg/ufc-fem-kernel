# `RT_Cont_Core.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Cont_SurfDesc` (lines 41–44)

```fortran
  TYPE :: RT_Cont_SurfDesc
    INTEGER(i4) :: surf_id  = 0_i4  ! Unique surface ID
    INTEGER(i4) :: n_nodes  = 0_i4  ! Slave/master node count
  END TYPE RT_Cont_SurfDesc
```

### `RT_Cont_PairDef` (lines 47–53)

```fortran
  TYPE :: RT_Cont_PairDef
    INTEGER(i4) :: pair_id       = 0_i4  ! Pair index
    INTEGER(i4) :: master_surf_id = 0_i4
    INTEGER(i4) :: slave_surf_id  = 0_i4
    LOGICAL     :: friction       = .FALSE.
    LOGICAL     :: thermal        = .FALSE.
  END TYPE RT_Cont_PairDef
```

### `RT_Cont_PairBuf` (lines 56–63)

```fortran
  TYPE :: RT_Cont_PairBuf
    TYPE(RT_Cont_PairDef)         :: def
    LOGICAL                       :: active         = .FALSE.
    INTEGER(i4)                   :: n_active_nodes = 0_i4
    REAL(wp), ALLOCATABLE         :: gap(:)          ! (n_slave_nodes)
    REAL(wp), ALLOCATABLE         :: normal_force(:) ! (n_slave_nodes)
    REAL(wp), ALLOCATABLE         :: fric_force(:,:) ! (3, n_slave_nodes)
  END TYPE RT_Cont_PairBuf
```

### `RT_Cont_Mgr` (lines 78–87)

```fortran
  TYPE, PUBLIC :: RT_Cont_Mgr
    LOGICAL     :: inited = .FALSE.
    INTEGER(i4) :: nContPairs = 0_i4
    INTEGER(i4) :: maxContPairs = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => Mgr_Init
    PROCEDURE, PUBLIC :: Clean => Mgr_Clean
    PROCEDURE, PUBLIC :: Reg => Mgr_Reg
    PROCEDURE, PUBLIC :: GetStat => Mgr_GetStat
  END TYPE RT_Cont_Mgr
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Contact_Core_Init` | 100 | `SUBROUTINE RT_Contact_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `RT_Contact_Core_Finalize` | 128 | `SUBROUTINE RT_Contact_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `RT_Contact_Search` | 147 | `SUBROUTINE RT_Contact_Search(desc, state, algo, status)` |
| SUBROUTINE | `RT_Contact_Evaluate_Pairs` | 188 | `SUBROUTINE RT_Contact_Evaluate_Pairs(desc, state, algo, ctx, status)` |
| SUBROUTINE | `RT_Contact_Assemble_K` | 229 | `SUBROUTINE RT_Contact_Assemble_K(desc, state, ctx, status)` |
| SUBROUTINE | `RT_Contact_Assemble_F` | 272 | `SUBROUTINE RT_Contact_Assemble_F(desc, state, ctx, status)` |
| SUBROUTINE | `RT_Contact_Update_Status` | 308 | `SUBROUTINE RT_Contact_Update_Status(desc, state, status)` |
| FUNCTION | `RT_Contact_Get_N_Active` | 326 | `PURE FUNCTION RT_Contact_Get_N_Active(state) RESULT(n)` |
| SUBROUTINE | `RT_Cont_RegVars` | 339 | `SUBROUTINE RT_Cont_RegVars(model, varCtx)` |
| SUBROUTINE | `Mgr_Init` | 374 | `SUBROUTINE Mgr_Init(this, maxContPairs, status)` |
| SUBROUTINE | `Mgr_Clean` | 402 | `SUBROUTINE Mgr_Clean(this, status)` |
| SUBROUTINE | `Mgr_Reg` | 417 | `SUBROUTINE Mgr_Reg(this, model, status)` |
| SUBROUTINE | `Mgr_GetStat` | 438 | `SUBROUTINE Mgr_GetStat(this, nContactPairs)` |
| SUBROUTINE | `RT_Cont_Init` | 448 | `SUBROUTINE RT_Cont_Init(maxContactPairs, status)` |
| SUBROUTINE | `RT_Cont_Clean` | 461 | `SUBROUTINE RT_Cont_Clean(status)` |
| SUBROUTINE | `RT_Cont_RegModel` | 472 | `SUBROUTINE RT_Cont_RegModel(model, varCtx, status)` |
| SUBROUTINE | `RT_Cont_GetStat` | 498 | `SUBROUTINE RT_Cont_GetStat(nContactPairs)` |
| SUBROUTINE | `contact_init_from_pair` | 513 | `SUBROUTINE contact_init_from_pair(pair, pair_def, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
