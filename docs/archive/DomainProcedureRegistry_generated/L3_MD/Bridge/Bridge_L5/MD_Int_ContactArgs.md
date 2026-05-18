# `MD_Int_ContactArgs.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_Int_ContactArgs.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Int_ContactArgs`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_ContactArgs`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_ContactArgs`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_Int_ContactArgs.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_IC_ContactAddK_Arg` (lines 28–32)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactAddK_Arg
    INTEGER(i4) :: eqRow(3), eqCol(3)
    REAL(wp)    :: penalty, scale
    REAL(wp)    :: nrm(3)
  END TYPE MD_IC_ContactAddK_Arg
```

### `MD_IC_ContactAddForce_Arg` (lines 39–42)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactAddForce_Arg
    INTEGER(i4) :: eq(3)
    REAL(wp)    :: f(3)
  END TYPE MD_IC_ContactAddForce_Arg
```

### `MD_IC_ContactAssemTriplets_Arg` (lines 50–53)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactAssemTriplets_Arg
    TYPE(UF_Model), POINTER :: model => NULL()
    TYPE(RT_Sol_DofMap), POINTER :: dofMap => NULL()
  END TYPE MD_IC_ContactAssemTriplets_Arg
```

### `MD_IC_ContactInit_Arg` (lines 60–68)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactInit_Arg
    INTEGER(i4) :: master_id = 0_i4
    INTEGER(i4) :: slave_id  = 0_i4
    INTEGER(i4) :: contact_type = 1_i4   !! CONTACT_NODE_TO (see MD_Int)
    INTEGER(i4) :: dimension  = 3_i4
    REAL(wp)    :: tol         = 1.0E-6_wp
    !! search_tol < 0: contact_init uses 0.1*tol (same as omitting search_tol)
    REAL(wp)    :: search_tol  = -1.0_wp
  END TYPE MD_IC_ContactInit_Arg
```

### `MD_IC_ContactUpdateGeom_Arg` (lines 75–77)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactUpdateGeom_Arg
    INTEGER(i4) :: ndof = 0_i4  !! if <=0, wrapper uses SIZE(disp)
  END TYPE MD_IC_ContactUpdateGeom_Arg
```

### `MD_IC_ContactEvalFace_Arg` (lines 84–93)

```fortran
  TYPE, PUBLIC :: MD_IC_ContactEvalFace_Arg
    INTEGER(i4) :: elemId = 0_i4
    INTEGER(i4) :: faceId = 0_i4
    REAL(wp)    :: xSlave(3) = 0.0_wp
    REAL(wp)    :: bestGap = 0.0_wp
    INTEGER(i4) :: bestElemId = 0_i4
    INTEGER(i4) :: bestFaceId = 0_i4
    REAL(wp)    :: bestNrm(3) = 0.0_wp
    REAL(wp)    :: bestX0(3) = 0.0_wp
  END TYPE MD_IC_ContactEvalFace_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
