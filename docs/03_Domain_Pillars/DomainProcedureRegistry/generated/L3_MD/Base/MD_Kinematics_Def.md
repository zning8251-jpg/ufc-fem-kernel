# `MD_Kinematics_Def.f90`

- **Source**: `L3_MD/Base/MD_Kinematics_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Kinematics_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Kinematics_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Kinematics`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Kinematics_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `KinematicsMeta` (lines 20–29)

```fortran
  TYPE, PUBLIC :: KinematicsMeta
    INTEGER(i4) :: dim           = 0_i4  ! problem dimension
    INTEGER(i4) :: ndim          = 0_i4  ! spatial dimension
    INTEGER(i4) :: ndi           = 0_i4  ! direct stress components
    INTEGER(i4) :: nshr          = 0_i4  ! shear stress components
    INTEGER(i4) :: ntens         = 0_i4  ! total stress components
    INTEGER(i4) :: Formul        = 0_i4  ! formulation type ID
    INTEGER(i4) :: kine_class    = 0_i4  ! kinematics class
    INTEGER(i4) :: analysis_type = 0_i4  ! UMAT analysis type (1-4)
  END TYPE KinematicsMeta
```

### `KinematicsTime` (lines 37–41)

```fortran
  TYPE, PUBLIC :: KinematicsTime
    REAL(wp) :: current = 0.0_wp  ! current step time
    REAL(wp) :: total   = 0.0_wp  ! total analysis time
    REAL(wp) :: inc     = 0.0_wp  ! time increment
  END TYPE KinematicsTime
```

### `KinematicsTemp` (lines 49–52)

```fortran
  TYPE, PUBLIC :: KinematicsTemp
    REAL(wp) :: current = 0.0_wp  ! current temperature
    REAL(wp) :: inc     = 0.0_wp  ! temperature increment
  END TYPE KinematicsTemp
```

### `KinematicsMech` (lines 60–71)

```fortran
  TYPE, PUBLIC :: KinematicsMech
    REAL(wp) :: strain(6)      = 0.0_wp  ! total strain tensor (Voigt)
    REAL(wp) :: dStrain(6)     = 0.0_wp  ! strain increment (Voigt)
    REAL(wp) :: F(3,3)         = 0.0_wp  ! deformation gradient (current)
    REAL(wp) :: F_old(3,3)     = 0.0_wp  ! deformation gradient (previous)
    REAL(wp) :: F_incr(3,3)    = 0.0_wp  ! incremental deformation gradient
    REAL(wp) :: Jac            = 1.0_wp  ! Jacobian determinant
    REAL(wp) :: C(3,3)         = 0.0_wp  ! right Cauchy-Green tensor
    REAL(wp) :: R(3,3)         = 0.0_wp  ! rotation tensor
    REAL(wp) :: coords_ref(3)  = 0.0_wp  ! reference coordinates
    REAL(wp) :: coords_curr(3) = 0.0_wp  ! current coordinates
  END TYPE KinematicsMech
```

### `KinematicsThermal` (lines 79–82)

```fortran
  TYPE, PUBLIC :: KinematicsThermal
    REAL(wp) :: temp  = 0.0_wp  ! temperature value
    REAL(wp) :: dTemp = 0.0_wp  ! temperature increment
  END TYPE KinematicsThermal
```

### `UF_Kinematics` (lines 90–102)

```fortran
  TYPE, PUBLIC :: UF_Kinematics
    TYPE(KinematicsMeta)     :: meta               ! metadata sub-type
    INTEGER(i4)              :: id     = 0_i4      ! element ID
    INTEGER(i4)              :: ipID   = 0_i4      ! integration point ID
    INTEGER(i4)              :: stepID = 0_i4      ! step ID
    INTEGER(i4)              :: incID  = 0_i4      ! increment ID
    TYPE(KinematicsTime)     :: time               ! time data
    TYPE(KinematicsTemp)     :: temp               ! temperature data
    TYPE(KinematicsMech)     :: mech               ! mechanical kinematics
    TYPE(KinematicsThermal)  :: thermal            ! thermal kinematics
    REAL(wp), POINTER        :: predef(:) => NULL() ! predefined field values
    REAL(wp), POINTER        :: user_real(:) => NULL() ! user-defined reals
  END TYPE UF_Kinematics
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
