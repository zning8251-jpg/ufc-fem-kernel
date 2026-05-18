# `MD_Inp_Parse.f90`

- **Source**: `L3_MD/KeyWord/MD_Inp_Parse.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Inp_Parse`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Inp_Parse`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Inp`
- **第四段角色（四段式）**: `_Parse`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_Inp_Parse.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_ParsedModel` (lines 61–107)

```fortran
    TYPE :: UF_ParsedModel
        ! Header
        CHARACTER(LEN=256) :: title = ''                           ! Model title
        
        ! Nodes
        INTEGER(i4) :: num_nodes = 0                              ! Number of nodes n_nodes  ? ?
        INTEGER(i4) :: ndim = 3                                    ! Spatial dimension n_dim  ? ?
        REAL(wp), ALLOCATABLE :: coords(:,:)                       ! Node coordinates X  ?ℝ^(n_dim×n_nodes)
        INTEGER(i4), ALLOCATABLE :: node_id(:)                     ! Original node IDs  ?ℤ^n_nodes
        
        ! Elements
        INTEGER(i4) :: num_elements = 0                            ! Number of elements n_elems  ? ?
        INTEGER(i4), ALLOCATABLE :: elem_conn(:,:)                 ! Element connectivity conn  ?ℤ^(max_nodes×n_elems)
        INTEGER(i4), ALLOCATABLE :: elem_type(:)                   ! Element type codes  ?ℤ^n_elems
        INTEGER(i4), ALLOCATABLE :: elem_id(:)                     ! Original element IDs  ?ℤ^n_elems
        INTEGER(i4), ALLOCATABLE :: elem_nnode(:)                  ! Nodes per element  ?ℤ^n_elems
        
        ! Material (simplified: one elastic material)
        REAL(wp) :: E = 0.0_wp                                     ! Young's modulus E  ? ?
        REAL(wp) :: nu = 0.0_wp                                    ! Poisson's ratio ν  ? ?
        REAL(wp) :: rho = 0.0_wp                                   ! Density ρ  ? ?
        
        ! Boundary conditions
        INTEGER(i4) :: num_bc = 0                                  ! Number of BCs n_bc  ? ?
        INTEGER(i4), ALLOCATABLE :: bc_node(:)                     ! BC node IDs  ?ℤ^n_bc
        INTEGER(i4), ALLOCATABLE :: bc_dof(:)                      ! BC DOF directions  ?ℤ^n_bc
        REAL(wp), ALLOCATABLE :: bc_val(:)                         ! Prescribed values u_0  ?ℝ^n_bc
        
        ! Concentrated loads
        INTEGER(i4) :: num_loads = 0                               ! Number of loads n_loads  ? ?
        INTEGER(i4), ALLOCATABLE :: load_node(:)                   ! Load node IDs  ?ℤ^n_loads
        INTEGER(i4), ALLOCATABLE :: load_dof(:)                    ! Load DOF directions  ?ℤ^n_loads
        REAL(wp), ALLOCATABLE :: load_val(:)                        ! Load magnitudes F_0  ?ℝ^n_loads
        
        ! Analysis parameters
        LOGICAL :: is_static = .TRUE.                              ! Static analysis flag
        REAL(wp) :: time_period = 1.0_wp                           ! Time period T  ? ?
        REAL(wp) :: initial_inc = 0.1_wp                           ! Initial increment Δt_0  ? ?
        
        ! Internal mapping
        INTEGER(i4), ALLOCATABLE :: node_map(:)                     ! Original→Internal node mapping  ?ℤ^n_nodes
        INTEGER(i4) :: max_node_id = 0                             ! Maximum node ID  ? ?
        
    CONTAINS
        PROCEDURE :: init => parsed_model_init
        PROCEDURE :: destroy => parsed_model_destroy
    END TYPE UF_ParsedModel
```

### `ParseInpFile_In` (lines 113–116)

```fortran
    TYPE, PUBLIC :: ParseInpFile_In
        CHARACTER(LEN=256) :: filename = ""                         ! Input filename
        INTEGER(i4) :: ndim = 3                                     ! Spatial dimension n_dim  ? ?(optional)
    END TYPE ParseInpFile_In
```

### `ParseInpFile_Out` (lines 119–122)

```fortran
    TYPE, PUBLIC :: ParseInpFile_Out
        TYPE(UF_ParsedModel) :: model                               ! Parsed model
        INTEGER(i4) :: ierr = 0                                     ! Error code  ? ?(0=OK, <0=error)
    END TYPE ParseInpFile_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `parsed_model_init` | 134 | `SUBROUTINE parsed_model_init(this, ndim)` |
| SUBROUTINE | `parsed_model_destroy` | 174 | `SUBROUTINE parsed_model_destroy(this)` |
| SUBROUTINE | `parse_inp_file` | 205 | `SUBROUTINE parse_inp_file(filename, model, ierr)` |
| FUNCTION | `get_keyword` | 352 | `FUNCTION get_keyword(line) RESULT(keyword)` |
| FUNCTION | `get_option` | 382 | `FUNCTION get_option(line, option_name) RESULT(value)` |
| FUNCTION | `to_upper` | 413 | `FUNCTION to_upper(str) RESULT(upper)` |
| FUNCTION | `element_type_code` | 429 | `FUNCTION element_type_code(type_str) RESULT(code)` |
| FUNCTION | `nodes_per_element` | 477 | `FUNCTION nodes_per_element(etype) RESULT(n)` |
| SUBROUTINE | `parse_nodes` | 522 | `SUBROUTINE parse_nodes(unit_num, model, ierr)` |
| SUBROUTINE | `parse_elements` | 576 | `SUBROUTINE parse_elements(unit_num, model, elem_type, ierr)` |
| SUBROUTINE | `parse_int_list` | 638 | `SUBROUTINE parse_int_list(line, first_val, rest, max_rest)` |
| SUBROUTINE | `parse_elastic` | 685 | `SUBROUTINE parse_elastic(unit_num, model, ierr)` |
| SUBROUTINE | `parse_boundary` | 711 | `SUBROUTINE parse_boundary(unit_num, model, ierr)` |
| SUBROUTINE | `parse_cload` | 767 | `SUBROUTINE parse_cload(unit_num, model, ierr)` |
| SUBROUTINE | `parse_static_params` | 811 | `SUBROUTINE parse_static_params(line, model)` |
| SUBROUTINE | `build_node_mapping` | 823 | `SUBROUTINE build_node_mapping(model)` |
| SUBROUTINE | `parser_get_coords` | 843 | `SUBROUTINE parser_get_coords(model, coords, num_nodes, ndim)` |
| SUBROUTINE | `parser_get_conn` | 859 | `SUBROUTINE parser_get_conn(model, conn, num_elements, max_nnode)` |
| SUBROUTINE | `parser_get_elem_types` | 886 | `SUBROUTINE parser_get_elem_types(model, elem_types)` |
| SUBROUTINE | `parser_get_bc_dofs` | 898 | `SUBROUTINE parser_get_bc_dofs(model, dof_per_node, bc_dofs, bc_vals, num_bc)` |
| SUBROUTINE | `parser_get_bc_vals` | 927 | `SUBROUTINE parser_get_bc_vals(model, bc_vals)` |
| SUBROUTINE | `parser_get_loads` | 939 | `SUBROUTINE parser_get_loads(model, dof_per_node, load_dofs, load_vals, num_loads)` |
| SUBROUTINE | `parser_destroy` | 968 | `SUBROUTINE parser_destroy(model)` |
| SUBROUTINE | `parse_nset` | 976 | `SUBROUTINE parse_nset(unit_num, model, ierr)` |
| SUBROUTINE | `parse_elset` | 987 | `SUBROUTINE parse_elset(unit_num, model, ierr)` |
| SUBROUTINE | `parse_plastic` | 998 | `SUBROUTINE parse_plastic(unit_num, model, ierr)` |
| SUBROUTINE | `parse_density` | 1009 | `SUBROUTINE parse_density(unit_num, model, ierr)` |
| SUBROUTINE | `parse_amplitude` | 1022 | `SUBROUTINE parse_amplitude(unit_num, model, ierr)` |
| SUBROUTINE | `parse_section` | 1033 | `SUBROUTINE parse_section(unit_num, model, ierr)` |
| SUBROUTINE | `parse_dload` | 1044 | `SUBROUTINE parse_dload(unit_num, model, ierr)` |
| SUBROUTINE | `parse_initial_conditions` | 1055 | `SUBROUTINE parse_initial_conditions(unit_num, model, ierr)` |
| SUBROUTINE | `parse_dynamic_params` | 1066 | `SUBROUTINE parse_dynamic_params(line, model)` |
| SUBROUTINE | `parse_output` | 1075 | `SUBROUTINE parse_output(unit_num, model, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
