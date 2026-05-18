# `MD_Model_Builder.f90`

- **Source**: `L3_MD/Model/MD_Model_Builder.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Model_Builder`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Builder`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model_Builder`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Builder.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Model_Builder_Build_Desc` (lines 44–47)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_Desc
    CHARACTER(LEN=512) :: filename   = ""  ! INP file path
    CHARACTER(LEN=256) :: model_name = ""  ! model name (optional)
  END TYPE MD_Model_Builder_Build_Desc
```

### `MD_Model_Builder_Build_Algo` (lines 55–59)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_Algo
    INTEGER(i4) :: parsing_method    = 1_i4    ! 1=Abaqus keyword, 2=XML
    LOGICAL     :: validate_input    = .TRUE.  ! validate input format
    LOGICAL     :: check_consistency = .TRUE.  ! check model consistency
  END TYPE MD_Model_Builder_Build_Algo
```

### `MD_Model_Builder_Build_Ctx` (lines 67–71)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_Ctx
    LOGICAL     :: verbose    = .FALSE.  ! verbose output flag
    LOGICAL     :: echo_input = .FALSE.  ! echo input content flag
    INTEGER(i4) :: log_level  = 0_i4     ! log level (0=silent,1=info,2=debug)
  END TYPE MD_Model_Builder_Build_Ctx
```

### `MD_Model_Builder_Build_State` (lines 79–84)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_State
    LOGICAL     :: parse_successful = .FALSE.  ! parse success flag
    INTEGER(i4) :: num_parts    = 0_i4         ! parts parsed
    INTEGER(i4) :: num_elements = 0_i4         ! elements parsed
    INTEGER(i4) :: num_nodes    = 0_i4         ! nodes parsed
  END TYPE MD_Model_Builder_Build_State
```

### `MD_Model_Builder_Build_In` (lines 92–97)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_In
    TYPE(MD_Model_Builder_Build_Desc)  :: desc   ! [in] build descriptor
    TYPE(MD_Model_Builder_Build_Algo)  :: algo   ! [in] algorithm params
    TYPE(MD_Model_Builder_Build_Ctx)   :: ctx    ! [in] build context
    TYPE(MD_Model_Builder_Build_State) :: state  ! [in] initial state
  END TYPE MD_Model_Builder_Build_In
```

### `MD_Model_Builder_Build_Out` (lines 105–109)

```fortran
  TYPE, PUBLIC :: MD_Model_Builder_Build_Out
    TYPE(UF_ModelDef)                 :: model   ! [out] built model
    TYPE(MD_Model_Builder_Build_State) :: state   ! [out] final state
    TYPE(ErrorStatusType)             :: status  ! [out] error status
  END TYPE MD_Model_Builder_Build_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Model_Builder_Build` | 118 | `SUBROUTINE MD_Model_Builder_Build(in, out)` |
| SUBROUTINE | `UF_build_model_from_inp` | 220 | `SUBROUTINE UF_build_model_from_inp(filename, model, ierr, verbose)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
