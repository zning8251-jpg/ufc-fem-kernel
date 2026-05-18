# `NM_Base_Utils.f90`

- **Source**: `L2_NM/Base/NM_Base_Utils.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Base_Utils`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Base_Utils`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Base_Utils`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/NM_Base_Utils.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Dot_Product_Fast_Arg` (lines 26–31)

```fortran
  TYPE :: Dot_Product_Fast_Arg
    ! [IN] vec1 - First vector
    ! [IN] vec2 - Second vector
    REAL(wp), ALLOCATABLE :: vec1(:)
    REAL(wp), ALLOCATABLE :: vec2(:)
  END TYPE Dot_Product_Fast_Arg
```

### `Cross_Product_Arg` (lines 36–43)

```fortran
  TYPE :: Cross_Product_Arg
    ! [IN]  a - First 3D vector
    ! [IN]  b - Second 3D vector
    ! [OUT] c - Cross product result (3D)
    REAL(wp) :: a(3)
    REAL(wp) :: b(3)
    REAL(wp) :: c(3)
  END TYPE Cross_Product_Arg
```

### `Triple_Product_Arg` (lines 48–55)

```fortran
  TYPE :: Triple_Product_Arg
    ! [IN] a - First 3D vector
    ! [IN] b - Second 3D vector
    ! [IN] c - Third 3D vector
    REAL(wp) :: a(3)
    REAL(wp) :: b(3)
    REAL(wp) :: c(3)
  END TYPE Triple_Product_Arg
```

### `Angle_Between_Arg` (lines 60–67)

```fortran
  TYPE :: Angle_Between_Arg
    ! [IN]  vec1  - First vector
    ! [IN]  vec2  - Second vector
    ! [OUT] angle - Angle between vectors (radians)
    REAL(wp), ALLOCATABLE :: vec1(:)
    REAL(wp), ALLOCATABLE :: vec2(:)
    REAL(wp)              :: angle
  END TYPE Angle_Between_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `Dot_Product_Fast` | 75 | `PURE FUNCTION Dot_Product_Fast(vec1, vec2) RESULT(dot)` |
| SUBROUTINE | `Dot_Product_Fast_Proc` | 89 | `SUBROUTINE Dot_Product_Fast_Proc(arg, dot)` |
| FUNCTION | `Cross_Product` | 102 | `PURE FUNCTION Cross_Product(a, b) RESULT(cross)` |
| SUBROUTINE | `Cross_Product_Proc` | 117 | `SUBROUTINE Cross_Product_Proc(arg)` |
| FUNCTION | `Triple_Product` | 130 | `PURE FUNCTION Triple_Product(a, b, c) RESULT(triple)` |
| SUBROUTINE | `Triple_Product_Proc` | 144 | `SUBROUTINE Triple_Product_Proc(arg, triple)` |
| FUNCTION | `Angle_Between` | 161 | `PURE FUNCTION Angle_Between(vec1, vec2) RESULT(angle)` |
| SUBROUTINE | `Angle_Between_Proc` | 182 | `SUBROUTINE Angle_Between_Proc(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
