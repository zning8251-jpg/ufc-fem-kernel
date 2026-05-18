# `PH_Elem_Def.f90`

- **Source**: `L4_PH/Element/PH_Elem_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Desc` (lines 75–80)

```fortran
  TYPE :: PH_Elem_Desc
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Cfg_Init_Desc) :: cfg    ! Config+Init fields (cfg%elem_type_id, cfg%family_id, cfg%ndim, cfg%section_type)
    TYPE(PH_Elem_Pop_Vld_Desc)  :: pop    ! Populate+Vld fields (pop%n_nodes, pop%n_dof, pop%dof_per_node, pop%n_integration, pop%n_elements)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Desc
```

### `PH_Elem_Ctx` (lines 89–96)

```fortran
  TYPE :: PH_Elem_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Inc_Evo_Ctx)  :: inc    ! Inc+Evo fields (inc%step_idx, inc%incr_idx)
    TYPE(PH_Elem_Itr_Asm_Ctx)  :: itr    ! Itr+Asm fields (itr%current_ip, itr%current_elem, itr%det_J, itr%weight)
    TYPE(PH_Elem_Lcl_Comp_Ctx) :: lcl    ! Lcl+Comp workspace (lcl%u_elem, lcl%du_elem, lcl%dN_dX, lcl%J_mat)
    TYPE(PH_Elem_Lcl_Evo_Ctx)  :: evo    ! Lcl+Evo workspace (evo%Ke_mat, evo%Ke_geo, evo%Ke, evo%R_int)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Ctx
```

### `PH_Elem_State` (lines 106–111)

```fortran
  TYPE :: PH_Elem_State
    !--- NEW: Auxiliary TYPE nesting (G8) ---
    TYPE(PH_Elem_Stp_Evo_State) :: stp    ! Step-level evolution (stp%initialized, stp%stiffness_built, stp%current_step, stp%n_active_elems, stp%n_converged)
    TYPE(PH_Elem_Itr_Acc_State) :: itr    ! Iteration-level accumulation (itr%rhs, itr%amatrx, itr%svars, itr%energy, itr%mass)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_State
```

### `PH_Elem_Stiff_Arg` (lines 119–125)

```fortran
  TYPE :: PH_Elem_Stiff_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: D_mat(:,:)  => NULL()  ! [IN]  constitutive matrix (nstrs, nstrs)
    REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! [IN]  element displacement (n_dof)
    REAL(wp), ALLOCATABLE :: Ke(:,:)                ! [OUT] element stiffness (n_dof, n_dof)
    REAL(wp), ALLOCATABLE :: R_int(:)               ! [OUT] internal force vector (n_dof)
  END TYPE PH_Elem_Stiff_Arg
```

### `PH_Elem_Algo` (lines 150–157)

```fortran
  TYPE :: PH_Elem_Algo
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Stp_Ctl_Algo)     :: stp    ! Step+Ctl static params (stp%integration_order, stp%hourglass_control, etc.)
    TYPE(PH_Elem_Stp_Ctl_Dyn_Algo) :: dyn    ! Step+Ctl dynamic params (dyn%reduced_integ, dyn%mass_type, etc.)
    ! [Phase:Cfg|Verb:Brg] strategy pointer — bare field
    PROCEDURE(PH_Elem_Integrator_Ifc), POINTER, NOPASS :: integrator => NULL()
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Algo
```

### `PH_Elem_Core_Ke_Arg` (lines 174–178)

```fortran
  TYPE :: PH_Elem_Core_Ke_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: D_mat(:,:)  => NULL()  ! [IN]  constitutive matrix (nstrs, nstrs)
    REAL(wp), ALLOCATABLE :: Ke(:,:)                ! [OUT] element stiffness (n_dof, n_dof)
  END TYPE PH_Elem_Core_Ke_Arg
```

### `PH_Elem_Core_Fe_Arg` (lines 185–189)

```fortran
  TYPE :: PH_Elem_Core_Fe_Arg
    REAL(wp), POINTER     :: coords(:,:)    => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: body_force(:)  => NULL()  ! [IN]  body force per dim (ndim)
    REAL(wp), ALLOCATABLE :: Fe(:)                     ! [OUT] element force vector (n_dof)
  END TYPE PH_Elem_Core_Fe_Arg
```

### `PH_Elem_Core_Fint_Arg` (lines 196–200)

```fortran
  TYPE :: PH_Elem_Core_Fint_Arg
    REAL(wp), POINTER     :: coords(:,:)    => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: stress_gp(:,:) => NULL()  ! [IN]  stress at GPs (n_gp, nstrs)
    REAL(wp), ALLOCATABLE :: Fint(:)                   ! [OUT] internal force vector (n_dof)
  END TYPE PH_Elem_Core_Fint_Arg
```

### `PH_Elem_Core_Mass_Arg` (lines 207–211)

```fortran
  TYPE :: PH_Elem_Core_Mass_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp)              :: rho = 0.0_wp           ! [IN]  material density
    REAL(wp), ALLOCATABLE :: Me(:,:)                ! [OUT] element mass matrix (n_dof, n_dof)
  END TYPE PH_Elem_Core_Mass_Arg
```

### `PH_Elem_Eval_Ke_Arg` (lines 218–222)

```fortran
  TYPE :: PH_Elem_Eval_Ke_Arg
    REAL(wp), POINTER     :: coords(:,:)   => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: mat_props(:)  => NULL()  ! [IN]  material property array
    REAL(wp), ALLOCATABLE :: Ke(:,:)                  ! [OUT] element stiffness (n_dof, n_dof)
  END TYPE PH_Elem_Eval_Ke_Arg
```

### `PH_Elem_Eval_Fe_Arg` (lines 229–235)

```fortran
  TYPE :: PH_Elem_Eval_Fe_Arg
    REAL(wp), POINTER     :: coords(:,:)   => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: u(:)          => NULL()  ! [IN]  displacement vector (n_dof)
    INTEGER(i4)           :: load_case     = 0_i4     ! [IN]  load case number
    REAL(wp), POINTER     :: load_magn(:)  => NULL()  ! [IN]  load magnitude array
    REAL(wp), ALLOCATABLE :: Fe(:)                    ! [OUT] element force vector (n_dof)
  END TYPE PH_Elem_Eval_Fe_Arg
```

### `PH_Elem_Eval_Mass_Arg` (lines 242–246)

```fortran
  TYPE :: PH_Elem_Eval_Mass_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp)              :: density = 0.0_wp       ! [IN]  material density
    REAL(wp), ALLOCATABLE :: Me(:,:)                ! [OUT] element mass matrix (n_dof, n_dof)
  END TYPE PH_Elem_Eval_Mass_Arg
```

### `PH_Elem_ComplexStiff_Form_Arg` (lines 253–261)

```fortran
  TYPE :: PH_Elem_ComplexStiff_Form_Arg
    REAL(wp), POINTER     :: K_val(:)   => NULL()  ! [IN]  stiffness values (CSR)
    INTEGER(i4), POINTER  :: ia(:)      => NULL()  ! [IN]  CSR row pointer
    INTEGER(i4), POINTER  :: ja(:)      => NULL()  ! [IN]  CSR column indices
    INTEGER(i4)           :: nnz        = 0_i4     ! [IN]  number of non-zeros
    REAL(wp)              :: eta        = 0.0_wp   ! [IN]  structural damping ratio
    REAL(wp), ALLOCATABLE :: K_real(:)             ! [OUT] real part of K*
    REAL(wp), ALLOCATABLE :: K_imag(:)             ! [OUT] imaginary part of K*
  END TYPE PH_Elem_ComplexStiff_Form_Arg
```

### `PH_Elem_NL_TL_Arg` (lines 268–275)

```fortran
  TYPE :: PH_Elem_NL_TL_Arg
    REAL(wp), POINTER     :: coords_ref(:,:) => NULL()  ! [IN]  reference coordinates
    REAL(wp), POINTER     :: u_elem(:)       => NULL()  ! [IN]  element displacement
    REAL(wp), POINTER     :: D(:,:)          => NULL()  ! [IN]  constitutive matrix
    REAL(wp), ALLOCATABLE :: Ke_mat(:,:)                ! [OUT] material stiffness
    REAL(wp), ALLOCATABLE :: Ke_geo(:,:)                ! [OUT] geometric stiffness
    REAL(wp), ALLOCATABLE :: R_int(:)                   ! [OUT] internal residual
  END TYPE PH_Elem_NL_TL_Arg
```

### `PH_Elem_NL_UL_Arg` (lines 282–289)

```fortran
  TYPE :: PH_Elem_NL_UL_Arg
    REAL(wp), POINTER     :: coords_prev(:,:) => NULL()  ! [IN]  previous-step coordinates
    REAL(wp), POINTER     :: u_incr(:)        => NULL()  ! [IN]  displacement increment
    REAL(wp), POINTER     :: D(:,:)           => NULL()  ! [IN]  constitutive matrix
    REAL(wp), ALLOCATABLE :: Ke_mat(:,:)                 ! [OUT] material stiffness
    REAL(wp), ALLOCATABLE :: Ke_geo(:,:)                 ! [OUT] geometric stiffness
    REAL(wp), ALLOCATABLE :: R_int(:)                    ! [OUT] internal residual
  END TYPE PH_Elem_NL_UL_Arg
```

### `PH_Elem_JacB_Arg` (lines 295–305)

```fortran
  TYPE :: PH_Elem_JacB_Arg
    REAL(wp), POINTER     :: coords(:,:)  => NULL()  ! [IN]  nodal coordinates
    REAL(wp)              :: xi   = 0.0_wp           ! [IN]  parametric coord xi
    REAL(wp)              :: eta  = 0.0_wp           ! [IN]  parametric coord eta
    REAL(wp)              :: zeta = 0.0_wp           ! [IN]  parametric coord zeta (3D)
    REAL(wp), ALLOCATABLE :: N(:)                    ! [OUT] shape function values
    REAL(wp), ALLOCATABLE :: dNdx(:,:)               ! [OUT] shape func derivatives (phys)
    REAL(wp), ALLOCATABLE :: J(:,:)                  ! [OUT] Jacobian matrix
    REAL(wp)              :: detJ = 0.0_wp           ! [OUT] Jacobian determinant
    REAL(wp), ALLOCATABLE :: B(:,:)                  ! [OUT] strain-displacement matrix
  END TYPE PH_Elem_JacB_Arg
```

### `PH_Elem_Contact_Arg` (lines 311–323)

```fortran
  TYPE :: PH_Elem_Contact_Arg
    INTEGER(i4)           :: edge_id     = 0_i4      ! [IN]  edge / surface id
    REAL(wp)              :: xi          = 0.0_wp    ! [IN]  parametric coord xi
    REAL(wp)              :: eta         = 0.0_wp    ! [IN]  parametric coord eta
    REAL(wp), POINTER     :: N(:)        => NULL()   ! [IN]  shape function values
    REAL(wp), POINTER     :: n_vec(:)    => NULL()   ! [IN]  outward normal vector
    REAL(wp)              :: gap         = 0.0_wp    ! [IN]  contact gap
    REAL(wp)              :: penalty     = 0.0_wp    ! [IN]  penalty factor
    REAL(wp)              :: edge_len    = 0.0_wp    ! [IN]  edge length
    REAL(wp), POINTER     :: coords(:,:) => NULL()   ! [IN]  nodal coordinates (edge center)
    REAL(wp), ALLOCATABLE :: K_el(:,:)               ! [OUT] contact stiffness contribution
    REAL(wp), ALLOCATABLE :: F_el(:)                 ! [OUT] contact force contribution
  END TYPE PH_Elem_Contact_Arg
```

### `PH_Element_Compute_Ke_Arg` (lines 331–341)

```fortran
  TYPE, PUBLIC :: PH_Element_Compute_Ke_Arg
    INTEGER(i4) :: elem_idx     = 0_i4              ! [IN]  element index
    INTEGER(i4) :: l3_elem_idx  = 0_i4              ! [IN]  L3 element index
    INTEGER(i4) :: mat_pt_idx   = 0_i4              ! [IN]  material point index
    INTEGER(i4) :: nDof         = 0_i4              ! [IN]  number of DOFs
    ! L5 从 ph_layer%material%slot_pool(mat_pt_idx)%desc%props 拷贝注入；
    ! TARGET 供 PH_Elem_Domain%Compute_Ke 内 eva%mat_props => ，避免 L4 USE 全局容器。
    REAL(wp), ALLOCATABLE :: mat_props_in(:)        ! [IN]  material property array
    TYPE(PH_Elem_Lcl_Evo_Ctx) :: evo                ! [INOUT] element evolution workspace
    TYPE(ErrorStatusType) :: status                 ! [OUT] error status
  END TYPE PH_Element_Compute_Ke_Arg
```

### `PH_Element_Compute_Fe_Arg` (lines 343–355)

```fortran
  TYPE, PUBLIC :: PH_Element_Compute_Fe_Arg
    INTEGER(i4) :: l3_elem_idx = 0_i4              ! [IN]  L3 element index
    INTEGER(i4) :: mat_pt_idx  = 0_i4              ! [IN]  material point index
    INTEGER(i4) :: nDof        = 0_i4              ! [IN]  number of DOFs
    REAL(wp) :: u(PH_ELEM_ASSEMBLY_U_MAX) = 0.0_wp ! [IN]  element nodal displacements
    INTEGER(i4) :: load_case = 0_i4                 ! [IN]  load case number
    ! L5 注入载荷幅值向量（与 PH_Elem_Eval_Fe / Compute_Fe 的 load_magn 对齐）；
    ! TARGET 供 PH_Elem_Domain%Compute_Fe 内 eva%load_magn => ，避免 L4 USE 全局容器。
    ! 若 RT_Asm_GlobalLoad 已将同项体力/分布载写入 F_ext，此处须保持零，避免 R=F_ext-F_int 双计。
    REAL(wp), ALLOCATABLE :: load_magn_in(:)        ! [IN]  load magnitude array
    REAL(wp), ALLOCATABLE :: Fe(:)                  ! [OUT] element force vector
    TYPE(ErrorStatusType) :: status                 ! [OUT] error status
  END TYPE PH_Element_Compute_Fe_Arg
```

### `PH_Elem_Constraint_Arg` (lines 361–368)

```fortran
  TYPE :: PH_Elem_Constraint_Arg
    INTEGER(i4)           :: ctype    = 0_i4         ! [IN]  constraint type code
    INTEGER(i4)           :: idof     = 0_i4         ! [IN]  local DOF index
    REAL(wp)              :: val      = 0.0_wp       ! [IN]  prescribed value
    REAL(wp)              :: penalty  = 0.0_wp       ! [IN]  penalty factor
    REAL(wp), ALLOCATABLE :: K_el(:,:)               ! [INOUT] element stiffness
    REAL(wp), ALLOCATABLE :: F_el(:)                 ! [INOUT] element force
  END TYPE PH_Elem_Constraint_Arg
```

### `PH_Elem_Itr_Asm_ArgHub_Real` (lines 382–387)

```fortran
  TYPE, PUBLIC :: PH_Elem_Itr_Asm_ArgHub_Real
    TYPE(PH_Elem_Core_Ke_Arg)   :: Ke
    TYPE(PH_Elem_Core_Fe_Arg)   :: Fe
    TYPE(PH_Elem_Core_Fint_Arg) :: Fint
    TYPE(PH_Elem_Core_Mass_Arg) :: Mass
  END TYPE PH_Elem_Itr_Asm_ArgHub_Real
```

### `PH_Elem_Lcl_Comp_ArgHub_Real` (lines 389–394)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_ArgHub_Real
    TYPE(PH_Elem_NL_TL_Arg)           :: nl_tl
    TYPE(PH_Elem_NL_UL_Arg)           :: nl_ul
    TYPE(PH_Elem_JacB_Arg)            :: jacb
    TYPE(PH_Elem_ComplexStiff_Form_Arg) :: cpx
  END TYPE PH_Elem_Lcl_Comp_ArgHub_Real
```

### `PH_Elem_Lcl_Brg_ArgHub_Real` (lines 396–399)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Brg_ArgHub_Real
    TYPE(PH_Elem_Contact_Arg)    :: contact
    TYPE(PH_Elem_Constraint_Arg) :: constr
  END TYPE PH_Elem_Lcl_Brg_ArgHub_Real
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Integrator_Ifc` | 134 | `SUBROUTINE PH_Elem_Integrator_Ifc(desc, state, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
