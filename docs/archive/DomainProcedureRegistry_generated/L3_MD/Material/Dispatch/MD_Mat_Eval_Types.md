# `MD_Mat_Eval_Types.f90`

- **Source**: `L3_MD/Material/Dispatch/MD_Mat_Eval_Types.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Eval_Types`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Eval_Types`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Eval`
- **第四段角色（四段式）**: `_Types`
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Dispatch/MD_Mat_Eval_Types.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MatEval_Cfg` (lines 21–23)

```fortran
  TYPE :: MatEval_Cfg
    INTEGER(i4) :: ndim = 0
  END TYPE MatEval_Cfg
```

### `MatEval_Ctx` (lines 25–42)

```fortran
  TYPE :: MatEval_Ctx
    INTEGER(i4) :: ndi = 0, nshr = 0, ntens = 0, nstatv = 0
    TYPE(MatEval_Cfg) :: cfg
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: stran(6) = 0.0_wp
    REAL(wp) :: dstran(6) = 0.0_wp
    REAL(wp) :: statev(MD_MATCTX_MAX_STATEV) = 0.0_wp
    REAL(wp) :: ddsdde(6,6) = 0.0_wp
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    REAL(wp) :: drpldt = 0.0_wp
    REAL(wp) :: time(2) = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE MatEval_Ctx
```

### `MatAlgo_Algo` (lines 44–46)

```fortran
  TYPE :: MatAlgo_Algo
    INTEGER(i4) :: kstep = 0, kinc = 0
  END TYPE MatAlgo_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
