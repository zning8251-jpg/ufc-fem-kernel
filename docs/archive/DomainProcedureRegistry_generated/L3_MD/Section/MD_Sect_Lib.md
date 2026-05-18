# `MD_Sect_Lib.f90`

- **Source**: `L3_MD/Section/MD_Sect_Lib.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sect_Lib`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Lib`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect`
- **第四段角色（四段式）**: `_Lib`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Lib.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_SectionDef` (lines 58–167)

```fortran
    TYPE, PUBLIC :: UF_SectionDef
        CHARACTER(LEN=MAX_SECTION_NAME) :: name = ""
        INTEGER(i4) :: id = 0
        INTEGER(i4) :: section_type = SECTION_SOLID
        
        ! Material reference
        CHARACTER(LEN=MAX_SECTION_NAME) :: material_name = ""
        INTEGER(i4) :: material_id = 0
        
        ! Element set this section is assigned to
        CHARACTER(LEN=MAX_SECTION_NAME) :: elset_name = ""
        
        ! Orientation (for anisotropic materials)
        CHARACTER(LEN=MAX_SECTION_NAME) :: orientation_name = ""
        
        ! ======================================================================
        ! SOLID SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: thickness = 1.0_wp           ! For 2D elements
        
        ! ======================================================================
        ! SHELL SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: shell_thickness = 0.0_wp
        INTEGER(i4) :: num_integration_points = 5   ! Through thickness
        INTEGER(i4) :: shell_formulation = SHELL_MINDLIN
        REAL(wp) :: offset_ratio = 0.0_wp        ! Shell offset ratio
        LOGICAL :: reduced_integration = .FALSE.
        
        ! ======================================================================
        ! BEAM SECTION PROPERTIES
        ! ======================================================================
        INTEGER(i4) :: beam_formulation = BEAM_TIMOSHENKO
        INTEGER(i4) :: xsec_type = BEAM_XSEC_RECT
        
        ! Cross-section dimensions (interpretation depends on xsec_type)
        REAL(wp) :: xsec_dims(10) = 0.0_wp
        ! For RECT: dims(1)=width, dims(2)=height
        ! For CIRCULAR: dims(1)=radius
        ! For PIPE: dims(1)=outer_radius, dims(2)=thickness
        ! For I: dims(1)=h, dims(2)=b1, dims(3)=b2, dims(4)=t1, dims(5)=t2, dims(6)=tw
        
        ! Computed cross-section properties
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: Iyy = 0.0_wp                 ! Second moment about y
        REAL(wp) :: Izz = 0.0_wp                 ! Second moment about z
        REAL(wp) :: Iyz = 0.0_wp                 ! Product of inertia
        REAL(wp) :: J = 0.0_wp                   ! Torsional constant
        REAL(wp) :: shear_factor_y = 0.0_wp      ! Shear correction factor
        REAL(wp) :: shear_factor_z = 0.0_wp
        
        ! ======================================================================
        ! MEMBRANE SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: membrane_thickness = 0.0_wp
        
        ! ======================================================================
        ! TRUSS SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: truss_area = 0.0_wp
        
        ! ======================================================================
        ! COHESIVE SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: cohesive_thickness = 1.0_wp
        INTEGER(i4) :: response_type = 1         ! 1=traction-separation
        
        ! ======================================================================
        ! GASKET SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: gasket_thickness = 1.0_wp
        REAL(wp) :: gasket_initial_gap = 0.0_wp
        REAL(wp) :: gasket_initial_void = 0.0_wp
        INTEGER(i4) :: gasket_type = 1           ! 1=thickness-direction only
        
        ! ======================================================================
        ! ACOUSTIC SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: acoustic_bulk_modulus = 0.0_wp
        REAL(wp) :: acoustic_density = 0.0_wp
        
        ! ======================================================================
        ! CONNECTOR SECTION PROPERTIES
        ! ======================================================================
        INTEGER(i4) :: connector_type = 1        ! 1=JOIN, 2=HINGE, 3=SLIDER
        REAL(wp) :: connector_stiffness(6) = 0.0_wp
        REAL(wp) :: connector_damping(6) = 0.0_wp
        
        ! ======================================================================
        ! INTEGRATION CONTROL
        ! ======================================================================
        INTEGER(i4) :: num_gauss_points = 0      ! 0 = default for element type
        LOGICAL :: hourglass_control = .TRUE.
        REAL(wp) :: hourglass_stiffness = 0.0_wp
        
    CONTAINS
        PROCEDURE :: init => section_init
        PROCEDURE :: set_solid => section_set_solid
        PROCEDURE :: set_shell => section_set_shell
        PROCEDURE :: set_beam_rect => section_set_beam_rect
        PROCEDURE :: set_beam_circular => section_set_beam_circular
        PROCEDURE :: set_beam_general => section_set_beam_general
        PROCEDURE :: set_membrane => section_set_membrane
        PROCEDURE :: set_truss => section_set_truss
        PROCEDURE :: set_cohesive => section_set_cohesive
        PROCEDURE :: set_gasket => section_set_gasket
        PROCEDURE :: set_acoustic => section_set_acoustic
        PROCEDURE :: set_connector => section_set_connector
        PROCEDURE :: compute_beam_props => section_compute_beam_props
    END TYPE UF_SectionDef
```

### `UF_SectionDBType` (lines 172–183)

```fortran
    TYPE, PUBLIC :: UF_SectionDBType

        INTEGER(i4) :: num_sections = 0
        TYPE(UF_SectionDef), ALLOCATABLE :: sections(:)
    CONTAINS
        PROCEDURE :: init => secdb_init
        PROCEDURE :: add_section => secdb_add_section
        PROCEDURE :: find_by_name => secdb_find_by_name
        PROCEDURE :: find_by_elset => secdb_find_by_elset
        PROCEDURE :: get_section => secdb_get_section
        PROCEDURE :: clear => secdb_clear
    END TYPE UF_SectionDBType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `section_init` | 191 | `SUBROUTINE section_init(this, name, sec_type, material_name)` |
| SUBROUTINE | `section_set_solid` | 204 | `SUBROUTINE section_set_solid(this, thickness)` |
| SUBROUTINE | `section_set_shell` | 214 | `SUBROUTINE section_set_shell(this, thickness, num_ip, formulation)` |
| SUBROUTINE | `section_set_beam_rect` | 229 | `SUBROUTINE section_set_beam_rect(this, width, height)` |
| SUBROUTINE | `section_set_beam_circular` | 242 | `SUBROUTINE section_set_beam_circular(this, radius)` |
| SUBROUTINE | `section_set_beam_general` | 254 | `SUBROUTINE section_set_beam_general(this, area, Iyy, Izz, J)` |
| SUBROUTINE | `section_set_membrane` | 267 | `SUBROUTINE section_set_membrane(this, thickness)` |
| SUBROUTINE | `section_set_truss` | 276 | `SUBROUTINE section_set_truss(this, area)` |
| SUBROUTINE | `section_set_cohesive` | 286 | `SUBROUTINE section_set_cohesive(this, thickness, response)` |
| SUBROUTINE | `section_set_gasket` | 297 | `SUBROUTINE section_set_gasket(this, thickness, initial_gap, gasket_type_in)` |
| SUBROUTINE | `section_set_acoustic` | 310 | `SUBROUTINE section_set_acoustic(this, bulk_modulus, density)` |
| SUBROUTINE | `section_set_connector` | 321 | `SUBROUTINE section_set_connector(this, conn_type, stiffness, damping)` |
| SUBROUTINE | `section_compute_beam_props` | 333 | `SUBROUTINE section_compute_beam_props(this)` |
| SUBROUTINE | `secdb_init` | 377 | `SUBROUTINE secdb_init(this, capacity)` |
| SUBROUTINE | `secdb_add_section` | 392 | `SUBROUTINE secdb_add_section(this, sec)` |
| FUNCTION | `secdb_find_by_name` | 412 | `FUNCTION secdb_find_by_name(this, name) RESULT(idx)` |
| FUNCTION | `secdb_find_by_elset` | 429 | `FUNCTION secdb_find_by_elset(this, elset_name) RESULT(idx)` |
| FUNCTION | `secdb_get_section` | 446 | `FUNCTION secdb_get_section(this, idx) RESULT(sec_ptr)` |
| SUBROUTINE | `secdb_clear` | 459 | `SUBROUTINE secdb_clear(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
