# `MD_BC_Mgr.f90`

- **Source**: `L3_MD/Boundary/MD_BC_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_BC_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_BC_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_BC`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_BC_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_BC_Cfg_Init_Desc` (lines 36–40)

```fortran
    TYPE, PUBLIC :: MD_BC_Cfg_Init_Desc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = 1_i4
    END TYPE MD_BC_Cfg_Init_Desc
```

### `MD_BC_Pop_Tgt_Desc` (lines 42–45)

```fortran
    TYPE, PUBLIC :: MD_BC_Pop_Tgt_Desc
        INTEGER(i4) :: targetType = 1_i4
        INTEGER(i4) :: targetId = 0_i4
    END TYPE MD_BC_Pop_Tgt_Desc
```

### `MD_BC_Pop_Val_Desc` (lines 47–51)

```fortran
    TYPE, PUBLIC :: MD_BC_Pop_Val_Desc
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE MD_BC_Pop_Val_Desc
```

### `MD_BC_Stp_Window_Desc` (lines 53–57)

```fortran
    TYPE, PUBLIC :: MD_BC_Stp_Window_Desc
        LOGICAL :: isActive = .TRUE.
        REAL(wp) :: startTime = 0.0_wp
        REAL(wp) :: endTime = 1.0e30_wp
    END TYPE MD_BC_Stp_Window_Desc
```

### `BCDef` (lines 64–84)

```fortran
    TYPE, PUBLIC :: BCDef
        TYPE(MD_BC_Cfg_Init_Desc) :: cfg
        TYPE(MD_BC_Pop_Tgt_Desc) :: tgt
        TYPE(MD_BC_Pop_Val_Desc) :: val
        TYPE(MD_BC_Stp_Window_Desc) :: stp
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = BC_DISPLACEMENT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp)    :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
        LOGICAL     :: isActive = .TRUE.
        REAL(wp)    :: startTime = 0.0_wp
        REAL(wp)    :: endTime = 1.0e30_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => BCDef_Init
        PROCEDURE, PUBLIC :: Valid => BCDef_Valid
        PROCEDURE, PUBLIC :: Clear => BCDef_Clear
    END TYPE BCDef
```

### `BCDef_Init_In` (lines 91–100)

```fortran
    TYPE, PUBLIC :: BCDef_Init_In
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = BC_DISPLACEMENT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE BCDef_Init_In
```

### `BCDef_Init_Out` (lines 107–109)

```fortran
    TYPE, PUBLIC :: BCDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE BCDef_Init_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BCDef_Init` | 118 | `SUBROUTINE BCDef_Init(this, id, name, bcType, targetType, targetId, dof, value, amplitudeId, status)` |
| SUBROUTINE | `BCDef_Valid` | 168 | `SUBROUTINE BCDef_Valid(this, status)` |
| SUBROUTINE | `BCDef_Clear` | 224 | `SUBROUTINE BCDef_Clear(this)` |
| SUBROUTINE | `BCDef_Init_Structured` | 254 | `SUBROUTINE BCDef_Init_Structured(in, out, bc)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
